import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';
import '../services/local_notification_scheduler_service.dart';
import '../database/database.dart';
import '../services/onboarding_service.dart';
import '../utils/app_logger.dart';

/// Result of toggling the master notification switch.
enum ToggleNotificationResult { success, permissionDenied, error }

/// Central controller for the Settings screen.
///
/// Owns notification state, icon state, user/auth state, and all stream
/// subscriptions. UI subscribes via ChangeNotifier.
/// Follows the same pattern as [CoffeeBeansController] and [StatsController].
class SettingsController extends ChangeNotifier {
  // ── User / auth state ──
  bool isAnonymous = true;
  String? userId;

  // ── Icon state ──
  static const MethodChannel _iconChannel =
      MethodChannel('com.coffee.timer/icon');
  String? currentIconName;
  bool iconApiAvailable = false;
  String? localIconState;
  bool get isDefaultIcon => localIconState == null || localIconState == 'Default';

  // ── Notification state ──
  bool masterNotificationsEnabled = true;
  bool notificationsEnabled = true;
  bool systemPermissionDenied = false;
  bool isLoading = true;

  // Optional notification toggles
  bool morningReminderEnabled = false;
  TimeOfDay morningReminderTime = const TimeOfDay(hour: 8, minute: 30);
  bool weeklySummaryEnabled = false;
  bool beanFreshnessEnabled = false;

  // ── Debug flag ──
  static const showNotifDebugPanel =
      bool.fromEnvironment('NOTIF_DEBUG', defaultValue: kDebugMode);

  // ── Private ──
  final NotificationService _notificationService = NotificationService.instance;

  StreamSubscription<bool>? _notifStateSub;
  StreamSubscription<bool>? _permSub;
  StreamSubscription<bool>? _morningSub;
  StreamSubscription<TimeOfDay>? _morningTimeSub;
  StreamSubscription<bool>? _weeklySub;
  StreamSubscription<bool>? _beanFreshnessSub;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads auth state from Supabase.
  void loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    isAnonymous = user?.isAnonymous ?? true;
    userId = user?.id;
    notifyListeners();
  }

  /// Initializes the icon API. Platform-specific: Android uses native
  /// MethodChannel, iOS uses FlutterDynamicIconPlus plugin.
  Future<void> initIconApi() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        final current = await _iconChannel.invokeMethod('getCurrentIcon');
        AppLogger.debug('Native getCurrentIcon returned: $current');
        iconApiAvailable = true;
        currentIconName = current;
        localIconState = current;
      } else {
        final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
        final current =
            supported ? await FlutterDynamicIconPlus.alternateIconName : null;
        AppLogger.debug(
            'iOS - Icon API supported: $supported, current icon: $current');
        iconApiAvailable = supported;
        currentIconName = current;
        localIconState = current ?? 'Default';
      }
    } catch (e) {
      AppLogger.error('Icon API init error', errorObject: e);
      iconApiAvailable = false;
    }
    notifyListeners();
  }

  /// Sets the app icon. Returns `true` on success, `false` on failure.
  /// The caller is responsible for showing error feedback (snackbar).
  Future<bool> setIcon(String? iconName) async {
    if (!iconApiAvailable) return false;

    try {
      AppLogger.debug(
          '==================== ICON CHANGE START ====================');
      AppLogger.debug('Current state before change: $localIconState');
      AppLogger.debug('Requested icon change to: $iconName');

      bool success = false;

      if (Platform.isAndroid) {
        AppLogger.debug('Using native method for Android');
        success =
            await _iconChannel.invokeMethod('setIcon', {'iconName': iconName});
        AppLogger.debug('Native setIcon returned: $success');
      } else {
        AppLogger.debug('Using plugin for iOS');
        final actualIconName = iconName == 'Default' ? null : iconName;
        await FlutterDynamicIconPlus.setAlternateIconName(
            iconName: actualIconName);
        success = true;
        AppLogger.debug('Plugin setIcon completed');
      }

      if (success) {
        localIconState = iconName;
        notifyListeners();
        AppLogger.debug('Local state updated to: $iconName');
        AppLogger.debug(
            '==================== ICON CHANGE END ====================');
      }
      return success;
    } catch (e) {
      AppLogger.error('Icon change error', errorObject: e);
      AppLogger.debug('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Initializes notification settings: loads persisted state, checks
  /// system permissions, and subscribes to 6 reactive streams.
  Future<void> initNotificationSettings() async {
    if (kIsWeb) {
      isLoading = false;
      notificationsEnabled = false;
      systemPermissionDenied = false;
      notifyListeners();
      return;
    }

    try {
      await _notificationService.initialize();

      final master = await _notificationService.settings.isMasterEnabled();
      final hasPermission =
          await _notificationService.permissions.hasNotificationPermission;

      masterNotificationsEnabled = master;
      notificationsEnabled = master && hasPermission;
      systemPermissionDenied = !hasPermission;
      isLoading = false;

      // Load optional toggles
      final settingsService = _notificationService.settings;
      morningReminderEnabled =
          await settingsService.isMorningReminderEnabled();
      morningReminderTime = await settingsService.getMorningReminderTime();
      weeklySummaryEnabled = await settingsService.isWeeklySummaryEnabled();
      beanFreshnessEnabled = await settingsService.isBeanFreshnessEnabled();

      notifyListeners();

      // Subscribe to live updates
      _notifStateSub =
          _notificationService.notificationStateStream.listen((state) {
        notificationsEnabled = state;
        notifyListeners();
      });

      _permSub =
          _notificationService.permissions.permissionChanges.listen((hasPerm) {
        systemPermissionDenied = !hasPerm;
        if (!hasPerm && notificationsEnabled) {
          notificationsEnabled = false;
        }
        notifyListeners();
      });

      _morningSub = settingsService.morningChanges.listen((enabled) {
        morningReminderEnabled = enabled;
        notifyListeners();
      });
      _morningTimeSub = settingsService.morningTimeChanges.listen((time) {
        morningReminderTime = time;
        notifyListeners();
      });
      _weeklySub = settingsService.weeklyChanges.listen((enabled) {
        weeklySummaryEnabled = enabled;
        notifyListeners();
      });
      _beanFreshnessSub =
          settingsService.beanFreshnessChanges.listen((enabled) {
        beanFreshnessEnabled = enabled;
        notifyListeners();
      });
    } catch (e) {
      AppLogger.error('Error initializing notification settings',
          errorObject: e);
      isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the master notification switch.
  ///
  /// Returns [ToggleNotificationResult] so the screen can decide whether to
  /// show a dialog (e.g. when permission is denied).
  Future<ToggleNotificationResult> toggleNotifications(bool enabled) async {
    if (kIsWeb) return ToggleNotificationResult.error;

    try {
      if (enabled) {
        final hasPerm =
            await _notificationService.permissions.hasNotificationPermission;

        if (!hasPerm) {
          final granted = await _notificationService.requestPermissions();
          if (!granted) {
            return ToggleNotificationResult.permissionDenied;
          }
        }
      }

      await _notificationService.updateMasterToggle(
        enabled: enabled,
        userId: userId,
      );

      masterNotificationsEnabled = enabled;
      notificationsEnabled = enabled && !systemPermissionDenied;
      notifyListeners();

      return ToggleNotificationResult.success;
    } catch (e) {
      AppLogger.error('Error toggling notifications', errorObject: e);
      return ToggleNotificationResult.error;
    }
  }

  /// Handles an optional toggle change (morning reminder, weekly summary,
  /// bean freshness). Persists the new value and triggers a reschedule.
  Future<void> onOptionalToggleChanged(
    bool value,
    Future<void> Function(bool) setter, {
    required AppDatabase database,
    required OnboardingService onboarding,
    required String locale,
  }) async {
    await setter(value);
    unawaited(LocalNotificationSchedulerService.instance.rescheduleAll(
      database: database,
      onboarding: onboarding,
      locale: locale,
    ));
  }

  /// Updates the morning reminder time and triggers a reschedule.
  Future<void> updateMorningReminderTime(
    TimeOfDay picked, {
    required AppDatabase database,
    required OnboardingService onboarding,
    required String locale,
  }) async {
    await _notificationService.settings.setMorningReminderTime(picked);
    unawaited(LocalNotificationSchedulerService.instance.rescheduleAll(
      database: database,
      onboarding: onboarding,
      locale: locale,
    ));
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _notifStateSub?.cancel();
    _permSub?.cancel();
    _morningSub?.cancel();
    _morningTimeSub?.cancel();
    _weeklySub?.cancel();
    _beanFreshnessSub?.cancel();
    super.dispose();
  }
}
