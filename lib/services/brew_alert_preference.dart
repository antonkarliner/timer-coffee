import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_mode.dart';

/// Owns the brew-alert mode: how the app signals a step change while
/// brewing (silent / vibration / sound).
///
/// The mode is stored in SharedPreferences under the pre-existing
/// `notificationMode` key with the pre-existing int values (0 none /
/// 1 vibration / 2 sound), so existing installs keep their setting.
///
/// Both the Preparation screen and the Settings brewing page read the same
/// [mode] notifier: Preparation reads the mode in `initState`, so a change
/// made in Settings while Preparation is still on the navigation stack
/// below would otherwise not show. Writing through [set] notifies every
/// listener at once.
///
/// No analytics live here; callers emit their own events (see
/// `SettingsAnalytics.settingChanged` with `SettingKey.brewAlerts`).
class BrewAlertPreference {
  BrewAlertPreference._();

  static final BrewAlertPreference instance = BrewAlertPreference._();

  static const _prefsKey = 'notificationMode';

  final ValueNotifier<NotificationMode> _notifier =
      ValueNotifier<NotificationMode>(NotificationMode.none);

  /// The current brew-alert mode. Listen to this, not to snapshots:
  /// the value can change from another screen.
  ValueListenable<NotificationMode> get mode => _notifier;

  /// Reads the stored mode into [mode]. Safe to call more than once.
  Future<void> load() async {
    final setsBefore = _setCount;
    final prefs = await SharedPreferences.getInstance();
    // A choice made while this read was in flight wins over the stored one.
    if (_setCount != setsBefore) return;
    // Stored default today is 0 (none) for installs that never chose.
    _notifier.value = NotificationMode.fromValue(prefs.getInt(_prefsKey) ?? 0);
  }

  int _setCount = 0;

  /// Updates [mode] and persists [m]. No-op when [m] is already current,
  /// so re-choosing the visible value neither writes nor notifies.
  Future<void> set(NotificationMode m) async {
    if (_notifier.value == m) return;
    _setCount++;
    // Update the notifier synchronously, before the first await, so
    // listeners (and anything they setState) see the new value this frame.
    _notifier.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, m.value);
  }

  /// Restores the initial value. Tests only.
  @visibleForTesting
  void resetForTesting() {
    _notifier.value = NotificationMode.none;
  }
}

/// Analytics wire name of a brew-alert mode
/// (`silent` / `vibration` / `sound`), for `setting_changed` events.
extension NotificationModeWireName on NotificationMode {
  String get wireName => switch (this) {
    NotificationMode.none => 'silent',
    NotificationMode.vibrationOnly => 'vibration',
    NotificationMode.soundOnly => 'sound',
  };
}
