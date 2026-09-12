import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
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
  late CoffeeBeansProvider beans;
  late UserStatProvider stats;
  late UserRecipeProvider recipes;

  setUp(() async {
    db = openTestDatabase();
    beans = CoffeeBeansProvider(db, DatabaseProvider(db));
    stats = UserStatProvider(db, beans);
    recipes = UserRecipeProvider(db);
    await db
        .into(db.brewingMethods)
        .insert(
          BrewingMethodsCompanion.insert(
            brewingMethodId: 'method-1',
            brewingMethod: 'V60',
          ),
        );
    // Real analytics so the delete events below are observable in the
    // buffer. Plain `test()`s — no FakeAsync, so the flush timer is fine.
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() async {
    AnalyticsService.resetForTesting();
    await db.close();
  });

  Future<UserStat> statRow(String uuid) => (db.select(
    db.userStats,
  )..where((r) => r.statUuid.equals(uuid))).getSingle();

  Future<CoffeeBean> beanRow(String uuid) => (db.select(
    db.coffeeBeans,
  )..where((r) => r.beansUuid.equals(uuid))).getSingle();

  Future<Recipe> recipeRow(String id) =>
      (db.select(db.recipes)..where((r) => r.id.equals(id))).getSingle();

  Future<void> seedBean({
    String beanUuid = 'bean-1',
    double packageWeight = 100,
  }) async {
    await db.coffeeBeansDao.insertCoffeeBeans(
      CoffeeBeansModel(
        beansUuid: beanUuid,
        roaster: 'Test Roaster',
        name: 'Test Beans',
        origin: 'Test Origin',
        packageWeightGrams: packageWeight,
        versionVector: VersionVector.initial('bean-device').toString(),
      ),
    );
  }

  Future<void> seedStatWithBean({
    String statUuid = 'stat-1',
    String? beanUuid = 'bean-1',
  }) async {
    if (beanUuid != null) {
      await seedBean(beanUuid: beanUuid);
    }
    await db.userStatsDao.insertUserStat(
      UserStatsModel(
        statUuid: statUuid,
        recipeId: 'recipe-1',
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 1,
        brewingMethodId: 'method-1',
        createdAt: DateTime.utc(2026, 7, 14),
        beans: beanUuid == null ? null : 'Test Beans',
        roaster: beanUuid == null ? null : 'Test Roaster',
        isMarked: false,
        coffeeBeansUuid: beanUuid,
        versionVector: VersionVector.initial('stat-device').toString(),
        isDeleted: false,
      ),
    );
  }

  Future<void> seedCustomRecipeWithBrew() async {
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
    await recipes.loadUserRecipes();
  }

  group('diary entry tombstones', () {
    test('deleteUserStat stamps deleted_at and hides the entry', () async {
      await seedStatWithBean(beanUuid: null);

      await stats.deleteUserStat('stat-1');

      final row = await statRow('stat-1');
      expect(row.isDeleted, isTrue);
      expect(row.deletedAt, isNotNull);
      expect(await db.userStatsDao.fetchStatByUuid('stat-1'), isNull);
      expect(await stats.fetchUserStatByUuid('stat-1'), isNull);
    });

    test('restoreUserStat clears is_deleted and deleted_at', () async {
      await seedStatWithBean(beanUuid: null);
      await stats.deleteUserStat('stat-1');

      await stats.restoreUserStat('stat-1');

      final row = await statRow('stat-1');
      expect(row.isDeleted, isFalse);
      expect(row.deletedAt, isNull);

      // The entry is visible on its surfaces again...
      expect(await db.userStatsDao.fetchStatByUuid('stat-1'), isNotNull);
      expect(await stats.fetchUserStatByUuid('stat-1'), isNotNull);

      // ...and the Supabase payload carries the explicit clear, so the
      // restored state round-trips through sync instead of re-tombstoning.
      final stat = (await stats.fetchUserStatByUuid('stat-1'))!;
      expect(
        stats.serializeUserStatForTesting(stat),
        containsPair('deleted_at', null),
      );
    });

    test(
      'restoreUserStat advances the version vector strictly beyond the delete',
      () async {
        await seedStatWithBean(beanUuid: null);
        final before = VersionVector.fromString(
          (await statRow('stat-1')).versionVector,
        );

        await stats.deleteUserStat('stat-1');
        final deleted = VersionVector.fromString(
          (await statRow('stat-1')).versionVector,
        );

        await stats.restoreUserStat('stat-1');
        final restored = VersionVector.fromString(
          (await statRow('stat-1')).versionVector,
        );

        expect(deleted.isNewerThan(before), isTrue);
        expect(restored.version, deleted.version + 1);
        expect(restored.isNewerThan(deleted), isTrue);
      },
    );

    test(
      'the restored vector wins the sync race an equal vector would lose',
      () async {
        // syncNewUserStats() compares _isRemoteNewer/_isLocalNewer first and
        // only falls back to its tie-break when the vectors are EQUAL — and
        // that tie-break deliberately prefers deletions over restorations. A
        // restore that reused the delete's vector would therefore be
        // re-deleted on the next sync. Pin both halves of that routing.
        await seedStatWithBean(beanUuid: null);
        await stats.deleteUserStat('stat-1');
        final tombstoneVector = VersionVector.fromString(
          (await statRow('stat-1')).versionVector,
        );

        await stats.restoreUserStat('stat-1');
        final restoredVector = VersionVector.fromString(
          (await statRow('stat-1')).versionVector,
        );

        // With the tombstone's vector (the broken behavior): neither side is
        // newer, so sync reaches the deletion-preferring tie-break.
        expect(tombstoneVector.isNewerThan(tombstoneVector), isFalse);
        // With the restored vector: the local row routes through the
        // local-newer branch, which pushes the restore to Supabase.
        expect(restoredVector.isNewerThan(tombstoneVector), isTrue);
      },
    );
  });

  group('coffee bean tombstones', () {
    test('deleteCoffeeBeans stamps deleted_at and hides the bean', () async {
      await seedBean();

      await beans.deleteCoffeeBeans('bean-1');

      final row = await beanRow('bean-1');
      expect(row.isDeleted, isTrue);
      expect(row.deletedAt, isNotNull);
      expect(await db.coffeeBeansDao.fetchCoffeeBeansByUuid('bean-1'), isNull);
    });

    test('restoreCoffeeBeans clears is_deleted and deleted_at', () async {
      await seedBean();
      await beans.deleteCoffeeBeans('bean-1');

      await beans.restoreCoffeeBeans('bean-1');

      final row = await beanRow('bean-1');
      expect(row.isDeleted, isFalse);
      expect(row.deletedAt, isNull);
      expect(
        await db.coffeeBeansDao.fetchCoffeeBeansByUuid('bean-1'),
        isNotNull,
      );
    });

    test(
      'restoreCoffeeBeans advances the version vector strictly beyond the delete',
      () async {
        await seedBean();
        final before = VersionVector.fromString(
          (await beanRow('bean-1')).versionVector,
        );

        await beans.deleteCoffeeBeans('bean-1');
        final deleted = VersionVector.fromString(
          (await beanRow('bean-1')).versionVector,
        );

        await beans.restoreCoffeeBeans('bean-1');
        final restored = VersionVector.fromString(
          (await beanRow('bean-1')).versionVector,
        );

        expect(deleted.isNewerThan(before), isTrue);
        expect(restored.version, deleted.version + 1);
        expect(restored.isNewerThan(deleted), isTrue);
      },
    );

    test('a restored bean still has its diary entries linked', () async {
      await seedStatWithBean();
      await beans.deleteCoffeeBeans('bean-1');
      await beans.restoreCoffeeBeans('bean-1');

      // The delete path no longer detaches the bean from its diary entries
      // (Phase 1 removed that), so the restored bean is linked again.
      final stat = (await db.userStatsDao.fetchStatByUuid('stat-1'))!;
      expect(stat.coffeeBeansUuid, 'bean-1');

      final entries = await db.userStatsDao.fetchDiaryEntries('en');
      expect(entries, hasLength(1));
      expect(entries.single.beanName, 'Test Beans');
      expect(entries.single.roaster, 'Test Roaster');
    });
  });

  group('custom recipe tombstones', () {
    test(
      'deleteUserRecipe stamps deleted_at and restoreUserRecipe clears it',
      () async {
        await seedCustomRecipeWithBrew();

        await recipes.deleteUserRecipe('usr-user-1-recipe');
        var row = await recipeRow('usr-user-1-recipe');
        expect(row.isDeleted, isTrue);
        expect(row.deletedAt, isNotNull);

        await recipes.restoreUserRecipe('usr-user-1-recipe');
        row = await recipeRow('usr-user-1-recipe');
        expect(row.isDeleted, isFalse);
        expect(row.deletedAt, isNull);
      },
    );

    test('a restored recipe is visible again on the browse surfaces', () async {
      await seedCustomRecipeWithBrew();
      await recipes.deleteUserRecipe('usr-user-1-recipe');
      expect(await db.recipesDao.getAllRecipes('en'), isEmpty);
      expect(
        recipes.userRecipes.any((r) => r.id == 'usr-user-1-recipe'),
        isFalse,
      );

      await recipes.restoreUserRecipe('usr-user-1-recipe');

      final ids = (await db.recipesDao.getAllRecipes('en')).map((r) => r.id);
      expect(ids, contains('usr-user-1-recipe'));
      expect(
        recipes.userRecipes.any((r) => r.id == 'usr-user-1-recipe'),
        isTrue,
      );

      // The brew history logged with the recipe survived the round trip.
      final entries = await db.userStatsDao.fetchDiaryEntries('en');
      expect(entries, hasLength(1));
      expect(entries.single.recipeName, 'My V60 recipe');
    });
  });

  group('delete analytics (plan 056 phase 5)', () {
    List<Map<String, dynamic>> eventsNamed(String name) =>
        AnalyticsService.instance.bufferedEventsForTesting
            .where((event) => event['event_name'] == name)
            .toList();

    test('bean_deleted reports linked brews and remaining stock', () async {
      await seedStatWithBean(); // 1 live entry linked to bean-1, 100 g bag

      await beans.deleteCoffeeBeans('bean-1');

      final events = eventsNamed('bean_deleted');
      expect(events, hasLength(1));
      expect(events.single['category'], 'beans');
      final properties = events.single['properties'] as Map;
      expect(properties['brew_count'], 1);
      expect(properties['has_linked_brews'], isTrue);
      expect(properties['has_stock_remaining'], isTrue);
      // Privacy rule: counts and booleans only — never the bean or roaster
      // name (the seed data carries both, so a leak would fail this).
      for (final value in properties.values) {
        expect(value, anyOf(isA<bool>(), isA<int>()));
      }
    });

    test('bean_deleted skips soft-deleted entries and empty bags', () async {
      await seedBean(packageWeight: 0);
      await db.userStatsDao.insertUserStat(
        UserStatsModel(
          statUuid: 'stat-tombstoned',
          recipeId: 'recipe-1',
          coffeeAmount: 15,
          waterAmount: 250,
          sweetnessSliderPosition: 1,
          strengthSliderPosition: 1,
          brewingMethodId: 'method-1',
          createdAt: DateTime.utc(2026, 7, 15),
          beans: 'Test Beans',
          roaster: 'Test Roaster',
          isMarked: false,
          coffeeBeansUuid: 'bean-1',
          versionVector: VersionVector.initial('stat-device').toString(),
          isDeleted: true,
        ),
      );

      await beans.deleteCoffeeBeans('bean-1');

      final events = eventsNamed('bean_deleted');
      expect(events, hasLength(1));
      final properties = events.single['properties'] as Map;
      // The only linked entry is soft-deleted — it must not be counted.
      expect(properties['brew_count'], 0);
      expect(properties['has_linked_brews'], isFalse);
      // package_weight_grams 0 is an empty bag: no remaining stock.
      expect(properties['has_stock_remaining'], isFalse);
    });

    test('user_recipe_deleted counts only live diary entries', () async {
      await seedCustomRecipeWithBrew(); // stat-1 live, recipe not public
      Future<void> addStat(String uuid, {required bool deleted}) =>
          db.userStatsDao.insertUserStat(
            UserStatsModel(
              statUuid: uuid,
              recipeId: 'usr-user-1-recipe',
              coffeeAmount: 15,
              waterAmount: 250,
              sweetnessSliderPosition: 1,
              strengthSliderPosition: 2,
              brewingMethodId: 'method-1',
              createdAt: DateTime(2024, 2, 1),
              isMarked: false,
              versionVector: VersionVector.initial('device-1').toString(),
              isDeleted: deleted,
            ),
          );
      await addStat('stat-2', deleted: false);
      await addStat('stat-tombstoned', deleted: true);

      await recipes.deleteUserRecipe('usr-user-1-recipe');

      final events = eventsNamed('user_recipe_deleted');
      expect(events, hasLength(1));
      expect(events.single['category'], 'general');
      final properties = events.single['properties'] as Map;
      // 2 live entries (stat-1, stat-2); the soft-deleted one is NOT counted.
      expect(properties['brew_count'], 2);
      expect(properties['is_public'], isFalse);
      // Privacy rule: counts and booleans only — never the recipe name.
      for (final value in properties.values) {
        expect(value, anyOf(isA<bool>(), isA<int>()));
      }
    });

    test('user_recipe_deleted flags a recipe that was public', () async {
      await db
          .into(db.recipes)
          .insert(
            RecipesCompanion.insert(
              id: 'usr-user-1-pub',
              brewingMethodId: 'method-1',
              coffeeAmount: 15,
              waterAmount: 250,
              waterTemp: 93,
              brewTime: 180,
              vendorId: const Value('usr-user-1'),
              isPublic: const Value(true),
            ),
          );
      await db.userStatsDao.insertUserStat(
        UserStatsModel(
          statUuid: 'stat-pub',
          recipeId: 'usr-user-1-pub',
          coffeeAmount: 15,
          waterAmount: 250,
          sweetnessSliderPosition: 1,
          strengthSliderPosition: 2,
          brewingMethodId: 'method-1',
          createdAt: DateTime(2024, 3, 1),
          isMarked: false,
          versionVector: VersionVector.initial('device-1').toString(),
          isDeleted: false,
        ),
      );

      await recipes.deleteUserRecipe('usr-user-1-pub');

      final events = eventsNamed('user_recipe_deleted');
      expect(events, hasLength(1));
      final properties = events.single['properties'] as Map;
      expect(properties['brew_count'], 1);
      expect(properties['is_public'], isTrue);
    });

    test('delete events stay silent when analytics never initialized', () async {
      AnalyticsService.resetForTesting(); // maybeInstance == null
      await seedBean();
      await seedCustomRecipeWithBrew();

      // The null-safe maybeInstance?.track form must not throw here.
      await beans.deleteCoffeeBeans('bean-1');
      await recipes.deleteUserRecipe('usr-user-1-recipe');

      expect(AnalyticsService.maybeInstance, isNull);
    });
  });
}
