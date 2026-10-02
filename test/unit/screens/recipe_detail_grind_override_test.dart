import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/screens/recipe_detail_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  group('decideGrindSizeOverride', () {
    test('keeps the override when the field comes from a bean', () {
      expect(
        decideGrindSizeOverride(
          fieldText: 'Fine',
          grindSizeFromBean: true,
          defaultGrindSize: 'Medium',
          currentOverride: 'Coarse',
        ),
        (action: GrindSizeOverrideAction.keep, value: null),
      );
    });

    for (final fieldText in ['', 'Medium']) {
      test('keeps "$fieldText" without an existing override', () {
        expect(
          decideGrindSizeOverride(
            fieldText: fieldText,
            grindSizeFromBean: false,
            defaultGrindSize: 'Medium',
            currentOverride: null,
          ),
          (action: GrindSizeOverrideAction.keep, value: null),
        );
      });

      test('clears "$fieldText" with an existing override', () {
        expect(
          decideGrindSizeOverride(
            fieldText: fieldText,
            grindSizeFromBean: false,
            defaultGrindSize: 'Medium',
            currentOverride: 'Coarse',
          ),
          (action: GrindSizeOverrideAction.clear, value: null),
        );
      });
    }

    test('keeps a field equal to the current override', () {
      expect(
        decideGrindSizeOverride(
          fieldText: 'Coarse',
          grindSizeFromBean: false,
          defaultGrindSize: 'Medium',
          currentOverride: 'Coarse',
        ),
        (action: GrindSizeOverrideAction.keep, value: null),
      );
    });

    test('sets a real edit', () {
      expect(
        decideGrindSizeOverride(
          fieldText: 'Fine',
          grindSizeFromBean: false,
          defaultGrindSize: 'Medium',
          currentOverride: 'Coarse',
        ),
        (action: GrindSizeOverrideAction.set, value: 'Fine'),
      );
    });

    test('trims surrounding whitespace for comparisons and saved edits', () {
      for (final entry in [
        ('   ', GrindSizeOverrideAction.clear, null),
        (' Medium ', GrindSizeOverrideAction.clear, null),
        (' Coarse ', GrindSizeOverrideAction.keep, null),
        (' Fine ', GrindSizeOverrideAction.set, 'Fine'),
      ]) {
        expect(
          decideGrindSizeOverride(
            fieldText: entry.$1,
            grindSizeFromBean: false,
            defaultGrindSize: ' Medium ',
            currentOverride: ' Coarse ',
          ),
          (action: entry.$2, value: entry.$3),
        );
      }
    });

    test('compares text exactly without folding case', () {
      expect(
        decideGrindSizeOverride(
          fieldText: 'medium',
          grindSizeFromBean: false,
          defaultGrindSize: 'Medium',
          currentOverride: null,
        ),
        (action: GrindSizeOverrideAction.set, value: 'medium'),
      );
    });
  });

  group('clearGrindOverridesMatchingDefaults', () {
    late AppDatabase db;

    setUp(() {
      db = openTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedRecipe(
      String recipeId,
      String? override,
      Map<String, String> defaults,
    ) async {
      await db
          .into(db.recipes)
          .insert(
            RecipesCompanion.insert(
              id: recipeId,
              brewingMethodId: 'method-1',
              coffeeAmount: 20,
              waterAmount: 320,
              waterTemp: 93,
              brewTime: 180,
            ),
          );
      for (final entry in defaults.entries) {
        await db
            .into(db.recipeLocalizations)
            .insert(
              RecipeLocalizationsCompanion.insert(
                id: '$recipeId-${entry.key}',
                recipeId: recipeId,
                locale: entry.key,
                name: recipeId,
                grindSize: entry.value,
                shortDescription: '',
              ),
            );
      }
      await db
          .into(db.userRecipePreferences)
          .insert(
            UserRecipePreferencesCompanion.insert(
              recipeId: recipeId,
              isFavorite: true,
              lastUsed: Value(DateTime(2024, 1, 15)),
              customGrindSize: Value(override),
              customCoffeeAmount: const Value(18),
              customWaterAmount: const Value(300),
              customWaterTemp: const Value(91),
              sweetnessSliderPosition: const Value(3),
              strengthSliderPosition: const Value(4),
              coffeeChroniclerSliderPosition: const Value(5),
            ),
          );
    }

    test(
      'clears only matching defaults and preserves every other field',
      () async {
        const defaults = {'en': 'Medium', 'fa': 'متوسط'};
        await seedRecipe('en-match', 'Medium', defaults);
        await seedRecipe('fa-match', 'متوسط', defaults);
        await seedRecipe('override-whitespace', '\t Medium \n', defaults);
        await seedRecipe('default-whitespace', 'Medium', {
          'en': '\t Medium \n',
        });
        await seedRecipe('both-whitespace', '\u00a0Medium\u00a0', {
          'en': '\nMedium\t',
        });
        await seedRecipe('multiple-matches', 'Medium', {
          'en': 'Medium',
          'fa': 'Medium',
        });
        await seedRecipe('real-override', 'Coarse', defaults);
        await seedRecipe('case-difference', 'medium', defaults);
        await seedRecipe('null-override', null, defaults);
        final before = await db.userRecipePreferencesDao.getAllPreferences();
        const clearedIds = [
          'en-match',
          'fa-match',
          'override-whitespace',
          'default-whitespace',
          'both-whitespace',
          'multiple-matches',
        ];

        final result = await db.userRecipePreferencesDao
            .clearGrindOverridesMatchingDefaults();

        expect(result, unorderedEquals(clearedIds));
        final after = await db.userRecipePreferencesDao.getAllPreferences();
        expect(
          after,
          unorderedEquals(
            before.map(
              (preference) => clearedIds.contains(preference.recipeId)
                  ? preference.copyWith(customGrindSize: const Value(null))
                  : preference,
            ),
          ),
        );
        expect(
          await db.userRecipePreferencesDao
              .clearGrindOverridesMatchingDefaults(),
          isEmpty,
        );
      },
    );

    test('keeps an override matching only another recipe default', () async {
      await seedRecipe('first', 'Coarse', {'en': 'Medium'});
      await seedRecipe('second', null, {'en': 'Coarse'});
      final before = await db.userRecipePreferencesDao.getAllPreferences();

      expect(
        await db.userRecipePreferencesDao.clearGrindOverridesMatchingDefaults(),
        isEmpty,
      );
      expect(
        await db.userRecipePreferencesDao.getAllPreferences(),
        unorderedEquals(before),
      );
    });
  });

  group('clearCustomGrindSize', () {
    late AppDatabase db;

    setUp(() {
      db = openTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'clears only the grind override and preserves amounts and lastUsed',
      () async {
        final lastUsed = DateTime(2024, 1, 15);
        await db
            .into(db.userRecipePreferences)
            .insert(
              UserRecipePreferencesCompanion.insert(
                recipeId: '106',
                lastUsed: Value(lastUsed),
                isFavorite: false,
                customGrindSize: const Value('Coarse'),
                customCoffeeAmount: const Value(18),
                customWaterAmount: const Value(300),
              ),
            );

        await db.userRecipePreferencesDao.clearCustomGrindSize('106');

        final preference = await db.userRecipePreferencesDao
            .getPreferencesForRecipe('106');
        expect(preference, isNotNull);
        expect(preference!.customGrindSize, isNull);
        expect(preference.customCoffeeAmount, 18);
        expect(preference.customWaterAmount, 300);
        expect(preference.lastUsed, lastUsed);
      },
    );

    test('does not create a preference row when none exists', () async {
      await db.userRecipePreferencesDao.clearCustomGrindSize('missing');

      expect(await db.userRecipePreferencesDao.getAllPreferences(), isEmpty);
    });
  });
}
