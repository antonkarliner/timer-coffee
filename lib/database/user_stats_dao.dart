part of 'database.dart';

@DriftAccessor(tables: [UserStats])
class UserStatsDao extends DatabaseAccessor<AppDatabase>
    with _$UserStatsDaoMixin {
  final AppDatabase db;

  UserStatsDao(this.db) : super(db);

  Future<void> insertUserStat(
      {required String userId,
      required String recipeId,
      required double coffeeAmount,
      required double waterAmount,
      required int sweetnessSliderPosition,
      required int strengthSliderPosition,
      required String brewingMethodId,
      String? notes,
      String? beans,
      String? roaster,
      double? rating}) async {
    await into(userStats).insertOnConflictUpdate(UserStatsCompanion(
      userId: Value(userId),
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
    ));
  }

  // 1. Fetch stat by id
  Future<UserStatsModel?> fetchStatById(int id) async {
    final query = select(userStats)..where((tbl) => tbl.id.equals(id));
    final userStat = await query.getSingleOrNull();

    if (userStat == null) return null;

    return UserStatsModel(
      id: userStat.id,
      userId: userStat.userId,
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
    );
  }

  // Fetch all stats ordered by createdAt date descending
  Future<List<UserStatsModel>> fetchAllStats() async {
    final query = select(userStats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
      ]);
    final List<UserStat> userStatsList = await query.get();

    return userStatsList
        .map((dbUserStat) => UserStatsModel(
              id: dbUserStat.id,
              userId: dbUserStat.userId,
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
            ))
        .toList();
  }

  Future<void> updateUserStat({
    required int id,
    String? userId,
    String? recipeId,
    double? coffeeAmount,
    double? waterAmount,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    String? brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
  }) async {
    // Create a companion with only the fields that are not null.
    final updateCompanion = UserStatsCompanion(
      id: Value(id),
      userId: userId != null ? Value(userId) : Value.absent(),
      recipeId: recipeId != null ? Value(recipeId) : Value.absent(),
      coffeeAmount: coffeeAmount != null ? Value(coffeeAmount) : Value.absent(),
      waterAmount: waterAmount != null ? Value(waterAmount) : Value.absent(),
      sweetnessSliderPosition: sweetnessSliderPosition != null
          ? Value(sweetnessSliderPosition)
          : Value.absent(),
      strengthSliderPosition: strengthSliderPosition != null
          ? Value(strengthSliderPosition)
          : Value.absent(),
      brewingMethodId:
          brewingMethodId != null ? Value(brewingMethodId) : Value.absent(),
      notes: notes != null ? Value(notes) : Value.absent(),
      beans: beans != null ? Value(beans) : Value.absent(),
      roaster: roaster != null ? Value(roaster) : Value.absent(),
      rating: rating != null ? Value(rating) : Value.absent(),
    );

    // Perform the update.
    await (update(userStats)..where((tbl) => tbl.id.equals(id)))
        .write(updateCompanion);
  }

// Fetch all distinct roasters from the database, ordered by most recent
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

// Fetch all distinct beans from the database, ordered by most recent
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

  Future<void> deleteUserStat(int id) async {
    await (delete(userStats)..where((t) => t.id.equals(id))).go();
  }
}
