import 'package:shared_preferences/shared_preferences.dart';

/// Which launch popups a surface has already shown, under one prefs [key]
/// per surface and locale (e.g. `lastPopupId_en`).
///
/// This used to be only the last id shown, which was enough while the
/// newest popup only ever moved forward. With audience targeting (app plan
/// 076 §3) the popup a viewer gets can move back — a targeted popup ends, or
/// the viewer leaves its audience — and the older popup they had already
/// closed would show again. So recent ids are remembered too. [key] itself
/// still holds the last id, which is also what older installs have.
class SeenPopupIds {
  SeenPopupIds._();

  static const _maxRemembered = 50;

  static String _historyKey(String key) => '${key}_history';

  static bool contains(SharedPreferences prefs, String key, int id) =>
      prefs.getInt(key) == id ||
      (prefs.getStringList(_historyKey(key)) ?? const []).contains('$id');

  static Future<void> add(SharedPreferences prefs, String key, int id) async {
    final history = [...?prefs.getStringList(_historyKey(key))];
    final last = prefs.getInt(key);
    // Carry the pre-history last id over, so an upgrade doesn't forget it.
    if (last != null && last != id && !history.contains('$last')) {
      history.add('$last');
    }
    history
      ..remove('$id')
      ..add('$id');
    if (history.length > _maxRemembered) {
      history.removeRange(0, history.length - _maxRemembered);
    }
    await prefs.setStringList(_historyKey(key), history);
    await prefs.setInt(key, id);
  }
}
