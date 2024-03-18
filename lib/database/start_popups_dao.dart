// lib/database/start_popups_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [StartPopups])
class StartPopupsDao extends DatabaseAccessor<AppDatabase>
    with _$StartPopupsDaoMixin {
  final AppDatabase db;

  StartPopupsDao(this.db) : super(db);

  // Retrieve the start popup content for a specific app version and locale
  Future<StartPopupModel?> getStartPopup(
      String appVersion, String locale) async {
    final query = select(startPopups)
      ..where((tbl) =>
          tbl.appVersion.equals(appVersion) & tbl.locale.equals(locale))
      ..limit(1);
    final result = await query.getSingleOrNull();
    if (result != null) {
      return StartPopupModel(
        id: result.id,
        content: result.content,
        appVersion: result.appVersion,
        locale: result.locale,
      );
    }
    return null;
  }
}
