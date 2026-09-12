import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/user_recipe_provider.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_database.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  late AppDatabase db;
  late UserRecipeProvider provider;

  setUp(() {
    db = openTestDatabase();
    provider = UserRecipeProvider(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCustomRecipeWithBrew() async {
    await db
        .into(db.brewingMethods)
        .insert(
          BrewingMethodsCompanion.insert(
            brewingMethodId: 'method-1',
            brewingMethod: 'V60',
          ),
        );
    await db
        .into(db.recipes)
        .insert(
          RecipesCompanion.insert(
            id: 'usr-user-1-recipe',
            brewingMethodId: 'method-1',
            coffeeAmount: 15,
            waterAmount: 250,
            waterTemp: 93,
            brewTime: 180,
            vendorId: const Value('usr-user-1'),
          ),
        );
    await db
        .into(db.recipeLocalizations)
        .insert(
          RecipeLocalizationsCompanion.insert(
            id: 'usr-user-1-recipe-en',
            recipeId: 'usr-user-1-recipe',
            locale: 'en',
            name: 'My V60 recipe',
            grindSize: 'Medium-fine',
            shortDescription: 'A personal recipe',
          ),
        );
    await db.userStatsDao.insertUserStat(
      UserStatsModel(
        statUuid: 'stat-1',
        recipeId: 'usr-user-1-recipe',
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 2,
        brewingMethodId: 'method-1',
        createdAt: DateTime(2024, 1, 15),
        isMarked: false,
        versionVector: VersionVector.initial('device-1').toString(),
        isDeleted: false,
      ),
    );
    await provider.loadUserRecipes();
  }

  test(
    'deleteUserRecipe tombstones the recipe and keeps its diary entries '
    'intact and readable',
    () async {
      await seedCustomRecipeWithBrew();

      await provider.deleteUserRecipe('usr-user-1-recipe');

      // The recipe row survives as a tombstone...
      final row = await (db.select(db.recipes)
            ..where((r) => r.id.equals('usr-user-1-recipe')))
          .getSingle();
      expect(row.isDeleted, isTrue);
      expect(row.deletedAt, isNotNull);

      // ...the user_stats row still exists...
      final stat = await db.userStatsDao.fetchStatByUuid('stat-1');
      expect(stat, isNotNull);

      // ...and fetchDiaryEntries still returns the brew with its recipe name.
      final entries = await db.userStatsDao.fetchDiaryEntries('en');
      expect(entries, hasLength(1));
      expect(entries.single.statUuid, 'stat-1');
      expect(entries.single.recipeName, 'My V60 recipe');
      expect(entries.single.methodName, 'V60');

      // The deleted recipe leaves the provider state.
      expect(
        provider.userRecipes.any((r) => r.id == 'usr-user-1-recipe'),
        isFalse,
      );
    },
  );

  test(
    'a tombstoned recipe is invisible on browse surfaces but still openable '
    'from diary history',
    () async {
      await seedCustomRecipeWithBrew();
      await provider.deleteUserRecipe('usr-user-1-recipe');

      expect(await db.recipesDao.getAllRecipes('en'), isEmpty);
      expect(
        await db.recipesDao.getRecipeModelById('usr-user-1-recipe', 'en'),
        isNotNull,
      );
    },
  );

  test(
    'saving (or importing) over a deleted recipe id makes it visible again',
    () async {
      await seedCustomRecipeWithBrew();
      await provider.deleteUserRecipe('usr-user-1-recipe');

      final model = await db.recipesDao.getRecipeModelById(
        'usr-user-1-recipe',
        'en',
      );
      expect(model, isNotNull);

      // The save path writes the existing recipe id and must clear the
      // tombstone, mirroring what a re-import does.
      await provider.updateUserRecipe(model!);

      final row = await (db.select(db.recipes)
            ..where((r) => r.id.equals('usr-user-1-recipe')))
          .getSingle();
      expect(row.isDeleted, isFalse);
      expect(row.deletedAt, isNull);

      final ids = (await db.recipesDao.getAllRecipes('en')).map((r) => r.id);
      expect(ids, contains('usr-user-1-recipe'));
    },
  );
}
