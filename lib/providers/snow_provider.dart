import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the seasonal snow overlay is shown.
///
/// The value persists to SharedPreferences under [prefKey] so it survives
/// restarts. It is loaded fire-and-forget in the constructor; a value set
/// before that load finishes wins over the stored one.
class SnowEffectProvider with ChangeNotifier {
  static const prefKey = 'snow_effect_enabled';

  bool _isSnowing = false;
  bool _userSet = false;

  SnowEffectProvider() {
    _load();
  }

  bool get isSnowing => _isSnowing;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(prefKey) ?? false;
    // A set that raced this load wins; never clobber the user's choice.
    if (_userSet || stored == _isSnowing) return;
    _isSnowing = stored;
    notifyListeners();
  }

  /// Sets the snow effect and persists it. No-op when unchanged.
  Future<void> setSnowEffect(bool enabled) async {
    if (enabled == _isSnowing) return;
    _isSnowing = enabled;
    _userSet = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, enabled);
  }

  Future<void> toggleSnowEffect() => setSnowEffect(!_isSnowing);
}
