part of 'database.dart';

@DriftAccessor(tables: [UserStats])
class UserStatsDao extends DatabaseAccessor<AppDatabase>
    with _$UserStatsDaoMixin {
  final AppDatabase db;

  UserStatsDao(this.db) : super(db);

  UserStatsModel _userStatFromRow(UserStat row) {
    return UserStatsModel(
      statUuid: row.statUuid,
      id: row.id,
      recipeId: row.recipeId,
      coffeeAmount: row.coffeeAmount,
      waterAmount: row.waterAmount,
      sweetnessSliderPosition: row.sweetnessSliderPosition,
      strengthSliderPosition: row.strengthSliderPosition,
      brewingMethodId: row.brewingMethodId,
      createdAt: row.createdAt,
      notes: row.notes,
      beans: row.beans,
      roaster: row.roaster,
      rating: row.rating,
      coffeeBeansId: row.coffeeBeansId,
      isMarked: row.isMarked,
      coffeeBeansUuid: row.coffeeBeansUuid,
      versionVector: row.versionVector,
      isDeleted: row.isDeleted, // Added isDeleted field
    );
  }

  UserStatsCompanion _userStatToCompanion(UserStatsModel model) {
    return UserStatsCompanion(
      statUuid: Value(model.statUuid),
      recipeId: Value(model.recipeId),
      coffeeAmount: Value(model.coffeeAmount),
      waterAmount: Value(model.waterAmount),
      sweetnessSliderPosition: Value(model.sweetnessSliderPosition),
      strengthSliderPosition: Value(model.strengthSliderPosition),
      brewingMethodId: Value(model.brewingMethodId),
      createdAt: Value(model.createdAt),
      notes: Value(model.notes),
      beans: Value(model.beans),
      roaster: Value(model.roaster),
      rating: Value(model.rating),
      coffeeBeansId: Value(model.coffeeBeansId),
      isMarked: Value(model.isMarked),
      coffeeBeansUuid: Value(model.coffeeBeansUuid),
      versionVector: Value(model.versionVector),
      isDeleted: Value(model.isDeleted), // Added isDeleted field
    );
  }

  Future<void> insertUserStat(UserStatsModel stat) async {
    await into(userStats).insertOnConflictUpdate(_userStatToCompanion(stat));
  }

  Future<UserStatsModel?> fetchStatByUuid(String statUuid) async {
    final query = select(userStats)
      ..where(
          (tbl) => tbl.statUuid.equals(statUuid) & tbl.isDeleted.equals(false));
    final result = await query.getSingleOrNull();
    return result != null ? _userStatFromRow(result) : null;
  }

  Future<List<UserStatsModel>> fetchAllStats() async {
    final query = select(userStats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
      ])
      ..where((t) => t.isDeleted.equals(false)); // Fetch only non-deleted stats
    final List<UserStat> userStatsList = await query.get();

    return userStatsList.map(_userStatFromRow).toList();
  }

  Future<void> updateUserStat(UserStatsModel stat) async {
    print('UserStatsDao.updateUserStat called with stat: ${stat.toString()}');

    final companion = _userStatToCompanion(stat);
    print('Update values: $companion');

    final query = update(userStats)
      ..where((tbl) => tbl.statUuid.equals(stat.statUuid));

    try {
      final updatedRows = await query.write(companion);
      print('Rows updated: $updatedRows');

      // Verify the update
      final updatedStat = await fetchStatByUuid(stat.statUuid);
      print('Stat after update: ${updatedStat.toString()}');

      if (updatedRows == 0) {
        print(
            'Warning: No rows were updated. The stat might not exist in the database.');
      }
    } catch (e) {
      print('Error updating user stat: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchAllDistinctRoasters() async {
    final query = selectOnly(userStats, distinct: true)
      ..addColumns([userStats.roaster])
      ..where(userStats.roaster.isNotNull() & userStats.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: userStats.createdAt, mode: OrderingMode.desc)
      ]);
    final roasters =
        await query.map((row) => row.read(userStats.roaster)).get();
    return roasters.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctBeans() async {
    final query = selectOnly(userStats, distinct: true)
      ..addColumns([userStats.beans])
      ..where(userStats.beans.isNotNull() & userStats.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: userStats.createdAt, mode: OrderingMode.desc)
      ]);
    final beans = await query.map((row) => row.read(userStats.beans)).get();
    return beans.whereType<String>().toList();
  }

  Future<void> deleteUserStat(String statUuid) async {
    await (delete(userStats)..where((t) => t.statUuid.equals(statUuid))).go();
  }

  Future<double> fetchBrewedCoffeeAmount(DateTime start, DateTime end) async {
    final query = select(userStats)
      ..where((u) =>
          u.createdAt.isBetweenValues(start, end) & u.isDeleted.equals(false));
    final List<double> totalWaterAmount =
        await query.map((row) => row.waterAmount).get();
    return totalWaterAmount.fold<double>(
        0.0, (double sum, double element) => sum + element);
  }

  Future<List<String>> fetchTopRecipes(DateTime start, DateTime end) async {
    final query = customSelect(
      'SELECT recipe_id, COUNT(recipe_id) AS usage_count '
      'FROM user_stats WHERE created_at BETWEEN ? AND ? AND is_deleted = false '
      'GROUP BY recipe_id ORDER BY usage_count DESC LIMIT 3',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {userStats},
    );
    final resultRows = await query.get();
    return resultRows.map((row) => row.read<String>('recipe_id')).toList();
  }

  Future<List<UserStat>> fetchStatsNeedingUuidUpdate() {
    return (select(userStats)
          ..where((tbl) =>
              tbl.coffeeBeansId.isNotNull() &
              tbl.coffeeBeansUuid.isNull() &
              tbl.isDeleted.equals(false)))
        .get();
  }

  Future<void> batchUpdateCoffeeBeansUuids(
      List<UserStatsCompanion> updates) async {
    await batch((batch) {
      for (final update in updates) {
        if (update.statUuid.present && update.statUuid.value != null) {
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.statUuid.equals(update.statUuid.value!),
          );
        } else if (update.id.present && update.id.value != null) {
          // Fallback to using id if statUuid is not available
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.id.equals(update.id.value!),
          );
        } else {
          print(
              'Warning: Unable to update record. Both statUuid and id are null or not present.');
        }
      }
    });
  }

  Future<List<UserStat>> fetchStatsNeedingStatUuidUpdate() {
    return (select(userStats)
          ..where((tbl) => tbl.statUuid.isNull() & tbl.isDeleted.equals(false)))
        .get();
  }

  Future<void> batchUpdateStatUuids(List<UserStatsCompanion> updates) async {
    await batch((batch) {
      for (final update in updates) {
        if (update.id.present && update.id.value != null) {
          // If we have an id, use it to find the record to update
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.id.equals(update.id.value!),
          );
        } else if (update.statUuid.present) {
          // If we don't have an id but have a statUuid, use it
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.statUuid.equals(update.statUuid.value),
          );
        }
        // If neither id nor statUuid is present, we can't update the record
      }
    });
  }

  Future<void> insertOrUpdateMultipleStats(List<UserStatsModel> stats) async {
    await batch((batch) {
      for (final stat in stats) {
        batch.insert(
          userStats,
          _userStatToCompanion(stat),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<UserStatsModel>> fetchAllStatsWithVersionVectors() async {
    final query = select(userStats);
    final results = await query.map(_userStatFromRow).get();
    return results;
  }

  Future<List<UserStatsModel>> fetchStatsByUuids(List<String> uuids) async {
    final query = select(userStats)
      ..where((tbl) =>
          tbl.statUuid.isIn(uuids) &
          tbl.isDeleted.equals(false)); // Fetch only non-deleted stats
    final results = await query.get();
    return results.map(_userStatFromRow).toList();
  }
}
