part of 'database.dart';

/// Result of a batch insert operation
class BatchInsertResult {
  final bool success;
  final List<UserStatsModel> failedStats;
  final String? errorMessage;

  BatchInsertResult({
    required this.success,
    required this.failedStats,
    this.errorMessage,
  });

  factory BatchInsertResult.successful() {
    return BatchInsertResult(success: true, failedStats: []);
  }

  factory BatchInsertResult.failed(
      List<UserStatsModel> failedStats, String? errorMessage) {
    return BatchInsertResult(
      success: false,
      failedStats: failedStats,
      errorMessage: errorMessage,
    );
  }
}

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
    final companion = _userStatToCompanion(stat);
    final query = update(userStats)
      ..where((tbl) => tbl.statUuid.equals(stat.statUuid));
    await query.write(companion);
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
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.id.equals(update.id.value!),
          );
        } else {
          AppLogger.warning(
              '[UserStatsDao] Unable to update record. Both statUuid and id are null or not present.');
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
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.id.equals(update.id.value!),
          );
        } else if (update.statUuid.present) {
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.statUuid.equals(update.statUuid.value),
          );
        }
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

  /// Enhanced batch insert method that provides feedback on failed operations
  Future<BatchInsertResult> insertOrUpdateMultipleStatsWithFeedback(
      List<UserStatsModel> stats) async {
    if (stats.isEmpty) {
      return BatchInsertResult.successful();
    }

    try {
      await batch((batch) {
        for (final stat in stats) {
          batch.insert(
            userStats,
            _userStatToCompanion(stat),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      return BatchInsertResult.successful();
    } catch (e) {
      final isForeignKeyError =
          e.toString().contains('FOREIGN KEY constraint failed');

      if (isForeignKeyError) {
        AppLogger.error(
            '[UserStatsDao] Foreign key constraint failed during batch insert. Stats count: ${stats.length}',
            errorObject: e);
        return BatchInsertResult.failed(stats, e.toString());
      }

      AppLogger.error('[UserStatsDao] Unexpected error during batch insert',
          errorObject: e);
      return BatchInsertResult.failed(stats, e.toString());
    }
  }

  /// Validates if the specified recipe IDs exist in the database
  Future<Map<String, bool>> validateRecipeReferences(
      List<String> recipeIds) async {
    if (recipeIds.isEmpty) {
      return {};
    }

    final uniqueRecipeIds = recipeIds.toSet().toList();

    try {
      // Query for existing recipes in batch
      final existingRecipes = await (select(recipes)
            ..where((tbl) => tbl.id.isIn(uniqueRecipeIds)))
          .get();

      final existingIds = existingRecipes.map((r) => r.id).toSet();

      // Create a map indicating which recipe IDs exist
      final validationMap = <String, bool>{};
      for (final recipeId in uniqueRecipeIds) {
        validationMap[recipeId] = existingIds.contains(recipeId);
      }

      return validationMap;
    } catch (e) {
      AppLogger.error('[UserStatsDao] Error validating recipe references',
          errorObject: e);
      // Assume all recipes don't exist if validation fails
      return Map.fromEntries(
        uniqueRecipeIds.map((id) => MapEntry(id, false)),
      );
    }
  }

  /// Returns any available recipe to use as a safe FK fallback
  Future<Recipe?> _fetchAnyRecipe() async {
    return (select(recipes)..limit(1)).getSingleOrNull();
  }

  /// Creates a fallback stat that points to an existing recipe (if any)
  Future<UserStatsModel?> createFallbackStat(
      UserStatsModel originalStat) async {
    final fallbackRecipe = await _fetchAnyRecipe();

    if (fallbackRecipe == null) {
      AppLogger.warning(
          '[UserStatsDao] Unable to create fallback stat: no recipes available');
      return null;
    }

    return originalStat.copyWith(
      recipeId: fallbackRecipe.id,
      brewingMethodId: fallbackRecipe.brewingMethodId,
    );
  }

  /// Attempts to insert a stat with a fallback recipe reference if the original fails
  Future<void> insertUserStatWithFallback(UserStatsModel stat) async {
    try {
      await insertUserStat(stat);
    } catch (e) {
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        final sanitizedUuid = AppLogger.sanitize(stat.statUuid);
        final sanitizedRecipeId = AppLogger.sanitize(stat.recipeId);
        AppLogger.warning(
            '[UserStatsDao] Foreign key constraint failed for stat $sanitizedUuid, attempting fallback');
        AppLogger.debug(
            '[UserStatsDao] Original recipe ID: $sanitizedRecipeId');

        final fallbackStat = await createFallbackStat(stat);

        if (fallbackStat == null) {
          AppLogger.warning(
              '[UserStatsDao] Skipping stat $sanitizedUuid - no valid fallback recipe found');
          rethrow;
        }

        try {
          await insertUserStat(fallbackStat);
          AppLogger.debug(
              '[UserStatsDao] Successfully inserted fallback stat for $sanitizedUuid');
        } catch (fallbackError) {
          AppLogger.error('[UserStatsDao] Failed to insert fallback stat',
              errorObject: fallbackError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<List<UserStatsModel>> fetchAllStatsWithVersionVectors() async {
    final query = select(userStats);
    final results = await query.map(_userStatFromRow).get();
    return results;
  }

  Future<List<UserStatsModel>> fetchStatsByUuids(List<String> uuids) async {
    final query = select(userStats)
      ..where((tbl) => tbl.statUuid.isIn(uuids) & tbl.isDeleted.equals(false));
    final results = await query.get();
    return results.map(_userStatFromRow).toList();
  }

  Future<void> detachCoffeeBeanFromStats(String beansUuid) async {
    await (update(userStats)
          ..where((tbl) => tbl.coffeeBeansUuid.equals(beansUuid)))
        .write(UserStatsCompanion(
      coffeeBeansUuid: const Value(null),
    ));
  }
}
