// lib/database/launch_popups_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [LaunchPopups])
class LaunchPopupsDao extends DatabaseAccessor<AppDatabase>
    with _$LaunchPopupsDaoMixin {
  final AppDatabase db;

  LaunchPopupsDao(this.db) : super(db);

  // Retrieve the latest launch popup content for a specific locale
  Future<LaunchPopupModel?> getLatestLaunchPopup(String locale) async {
    final query = select(launchPopups)
      ..where((tbl) => tbl.locale.equals(locale))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
      ])
      ..limit(1);
    final result = await query.getSingleOrNull();
    if (result != null) {
      return LaunchPopupModel(
        id: result.id,
        content: result.content,
        locale: result.locale,
        createdAt: result.createdAt,
      );
    }
    return null;
  }
}
