import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('coffee bean identity invariants', () {
    test('current schema requires UUID and version vector', () async {
      final rows = await db
          .customSelect("PRAGMA table_info('coffee_beans')")
          .get();
      final columns = {
        for (final row in rows) row.data['name'] as String: row.data,
      };

      expect(columns['beans_uuid']?['notnull'], 1);
      expect(columns['beans_uuid']?['pk'], 1);
      expect(columns['version_vector']?['notnull'], 1);
    });

    test('database rejects missing UUID or version vector', () async {
      await expectLater(
        db.customStatement('''
          INSERT INTO coffee_beans
            (beans_uuid, roaster, name, origin, version_vector)
          VALUES (NULL, 'Roaster', 'Beans', 'Origin', 'device:1')
        '''),
        throwsA(anything),
      );

      await expectLater(
        db.customStatement('''
          INSERT INTO coffee_beans
            (beans_uuid, roaster, name, origin, version_vector)
          VALUES ('beans-1', 'Roaster', 'Beans', 'Origin', NULL)
        '''),
        throwsA(anything),
      );
    });
  });

  test('stat UUID batch update targets the matching record', () async {
    final versionVector = VersionVector.initial('device-1').toString();
    for (final uuid in ['stat-1', 'stat-2']) {
      await db.userStatsDao.insertUserStat(
        UserStatsModel(
          statUuid: uuid,
          recipeId: 'recipe-1',
          coffeeAmount: 20,
          waterAmount: 300,
          sweetnessSliderPosition: 1,
          strengthSliderPosition: 2,
          brewingMethodId: 'method-1',
          createdAt: DateTime(2024),
          isMarked: false,
          versionVector: versionVector,
          isDeleted: false,
        ),
      );
    }

    await db.userStatsDao.batchUpdateCoffeeBeansUuids([
      const UserStatsCompanion(
        statUuid: Value('stat-1'),
        coffeeBeansUuid: Value('beans-1'),
      ),
    ]);

    expect(
      (await db.userStatsDao.fetchStatByUuid('stat-1'))?.coffeeBeansUuid,
      'beans-1',
    );
    expect(
      (await db.userStatsDao.fetchStatByUuid('stat-2'))?.coffeeBeansUuid,
      isNull,
    );
  });
}
