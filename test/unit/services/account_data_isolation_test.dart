import 'dart:async';
import 'dart:convert';

import 'package:coffee_timer/database/account_data_store.dart';
import 'package:coffee_timer/database/account_database_scope.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/authentication_service.dart';
import 'package:coffee_timer/services/data_export_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _session(String id) => Session(
  accessToken: 'token-for-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '',
  ),
);

Future<void> _populate(
  AppDatabase db,
  String owner, {
  bool recipeOnly = false,
}) async {
  final recipe = 'usr-$owner-brew';
  await db.batch((batch) {
    const mode = InsertMode.insertOrIgnore;
    batch.insert(
      db.brewingMethods,
      BrewingMethodsCompanion.insert(
        brewingMethodId: 'method',
        brewingMethod: 'Pour over',
      ),
      mode: mode,
    );
    batch.insert(
      db.supportedLocales,
      SupportedLocalesCompanion.insert(locale: 'en', localeName: 'English'),
      mode: mode,
    );
    batch.insert(
      db.recipes,
      RecipesCompanion.insert(
        id: recipe,
        brewingMethodId: 'method',
        coffeeAmount: 15,
        waterAmount: 225,
        waterTemp: 94,
        brewTime: 180,
        vendorId: Value('usr-$owner'),
      ),
    );
    batch.insert(
      db.steps,
      StepsCompanion.insert(
        id: 'step-$owner',
        recipeId: recipe,
        stepOrder: 1,
        description: '$owner step',
        time: '30',
        locale: 'en',
      ),
    );
    batch.insert(
      db.recipeLocalizations,
      RecipeLocalizationsCompanion.insert(
        id: 'locale-$owner',
        recipeId: recipe,
        locale: 'en',
        name: '$owner recipe',
        grindSize: 'medium',
        shortDescription: '',
      ),
    );
    if (recipeOnly) return;
    batch.insert(
      db.coffeeBeans,
      CoffeeBeansCompanion.insert(
        beansUuid: 'bean-$owner',
        roaster: 'Roaster',
        name: '$owner beans',
        origin: 'Origin',
        versionVector: '',
      ),
    );
    batch.insert(
      db.userStats,
      UserStatsCompanion.insert(
        statUuid: 'stat-$owner',
        recipeId: recipe,
        coffeeAmount: 15,
        waterAmount: 225,
        sweetnessSliderPosition: 0,
        strengthSliderPosition: 0,
        brewingMethodId: 'method',
        notes: Value('$owner notes'),
        versionVector: '',
      ),
    );
    batch.insert(
      db.userRecipePreferences,
      UserRecipePreferencesCompanion.insert(recipeId: recipe, isFavorite: true),
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a late anonymous sign-in restores the offline partition it created', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final signup = Completer<http.Response>();
    final auth = GoTrueClient(
      url: 'https://account.example/auth/v1',
      autoRefreshToken: false,
      httpClient: MockClient((request) => signup.future),
    );
    final scopes = <AccountDatabaseScope>[];
    final databases = <AppDatabase>[];
    final store = AccountDataStore(
      auth: auth,
      prefs: prefs,
      supabaseUrl: 'https://account.example',
      supabaseKey: 'anon-key',
      databaseFactory: (scope) {
        scopes.add(scope);
        final database = AppDatabase(
          NativeDatabase.memory(),
          accountScope: scope,
        );
        databases.add(database);
        return database;
      },
    );
    addTearDown(() async {
      auth.dispose();
      for (final db in databases) {
        await db.close();
      }
      for (final scope in scopes) {
        await scope.client.dispose();
      }
    });

    final startup = store.startAnonymousSession();
    final offline = await store.openCurrent();
    await _populate(offline, 'anonymous');
    await (offline.update(offline.recipes)
          ..where((recipe) => recipe.id.equals('usr-anonymous-brew')))
        .write(const RecipesCompanion(vendorId: Value(null)));
    await _populate(offline, 'different-owner', recipeOnly: true);

    final mountedGuest = Completer<AppDatabase>();
    final subscription = auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        mountedGuest.complete(store.openCurrent());
      }
    });
    addTearDown(subscription.cancel);
    const guestId = 'd7252b03-4f3b-4938-aeec-5d050287a732';
    signup.complete(http.Response(jsonEncode({
      'access_token': 'fixture-access-token',
      'token_type': 'bearer',
      'refresh_token': 'fixture-refresh-token',
      'expires_in': 3600,
      'user': {
        'id': guestId,
        'aud': 'authenticated',
        'app_metadata': {'provider': 'anonymous'},
        'user_metadata': <String, dynamic>{},
        'is_anonymous': true,
        'created_at': '2026-01-01T00:00:00Z',
      },
    }), 200, headers: {'content-type': 'application/json'}));
    await startup;

    final guest = await mountedGuest.future;
    expect(guest.accountScope?.userId, guestId);
    final recipe = await guest.select(guest.recipes).getSingle();
    expect(recipe.id, 'usr-$guestId-brew');
    expect(recipe.vendorId, 'usr-$guestId');
    expect((await guest.select(guest.userStats).getSingle()).recipeId, recipe.id);
    expect(
      (await guest.select(guest.userRecipePreferences).getSingle()).recipeId,
      recipe.id,
    );
    expect(await guest.select(guest.coffeeBeans).get(), hasLength(1));
    expect(await offline.select(offline.recipes).get(), hasLength(2));
  });

  test('a new account sees and syncs only its own rows', () async {
    Session? active = _session('alice');
    final requests = <http.Request>[];

    AppDatabase partition(String id) {
      final scope = AccountDatabaseScope(
        userId: id,
        partitionId: 'user:$id',
        supabaseUrl: 'https://example.test',
        supabaseKey: 'test-key',
        currentSession: () => active,
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final database = AppDatabase(
        NativeDatabase.memory(),
        accountScope: scope,
      );
      addTearDown(scope.client.dispose);
      addTearDown(database.close);
      return database;
    }

    final alice = partition('alice');
    final bob = partition('bob');
    await _populate(alice, 'alice');
    await _populate(bob, 'bob');
    // A cached recipe from a different owner also has no place in an export.
    await _populate(bob, 'carol', recipeOnly: true);

    final aliceExport = DataExportService(database: alice);
    final bobExport = DataExportService(database: bob);
    expect(
      alice.accountScope!.databaseName,
      isNot(bob.accountScope!.databaseName),
    );
    await aliceExport.requestCode('owner@example.com');
    expect(requests.single.headers['authorization'], 'Bearer token-for-alice');
    requests.clear();

    final staleExport = aliceExport.confirmAndSend('123456');
    active = _session('bob');
    expect(await staleExport, isA<DataExportExpiredOrNoRequest>());
    expect(requests, isEmpty);
    expect((await bob.userStatsDao.fetchAllStats()).single.notes, 'bob notes');

    final preferences = DatabaseProvider(bob);
    final beans = CoffeeBeansProvider(bob, preferences);
    final brews = UserStatProvider(bob, beans);
    await preferences.uploadUserPreferencesToSupabase();
    await beans.batchUploadCoffeeBeans();
    await brews.batchUploadUserStats();
    expect(await bobExport.confirmAndSend('123456'), isA<DataExportSuccess>());
    expect(requests, hasLength(4));
    for (final request in requests) {
      expect(request.headers['authorization'], 'Bearer token-for-bob');
      expect(request.body, isNot(contains('alice')));
      expect(request.body, isNot(contains('carol')));
    }
    final payload = jsonDecode(requests.last.body) as Map;
    final dump = payload['localData'] as Map;
    expect(dump['brews'].single['notes'], 'bob notes');
    expect(dump['beans'].single['name'], 'bob beans');
    expect(dump['customRecipes'].single['id'], 'usr-bob-brew');
    expect(dump['recipeSteps'].single['description'], 'bob step');
    expect(dump['recipeLocalizations'].single['name'], 'bob recipe');

    // An already-created database request also cannot obtain Bob's token.
    await expectLater(
      alice.accountScope!.client.from('user_stats').select(),
      throwsA(isA<StateError>()),
    );
    expect(requests, hasLength(4));

    active = _session('alice');
    expect(
      (await alice.userStatsDao.fetchAllStats()).single.notes,
      'alice notes',
    );
    expect(
      await aliceExport.confirmAndSend('123456'),
      isA<DataExportSuccess>(),
    );
    expect(requests.last.headers['authorization'], 'Bearer token-for-alice');
  });

  test(
    'legacy recovery retains unknown ownership offline and copies exact-owner recipes',
    () async {
      final legacy = AppDatabase(NativeDatabase.memory());
      final current = AppDatabase(NativeDatabase.memory());
      addTearDown(legacy.close);
      addTearDown(current.close);
      await _populate(legacy, 'owner');
      await _populate(legacy, 'different-owner');

      await copyAccountData(
        source: legacy,
        destination: current,
        sourceUserId: 'owner',
        destinationUserId: 'owner',
        includePrivateRows: false,
      );

      expect(
        (await current.select(current.recipes).get()).single.id,
        'usr-owner-brew',
      );
      expect(
        (await current.select(current.steps).get()).single.description,
        'owner step',
      );
      expect(await current.select(current.userStats).get(), isEmpty);
      expect(await current.select(current.coffeeBeans).get(), isEmpty);
      expect(
        await current.select(current.userRecipePreferences).get(),
        isEmpty,
      );
      expect(await legacy.select(legacy.userStats).get(), hasLength(2));
    },
  );

  test(
    'proved guest transfer preserves beans, diary, preferences and recipe links',
    () async {
      final guest = AppDatabase(NativeDatabase.memory());
      final account = AppDatabase(NativeDatabase.memory());
      addTearDown(guest.close);
      addTearDown(account.close);
      await _populate(guest, 'guest');
      await _populate(account, 'account');

      await copyAccountData(
        source: guest,
        destination: account,
        sourceUserId: 'guest',
        destinationUserId: 'account-upgrade',
        includePrivateRows: true,
      );
      final migratedBrew = await (account.select(
        account.userStats,
      )..where((row) => row.statUuid.equals('stat-guest'))).getSingle();

      expect(migratedBrew.recipeId, 'usr-account-upgrade-brew');
      expect(migratedBrew.notes, 'guest notes');
      expect(await account.select(account.coffeeBeans).get(), hasLength(2));
      expect(
        (await account.select(account.steps).get())
            .where((row) => row.recipeId == 'usr-account-upgrade-brew')
            .single
            .description,
        'guest step',
      );
      expect(
        (await account.select(account.userRecipePreferences).get()).any(
          (row) => row.recipeId == 'usr-account-upgrade-brew',
        ),
        isTrue,
      );
      expect(
        (await guest.select(guest.recipes).get()).single.id,
        'usr-guest-brew',
      );

      expect(
        AuthenticationService.isVerifiedGuestMigration({
          'skipped': 'source_proof_required',
        }),
        isFalse,
      );
      expect(
        AuthenticationService.isVerifiedGuestMigration({
          'skipped': 'old_user_not_anonymous',
        }),
        isFalse,
      );
      expect(
        AuthenticationService.isVerifiedGuestMigration({
          'oldUserDeleted': true,
        }),
        isTrue,
      );
      expect(
        AuthenticationService.isVerifiedGuestMigration({
          'skipped': 'already_migrated',
        }),
        isTrue,
      );
    },
  );

  test('a verified handoff retries only for its recorded destination', () async {
    SharedPreferences.setMockInitialValues({'legacyRecipesRecovered.guest': true});
    final prefs = await SharedPreferences.getInstance();
    final auth = GoTrueClient(
      url: 'https://account.example/auth/v1',
      autoRefreshToken: false,
      httpClient: MockClient((_) async => throw StateError('Unexpected request')),
    );
    addTearDown(auth.dispose);

    Future<void> restoreSession(String userId) async {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      final claims = base64Url.encode(utf8.encode(jsonEncode({
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        'sub': userId,
        'role': 'authenticated',
      }))).replaceAll('=', '');
      await auth.recoverSession(jsonEncode({
        'access_token': 'test.$claims.signature',
        'expires_in': 3600,
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'user': {
          'id': userId,
          'aud': 'authenticated',
          'app_metadata': {'provider': 'email'},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }));
    }

    final source = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    await _populate(source, 'guest');
    final firstAttempt = AccountDataStore(
      auth: auth,
      prefs: prefs,
      supabaseUrl: 'https://account.example',
      supabaseKey: 'anon-key',
      databaseFactory: (scope) {
        addTearDown(scope.client.dispose);
        if (scope.userId == 'guest') return source;
        throw StateError('Destination storage temporarily unavailable');
      },
    );
    await restoreSession('destination');
    await expectLater(
      firstAttempt.migrateVerifiedGuest('guest', 'destination'),
      throwsStateError,
    );

    final restarted = AccountDataStore(
      auth: auth,
      prefs: prefs,
      supabaseUrl: 'https://account.example',
      supabaseKey: 'anon-key',
      databaseFactory: (scope) {
        addTearDown(scope.client.dispose);
        if (scope.userId == 'guest') return source;
        final db = AppDatabase(NativeDatabase.memory(), accountScope: scope);
        addTearDown(db.close);
        return db;
      },
    );
    await restoreSession('unrelated-account');
    final unrelated = await restarted.openCurrent();
    expect(await unrelated.select(unrelated.recipes).get(), isEmpty);

    await restoreSession('destination');
    final destination = await restarted.openCurrent();
    final copied = await destination.select(destination.recipes).getSingle();
    expect(copied.id, 'usr-destination-brew');
    expect((await destination.select(destination.userStats).getSingle()).recipeId, copied.id);
    expect((await source.select(source.recipes).getSingle()).id, 'usr-guest-brew');
  });
}
