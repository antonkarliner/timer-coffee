// lib/database/contributors_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [Contributors])
class ContributorsDao extends DatabaseAccessor<AppDatabase>
    with _$ContributorsDaoMixin {
  final AppDatabase db;

  ContributorsDao(this.db) : super(db);

  Future<List<ContributorModel>> getAllContributorsForLocale(
      String locale) async {
    final query = select(contributors)
      ..where((tbl) => tbl.locale.equals(locale));
    final result = await query.get();
    return result
        .map((row) => ContributorModel(
              id: row.id,
              content: row.content,
              locale: row.locale,
            ))
        .toList();
  }
}
