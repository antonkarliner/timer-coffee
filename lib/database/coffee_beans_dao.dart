part of 'database.dart';

@DriftAccessor(tables: [CoffeeBeans])
class CoffeeBeansDao extends DatabaseAccessor<AppDatabase>
    with _$CoffeeBeansDaoMixin {
  final AppDatabase db;

  CoffeeBeansDao(this.db) : super(db);

  CoffeeBeansModel _coffeeBeansFromRow(CoffeeBean row) {
    return CoffeeBeansModel(
      beansUuid: row.beansUuid,
      id: row.id,
      roaster: row.roaster,
      name: row.name,
      origin: row.origin,
      variety: row.variety,
      tastingNotes: row.tastingNotes,
      processingMethod: row.processingMethod,
      elevation: row.elevation,
      harvestDate: row.harvestDate,
      roastDate: row.roastDate,
      region: row.region,
      roastLevel: row.roastLevel,
      cuppingScore: row.cuppingScore,
      notes: row.notes,
      farmer: row.farmer,
      farm: row.farm,
      isFavorite: row.isFavorite,
      versionVector: row.versionVector,
      isDeleted: row.isDeleted, // Added isDeleted field
    );
  }

  CoffeeBeansCompanion _coffeeBeansToCompanion(CoffeeBeansModel model) {
    return CoffeeBeansCompanion(
      beansUuid: Value(model.beansUuid),
      roaster: Value(model.roaster),
      name: Value(model.name),
      origin: Value(model.origin),
      variety: Value(model.variety),
      tastingNotes: Value(model.tastingNotes),
      processingMethod: Value(model.processingMethod),
      elevation: Value(model.elevation),
      harvestDate: Value(model.harvestDate),
      roastDate: Value(model.roastDate),
      region: Value(model.region),
      roastLevel: Value(model.roastLevel),
      cuppingScore: Value(model.cuppingScore),
      notes: Value(model.notes),
      farmer: Value(model.farmer),
      farm: Value(model.farm),
      isFavorite: Value(model.isFavorite),
      versionVector: Value(model.versionVector),
      isDeleted: Value(model.isDeleted), // Added isDeleted field
    );
  }

  Future<void> insertCoffeeBeans(CoffeeBeansModel beans) async {
    await into(coffeeBeans)
        .insertOnConflictUpdate(_coffeeBeansToCompanion(beans));
  }

  Future<List<String>> fetchAllDistinctFarmers() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.farmer])
      ..where(
          coffeeBeans.farmer.isNotNull() & coffeeBeans.isDeleted.equals(false));
    final farmers =
        await query.map((row) => row.read(coffeeBeans.farmer)).get();
    return farmers.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctFarms() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.farm])
      ..where(
          coffeeBeans.farm.isNotNull() & coffeeBeans.isDeleted.equals(false));
    final farms = await query.map((row) => row.read(coffeeBeans.farm)).get();
    return farms.whereType<String>().toList();
  }

  Future<List<CoffeeBeansModel>> fetchAllCoffeeBeans() async {
    final query = select(coffeeBeans)
      ..orderBy([
        (t) => OrderingTerm(expression: t.roastDate, mode: OrderingMode.desc)
      ])
      ..where((t) => t.isDeleted.equals(false)); // Fetch only non-deleted beans
    final List<CoffeeBean> beansList = await query.get();
    return beansList.map(_coffeeBeansFromRow).toList();
  }

  Future<List<String>> fetchAllDistinctRoasters() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.roaster])
      ..where(coffeeBeans.roaster.isNotNull() &
          coffeeBeans.isDeleted.equals(false));

    final roasters =
        await query.map((row) => row.read(coffeeBeans.roaster)!).get();

    // Group roasters case-insensitively
    final roasterSet = <String, String>{};
    for (final roaster in roasters) {
      final lowerRoaster = roaster.toLowerCase();
      if (!roasterSet.containsKey(lowerRoaster)) {
        roasterSet[lowerRoaster] = roaster;
      }
    }
    return roasterSet.values.toList();
  }

  Future<List<String>> fetchAllDistinctNames() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.name])
      ..where(coffeeBeans.name.isNotNull() &
          coffeeBeans.isDeleted.equals(false)); // Exclude deleted beans
    final names = await query.map((row) => row.read(coffeeBeans.name)).get();
    return names.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctVarieties() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.variety])
      ..where(coffeeBeans.variety.isNotNull() &
          coffeeBeans.isDeleted.equals(false)); // Exclude deleted beans
    final varieties =
        await query.map((row) => row.read(coffeeBeans.variety)).get();
    return varieties.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctProcessingMethods() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.processingMethod])
      ..where(coffeeBeans.processingMethod.isNotNull() &
          coffeeBeans.isDeleted.equals(false)); // Exclude deleted beans
    final processingMethods =
        await query.map((row) => row.read(coffeeBeans.processingMethod)).get();
    return processingMethods.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctRoastLevels() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.roastLevel])
      ..where(coffeeBeans.roastLevel.isNotNull() &
          coffeeBeans.isDeleted.equals(false)); // Exclude deleted beans
    final roastLevels =
        await query.map((row) => row.read(coffeeBeans.roastLevel)).get();
    return roastLevels.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctOrigins() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.origin])
      ..where(
          coffeeBeans.origin.isNotNull() & coffeeBeans.isDeleted.equals(false));

    final origins =
        await query.map((row) => row.read(coffeeBeans.origin)!).get();

    // Group origins case-insensitively
    final originSet = <String, String>{};
    for (final origin in origins) {
      final lowerOrigin = origin.toLowerCase();
      if (!originSet.containsKey(lowerOrigin)) {
        originSet[lowerOrigin] = origin;
      }
    }
    return originSet.values.toList();
  }

  Future<List<String>> fetchAllDistinctTastingNotes() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.tastingNotes])
      ..where(coffeeBeans.tastingNotes.isNotNull() &
          coffeeBeans.isDeleted.equals(false)); // Exclude deleted beans
    final tastingNotes =
        await query.map((row) => row.read(coffeeBeans.tastingNotes)).get();
    return tastingNotes
        .whereType<String>()
        .expand((note) => note.split(', '))
        .toList();
  }

  Future<List<String>> fetchAllDistinctRegions() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.region])
      ..where(coffeeBeans.region.isNotNull() &
          coffeeBeans.isDeleted.equals(false)); // Exclude deleted beans
    final regions =
        await query.map((row) => row.read(coffeeBeans.region)).get();
    return regions.whereType<String>().toList();
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansById(int id) async {
    final query = select(coffeeBeans)
      ..where((tbl) =>
          tbl.id.equals(id) &
          tbl.isDeleted.equals(false)); // Exclude deleted beans
    final beans = await query.getSingleOrNull();
    print('Query result for ID $id: $beans');
    if (beans == null) return null;
    return _coffeeBeansFromRow(beans);
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansByUuid(String uuid) async {
    final query = select(coffeeBeans)
      ..where((tbl) =>
          tbl.beansUuid.equals(uuid) &
          tbl.isDeleted.equals(false)); // Exclude deleted beans
    final beans = await query.getSingleOrNull();
    return beans != null ? _coffeeBeansFromRow(beans) : null;
  }

  Future<void> updateCoffeeBeans(CoffeeBeansModel beans) async {
    print('DEBUG: DAO updateCoffeeBeans called for UUID: ${beans.beansUuid}');
    print(
        'DEBUG: Updating with data - Name: ${beans.name}, Roaster: ${beans.roaster}');

    try {
      final rowsAffected = await (update(coffeeBeans)
            ..where((tbl) => tbl.beansUuid.equals(beans.beansUuid)))
          .write(_coffeeBeansToCompanion(beans));

      print('DEBUG: Database update completed. Rows affected: $rowsAffected');

      if (rowsAffected == 0) {
        print('DEBUG: WARNING - No rows were updated! Bean may not exist.');
      }
    } catch (e) {
      print('DEBUG: ERROR in DAO updateCoffeeBeans: $e');
      throw e;
    }
  }

  Future<void> softDeleteCoffeeBeans(String uuid) async {
    final query = update(coffeeBeans)
      ..where((tbl) => tbl.beansUuid.equals(uuid));
    await query.write(CoffeeBeansCompanion(isDeleted: Value(true)));
  }

  Future<void> deleteCoffeeBeans(String uuid) async {
    // Physical delete only if necessary
    await (delete(coffeeBeans)..where((tbl) => tbl.beansUuid.equals(uuid)))
        .go();
  }

  Future<void> insertOrUpdateMultipleCoffeeBeans(
      List<CoffeeBeansModel> beansList) async {
    await batch((batch) {
      for (final beans in beansList) {
        batch.insert(
          coffeeBeans,
          _coffeeBeansToCompanion(beans),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> updateFavoriteStatus(String uuid, bool isFavorite) async {
    await (update(coffeeBeans)..where((tbl) => tbl.beansUuid.equals(uuid)))
        .write(CoffeeBeansCompanion(isFavorite: Value(isFavorite)));
  }

  Future<void> batchUpdateMissingUuidsAndTimestamps(
      List<CoffeeBeansCompanion> updates) async {
    await batch((batch) {
      for (final update in updates) {
        if (update.id.present && update.id.value != null) {
          batch.update(
            coffeeBeans,
            update,
            where: (tbl) => tbl.id.equals(update.id.value!),
          );
        } else if (update.beansUuid.present) {
          batch.update(
            coffeeBeans,
            update,
            where: (tbl) => tbl.beansUuid.equals(update.beansUuid.value),
          );
        }
      }
    });
  }

  Future<List<CoffeeBean>> fetchBeansNeedingUpdate() {
    return (select(coffeeBeans)..where((tbl) => tbl.versionVector.isNull()))
        .get();
  }

  Future<List<CoffeeBeansModel>> fetchAllBeansWithVersionVectors() async {
    final query = select(coffeeBeans);
    final results = await query.get();
    return results.map(_coffeeBeansFromRow).toList();
  }

  Future<List<CoffeeBeansModel>> fetchBeansByUuids(List<String> uuids) async {
    final query = select(coffeeBeans)
      ..where((tbl) =>
          tbl.beansUuid.isIn(uuids) &
          tbl.isDeleted.equals(false)); // Fetch only non-deleted beans
    final results = await query.get();
    return results.map(_coffeeBeansFromRow).toList();
  }

  Future<List<CoffeeBeansModel>> fetchCoffeeBeansFiltered({
    List<String>? roasters,
    List<String>? origins,
    bool? isFavorite,
  }) async {
    final query = select(coffeeBeans)..where((t) => t.isDeleted.equals(false));

    if (roasters != null && roasters.isNotEmpty) {
      final lowerRoasters = roasters.map((r) => r.toLowerCase()).toList();
      query.where((t) => t.roaster.lower().isIn(lowerRoasters));
    }

    if (origins != null && origins.isNotEmpty) {
      final lowerOrigins = origins.map((o) => o.toLowerCase()).toList();
      query.where((t) => t.origin.lower().isIn(lowerOrigins));
    }

    if (isFavorite != null) {
      query.where((t) => t.isFavorite.equals(isFavorite));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.roastDate, mode: OrderingMode.desc),
    ]);

    final beansList = await query.get();
    return beansList.map(_coffeeBeansFromRow).toList();
  }

  Future<List<String>> fetchOriginsForRoasters(
      List<String> selectedRoasters) async {
    if (selectedRoasters.isEmpty) {
      return await fetchAllDistinctOrigins();
    }

    final lowerRoasters = selectedRoasters.map((r) => r.toLowerCase()).toList();

    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.origin])
      ..where(coffeeBeans.origin.isNotNull() &
          coffeeBeans.isDeleted.equals(false) &
          coffeeBeans.roaster.lower().isIn(lowerRoasters));

    final origins =
        await query.map((row) => row.read(coffeeBeans.origin)!).get();

    // Group origins case-insensitively
    final originSet = <String, String>{};
    for (final origin in origins) {
      final lowerOrigin = origin.toLowerCase();
      if (!originSet.containsKey(lowerOrigin)) {
        originSet[lowerOrigin] = origin;
      }
    }
    return originSet.values.toList();
  }
}
