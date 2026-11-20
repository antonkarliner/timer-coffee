import 'dart:convert';

import 'package:coffee_timer/database/account_database_scope.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/user_recipe_provider.dart';
import 'package:coffee_timer/services/recipe_publication.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'offline withdrawal stays pending under its owner until confirmation',
    () async {
      SharedPreferences.setMockInitialValues({});
      const owner = 'test-owner';
      const recipeId = 'usr-$owner-123';
      final user = User(
        id: owner,
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '',
      );
      Session? activeSession = Session(
        accessToken: 'local-test-token',
        tokenType: 'bearer',
        user: user,
      );
      bool online = false;
      final requests = <http.Request>[];
      final scope = AccountDatabaseScope(
        userId: owner,
        partitionId: owner,
        supabaseUrl: 'https://local.example',
        supabaseKey: 'test-key',
        currentSession: () => activeSession,
        httpClient: MockClient((request) async {
          requests.add(request);
          if (!online) throw http.ClientException('Offline');
          return http.Response(
            jsonEncode({'ispublic': false}),
            200,
            headers: {'Content-Type': 'application/json'},
            request: request,
          );
        }),
      );
      final db = AppDatabase(
        NativeDatabase.memory(),
        accountScope: scope,
        enableForeignKeyConstraints: false,
      );
      addTearDown(db.close);
      await db
          .into(db.recipes)
          .insert(
            RecipesCompanion.insert(
              id: recipeId,
              vendorId: const Value('usr-$owner'),
              brewingMethodId: 'v60',
              coffeeAmount: 15,
              waterAmount: 250,
              waterTemp: 94,
              brewTime: 60,
              isPublic: const Value(true),
            ),
          );

      final provider = UserRecipeProvider(db);
      addTearDown(provider.dispose);
      await expectLater(
        provider.unpublishRecipe(recipeId),
        throwsA(isA<PendingRecipeWithdrawal>()),
      );
      final prefs = await SharedPreferences.getInstance();
      final key = pendingRecipeWithdrawalKey(owner, recipeId);
      expect(prefs.getBool(key), isTrue);
      expect((await db.select(db.recipes).getSingle()).isPublic, isTrue);

      final ownerSession = activeSession;
      activeSession = null;
      online = true;
      expect(
        await confirmRecipeWithdrawal(db, scope.client, owner, recipeId),
        isFalse,
      );
      expect(prefs.getBool(key), isTrue);
      expect(requests, hasLength(1));

      activeSession = ownerSession;
      expect(
        await confirmRecipeWithdrawal(db, scope.client, owner, recipeId),
        isTrue,
      );
      expect(prefs.containsKey(key), isFalse);
      expect((await db.select(db.recipes).getSingle()).isPublic, isFalse);
      expect(requests.last.url.queryParameters['vendor_id'], 'eq.usr-$owner');
    },
  );
  test(
    'an active offline partition can create and edit its own recipes',
    () async {
      Session? activeSession;
      final scope = AccountDatabaseScope(
        userId: null,
        partitionId: 'offline-test',
        supabaseUrl: 'https://local.example',
        supabaseKey: 'test-key',
        currentSession: () => activeSession,
      );
      final db = AppDatabase(
        NativeDatabase.memory(),
        accountScope: scope,
        enableForeignKeyConstraints: false,
      );
      addTearDown(db.close);
      final provider = UserRecipeProvider(db);
      addTearDown(provider.dispose);
      final recipe = RecipeModel(
        id: 'usr-anonymous-123',
        vendorId: 'usr-anonymous',
        name: 'Offline coffee',
        brewingMethodId: 'v60',
        coffeeAmount: 15,
        waterAmount: 250,
        waterTemp: 94,
        brewTime: const Duration(minutes: 3),
        grindSize: 'Fine',
        shortDescription: '',
        steps: const [],
      );

      await provider.createUserRecipe(recipe);
      await provider.updateUserRecipe(recipe.copyWith(name: 'Edited offline'));
      expect(
        (await db.recipesDao.getRecipeModelById(recipe.id, 'en'))?.name,
        'Edited offline',
      );

      activeSession = Session(
        accessToken: 'local-test-token',
        tokenType: 'bearer',
        user: User(
          id: 'new-owner',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '',
        ),
      );
      await expectLater(
        provider.updateUserRecipe(recipe.copyWith(name: 'Wrong account')),
        throwsStateError,
      );
    },
  );

  test(
    'a confirmed import deduplicates live copies and skips cloud tombstones',
    () async {
      const owner = 'import-owner';
      final requests = <http.Request>[];
      final scope = AccountDatabaseScope(
        userId: owner,
        partitionId: owner,
        supabaseUrl: 'https://local.example',
        supabaseKey: 'test-key',
        currentSession: () => Session(
          accessToken: 'local-test-token',
          tokenType: 'bearer',
          user: User(
            id: owner,
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: '',
          ),
        ),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('null', 200, request: request);
        }),
      );
      final db = AppDatabase(
        NativeDatabase.memory(),
        accountScope: scope,
        enableForeignKeyConstraints: false,
      );
      addTearDown(db.close);
      final provider = UserRecipeProvider(db);
      addTearDown(provider.dispose);
      final recipe = <String, dynamic>{
        'id': 'usr-source-shared',
        'import_id': 'usr-45a9477e-609c-4efa-afe8-9bf06a84c654-legacy-root',
        // A legacy adaptation may retain its source ID after the root
        // author's account was deleted and its FK became null.
        'original_author_id': null,
        'brewing_method_id': 'v60',
        'coffee_amount': 15,
        'water_amount': 250,
        'water_temp': 94,
        'brew_time': 60,
        'user_recipe_localizations': [
          {
            'locale': 'en',
            'name': 'Published recipe',
            'grind_size': 'Fine',
            'short_description': '',
          },
        ],
        'user_steps': [
          {
            'locale': 'en',
            'step_order': 1,
            'description': 'Pour',
            'time': '60',
          },
        ],
      };

      final first = await provider.importSupabaseRecipe(recipe);
      expect(first, isNotNull);
      expect(await provider.importSupabaseRecipe(recipe), first);
      expect(requests, hasLength(1));

      await db.recipesDao.softDeleteRecipe(first!);
      final replacement = await provider.importSupabaseRecipe(recipe);
      expect(replacement, isNotNull);
      expect(replacement, isNot(first));
      expect(await provider.importSupabaseRecipe(recipe), replacement);
      expect(requests, hasLength(2));
      final liveCopy = (await db.recipesDao.getAllRecipes('en')).single;
      expect(liveCopy.id, replacement);
      expect(liveCopy.importId, recipe['id']);
      expect(liveCopy.originalAuthorId, isNull);
    },
  );
}
