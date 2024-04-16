// lib/database/coffee_facts_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [CoffeeFacts])
class CoffeeFactsDao extends DatabaseAccessor<AppDatabase>
    with _$CoffeeFactsDaoMixin {
  final AppDatabase db;

  CoffeeFactsDao(this.db) : super(db);

  // Retrieve a random coffee fact for a specific locale
  Future<CoffeeFactModel?> getRandomCoffeeFact(String locale) async {
    // Define a custom ordering term using a raw SQL snippet for random ordering.
    final customOrdering = CustomExpression('RANDOM()');

    final query = select(coffeeFacts)
      ..where((tbl) => tbl.locale.equals(locale))
      ..orderBy([(tbl) => OrderingTerm(expression: customOrdering)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row != null
        ? CoffeeFactModel(id: row.id, fact: row.fact, locale: row.locale)
        : null;
  }
}
