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
  static const int kPourArmPercent = 50;

  final bool _isWeb;

  bool _manualStepControlEnabled = false;
  bool _pourLayoutEnabled = false;
  String? _layoutArm;

  bool get manualStepControlEnabled => _manualStepControlEnabled;

  bool get pourLayoutEnabled => _pourLayoutEnabled;

  String? get layoutArm => _layoutArm;

  AdvancedFeaturesService({bool? isWeb}) : _isWeb = isWeb ?? kIsWeb;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _manualStepControlEnabled = prefs.getBool(_kManualStepControlKey) ?? false;
    _pourLayoutEnabled = prefs.getBool(kPourLayoutKey) ?? false;
    final persistedArm = prefs.get(kLayoutArmKey);
    _layoutArm =
        persistedArm is String &&
            (persistedArm == 'pour' || persistedArm == 'classic')
        ? persistedArm
        : null;
    notifyListeners();
  }

  static String armForInstallId(
    String installId, {
    int pourPercent = kPourArmPercent,
  }) {
    if (installId.length < 2) return 'classic';

    final lastByte = int.tryParse(
      installId.substring(installId.length - 2),
      radix: 16,
    );
    if (lastByte == null) return 'classic';

    return lastByte * 100 ~/ 256 < pourPercent ? 'pour' : 'classic';
  }

  Future<void> assignLayoutArmIfEligible({
    required bool firstBrewDone,
    required String installId,
    required bool experimentActive,
  }) async {
    if (_isWeb || firstBrewDone || _layoutArm != null || !experimentActive) {
      return;
    }

    final arm = armForInstallId(installId);
    final pourWasFlipped = arm == 'pour' && !_pourLayoutEnabled;
    _layoutArm = arm;
    if (pourWasFlipped) {
      _pourLayoutEnabled = true;
    }
    notifyListeners();

    if (pourWasFlipped) {
      AnalyticsService.maybeInstance?.track(
        'beta_feature_toggled',
        properties: {
          'feature': 'pour_layout',
          'enabled': true,
          'source': 'experiment_assignment',
        },
      );
    }
    AnalyticsService.maybeInstance?.track(
      'layout_arm_assigned',
      properties: {'arm': arm, 'pour_percent': kPourArmPercent},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPourLayoutKey, _pourLayoutEnabled);
    await prefs.setString(kLayoutArmKey, arm);
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
