import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// Holds opt-in toggles for advanced / beta features.
///
/// Exposes manual step control and the immersive pour layout, persisting both
/// choices and centralizing analytics for immersive-layout changes.
class AdvancedFeaturesService extends ChangeNotifier {
  static const _kManualStepControlKey = 'advanced_manual_step_control_enabled';
  static const kPourLayoutKey = 'advanced_pour_layout_enabled';
  static const kLayoutArmKey = 'advanced_layout_arm';

  bool _manualStepControlEnabled = false;
  bool _pourLayoutEnabled = false;

  bool get manualStepControlEnabled => _manualStepControlEnabled;

  bool get pourLayoutEnabled => _pourLayoutEnabled;

  AdvancedFeaturesService();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _manualStepControlEnabled = prefs.getBool(_kManualStepControlKey) ?? false;
    _pourLayoutEnabled = prefs.getBool(kPourLayoutKey) ?? false;
    notifyListeners();
  }

  Future<void> setManualStepControlEnabled(bool enabled) async {
    if (_manualStepControlEnabled == enabled) return;
    _manualStepControlEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kManualStepControlKey, enabled);
  }

  Future<void> setPourLayoutEnabled(
    bool enabled, {
    required String source,
  }) async {
    if (_pourLayoutEnabled == enabled) return;
    _pourLayoutEnabled = enabled;
    notifyListeners();
    AnalyticsService.maybeInstance?.track(
      'beta_feature_toggled',
      properties: {
        'feature': 'pour_layout',
        'enabled': enabled,
        'source': source,
      },
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPourLayoutKey, enabled);
  }
}
