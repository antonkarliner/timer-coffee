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
    List<UserStatsModel> failedStats,
    String? errorMessage,
  ) {
    return BatchInsertResult(
      success: false,
      failedStats: failedStats,
      errorMessage: errorMessage,
    );
  }
}

class GrindSuggestionResult {
  final String grindSize;
  final int? tasteBalance;

  const GrindSuggestionResult({
    required this.grindSize,
    required this.tasteBalance,
  });
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
      grindSize: row.grindSize,
      tdsPercent: row.tdsPercent,
      extractionYieldPercent: row.extractionYieldPercent,
      waterTemp: row.waterTemp,
      tasteBalance: row.tasteBalance,
      entrySource: row.entrySource,
      tags: row.tags,
      versionVector: row.versionVector,
      isDeleted: row.isDeleted,
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
      grindSize: Value(model.grindSize),
      tdsPercent: Value(model.tdsPercent),
      extractionYieldPercent: Value(model.extractionYieldPercent),
      waterTemp: Value(model.waterTemp),
      tasteBalance: Value(model.tasteBalance),
      entrySource: Value(model.entrySource),
      tags: Value(model.tags),
      versionVector: Value(model.versionVector),
      isDeleted: Value(model.isDeleted),
    );
  }

  Future<void> insertUserStat(UserStatsModel stat) async {
    await into(userStats).insertOnConflictUpdate(_userStatToCompanion(stat));
  }

  Future<UserStatsModel?> fetchStatByUuid(String statUuid) async {
    final query = select(userStats)
      ..where(
        (tbl) => tbl.statUuid.equals(statUuid) & tbl.isDeleted.equals(false),
      );
    final result = await query.getSingleOrNull();
    return result != null ? _userStatFromRow(result) : null;
  }

  Future<GrindSuggestionResult?> latestGrindSuggestionForBeanAndMethod(
    String beansUuid,
    String brewingMethodId,
  ) async {
    final query = selectOnly(userStats)
      ..addColumns([userStats.grindSize, userStats.tasteBalance])
      ..where(
        userStats.coffeeBeansUuid.equals(beansUuid) &
            userStats.brewingMethodId.equals(brewingMethodId) &
            userStats.isDeleted.equals(false) &
            userStats.grindSize.isNotNull() &
            userStats.grindSize.equals('').not(),
      )
      ..orderBy([
        OrderingTerm(expression: userStats.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    final grindSize = row?.read(userStats.grindSize);
    if (grindSize == null) return null;
    return GrindSuggestionResult(
      grindSize: grindSize,
      tasteBalance: row?.read(userStats.tasteBalance),
    );
  }

  Future<List<UserStatsModel>> fetchAllStats() async {
    final query = select(userStats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
      ..where((t) => t.isDeleted.equals(false)); // Fetch only non-deleted stats
    final List<UserStat> userStatsList = await query.get();

    return userStatsList.map(_userStatFromRow).toList();
  }

  /// Loads every non-deleted diary row and its display metadata in one query.
  /// Recipe names prefer [locale] and fall back to English. Brewing method
  /// names are stored directly on `brewing_methods` and are not localized in
  /// the current schema. Soft-deleted beans are treated as unlinked, matching
  /// [CoffeeBeansDao.fetchCoffeeBeansByUuid]. When an entry has no stored
  /// `water_temp`, it falls back to the linked recipe's default temperature
  /// and is flagged via `water_temp_is_derived` so callers can mark it as an
  /// assumption rather than a recorded value.
  Future<List<DiaryEntry>> fetchDiaryEntries(String locale) async {
    final query = customSelect(
      '''
        SELECT
          us.stat_uuid,
          us.recipe_id,
          COALESCE(localized.name, english.name, '') AS recipe_name,
          us.brewing_method_id,
          bm.brewing_method AS method_name,
          us.created_at,
          us.coffee_amount,
          us.water_amount,
          us.grind_size,
          COALESCE(us.water_temp, r.water_temp) AS water_temp,
          (us.water_temp IS NULL AND r.water_temp IS NOT NULL) AS water_temp_is_derived,
          us.tds_percent,
          us.extraction_yield_percent,
          us.taste_balance,
          us.entry_source,
          us.tags,
          us.rating,
          us.is_marked,
          us.notes,
          us.coffee_beans_uuid,
          cb.name AS bean_name,
          cb.roaster AS bean_roaster,
          cb.origin AS bean_origin
        FROM user_stats AS us
        INNER JOIN brewing_methods AS bm
          ON bm.brewing_method_id = us.brewing_method_id
        LEFT JOIN recipes AS r
          ON r.id = us.recipe_id
        LEFT JOIN recipe_localizations AS localized
          ON localized.id = (
            SELECT id FROM recipe_localizations
            WHERE recipe_id = us.recipe_id AND locale = ?
            LIMIT 1
          )
        LEFT JOIN recipe_localizations AS english
          ON english.id = (
            SELECT id FROM recipe_localizations
            WHERE recipe_id = us.recipe_id AND locale = 'en'
            LIMIT 1
          )
        LEFT JOIN coffee_beans AS cb
          ON cb.beans_uuid = us.coffee_beans_uuid AND cb.is_deleted = false
        WHERE us.is_deleted = false
        ORDER BY us.created_at DESC
      ''',
      variables: [Variable.withString(locale)],
      readsFrom: {
        userStats,
        db.brewingMethods,
        db.recipes,
        db.recipeLocalizations,
        db.coffeeBeans,
      },
    );

    return query.map((row) {
      return DiaryEntry(
        statUuid: row.read<String>('stat_uuid'),
        recipeId: row.read<String>('recipe_id'),
        recipeName: row.read<String>('recipe_name'),
        brewingMethodId: row.read<String>('brewing_method_id'),
        methodName: row.read<String>('method_name'),
        createdAt: row.read<DateTime>('created_at'),
        coffeeAmount: row.read<double>('coffee_amount'),
        waterAmount: row.read<double>('water_amount'),
        grindSize: row.readNullable<String>('grind_size'),
        waterTemp: row.readNullable<double>('water_temp'),
        waterTempIsDerived: row.read<bool>('water_temp_is_derived'),
        tdsPercent: row.readNullable<double>('tds_percent'),
        extractionYieldPercent: row.readNullable<double>(
          'extraction_yield_percent',
        ),
        tasteBalance: row.readNullable<int>('taste_balance'),
        entrySource: row.readNullable<int>('entry_source'),
        tags: row.readNullable<String>('tags'),
        rating: row.readNullable<double>('rating'),
        isMarked: row.read<bool>('is_marked'),
        notes: row.readNullable<String>('notes'),
        coffeeBeansUuid: row.readNullable<String>('coffee_beans_uuid'),
        beanName: row.readNullable<String>('bean_name'),
        roaster: row.readNullable<String>('bean_roaster'),
        origin: row.readNullable<String>('bean_origin'),
      );
    }).get();
  }

  /// The three most-used brewing methods in the trailing 90-day window.
  ///
  /// Method names are stored directly on `brewing_methods`; [locale] is kept
  /// in the API so this aggregate can adopt localized method names without a
  /// call-site change if the catalog gains localizations later.
  Future<List<({String brewingMethodId, String methodName, int count})>>
  topMethodsLast90Days(String locale) async {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 90));
    final query = customSelect(
      '''
        SELECT
          us.brewing_method_id,
          bm.brewing_method AS method_name,
          COUNT(*) AS brew_count
        FROM user_stats AS us
        INNER JOIN brewing_methods AS bm
          ON bm.brewing_method_id = us.brewing_method_id
        WHERE us.is_deleted = false AND us.created_at >= ?
        GROUP BY us.brewing_method_id, bm.brewing_method
        ORDER BY brew_count DESC, bm.brewing_method ASC
        LIMIT 3
      ''',
      variables: [Variable.withDateTime(cutoff)],
      readsFrom: {userStats, db.brewingMethods},
    );
    final rows = await query.get();
    return rows
        .map(
          (row) => (
            brewingMethodId: row.read<String>('brewing_method_id'),
            methodName: row.read<String>('method_name'),
            count: row.read<int>('brew_count'),
          ),
        )
        .toList();
  }

  /// Returns the most recent non-deleted brews, newest first, capped at
  /// [limit]. Used by "prefill from history" pickers where showing the
  /// full unbounded history (see [fetchAllStats]) would be wasteful.
  Future<List<UserStatsModel>> fetchRecentStats({int limit = 20}) async {
    final query = select(userStats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
      ..where((t) => t.isDeleted.equals(false))
      ..limit(limit);
    final List<UserStat> userStatsList = await query.get();

    return userStatsList.map(_userStatFromRow).toList();
  }

  Future<UserStatsModel?> fetchEarliestStat() async {
    final query = select(userStats)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result != null ? _userStatFromRow(result) : null;
  }

  /// Returns the user's earliest brew timestamp, or null if there are no
  /// non-deleted brews yet. Thin convenience wrapper over [fetchEarliestStat].
  Future<DateTime?> earliestBrewAt() async {
    final stat = await fetchEarliestStat();
    return stat?.createdAt;
  }

  Future<List<String>> fetchDistinctBrewingMethodsForBean(
    String beansUuid,
  ) async {
    final query = customSelect(
      'SELECT brewing_method_id FROM user_stats '
      'WHERE coffee_beans_uuid = ? AND is_deleted = false '
      'GROUP BY brewing_method_id ORDER BY MAX(created_at) DESC',
      variables: [Variable.withString(beansUuid)],
      readsFrom: {userStats},
    );
    return (await query.get())
        .map((r) => r.read<String>('brewing_method_id'))
        .toList();
  }

  Future<List<UserStatsModel>> fetchStatsByBeanUuid(String beansUuid) async {
    final query = select(userStats)
      ..where(
        (t) => t.coffeeBeansUuid.equals(beansUuid) & t.isDeleted.equals(false),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return (await query.get()).map(_userStatFromRow).toList();
  }

  /// Median `coffeeAmount` (grams) for non-deleted brews on a specific bean.
  /// Returns null when fewer than [minBrews] valid samples exist.
  Future<double?> medianCoffeeAmountForBean(
    String beansUuid, {
    int minBrews = 3,
  }) async {
    final query = selectOnly(userStats)
      ..addColumns([userStats.coffeeAmount])
      ..where(
        userStats.coffeeBeansUuid.equals(beansUuid) &
            userStats.isDeleted.equals(false) &
            userStats.coffeeAmount.isBiggerThanValue(0),
      );
    final values = (await query.get())
        .map((row) => row.read(userStats.coffeeAmount))
        .whereType<double>()
        .toList();
    return _median(values, minBrews: minBrews);
  }

  /// Median `coffeeAmount` (grams) for non-deleted brews created on/after
  /// [since]. Returns null when fewer than [minBrews] valid samples exist.
  Future<double?> medianCoffeeAmountSince(
    DateTime since, {
    int minBrews = 3,
  }) async {
    final query = selectOnly(userStats)
      ..addColumns([userStats.coffeeAmount])
      ..where(
        userStats.isDeleted.equals(false) &
            userStats.coffeeAmount.isBiggerThanValue(0) &
            userStats.createdAt.isBiggerOrEqualValue(since),
      );
    final values = (await query.get())
        .map((row) => row.read(userStats.coffeeAmount))
        .whereType<double>()
        .toList();
    return _median(values, minBrews: minBrews);
  }

  static double? _median(List<double> values, {required int minBrews}) {
    if (values.length < minBrews) return null;
    values.sort();
    final n = values.length;
    if (n.isOdd) return values[n ~/ 2];
    return (values[n ~/ 2 - 1] + values[n ~/ 2]) / 2.0;
  }

  Future<int> countDistinctBrewedRecipes() async {
    final query = customSelect(
      'SELECT COUNT(DISTINCT recipe_id) AS recipe_count '
      'FROM user_stats WHERE is_deleted = false',
      readsFrom: {userStats},
    );
    final row = await query.getSingleOrNull();
    return row?.read<int>('recipe_count') ?? 0;
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
        OrderingTerm(expression: userStats.createdAt, mode: OrderingMode.desc),
      ]);
    final roasters = await query
        .map((row) => row.read(userStats.roaster))
        .get();
    return roasters.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctBeans() async {
    final query = selectOnly(userStats, distinct: true)
      ..addColumns([userStats.beans])
      ..where(userStats.beans.isNotNull() & userStats.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: userStats.createdAt, mode: OrderingMode.desc),
      ]);
    final beans = await query.map((row) => row.read(userStats.beans)).get();
    return beans.whereType<String>().toList();
  }

  /// Custom tags across non-deleted diary entries, ordered by recency of
  /// last use (rows come back newest-`createdAt`-first, and tags are folded
  /// in that order), for quick picks / autocomplete surfaces. Deduplicated
  /// case-insensitively, keeping the casing of the most recently used
  /// occurrence.
  ///
  /// SQLite forbids `ORDER BY` on a column that isn't part of a `DISTINCT`
  /// select list, so this selects the raw (non-distinct) `tags` column
  /// ordered by `createdAt` and dedupes in Dart after expanding each stored
  /// comma-separated string.
  Future<List<String>> fetchAllDistinctTags() async {
    final query = selectOnly(userStats)
      ..addColumns([userStats.tags])
      ..where(userStats.tags.isNotNull() & userStats.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: userStats.createdAt, mode: OrderingMode.desc),
      ]);
    final storedTags = await query.map((row) => row.read(userStats.tags)).get();

    final seen = <String>{};
    final orderedTags = <String>[];
    for (final stored in storedTags.whereType<String>()) {
      for (final tag in diaryTagsFromStorage(stored)) {
        if (seen.add(tag.toLowerCase())) {
          orderedTags.add(tag);
        }
      }
    }
    return orderedTags;
  }

  Future<void> deleteUserStat(String statUuid) async {
    await (delete(userStats)..where((t) => t.statUuid.equals(statUuid))).go();
  }

  Future<double> fetchBrewedCoffeeAmount(DateTime start, DateTime end) async {
    final query = select(userStats)
      ..where(
        (u) =>
            u.createdAt.isBetweenValues(start, end) & u.isDeleted.equals(false),
      );
    final List<double> totalWaterAmount = await query
        .map((row) => row.waterAmount)
        .get();
    return totalWaterAmount.fold<double>(
      0.0,
      (double sum, double element) => sum + element,
    );
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
    return (select(userStats)..where(
          (tbl) =>
              tbl.coffeeBeansId.isNotNull() &
              tbl.coffeeBeansUuid.isNull() &
              tbl.isDeleted.equals(false),
        ))
        .get();
  }

  Future<void> batchUpdateCoffeeBeansUuids(
    List<UserStatsCompanion> updates,
  ) async {
    await batch((batch) {
      for (final update in updates) {
        if (update.statUuid.present) {
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.statUuid.equals(update.statUuid.value),
          );
        } else if (update.id.present && update.id.value != null) {
          batch.update(
            userStats,
            update,
            where: (tbl) => tbl.id.equals(update.id.value!),
          );
        } else {
          AppLogger.warning(
            '[UserStatsDao] Unable to update record. Both statUuid and id are null or not present.',
          );
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
    List<UserStatsModel> stats,
  ) async {
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
      final isForeignKeyError = e.toString().contains(
        'FOREIGN KEY constraint failed',
      );

      if (isForeignKeyError) {
        AppLogger.error(
          '[UserStatsDao] Foreign key constraint failed during batch insert. Stats count: ${stats.length}',
          errorObject: e,
        );
        return BatchInsertResult.failed(stats, e.toString());
      }

      AppLogger.error(
        '[UserStatsDao] Unexpected error during batch insert',
        errorObject: e,
      );
      return BatchInsertResult.failed(stats, e.toString());
    }
  }

  /// Validates if the specified recipe IDs exist in the database
  Future<Map<String, bool>> validateRecipeReferences(
    List<String> recipeIds,
  ) async {
    if (recipeIds.isEmpty) {
      return {};
    }

    final uniqueRecipeIds = recipeIds.toSet().toList();

    try {
      // Query for existing recipes in batch
      final existingRecipes = await (select(
        recipes,
      )..where((tbl) => tbl.id.isIn(uniqueRecipeIds))).get();

      final existingIds = existingRecipes.map((r) => r.id).toSet();

      // Create a map indicating which recipe IDs exist
      final validationMap = <String, bool>{};
      for (final recipeId in uniqueRecipeIds) {
        validationMap[recipeId] = existingIds.contains(recipeId);
      }

      return validationMap;
    } catch (e) {
      AppLogger.error(
        '[UserStatsDao] Error validating recipe references',
        errorObject: e,
      );
      // Assume all recipes don't exist if validation fails
      return Map.fromEntries(uniqueRecipeIds.map((id) => MapEntry(id, false)));
    }
  }

  /// Returns any available recipe to use as a safe FK fallback
  Future<Recipe?> _fetchAnyRecipe() async {
    return (select(recipes)..limit(1)).getSingleOrNull();
  }

  /// Creates a fallback stat that points to an existing recipe (if any)
  Future<UserStatsModel?> createFallbackStat(
    UserStatsModel originalStat,
  ) async {
    final fallbackRecipe = await _fetchAnyRecipe();

    if (fallbackRecipe == null) {
      AppLogger.warning(
        '[UserStatsDao] Unable to create fallback stat: no recipes available',
      );
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
          '[UserStatsDao] Foreign key constraint failed for stat $sanitizedUuid, attempting fallback',
        );
        AppLogger.debug(
          '[UserStatsDao] Original recipe ID: $sanitizedRecipeId',
        );

        final fallbackStat = await createFallbackStat(stat);

        if (fallbackStat == null) {
          AppLogger.warning(
            '[UserStatsDao] Skipping stat $sanitizedUuid - no valid fallback recipe found',
          );
          rethrow;
        }

        try {
          await insertUserStat(fallbackStat);
          AppLogger.debug(
            '[UserStatsDao] Successfully inserted fallback stat for $sanitizedUuid',
          );
        } catch (fallbackError) {
          AppLogger.error(
            '[UserStatsDao] Failed to insert fallback stat',
            errorObject: fallbackError,
          );
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
        .write(UserStatsCompanion(coffeeBeansUuid: const Value(null)));
  }
}
