import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/utils/version_vector.dart';
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

  test(
    'topMethodsLast90Days applies boundary, deletion, ordering, and limit',
    () async {
      for (var index = 1; index <= 5; index++) {
        await db
            .into(db.brewingMethods)
            .insert(
              BrewingMethodsCompanion.insert(
                brewingMethodId: 'method-$index',
                brewingMethod: 'Method $index',
              ),
            );
        await db
            .into(db.recipes)
            .insert(
              RecipesCompanion.insert(
                id: 'recipe-$index',
                brewingMethodId: 'method-$index',
                coffeeAmount: 15,
                waterAmount: 250,
                waterTemp: 93,
                brewTime: 180,
              ),
            );
      }

      final now = DateTime.now().toUtc();
      var uuid = 0;
      Future<void> addBrews(
        int method,
        int count, {
        DateTime? createdAt,
        bool isDeleted = false,
      }) async {
        for (var index = 0; index < count; index++) {
          uuid++;
          await db.userStatsDao.insertUserStat(
            UserStatsModel(
              statUuid: 'stat-$uuid',
              recipeId: 'recipe-$method',
              coffeeAmount: 15,
              waterAmount: 250,
              sweetnessSliderPosition: 0,
              strengthSliderPosition: 0,
              brewingMethodId: 'method-$method',
              createdAt: createdAt ?? now.subtract(const Duration(days: 1)),
              isMarked: false,
              versionVector: VersionVector.initial('test').toString(),
              isDeleted: isDeleted,
            ),
          );
        }
      }

      await addBrews(1, 5);
      await addBrews(2, 4);
      await addBrews(3, 2);
      await addBrews(4, 2);
      await addBrews(5, 8, isDeleted: true);
      await addBrews(
        3,
        1,
        createdAt: now.subtract(const Duration(days: 90, minutes: -1)),
      );
      await addBrews(
        3,
        10,
        createdAt: now.subtract(const Duration(days: 90, minutes: 1)),
      );

      final result = await db.userStatsDao.topMethodsLast90Days('en');

      expect(result, hasLength(3));
      expect(
        result.map((method) => (method.brewingMethodId, method.count)).toList(),
        [('method-1', 5), ('method-2', 4), ('method-3', 3)],
      );
    },
  );
}
