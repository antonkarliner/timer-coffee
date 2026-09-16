import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds opt-in toggles for advanced / beta features.
///
/// Currently exposes manual step control and the immersive pour layout on the
/// brewing screen. Add future beta toggles as sibling boolean fields following
/// the same pattern.
class AdvancedFeaturesService extends ChangeNotifier {
  static const _kManualStepControlKey = 'advanced_manual_step_control_enabled';
  static const _kPourLayoutKey = 'advanced_pour_layout_enabled';

  bool _manualStepControlEnabled = false;
  bool _pourLayoutEnabled = false;

  bool get manualStepControlEnabled => _manualStepControlEnabled;

  bool get pourLayoutEnabled => _pourLayoutEnabled;

  AdvancedFeaturesService();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _manualStepControlEnabled = prefs.getBool(_kManualStepControlKey) ?? false;
    _pourLayoutEnabled = prefs.getBool(_kPourLayoutKey) ?? false;
    notifyListeners();
  }

  Future<void> setManualStepControlEnabled(bool enabled) async {
    if (_manualStepControlEnabled == enabled) return;
    _manualStepControlEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kManualStepControlKey, enabled);
  }

  Future<void> setPourLayoutEnabled(bool enabled) async {
    if (_pourLayoutEnabled == enabled) return;
    _pourLayoutEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPourLayoutKey, enabled);
  }
}
