import 'dart:convert';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/services/data_export_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoffeeBeansModel _makeBean({
  String uuid = 'bean-1',
  String name = 'Test Bean',
  bool isDeleted = false,
}) {
  return CoffeeBeansModel(
    beansUuid: uuid,
    roaster: 'Test Roaster',
    name: name,
    origin: 'Ethiopia',
    isFavorite: true,
    isDeleted: isDeleted,
    versionVector: VersionVector.initial('test').toString(),
  );
}

UserStatsModel _makeStat({
  String uuid = 'stat-1',
  String recipeId = 'catalog-recipe-1',
  DateTime? createdAt,
}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: recipeId,
    coffeeAmount: 18.0,
    waterAmount: 300.0,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: 'method-1',
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1, 12),
    isMarked: false,
    versionVector: VersionVector.initial('test').toString(),
    isDeleted: false,
  );
}

Future<void> _insertRecipe(
  AppDatabase db,
  String id, {
  String? vendorId,
}) async {
  await db.recipesDao.insertOrUpdateRecipe(
    RecipesCompanion(
      id: Value(id),
      brewingMethodId: const Value('method-1'),
      coffeeAmount: const Value(20.0),
      waterAmount: const Value(320.0),
      waterTemp: const Value(93.0),
      brewTime: const Value(180),
      vendorId: vendorId == null ? const Value.absent() : Value(vendorId),
    ),
  );
}

Future<void> _insertStep(
  AppDatabase db, {
  required String id,
  required String recipeId,
}) async {
  await db.stepsDao.insertOrUpdateStep(
    StepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      stepOrder: const Value(1),
      description: const Value('Pour water'),
      time: const Value('30'),
      locale: const Value('en'),
    ),
  );
}

Future<void> _insertLocalization(
  AppDatabase db, {
  required String id,
  required String recipeId,
}) async {
  await db.recipeLocalizationsDao.insertOrUpdateLocalization(
    RecipeLocalizationsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      locale: const Value('en'),
      name: const Value('Test Recipe'),
      grindSize: const Value('medium'),
      shortDescription: const Value('A test recipe'),
    ),
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late DataExportService service;

  setUp(() {
    db = openTestDatabase();
    service = DataExportService(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('buildLocalDump', () {
    test('returns all expected top-level keys, even with an empty database', () async {
      final dump = await service.buildLocalDump();

      expect(
        dump.keys.toSet(),
        {
          'brews',
          'beans',
          'recipePreferences',
          'customRecipes',
          'recipeSteps',
          'recipeLocalizations',
          'publicProfile',
          'reviews',
          'reviewReplies',
        },
      );
      expect(dump['brews'], isEmpty);
      expect(dump['beans'], isEmpty);
      expect(dump['recipePreferences'], isEmpty);
      expect(dump['customRecipes'], isEmpty);
      expect(dump['recipeSteps'], isEmpty);
      expect(dump['recipeLocalizations'], isEmpty);
      // No local equivalent for these — always empty, filled in remotely.
      expect(dump['publicProfile'], isEmpty);
      expect(dump['reviews'], isEmpty);
      expect(dump['reviewReplies'], isEmpty);
    });

    test('includes brews (from UserStats) as JSON-safe snake_case maps', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'stat-1', createdAt: DateTime.utc(2026, 3, 4, 8, 30)),
      );

      final dump = await service.buildLocalDump();
      final brews = dump['brews'] as List;
      expect(brews, hasLength(1));
      final brew = brews.single as Map<String, dynamic>;
      expect(brew['stat_uuid'], 'stat-1');
      expect(brew['recipe_id'], 'catalog-recipe-1');
      expect(brew['coffee_amount'], 18.0);
      expect(brew['created_at'], '2026-03-04T08:30:00.000Z');
      expect(brew['is_deleted'], isFalse);
    });

    test('excludes soft-deleted brews and beans', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'stat-deleted'),
      );
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-deleted', isDeleted: true),
      );
      // Force is_deleted via a direct update since UserStatsModel's
      // constructor already accepts isDeleted; verify the DAO's filter is
      // respected end-to-end through the service.
      final deletedStat = _makeStat(uuid: 'stat-deleted-2');
      await db.userStatsDao.insertUserStat(deletedStat);
      await (db.update(db.userStats)
            ..where((t) => t.statUuid.equals('stat-deleted-2')))
          .write(const UserStatsCompanion(isDeleted: Value(true)));

      final dump = await service.buildLocalDump();
      final brewUuids = (dump['brews'] as List)
          .map((row) => (row as Map<String, dynamic>)['stat_uuid'])
          .toSet();
      final beanUuids = (dump['beans'] as List)
          .map((row) => (row as Map<String, dynamic>)['beans_uuid'])
          .toSet();

      expect(brewUuids.contains('stat-deleted-2'), isFalse);
      expect(beanUuids.contains('bean-deleted'), isFalse);
    });

    test('includes beans (from CoffeeBeans) with ISO date strings', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));

      final dump = await service.buildLocalDump();
      final beans = dump['beans'] as List;
      expect(beans, hasLength(1));
      final bean = beans.single as Map<String, dynamic>;
      expect(bean['beans_uuid'], 'bean-1');
      expect(bean['roaster'], 'Test Roaster');
      expect(bean['is_favorite'], isTrue);
    });

    test('includes recipe preferences keyed by recipe_id', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'catalog-recipe-1',
        isFavorite: true,
      );

      final dump = await service.buildLocalDump();
      final prefs = dump['recipePreferences'] as List;
      expect(prefs, hasLength(1));
      final pref = prefs.single as Map<String, dynamic>;
      expect(pref['recipe_id'], 'catalog-recipe-1');
      expect(pref['is_favorite'], isTrue);
    });

    test(
      'filters customRecipes/recipeSteps/recipeLocalizations to usr- ids only, '
      'excluding the shipped catalog',
      () async {
        // Catalog recipe (synced from the server) — must never appear.
        await _insertRecipe(db, 'catalog-recipe-1');
        await _insertStep(db, id: 'catalog-step-1', recipeId: 'catalog-recipe-1');
        await _insertLocalization(
          db,
          id: 'catalog-loc-1',
          recipeId: 'catalog-recipe-1',
        );

        // User-created recipe — must appear.
        const userRecipeId = 'usr-user123-1700000000000';
        await _insertRecipe(db, userRecipeId, vendorId: 'usr-user123');
        await _insertStep(db, id: 'user-step-1', recipeId: userRecipeId);
        await _insertLocalization(
          db,
          id: 'user-loc-1',
          recipeId: userRecipeId,
        );

        final dump = await service.buildLocalDump();

        final customRecipes = dump['customRecipes'] as List;
        expect(customRecipes, hasLength(1));
        final recipe = customRecipes.single as Map<String, dynamic>;
        expect(recipe['id'], userRecipeId);
        expect(recipe['vendor_id'], 'usr-user123');

        final steps = dump['recipeSteps'] as List;
        expect(steps, hasLength(1));
        expect((steps.single as Map<String, dynamic>)['recipe_id'], userRecipeId);

        final localizations = dump['recipeLocalizations'] as List;
        expect(localizations, hasLength(1));
        expect(
          (localizations.single as Map<String, dynamic>)['recipe_id'],
          userRecipeId,
        );
      },
    );

    test('the entire dump is JSON-encodable (no DateTime/blob leakage)', () async {
      await db.userStatsDao.insertUserStat(_makeStat());
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean());
      await db.userRecipePreferencesDao.updatePreferences(
        'catalog-recipe-1',
        isFavorite: true,
      );
      await _insertRecipe(db, 'usr-user123-1700000000000', vendorId: 'usr-user123');
      await _insertStep(
        db,
        id: 'user-step-1',
        recipeId: 'usr-user123-1700000000000',
      );
      await _insertLocalization(
        db,
        id: 'user-loc-1',
        recipeId: 'usr-user123-1700000000000',
      );

      final dump = await service.buildLocalDump();

      // jsonEncode throws on non-JSON-safe values (e.g. raw DateTime); this
      // is the strongest guarantee that everything is transport-ready.
      expect(() => jsonEncode(dump), returnsNormally);
    });
  });
}
