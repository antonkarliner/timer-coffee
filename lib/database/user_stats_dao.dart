part of 'database.dart';

@DriftAccessor(tables: [UserStats])
class UserStatsDao extends DatabaseAccessor<AppDatabase>
    with _$UserStatsDaoMixin {
  final AppDatabase db;

  UserStatsDao(this.db) : super(db);

  Future<void> insertUserStat({
    required String statUuid,
    required String recipeId,
    required double coffeeAmount,
    required double waterAmount,
    required int sweetnessSliderPosition,
    required int strengthSliderPosition,
    required String brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
    int? coffeeBeansId,
    bool isMarked = false,
    String? coffeeBeansUuid,
  }) async {
    await into(userStats).insertOnConflictUpdate(UserStatsCompanion(
      statUuid: Value(statUuid),
      recipeId: Value(recipeId),
      coffeeAmount: Value(coffeeAmount),
      waterAmount: Value(waterAmount),
      sweetnessSliderPosition: Value(sweetnessSliderPosition),
      strengthSliderPosition: Value(strengthSliderPosition),
      brewingMethodId: Value(brewingMethodId),
      createdAt: Value(DateTime.now().toUtc()),
      notes: Value(notes),
      beans: Value(beans),
      roaster: Value(roaster),
      rating: Value(rating),
      coffeeBeansId: Value(coffeeBeansId),
      isMarked: Value(isMarked),
      coffeeBeansUuid: Value(coffeeBeansUuid),
    ));
  }

  Future<UserStatsModel?> fetchStatByUuid(String statUuid) async {
    final query = select(userStats)
      ..where((tbl) => tbl.statUuid.equals(statUuid));
    final userStat = await query.getSingleOrNull();

    if (userStat == null) return null;

    return UserStatsModel(
      statUuid: userStat.statUuid,
      id: userStat.id,
      recipeId: userStat.recipeId,
      coffeeAmount: userStat.coffeeAmount,
      waterAmount: userStat.waterAmount,
      sweetnessSliderPosition: userStat.sweetnessSliderPosition,
      strengthSliderPosition: userStat.strengthSliderPosition,
      brewingMethodId: userStat.brewingMethodId,
      createdAt: userStat.createdAt,
      notes: userStat.notes,
      beans: userStat.beans,
      roaster: userStat.roaster,
      rating: userStat.rating,
      coffeeBeansId: userStat.coffeeBeansId,
      isMarked: userStat.isMarked,
      coffeeBeansUuid: userStat.coffeeBeansUuid,
    );
  }

  Future<List<UserStatsModel>> fetchAllStats() async {
    final query = select(userStats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
      ]);
    final List<UserStat> userStatsList = await query.get();

    return userStatsList
        .map((dbUserStat) => UserStatsModel(
              statUuid: dbUserStat.statUuid,
              id: dbUserStat.id,
              recipeId: dbUserStat.recipeId,
              coffeeAmount: dbUserStat.coffeeAmount,
              waterAmount: dbUserStat.waterAmount,
              sweetnessSliderPosition: dbUserStat.sweetnessSliderPosition,
              strengthSliderPosition: dbUserStat.strengthSliderPosition,
              brewingMethodId: dbUserStat.brewingMethodId,
              createdAt: dbUserStat.createdAt,
              notes: dbUserStat.notes,
              beans: dbUserStat.beans,
              roaster: dbUserStat.roaster,
              rating: dbUserStat.rating,
              coffeeBeansId: dbUserStat.coffeeBeansId,
              isMarked: dbUserStat.isMarked,
              coffeeBeansUuid: dbUserStat.coffeeBeansUuid,
            ))
        .toList();
  }

  Future<void> updateUserStat({
    required String statUuid,
    required Map<String, dynamic> data,
  }) async {
    print(
        'UserStatsDao updateUserStat called with statUuid: $statUuid, data: $data');

    final updateCompanion = UserStatsCompanion(
      statUuid: Value(statUuid),
      recipeId: data['recipeId'] != null
          ? Value(data['recipeId'])
          : const Value.absent(),
      coffeeAmount: data['coffeeAmount'] != null
          ? Value(data['coffeeAmount'])
          : const Value.absent(),
      waterAmount: data['waterAmount'] != null
          ? Value(data['waterAmount'])
          : const Value.absent(),
      sweetnessSliderPosition: data['sweetnessSliderPosition'] != null
          ? Value(data['sweetnessSliderPosition'])
          : const Value.absent(),
      strengthSliderPosition: data['strengthSliderPosition'] != null
          ? Value(data['strengthSliderPosition'])
          : const Value.absent(),
      brewingMethodId: data['brewingMethodId'] != null
          ? Value(data['brewingMethodId'])
          : const Value.absent(),
      notes:
          data['notes'] != null ? Value(data['notes']) : const Value.absent(),
      beans:
          data['beans'] != null ? Value(data['beans']) : const Value.absent(),
      roaster: data['roaster'] != null
          ? Value(data['roaster'])
          : const Value.absent(),
      rating:
          data['rating'] != null ? Value(data['rating']) : const Value.absent(),
      coffeeBeansId: data.containsKey('coffeeBeansId')
          ? Value(data['coffeeBeansId'])
          : const Value.absent(),
      isMarked: data['isMarked'] != null
          ? Value(data['isMarked'])
          : const Value.absent(),
      coffeeBeansUuid: data.containsKey('coffeeBeansUuid')
          ? Value(data['coffeeBeansUuid'])
          : const Value.absent(),
    );

    await (update(userStats)..where((tbl) => tbl.statUuid.equals(statUuid)))
        .write(updateCompanion);

    print('UserStatsDao updateUserStat completed for statUuid: $statUuid');

    final updatedStat = await fetchStatByUuid(statUuid);
    print(
        'Updated stat coffeeBeansId: ${updatedStat?.coffeeBeansId}, coffeeBeansUuid: ${updatedStat?.coffeeBeansUuid}, statUuid: ${updatedStat?.statUuid}');
  }

  Future<List<String>> fetchAllDistinctRoasters() async {
    final query = selectOnly(userStats, distinct: true)
      ..addColumns([userStats.roaster])
      ..where(userStats.roaster.isNotNull())
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
      ..where(userStats.beans.isNotNull())
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
      ..where((u) => u.createdAt.isBetweenValues(start, end));
    final List<double> totalWaterAmount =
        await query.map((row) => row.waterAmount).get();
    return totalWaterAmount.fold<double>(
        0.0, (double sum, double element) => sum + element);
  }

  Future<List<String>> fetchTopRecipes(DateTime start, DateTime end) async {
    final query = customSelect(
      'SELECT recipe_id, COUNT(recipe_id) AS usage_count '
      'FROM user_stats WHERE created_at BETWEEN ? AND ? '
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
              tbl.coffeeBeansId.isNotNull() & tbl.coffeeBeansUuid.isNull()))
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
          // You might want to log this or handle it in some way
        }
      }
    });
  }

  Future<List<UserStat>> fetchStatsNeedingStatUuidUpdate() {
    return (select(userStats)..where((tbl) => tbl.statUuid.isNull())).get();
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
}
