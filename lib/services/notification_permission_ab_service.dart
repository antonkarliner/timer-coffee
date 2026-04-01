import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import 'analytics_service.dart';

/// Manages the A/B test for notification permission prompt timing.
///
/// Three equally-sized groups (~33 % each):
///   Variant A: show the dialog after brew #1
///   Variant B: show the dialog after brew #2
///   Variant C: show the dialog after brew #3
///
/// Assignment is persisted in SharedPreferences on the first brew so that
/// users never switch groups. An analytics event is fired once at assignment.
class NotificationPermissionAbService {
  NotificationPermissionAbService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyVariant = 'notif_perm_ab_variant';
  static const _keyThreshold = 'notif_perm_ab_threshold';
  static const _keyBrewCount = 'notif_perm_ab_brew_count';
  static const _keyShown = 'notif_perm_ab_shown';

  /// Legacy key written by the old one-shot dialog logic.
  /// If present and false, the user already saw the dialog before the A/B
  /// test was introduced — skip them to avoid re-prompting.
  static const _legacyKeyFirstFinishScreen = 'firstfinishscreen';

  String get variant => _prefs.getString(_keyVariant) ?? '';
  int get threshold => _prefs.getInt(_keyThreshold) ?? 1;
  int get brewCount => _prefs.getInt(_keyBrewCount) ?? 0;
  bool get isShown => _prefs.getBool(_keyShown) ?? false;

  /// Records this brew completion and returns whether the dialog should be
  /// shown now. Assigns the variant on the first call.
  Future<bool> recordBrewAndCheckShouldShow() async {
    if (kIsWeb) return false;
    if (isShown) return false;

    // Migration: users who already saw the dialog under the old code never
    // need to see it again.
    if (_prefs.containsKey(_legacyKeyFirstFinishScreen) &&
        !(_prefs.getBool(_legacyKeyFirstFinishScreen) ?? true)) {
      await markShown();
      return false;
    }

    await _ensureVariantAssigned();

    final newCount = brewCount + 1;
    await _prefs.setInt(_keyBrewCount, newCount);

    AppLogger.debug(
      'NotifPermAb: variant=$variant threshold=$threshold brewCount=$newCount',
    );

    return newCount >= threshold;
  }

  Future<void> markShown() async {
    await _prefs.setBool(_keyShown, true);
  }

  // ── private ──────────────────────────────────────────────────────────────

  Future<void> _ensureVariantAssigned() async {
    if (_prefs.containsKey(_keyVariant)) return;

    final rng = math.Random();
    final roll = rng.nextInt(3); // 0, 1, or 2 — equal probability
    final assignedVariant = ['a', 'b', 'c'][roll];
    final assignedThreshold = roll + 1; // a=1, b=2, c=3

    await _prefs.setString(_keyVariant, assignedVariant);
    await _prefs.setInt(_keyThreshold, assignedThreshold);

    AppLogger.debug(
      'NotifPermAb: assigned variant=$assignedVariant '
      'threshold=$assignedThreshold',
    );

    AnalyticsService.instance.track(
      'notification_permission_ab_assigned',
      properties: {
        'variant': assignedVariant,
        'threshold': assignedThreshold,
      },
    );
  }
}
