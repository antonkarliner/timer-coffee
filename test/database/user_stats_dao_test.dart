import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

UserStatsModel _makeStat({
  String uuid = 'stat-uuid-1',
  String recipeId = 'recipe-1',
  String brewingMethodId = 'method-1',
  double coffeeAmount = 20.0,
  double waterAmount = 320.0,
  bool isDeleted = false,
  String? roaster,
  String? beans,
  DateTime? createdAt,
}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: recipeId,
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: brewingMethodId,
    createdAt: createdAt ?? DateTime(2024, 1, 15),
    isMarked: false,
    versionVector: VersionVector.initial('device-1').toString(),
    isDeleted: isDeleted,
    roaster: roaster,
    beans: beans,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('insertUserStat / fetchStatByUuid', () {
    test('inserts and retrieves by UUID', () async {
      await db.userStatsDao.insertUserStat(_makeStat());

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');

      expect(result, isNotNull);
      expect(result!.statUuid, 'stat-uuid-1');
      expect(result.coffeeAmount, 20.0);
      expect(result.waterAmount, 320.0);
    });

    test('returns null for missing UUID', () async {
      final result = await db.userStatsDao.fetchStatByUuid('nonexistent');
      expect(result, isNull);
    });

    test('returns null for soft-deleted record', () async {
      await db.userStatsDao.insertUserStat(_makeStat(isDeleted: true));

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(result, isNull);
    });
  });

  group('fetchAllStats', () {
    test('returns only non-deleted records', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'a'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'b', isDeleted: true));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'c'));

      final results = await db.userStatsDao.fetchAllStats();

      expect(results.length, 2);
      expect(results.map((s) => s.statUuid), containsAll(['a', 'c']));
      expect(results.map((s) => s.statUuid), isNot(contains('b')));
    });

    test('returns records ordered by createdAt descending', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'older', createdAt: DateTime(2024, 1, 1)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'newer', createdAt: DateTime(2024, 6, 1)),
      );

      final results = await db.userStatsDao.fetchAllStats();

      expect(results.first.statUuid, 'newer');
      expect(results.last.statUuid, 'older');
    });

    test('returns empty list when no stats exist', () async {
      final results = await db.userStatsDao.fetchAllStats();
      expect(results, isEmpty);
    });
  });

  group('updateUserStat', () {
    test('updates record fields', () async {
      final original = _makeStat(coffeeAmount: 20.0);
      await db.userStatsDao.insertUserStat(original);

      final updated = original.copyWith(coffeeAmount: 25.0, rating: 4.5);
      await db.userStatsDao.updateUserStat(updated);

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(result!.coffeeAmount, 25.0);
      expect(result.rating, 4.5);
    });

    test('soft-delete via updateUserStat hides from fetchStatByUuid', () async {
      await db.userStatsDao.insertUserStat(_makeStat());

      final deleted = _makeStat(isDeleted: true);
      await db.userStatsDao.updateUserStat(deleted);

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(result, isNull);
    });
  });

  group('deleteUserStat (hard delete)', () {
    test('removes record permanently', () async {
      await db.userStatsDao.insertUserStat(_makeStat());

      await db.userStatsDao.deleteUserStat('stat-uuid-1');

      final all = await db.userStatsDao.fetchAllStatsWithVersionVectors();
      expect(all, isEmpty);
    });

    test('silently succeeds when UUID does not exist', () async {
      await db.userStatsDao.deleteUserStat('nonexistent');
      // Passes if no exception is thrown
    });
  });

  group('insertUserStat - upsert on conflict', () {
    test('overwrites existing record when UUID matches', () async {
      await db.userStatsDao.insertUserStat(_makeStat(coffeeAmount: 20.0));

      await db.userStatsDao.insertUserStat(_makeStat(coffeeAmount: 30.0));

      final all = await db.userStatsDao.fetchAllStats();
      expect(all.length, 1);
      expect(all.first.coffeeAmount, 30.0);
    });
  });

  group('fetchBrewedCoffeeAmount', () {
    test('sums water amounts within date range', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', waterAmount: 300.0, createdAt: DateTime(2024, 3, 15)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', waterAmount: 400.0, createdAt: DateTime(2024, 3, 20)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '3', waterAmount: 500.0, createdAt: DateTime(2024, 5, 1)),
      );

      final total = await db.userStatsDao.fetchBrewedCoffeeAmount(
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 31),
      );

      expect(total, closeTo(700.0, 0.001));
    });

    test('excludes soft-deleted records', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', waterAmount: 300.0, createdAt: DateTime(2024, 3, 15)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', waterAmount: 400.0, isDeleted: true, createdAt: DateTime(2024, 3, 16)),
      );

      final total = await db.userStatsDao.fetchBrewedCoffeeAmount(
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 31),
      );

      expect(total, closeTo(300.0, 0.001));
    });

    test('returns 0.0 when no stats exist in range', () async {
      final total = await db.userStatsDao.fetchBrewedCoffeeAmount(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(total, 0.0);
    });
  });

  group('insertOrUpdateMultipleStats', () {
    test('batch inserts multiple stats', () async {
      final stats = [
        _makeStat(uuid: 'a'),
        _makeStat(uuid: 'b'),
        _makeStat(uuid: 'c'),
      ];

      await db.userStatsDao.insertOrUpdateMultipleStats(stats);

      final all = await db.userStatsDao.fetchAllStats();
      expect(all.length, 3);
    });

    test('empty list completes without error', () async {
      await db.userStatsDao.insertOrUpdateMultipleStats([]);
      // Passes if no exception is thrown
    });

    test('upserts existing records', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'x', coffeeAmount: 20.0));

      await db.userStatsDao.insertOrUpdateMultipleStats([
        _makeStat(uuid: 'x', coffeeAmount: 35.0),
      ]);

      final all = await db.userStatsDao.fetchAllStats();
      expect(all.length, 1);
      expect(all.first.coffeeAmount, 35.0);
    });
  });

  group('fetchAllDistinctRoasters', () {
    test('returns distinct roaster names', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '1', roaster: 'Roaster A'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '2', roaster: 'Roaster B'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '3', roaster: 'Roaster A'));

      final roasters = await db.userStatsDao.fetchAllDistinctRoasters();

      expect(roasters.toSet().length, 2);
      expect(roasters, containsAll(['Roaster A', 'Roaster B']));
    });

    test('excludes null roasters', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '1', roaster: null));

      final roasters = await db.userStatsDao.fetchAllDistinctRoasters();
      expect(roasters, isEmpty);
    });

    test('excludes deleted records', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '1', roaster: 'Active'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '2', roaster: 'Deleted', isDeleted: true));

      final roasters = await db.userStatsDao.fetchAllDistinctRoasters();

      expect(roasters, contains('Active'));
      expect(roasters, isNot(contains('Deleted')));
    });
  });

  group('fetchStatsByUuids', () {
    test('returns stats for given UUIDs', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'a'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'b'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'c'));

      final results = await db.userStatsDao.fetchStatsByUuids(['a', 'c']);

      expect(results.length, 2);
      expect(results.map((s) => s.statUuid), containsAll(['a', 'c']));
    });

    test('empty UUID list returns empty result', () async {
      final results = await db.userStatsDao.fetchStatsByUuids([]);
      expect(results, isEmpty);
    });
  });
}
