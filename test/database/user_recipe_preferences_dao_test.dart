import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Inserts a minimal recipe row (FK constraints are off in tests,
/// but having a real row makes some tests clearer).
Future<void> insertRecipe(AppDatabase db, String id) async {
  await db.into(db.recipes).insert(RecipesCompanion(
    id: Value(id),
    brewingMethodId: const Value('method-1'),
    coffeeAmount: const Value(20.0),
    waterAmount: const Value(320.0),
    waterTemp: const Value(93.0),
    brewTime: const Value(180),
  ));
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('getPreferencesForRecipe', () {
    test('returns null when no preferences exist', () async {
      final result =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(result, isNull);
    });

    test('returns preferences after creation', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: true);

      final result =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(result, isNotNull);
      expect(result!.isFavorite, isTrue);
    });
  });

  group('updatePreferences - create (no existing record)', () {
    test('creates record with isFavorite=true', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: true);

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.isFavorite, isTrue);
    });

    test('defaults isFavorite to false when not provided', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1');

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.isFavorite, isFalse);
    });

    test('creates record with custom coffee and water amounts', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        customCoffeeAmount: 18.5,
        customWaterAmount: 296.0,
      );

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.customCoffeeAmount, 18.5);
      expect(prefs.customWaterAmount, 296.0);
    });

    test('creates record with custom grind size', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        customGrindSize: 'medium-coarse',
      );

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.customGrindSize, 'medium-coarse');
    });

    test('creates record with sweetness and strength slider positions', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        sweetnessSliderPosition: 3,
        strengthSliderPosition: 1,
      );

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.sweetnessSliderPosition, 3);
      expect(prefs.strengthSliderPosition, 1);
    });
  });

  group('updatePreferences - update (existing record)', () {
    setUp(() async {
      // Create initial preferences
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        isFavorite: false,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 2,
      );
    });

    test('updates isFavorite from false to true', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: true);

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.isFavorite, isTrue);
    });

    test('not providing isFavorite leaves it unchanged', () async {
      // Set to true first
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: true);

      // Update without isFavorite
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        customCoffeeAmount: 25.0,
      );

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.isFavorite, isTrue); // should remain true
    });

    test('updating customGrindSize does not change slider positions', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        customGrindSize: 'coarse',
      );

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.customGrindSize, 'coarse');
      expect(prefs.sweetnessSliderPosition, 1); // unchanged
      expect(prefs.strengthSliderPosition, 2); // unchanged
    });

    test('updating slider positions only changes those fields', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        sweetnessSliderPosition: 3,
      );

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.sweetnessSliderPosition, 3);
      expect(prefs.strengthSliderPosition, 2); // unchanged
    });
  });

  group('clearCustomAmounts', () {
    test('nulls custom coffee and water amounts', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        customCoffeeAmount: 20.0,
        customWaterAmount: 240.0,
      );

      await db.userRecipePreferencesDao.clearCustomAmounts('r1');

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.customCoffeeAmount, isNull);
      expect(prefs.customWaterAmount, isNull);
    });

    test('leaves other preference fields untouched', () async {
      await db.userRecipePreferencesDao.updatePreferences(
        'r1',
        isFavorite: true,
        customGrindSize: 'medium-coarse',
        sweetnessSliderPosition: 3,
        customCoffeeAmount: 20.0,
        customWaterAmount: 240.0,
      );

      await db.userRecipePreferencesDao.clearCustomAmounts('r1');

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('r1');
      expect(prefs!.isFavorite, isTrue);
      expect(prefs.customGrindSize, 'medium-coarse');
      expect(prefs.sweetnessSliderPosition, 3);
    });

    test('is a no-op when no preference row exists', () async {
      await db.userRecipePreferencesDao.clearCustomAmounts('missing');

      final prefs =
          await db.userRecipePreferencesDao.getPreferencesForRecipe('missing');
      expect(prefs, isNull);
    });
  });

  group('getLastUsedRecipe', () {
    test('returns null when no preferences exist', () async {
      final result = await db.userRecipePreferencesDao.getLastUsedRecipe();
      expect(result, isNull);
    });

    test('returns only record when one exists', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1');

      final last = await db.userRecipePreferencesDao.getLastUsedRecipe();
      expect(last!.recipeId, 'r1');
    });

    test('returns most recently touched recipe', () async {
      // Insert directly with explicit timestamps to avoid same-millisecond flakiness
      await db.into(db.userRecipePreferences).insert(
        UserRecipePreferencesCompanion(
          recipeId: const Value('r1'),
          lastUsed: Value(DateTime(2024, 1, 1)),
          isFavorite: const Value(false),
        ),
      );
      await db.into(db.userRecipePreferences).insert(
        UserRecipePreferencesCompanion(
          recipeId: const Value('r2'),
          lastUsed: Value(DateTime(2024, 6, 1)),
          isFavorite: const Value(false),
        ),
      );

      final last = await db.userRecipePreferencesDao.getLastUsedRecipe();
      expect(last!.recipeId, 'r2');
    });
  });

  group('getFavoritePreferences', () {
    test('returns only favorited recipes', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: true);
      await db.userRecipePreferencesDao.updatePreferences('r2', isFavorite: false);
      await db.userRecipePreferencesDao.updatePreferences('r3', isFavorite: true);

      final favorites =
          await db.userRecipePreferencesDao.getFavoritePreferences();

      expect(favorites.length, 2);
      expect(
        favorites.map((p) => p.recipeId),
        containsAll(['r1', 'r3']),
      );
    });

    test('returns empty list when no favorites', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: false);

      final favorites =
          await db.userRecipePreferencesDao.getFavoritePreferences();
      expect(favorites, isEmpty);
    });

    test('returns empty list when no preferences at all', () async {
      final favorites =
          await db.userRecipePreferencesDao.getFavoritePreferences();
      expect(favorites, isEmpty);
    });
  });

  group('getAllPreferences', () {
    test('returns all records regardless of favorite status', () async {
      await db.userRecipePreferencesDao.updatePreferences('r1', isFavorite: true);
      await db.userRecipePreferencesDao.updatePreferences('r2', isFavorite: false);

      final all = await db.userRecipePreferencesDao.getAllPreferences();
      expect(all.length, 2);
    });
  });
}
