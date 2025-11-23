import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:coffee_timer/providers/fcm_provider.dart';
import 'package:coffee_timer/services/local_notification_manager.dart';
import 'package:coffee_timer/services/permission_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/services/exact_alarm_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';

/// Unified notification service that coordinates local notifications and permissions
///
/// This service now uses FcmProvider for FCM token management and provides
/// a centralized API for:
/// - Master notification toggle with BehaviorSubject-based state management
/// - Enhanced permission handling with Firebase-first approach and lifecycle-aware caching
/// - Local notification scheduling and display
///
/// Lifecycle Management:
/// - Automatically initializes on first access and tracks initialization state
/// - Subscribes to permission changes and master setting changes
/// - Properly disposes streams and cleans up resources
///
/// Permission Observer Behavior:
/// - Monitors system permission changes via enhanced PermissionService
/// - Automatically updates notification state when permissions change
/// - Provides real-time permission status streams for UI components
/// - Handles app lifecycle events to refresh permission cache
class NotificationService {
  /// Singleton instance for global access to notification functionality
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;

  /// Private constructor for singleton pattern
  NotificationService._internal();

  /// Core notification subsystem dependencies
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late final NotificationSettingsService _settingsService;
  late final PermissionService _permissionService;
  late final LocalNotificationManager _localManager;
  FcmProvider? _fcmProvider;

  /// Gets FCM provider instance, initializing if necessary
  FcmProvider get fcm {
    _fcmProvider ??= FcmProvider();
    return _fcmProvider!;
  }

  /// Stream controller for notification state management
  /// Emits true when notifications are enabled and permissions are granted
  final BehaviorSubject<bool> _notificationStateController =
      BehaviorSubject<bool>();

  /// Stream of notification state changes for UI components
  /// Provides distinct values to prevent unnecessary rebuilds
  Stream<bool> get notificationStateStream =>
      _notificationStateController.stream.distinct();

  /// Stream for handling notification tap events from both local and remote notifications
  /// Used by UI components to navigate when user taps a notification
  final BehaviorSubject<String?> onNotificationTapped = BehaviorSubject();

  /// Tracks whether service has been initialized
  /// Prevents duplicate initialization and ensures proper setup
  bool _initialized = false;
  bool get isInitialized => _initialized;

  bool? _lastMasterEnabled;
  bool? _lastPermissionGranted;

  /// Initializes notification service and all subsystems
  ///
  /// This method sets up of complete notification infrastructure including:
  /// - Settings service with SharedPreferences persistence
  /// - Enhanced permission service with Firebase-first approach and lifecycle-aware caching
  /// - Local notification manager with platform-specific initialization
  /// - FCM provider with token handling
  /// - Stream subscriptions for real-time state updates
  ///
  /// [silentInit] When true, uses silent permission checking to avoid iOS system dialogs
  /// [Throws] Exception if initialization fails, allowing caller to handle errors appropriately
  Future<void> initialize({bool silentInit = true}) async {
    if (_initialized) {
      AppLogger.debug('NotificationService already initialized');
      return;
    }

    try {
      AppLogger.debug(
          'Initializing NotificationService with enhanced PermissionService (silent: $silentInit)...');

      // Initialize services
      _settingsService = NotificationSettingsService();
      await _settingsService.init();
      _permissionService = PermissionService();
      await _permissionService.initialize(silentMode: silentInit);
      _localManager = LocalNotificationManager(_localNotificationsPlugin);

      // CRITICAL: Initialize LocalNotificationManager to create Android channels
      await _localManager.initialize();

      // Check permissions silently without triggering system dialog
      final initialPermission =
          await _permissionService.checkPermissionsSilently();
      _lastPermissionGranted = initialPermission;

      final initialMaster = await _settingsService.isMasterEnabled();
      _lastMasterEnabled = initialMaster;

      // Initialize FcmProvider through getter to ensure proper initialization
      final fcmProvider = fcm;
      await fcmProvider.initialize();
      // Note: ensureActiveToken will skip token retrieval during startup
      // because FcmProvider now uses silentMode=true during initialization
      // Token will be retrieved when user explicitly enables notifications
      await fcmProvider.ensureActiveToken();
      await _emitCurrentState();

      // Listen to settings and permission changes
      _settingsService.masterChanges.listen((enabled) async {
        final previousMaster = _lastMasterEnabled;
        _lastMasterEnabled = enabled;

        await _emitCurrentState();

        if (enabled) {
          await fcm.ensureActiveToken();
        } else if (previousMaster == true && !enabled) {
          await _handleDisableNotifications();
        }
      });

      // Enhanced permission monitoring with detailed state changes
      _permissionService.permissionChanges.listen((hasPermission) async {
        final previousPermission = _lastPermissionGranted;
        _lastPermissionGranted = hasPermission;

        AppLogger.debug(
            'Permission status changed: $hasPermission (previous: $previousPermission)');

        if (hasPermission) {
          final masterEnabled =
              _lastMasterEnabled ?? await _settingsService.isMasterEnabled();
          if (masterEnabled) {
            await fcm.ensureActiveToken();
          }
        } else if (previousPermission == true) {
          final masterEnabled =
              _lastMasterEnabled ?? await _settingsService.isMasterEnabled();
          if (masterEnabled) {
            await _handleDisableNotifications();
          }
        }

        await _emitCurrentState();
      });

      // Listen to detailed permission state changes for enhanced debugging
      _permissionService.permissionStateChanges.listen((permissionState) async {
        AppLogger.debug('Detailed permission state: $permissionState');
        // Update permission cache invalidation if needed
        if (permissionState.platformSpecificError != null) {
          AppLogger.debug(
              'Permission error detected: ${permissionState.platformSpecificError}');
        }
      });

      // Listen to FCM provider state changes
      fcmProvider.isEnabledStream.listen((_) async {
        await _emitCurrentState();
      });
      fcmProvider.hasPermissionStream.listen((_) async {
        await _emitCurrentState();
      });

      // Pipe tap events to main stream
      _localManager.onNotificationTapped.listen(onNotificationTapped.add);
      fcmProvider.onNotificationTapped.listen(onNotificationTapped.add);

      _initialized = true;
      AppLogger.debug(
          'NotificationService initialized successfully with enhanced PermissionService');
    } catch (e) {
      AppLogger.error('Failed to initialize NotificationService',
          errorObject: e);
      rethrow;
    }
  }

  // --- Public API ---

  /// Displays a local notification if both master toggle is enabled and permissions are granted
  ///
  /// This method checks both master setting and current permission status before
  /// displaying a notification. It's primary way to show local notifications
  /// like brew timers, completion alerts, etc.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for notification
  /// - [title]: Notification title to display
  /// - [body]: Notification body/content
  /// - [payload]: Optional payload data for handling notification taps
  ///
  /// Returns: Future that completes when notification is processed
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Check master setting first - if disabled, don't show notification
    if (!await _settingsService.isMasterEnabled()) {
      AppLogger.debug('Local notification suppressed: master toggle disabled');
      return;
    }

    // Enhanced permission check with detailed state
    final permissionState =
        await _permissionService.getCurrentPermissionState();
    if (!permissionState.granted || !permissionState.canShowNotifications) {
      AppLogger.debug(
          'Local notification suppressed: permission not granted - $permissionState');
      return;
    }

    await _localManager.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Schedules a local notification for future delivery if both master toggle is enabled
  /// and permissions are granted.
  ///
  /// This method is used for scheduled notifications like brew reminders,
  /// maintenance alerts, or time-sensitive notifications.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for notification
  /// - [title]: Notification title to display
  /// - [body]: Notification body/content
  /// - [scheduledDate]: When the notification should be delivered
  /// - [payload]: Optional payload data for handling notification taps
  ///
  /// Returns: Future that completes when notification is scheduled
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Check master setting first - if disabled, don't schedule notification
    if (!await _settingsService.isMasterEnabled()) {
      AppLogger.debug(
          'Scheduled notification suppressed: master toggle disabled');
      return;
    }

    // Enhanced permission check with detailed state
    final permissionState =
        await _permissionService.getCurrentPermissionState();
    if (!permissionState.granted || !permissionState.canShowNotifications) {
      AppLogger.debug(
          'Scheduled notification suppressed: permission not granted - $permissionState');
      return;
    }

    // Exact alarm permission is required on Android 12+ for precise scheduling.
    final canScheduleExactAlarms =
        await ExactAlarmService.ensureExactAlarmPermission();
    if (!canScheduleExactAlarms) {
      AppLogger.debug(
          'Scheduled notification suppressed: exact alarm permission missing');
      return;
    }

    await _localManager.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  /// Request permissions using Firebase-first approach through enhanced PermissionService
  Future<bool> requestPermissions() async {
    AppLogger.debug(
        'Requesting permissions through enhanced PermissionService...');

    // Use enhanced PermissionService with Firebase-first approach
    final granted = await _permissionService.requestPermissions();

    // Invalidate permission cache to ensure fresh state
    _permissionService.invalidatePermissionCache();

    await _emitCurrentState();
    return granted;
  }

  /// Get detailed permission state for debugging
  Future<PermissionState> getPermissionState() async {
    return await _permissionService.getCurrentPermissionState();
  }

  /// Force refresh permission status
  Future<bool> refreshPermissionStatus() async {
    return await _permissionService.refreshStatus();
  }

  /// Get current permission status without triggering system dialog
  ///
  /// This method uses silent permission checking to avoid triggering
  /// iOS system dialog on app startup or initialization.
  Future<bool> get hasNotificationPermission async {
    if (!_permissionService.isInitialized) {
      await _permissionService.initialize();
    }
    return await _permissionService.checkPermissionsSilently();
  }

  /// Updates master notification toggle and manages FCM token lifecycle through FcmProvider
  ///
  /// This method handles the complete flow of enabling/disabling notifications:
  /// - Updates master setting in SharedPreferences
  /// - When enabling: Uses FcmProvider to handle token management
  /// - When disabling: Uses FcmProvider to handle token cleanup
  /// - Emits state changes for UI updates
  ///
  /// Parameters:
  /// - [enabled]: Whether notifications should be enabled
  /// - [userId]: User ID for FCM token management (null for anonymous users)
  ///
  /// Returns: Future that completes when toggle is processed
  Future<void> updateMasterToggle({
    required bool enabled,
    required String? userId,
  }) async {
    AppLogger.debug('Updating master toggle to: $enabled for user: $userId');

    final fcmProvider = fcm;
    if (enabled) {
      await fcmProvider.enableNotifications(userId);
    } else {
      await fcmProvider.disableNotifications(userId: userId);
    }

    // Always emit current state after changes
    await _emitCurrentState();
  }

  /// Calculates and emits current notification state based on master setting and permissions
  ///
  /// This method is the single source of truth for notification state throughout the app.
  /// It combines the user's master toggle preference with current system permission
  /// status to determine if notifications should be active.
  ///
  /// Enhanced state logic with detailed permission checking:
  /// - Master enabled + Permission granted + Can show notifications = Notifications active
  /// - Master enabled + Permission denied = Notifications inactive (show error state)
  /// - Master enabled + Permission granted but can't show = Notifications inactive (show error state)
  /// - Master disabled + Any permission state = Notifications inactive
  ///
  /// Emits: Boolean state to [notificationStateStream] for UI components
  Future<void> _emitCurrentState() async {
    final masterEnabled = await _settingsService.isMasterEnabled();

    // Enhanced permission checking with detailed state
    final permissionState =
        await _permissionService.getCurrentPermissionState();
    final permissionGranted =
        permissionState.granted && permissionState.canShowNotifications;

    // Enhanced state calculation with detailed permission information
    final newState = masterEnabled && permissionGranted;

    AppLogger.debug(
        'Emitting notification state - master: $masterEnabled, permission: ${permissionState.granted}, canShow: ${permissionState.canShowNotifications}, result: $newState');

    if (permissionState.platformSpecificError != null) {
      AppLogger.debug(
          'Permission error affecting state: ${permissionState.platformSpecificError}');
    }

    _notificationStateController.add(newState);
  }

  Future<void> _handleDisableNotifications({String? userId}) async {
    // Use FcmProvider to handle disable logic
    AppLogger.debug('Starting notification disable process for user: $userId');

    try {
      final fcmProvider = fcm;
      await fcmProvider.disableNotifications(userId: userId);
      AppLogger.debug('Successfully disabled notifications via FcmProvider');
    } catch (e) {
      AppLogger.error('Failed to disable notifications via FcmProvider',
          errorObject: e);
    }
  }

  // --- Getters for services ---
  NotificationSettingsService get settings => _settingsService;
  PermissionService get permissions => _permissionService;

  void dispose() {
    _notificationStateController.close();
    _settingsService.dispose();
    _permissionService.dispose();
    _fcmProvider?.dispose();
  }
}
