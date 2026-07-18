import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/utils/diary_digest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiaryEntry entry({
    required String id,
    required DateTime createdAt,
    String methodName = 'V60',
    String? brewingMethodId,
    String? coffeeBeansUuid = 'bag-ethiopia',
    String? beanName = 'Ethiopia',
    String recipeName = 'Recipe',
    double? rating,
    int? tasteBalance,
  }) {
    return DiaryEntry(
      statUuid: id,
      recipeId: 'recipe-$id',
      recipeName: recipeName,
      brewingMethodId: brewingMethodId ?? methodName.toLowerCase(),
      methodName: methodName,
      createdAt: createdAt,
      coffeeAmount: 15,
      waterAmount: 250,
      rating: rating,
      tasteBalance: tasteBalance,
      isMarked: false,
      coffeeBeansUuid: coffeeBeansUuid,
      beanName: beanName,
    );
  }

  group('buildWeekDigest', () {
    test('returns null for fewer than two brews', () {
      expect(buildWeekDigest([]), isNull);
      expect(
        buildWeekDigest([
          entry(id: 'one', createdAt: DateTime.utc(2026, 7, 13, 8)),
        ]),
        isNull,
      );
    });

    test('breaks top-method count ties by the most recent brew', () {
      final digest = buildWeekDigest([
        entry(
          id: 'v60-old',
          createdAt: DateTime.utc(2026, 7, 13, 8),
          methodName: 'V60',
        ),
        entry(
          id: 'aero-old',
          createdAt: DateTime.utc(2026, 7, 14, 8),
          methodName: 'AeroPress',
        ),
        entry(
          id: 'v60-new',
          createdAt: DateTime.utc(2026, 7, 15, 8),
          methodName: 'V60',
        ),
        entry(
          id: 'aero-newest',
          createdAt: DateTime.utc(2026, 7, 16, 8),
          methodName: 'AeroPress',
        ),
      ]);

      expect(digest?.topMethodName, 'AeroPress');
      expect(digest?.weekStart, DateTime(2026, 7, 13));
    });

    test('breaks best-cup rating ties by the newest brew', () {
      final digest = buildWeekDigest([
        entry(
          id: 'older',
          createdAt: DateTime.utc(2026, 7, 13, 8),
          beanName: 'Older bean',
          rating: 4.5,
        ),
        entry(
          id: 'newer',
          createdAt: DateTime.utc(2026, 7, 14, 8),
          beanName: null,
          recipeName: 'Newer recipe',
          rating: 4.5,
        ),
      ]);

      expect(digest?.bestCup, (label: 'Newer recipe', rating: 4.5));
    });

    test(
      'reports a clear dial-in improvement for the same bean and method',
      () {
        final digest = buildWeekDigest([
          entry(
            id: 'sour',
            createdAt: DateTime.utc(2026, 7, 13, 8),
            tasteBalance: -1,
            rating: 3,
          ),
          entry(
            id: 'balanced',
            createdAt: DateTime.utc(2026, 7, 14, 8),
            tasteBalance: 0,
            rating: 4,
          ),
        ]);

        expect(digest?.dialIn?.beanName, 'Ethiopia');
        expect(digest?.dialIn?.methodName, 'V60');
      },
    );

    test('uses the newest labels for one UUID and method series', () {
      final digest = buildWeekDigest([
        entry(
          id: 'older',
          createdAt: DateTime.utc(2026, 7, 13, 8),
          beanName: 'Old label',
          methodName: 'Old V60 label',
          brewingMethodId: 'v60',
          tasteBalance: -1,
          rating: 3,
        ),
        entry(
          id: 'newer',
          createdAt: DateTime.utc(2026, 7, 14, 8),
          beanName: 'New label',
          methodName: 'V60',
          brewingMethodId: 'v60',
          tasteBalance: 0,
          rating: 4,
        ),
      ]);

      expect(digest?.dialIn?.beanName, 'New label');
      expect(digest?.dialIn?.methodName, 'V60');
    });

    test('does not merge same-named bags with different UUIDs', () {
      final digest = buildWeekDigest([
        entry(
          id: 'first-bag',
          createdAt: DateTime.utc(2026, 7, 13, 8),
          coffeeBeansUuid: 'bag-one',
          beanName: 'Kayon',
          tasteBalance: -1,
          rating: 3,
        ),
        entry(
          id: 'second-bag',
          createdAt: DateTime.utc(2026, 7, 14, 8),
          coffeeBeansUuid: 'bag-two',
          beanName: 'Kayon',
          tasteBalance: 0,
          rating: 4,
        ),
      ]);

      expect(digest?.dialIn, isNull);
    });

    test('does not merge one bag across different method IDs', () {
      final digest = buildWeekDigest([
        entry(
          id: 'first-method',
          createdAt: DateTime.utc(2026, 7, 13, 8),
          brewingMethodId: 'v60-one',
          tasteBalance: -1,
          rating: 3,
        ),
        entry(
          id: 'second-method',
          createdAt: DateTime.utc(2026, 7, 14, 8),
          brewingMethodId: 'v60-two',
          tasteBalance: 0,
          rating: 4,
        ),
      ]);

      expect(digest?.dialIn, isNull);
    });

    test('omits dial-in when no prior improvement is clearly present', () {
      final digest = buildWeekDigest([
        entry(
          id: 'first',
          createdAt: DateTime.utc(2026, 7, 13, 8),
          rating: 4.5,
        ),
        entry(
          id: 'second',
          createdAt: DateTime.utc(2026, 7, 14, 8),
          rating: 4.5,
        ),
      ]);

      expect(digest?.dialIn, isNull);
    });

    test('does not create dial-in facts for unlinked legacy entries', () {
      final older = entry(
        id: 'legacy-one',
        createdAt: DateTime.utc(2026, 7, 13, 8),
        coffeeBeansUuid: null,
        beanName: 'Kayon',
        tasteBalance: -1,
        rating: 3,
      );
      final newer = entry(
        id: 'legacy-two',
        createdAt: DateTime.utc(2026, 7, 14, 8),
        coffeeBeansUuid: null,
        beanName: 'Kayon',
        tasteBalance: 0,
        rating: 4,
      );

      expect(buildWeekDigest([older, newer])?.dialIn, isNull);
    });
  });

  test('normalizes linked bag identity without a name fallback', () {
    final linked = entry(
      id: 'linked',
      createdAt: DateTime.utc(2026, 7, 13, 8),
      coffeeBeansUuid: '  bag-id  ',
    );
    final unlinked = entry(
      id: 'unlinked',
      createdAt: DateTime.utc(2026, 7, 13, 8),
      coffeeBeansUuid: ' ',
      beanName: 'Kayon',
    );

    expect(linked.normalizedBagIdentity, 'bag-id');
    expect(unlinked.normalizedBagIdentity, isNull);
  });

  test(
    'onThisDay matches month and day, excludes current year, newest first',
    () {
      final matches = onThisDay([
        entry(id: 'current', createdAt: DateTime(2026, 7, 13, 8)),
        entry(id: 'wrong-day', createdAt: DateTime(2025, 7, 12, 8)),
        entry(id: 'older', createdAt: DateTime(2023, 7, 13, 8)),
        entry(id: 'newer', createdAt: DateTime(2025, 7, 13, 8)),
        entry(id: 'future', createdAt: DateTime(2027, 7, 13, 8)),
      ], DateTime(2026, 7, 13));

      expect(matches.map((entry) => entry.statUuid), ['newer', 'older']);
    },
  );
}
