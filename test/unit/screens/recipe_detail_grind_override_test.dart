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
