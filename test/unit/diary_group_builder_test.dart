import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiaryEntry entry({
    required String id,
    required DateTime createdAt,
    String methodId = 'v60',
    String methodName = 'V60',
    String? beanUuid = 'bean-1',
    String? beanName = 'Kayon',
    String? origin = 'Ethiopia',
    double? rating,
    int? tasteBalance,
  }) => DiaryEntry(
    statUuid: id,
    recipeId: 'recipe-$id',
    recipeName: 'Recipe $id',
    brewingMethodId: methodId,
    methodName: methodName,
    createdAt: createdAt,
    coffeeAmount: 15,
    waterAmount: 250,
    tasteBalance: tasteBalance,
    rating: rating,
    isMarked: false,
    coffeeBeansUuid: beanUuid,
    beanName: beanName,
    roaster: 'Test Roaster',
    origin: origin,
  );

  test('bean grouping skips entries without a linked bean', () {
    final entries = [
      entry(id: 'linked', createdAt: DateTime.utc(2026, 7, 2)),
      entry(
        id: 'unlinked',
        createdAt: DateTime.utc(2026, 7, 1),
        beanUuid: null,
      ),
    ];

    final groups = DiaryGroup.build(entries);

    expect(groups, hasLength(1));
    expect(groups.single.entries.single.statUuid, 'linked');
  });

  test('computes count, average, and chronological rating series', () {
    final entries = [
      entry(id: 'newest', createdAt: DateTime.utc(2026, 7, 3), rating: 5),
      entry(id: 'middle', createdAt: DateTime.utc(2026, 7, 2), rating: null),
      entry(id: 'oldest', createdAt: DateTime.utc(2026, 7, 1), rating: 3),
    ];

    final group = DiaryGroup.build(entries).single;

    expect(group.count, 3);
    expect(group.avgRating, 4);
    expect(group.ratingSeries, [3, 5]);
    expect(group.entries.map((item) => item.statUuid), [
      'newest',
      'middle',
      'oldest',
    ]);
  });

  test('latest balanced taste or 4.0 rating is dialed in', () {
    final balanced = DiaryGroup.build([
      entry(
        id: 'balanced',
        createdAt: DateTime.utc(2026, 7, 3),
        tasteBalance: 0,
      ),
    ]).single;
    final highlyRated = DiaryGroup.build([
      entry(id: 'rated', createdAt: DateTime.utc(2026, 7, 3), rating: 4),
    ]).single;
    final dialing = DiaryGroup.build([
      entry(
        id: 'dialing',
        createdAt: DateTime.utc(2026, 7, 3),
        rating: 3,
        tasteBalance: 1,
      ),
    ]).single;

    expect(balanced.isDialedIn, isTrue);
    expect(highlyRated.isDialedIn, isTrue);
    expect(dialing.isDialedIn, isFalse);
  });

  test('sorts groups by most recent brew descending', () {
    final groups = DiaryGroup.build([
      entry(
        id: 'older-group',
        createdAt: DateTime.utc(2026, 7, 1),
        beanUuid: 'older',
      ),
      entry(
        id: 'newer-group',
        createdAt: DateTime.utc(2026, 7, 3),
        beanUuid: 'newer',
      ),
    ]);

    expect(groups.map((group) => group.key), ['newer', 'older']);
  });
}
