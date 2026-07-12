import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

UserStatsModel _makeStat({
  String uuid = 'stat-uuid-extraction-1',
  String recipeId = 'recipe-1',
  String brewingMethodId = 'method-1',
  double coffeeAmount = 20.0,
  double waterAmount = 320.0,
  double? tdsPercent,
  double? extractionYieldPercent,
  bool isDeleted = false,
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
    tdsPercent: tdsPercent,
    extractionYieldPercent: extractionYieldPercent,
    versionVector: VersionVector.initial('device-1').toString(),
    isDeleted: isDeleted,
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

  group('tdsPercent / extractionYieldPercent round-trip', () {
    test('inserts and fetches non-null values', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'extraction-nonnull',
          tdsPercent: 1.38,
          extractionYieldPercent: 20.4,
        ),
      );

      final result =
          await db.userStatsDao.fetchStatByUuid('extraction-nonnull');

      expect(result, isNotNull);
      expect(result!.tdsPercent, 1.38);
      expect(result.extractionYieldPercent, 20.4);
    });

    test('updates via DAO with changed values and re-reads', () async {
      const uuid = 'extraction-update';
      final original = _makeStat(
        uuid: uuid,
        tdsPercent: 1.38,
        extractionYieldPercent: 20.4,
      );
      await db.userStatsDao.insertUserStat(original);

      final updated = original.copyWith(
        tdsPercent: 1.45,
        extractionYieldPercent: 21.9,
      );
      await db.userStatsDao.updateUserStat(updated);

      final result = await db.userStatsDao.fetchStatByUuid(uuid);

      expect(result, isNotNull);
      expect(result!.tdsPercent, 1.45);
      expect(result.extractionYieldPercent, 21.9);
    });

    test('round-trips null values for both fields', () async {
      const uuid = 'extraction-null';
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: uuid,
          tdsPercent: null,
          extractionYieldPercent: null,
        ),
      );

      final result = await db.userStatsDao.fetchStatByUuid(uuid);

      expect(result, isNotNull);
      expect(result!.tdsPercent, isNull);
      expect(result.extractionYieldPercent, isNull);
    });
  });
}
