part of 'database.dart';

@DriftAccessor(tables: [BrewingMethods])
class BrewingMethodsDao extends DatabaseAccessor<AppDatabase>
    with _$BrewingMethodsDaoMixin {
  final AppDatabase db;

  BrewingMethodsDao(this.db) : super(db);

  Future<List<BrewingMethodModel>> getAllBrewingMethods() async {
    final query = select(brewingMethods);
    final List<BrewingMethod> result = await query.get();

    return result
        .map((dbBrewingMethod) => BrewingMethodModel(
              brewingMethodId: dbBrewingMethod.brewingMethodId,
              brewingMethod: dbBrewingMethod.brewingMethod,
            ))
        .toList();
  }

  Future<String?> getBrewingMethodNameById(String brewingMethodId) async {
    final query = select(brewingMethods)
      ..where((t) => t.brewingMethodId.equals(brewingMethodId));
    final BrewingMethod? brewingMethod = await query.getSingleOrNull();
    return brewingMethod?.brewingMethod;
  }
}
