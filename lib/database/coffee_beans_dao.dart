part of 'database.dart';

@DriftAccessor(tables: [CoffeeBeans])
class CoffeeBeansDao extends DatabaseAccessor<AppDatabase>
    with _$CoffeeBeansDaoMixin {
  final AppDatabase db;

  CoffeeBeansDao(this.db) : super(db);

  Future<void> insertCoffeeBeans(CoffeeBeansCompanion entity) async {
    await into(coffeeBeans).insert(entity);
  }

  Future<List<CoffeeBeansModel>> fetchAllCoffeeBeans() async {
    final List<CoffeeBean> beansList = await select(coffeeBeans).get();
    return beansList
        .map((beans) => CoffeeBeansModel(
              id: beans.id,
              roaster: beans.roaster,
              name: beans.name,
              origin: beans.origin,
              variety: beans.variety,
              tastingNotes: beans.tastingNotes,
              processingMethod: beans.processingMethod,
              elevation: beans.elevation,
              harvestDate: beans.harvestDate,
              roastDate: beans.roastDate,
              region: beans.region,
              roastLevel: beans.roastLevel,
              cuppingScore: beans.cuppingScore,
              notes: beans.notes,
              isFavorite: beans.isFavorite,
              beansUuid: beans.beansUuid,
            ))
        .toList();
  }

  Future<List<String>> fetchAllDistinctRoasters() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.roaster])
      ..where(coffeeBeans.roaster.isNotNull());
    final roasters =
        await query.map((row) => row.read(coffeeBeans.roaster)).get();
    return roasters.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctNames() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.name])
      ..where(coffeeBeans.name.isNotNull());
    final names = await query.map((row) => row.read(coffeeBeans.name)).get();
    return names.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctVarieties() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.variety])
      ..where(coffeeBeans.variety.isNotNull());
    final varieties =
        await query.map((row) => row.read(coffeeBeans.variety)).get();
    return varieties.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctProcessingMethods() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.processingMethod])
      ..where(coffeeBeans.processingMethod.isNotNull());
    final processingMethods =
        await query.map((row) => row.read(coffeeBeans.processingMethod)).get();
    return processingMethods.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctRoastLevels() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.roastLevel])
      ..where(coffeeBeans.roastLevel.isNotNull());
    final roastLevels =
        await query.map((row) => row.read(coffeeBeans.roastLevel)).get();
    return roastLevels.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctOrigins() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.origin])
      ..where(coffeeBeans.origin.isNotNull());
    final origins =
        await query.map((row) => row.read(coffeeBeans.origin)).get();
    return origins.whereType<String>().toList();
  }

  Future<List<String>> fetchAllDistinctTastingNotes() async {
    final query = selectOnly(coffeeBeans, distinct: true)
      ..addColumns([coffeeBeans.tastingNotes])
      ..where(coffeeBeans.tastingNotes.isNotNull());
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
      ..where(coffeeBeans.region.isNotNull());
    final regions =
        await query.map((row) => row.read(coffeeBeans.region)).get();
    return regions.whereType<String>().toList();
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansById(int id) async {
    final query = select(coffeeBeans)..where((tbl) => tbl.id.equals(id));
    final beans = await query.getSingleOrNull();
    print('Query result: $beans');
    if (beans == null) return null;
    return CoffeeBeansModel(
      id: beans.id,
      roaster: beans.roaster,
      name: beans.name,
      origin: beans.origin,
      variety: beans.variety,
      tastingNotes: beans.tastingNotes,
      processingMethod: beans.processingMethod,
      elevation: beans.elevation,
      harvestDate: beans.harvestDate,
      roastDate: beans.roastDate,
      region: beans.region,
      roastLevel: beans.roastLevel,
      cuppingScore: beans.cuppingScore,
      notes: beans.notes,
      isFavorite: beans.isFavorite,
      beansUuid: beans.beansUuid,
    );
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansByUuid(String uuid) async {
    final query = select(coffeeBeans)
      ..where((tbl) => tbl.beansUuid.equals(uuid));
    final beans = await query.getSingleOrNull();
    print('Query result for UUID $uuid: $beans');
    if (beans == null) return null;
    return CoffeeBeansModel(
      id: beans.id,
      roaster: beans.roaster,
      name: beans.name,
      origin: beans.origin,
      variety: beans.variety,
      tastingNotes: beans.tastingNotes,
      processingMethod: beans.processingMethod,
      elevation: beans.elevation,
      harvestDate: beans.harvestDate,
      roastDate: beans.roastDate,
      region: beans.region,
      roastLevel: beans.roastLevel,
      cuppingScore: beans.cuppingScore,
      notes: beans.notes,
      isFavorite: beans.isFavorite,
      beansUuid: beans.beansUuid,
    );
  }

  Future<void> deleteCoffeeBeans(String uuid) async {
    await (delete(coffeeBeans)..where((tbl) => tbl.beansUuid.equals(uuid)))
        .go();
  }

  Future<void> updateCoffeeBeans(CoffeeBeansCompanion entity) async {
    await (update(coffeeBeans)..where((tbl) => tbl.id.equals(entity.id.value)))
        .write(entity);
  }

  Future<void> updateFavoriteStatus(String uuid, bool isFavorite) async {
    await (update(coffeeBeans)..where((tbl) => tbl.beansUuid.equals(uuid)))
        .write(CoffeeBeansCompanion(isFavorite: Value(isFavorite)));
  }

  Future<void> batchUpdateMissingUuidsAndTimestamps(
      List<CoffeeBeansCompanion> updates) async {
    await batch((batch) {
      for (final update in updates) {
        batch.update(
          coffeeBeans,
          update,
          where: (tbl) => tbl.id.equals(update.id.value),
        );
      }
    });
  }

  Future<List<CoffeeBean>> fetchBeansNeedingUpdate() {
    return (select(coffeeBeans)..where((tbl) => tbl.beansUuid.isNull())).get();
  }
}
