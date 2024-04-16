// lib/database/supported_locales_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [SupportedLocales])
class SupportedLocalesDao extends DatabaseAccessor<AppDatabase>
    with _$SupportedLocalesDaoMixin {
  final AppDatabase db;

  SupportedLocalesDao(this.db) : super(db);

  Future<List<SupportedLocaleModel>> getAllSupportedLocales() async {
    final query = select(db.supportedLocales);
    final result = await query.get();
    return result
        .map((row) => SupportedLocaleModel(
              locale: row.locale,
              localeName: row.localeName,
            ))
        .toList();
  }
}
