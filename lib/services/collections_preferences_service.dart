import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for the home-screen Collections section: whether it is
/// collapsed (header visible, carousel hidden) and whether it has been
/// dismissed entirely (the whole section hidden until re-enabled from
/// Settings).
class CollectionsPreferencesService extends ChangeNotifier {
  static const _kCollapsedKey = 'collections_section_collapsed';
  static const _kDismissedKey = 'collections_section_dismissed';

  bool _collapsed = false;
  bool _dismissed = false;

  bool get collapsed => _collapsed;
  bool get dismissed => _dismissed;

  CollectionsPreferencesService();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _collapsed = prefs.getBool(_kCollapsedKey) ?? false;
    _dismissed = prefs.getBool(_kDismissedKey) ?? false;
    notifyListeners();
  }

  Future<void> setCollapsed(bool value) async {
    if (_collapsed == value) return;
    _collapsed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCollapsedKey, value);
  }

  Future<void> setDismissed(bool value) async {
    if (_dismissed == value) return;
    _dismissed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDismissedKey, value);
  }
}
