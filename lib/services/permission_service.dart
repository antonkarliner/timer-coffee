import 'dart:async';
import 'dart:io';

import 'package:coffee_timer/utils/app_logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

/// Enhanced permission state with platform-specific details
class PermissionState {
  final bool granted;
  final bool canShowNotifications;
  final String? platformSpecificError;
  final bool isWeb;
  final AuthorizationStatus? firebaseStatus;
  final DateTime? lastChecked;

  PermissionState({
    required this.granted,
    required this.canShowNotifications,
    this.platformSpecificError,
    required this.isWeb,
    this.firebaseStatus,
    this.lastChecked,
  });

  @override
  String toString() {
    return 'PermissionState(granted: $granted, canShowNotifications: $canShowNotifications, '
        'platformSpecificError: $platformSpecificError, isWeb: $isWeb, '
        'firebaseStatus: $firebaseStatus, lastChecked: $lastChecked)';
  }
}

/// Firebase-first permission management service
///
/// This service prioritizes Firebase permissions for cross-platform consistency
/// and fixes the critical iOS platform bug where Android implementation was used.
/// It provides robust permission caching, real-time monitoring, and comprehensive error handling.
class PermissionService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<bool> _permissionSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<PermissionState> _permissionStateSubject =
      BehaviorSubject<PermissionState>.seeded(PermissionState(
          granted: false, canShowNotifications: false, isWeb: kIsWeb));

  Stream<bool> get permissionChanges => _permissionSubject.stream.distinct();
  Stream<PermissionState> get permissionStateChanges =>
      _permissionStateSubject.stream.distinct();

  bool _initialized = false;
  bool _hasNotificationPermission = false;
  AppLifecycleListener? _lifecycleListener;
  PermissionState? _lastPermissionState;
  DateTime? _lastPermissionCheck;

  /// Tracks whether service is in silent initialization mode to prevent system dialogs
  bool _silentInitializationMode = false;

  /// Public getter to access initialization status
  bool get isInitialized => _initialized;

  /// Public getter to access silent initialization mode
  bool get isSilentInitializationMode => _silentInitializationMode;

  /// Get current notification permission status
  Future<bool> get hasNotificationPermission async {
    if (!_initialized) {
      await initialize();
    }
    return _hasNotificationPermission;
  }

  /// Get detailed permission state for debugging
  Future<PermissionState> getCurrentPermissionState() async {
    if (!_initialized) {
      await initialize();
    }

    final state = await _computeCurrentPermissionState();
    _lastPermissionState = state;
    _lastPermissionCheck = DateTime.now();

    // Emit state change if different
    if (_permissionStateSubject.value != state) {
      _permissionStateSubject.add(state);
    }

    return state;
  }

  /// Refresh permission status and update streams
  Future<bool> refreshStatus() async {
    if (kIsWeb) {
      _hasNotificationPermission = true;
      _permissionSubject.add(true);
      _permissionStateSubject.add(
        PermissionState(
          granted: true,
          canShowNotifications: true,
          isWeb: true,
          lastChecked: DateTime.now(),
        ),
      );
      AppLogger.debug('Web platform: notifications enabled');
      return true;
    }

    // Use silent permission checking during initialization to avoid system dialogs
    bool current;
    if (_silentInitializationMode) {
      AppLogger.debug('Using silent permission check during initialization');
      current = await checkPermissionsSilently();
    } else {
      current = await _computeCurrentPermission();
    }

    if (current != _hasNotificationPermission) {
      _hasNotificationPermission = current;
      _permissionSubject.add(current);
      AppLogger.debug('Permission status changed: $current');
    }

    // Also update detailed state
    await getCurrentPermissionState();

    return _hasNotificationPermission;
  }

  /// Request permissions using Firebase-first approach
  ///
  /// This method prioritizes Firebase permissions for cross-platform consistency
  /// and falls back to local notifications when needed.
  ///
  /// SAFETY CHECK: This method will throw an exception if called during silent initialization
  /// to prevent accidental system dialog triggers during app startup.
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      _hasNotificationPermission = true;
      _permissionSubject.add(true);
      return true;
    }

    // CRITICAL SAFETY CHECK: Prevent permission requests during silent initialization
    if (_silentInitializationMode) {
      AppLogger.error(
          'SECURITY: Attempted to request permissions during silent initialization');
      throw Exception(
          'Permission requests are not allowed during silent initialization mode');
    }

    AppLogger.debug('Requesting permissions with Firebase-first approach...');

    try {
      bool permissionGranted = false;

      // Primary approach: Use Firebase permissions for all platforms
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        permissionGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        AppLogger.debug(
            'Firebase permission result: ${settings.authorizationStatus} (granted: $permissionGranted)');

        if (permissionGranted) {
          AppLogger.debug('Firebase permissions GRANTED by user');
        } else {
          AppLogger.debug('Firebase permissions DENIED by user');
        }

        // Store Firebase status for debugging
        final state = PermissionState(
          granted: permissionGranted,
          canShowNotifications: permissionGranted,
          isWeb: false,
          firebaseStatus: settings.authorizationStatus,
          lastChecked: DateTime.now(),
        );
        _permissionStateSubject.add(state);
      } catch (e) {
        AppLogger.error(
            'Firebase permission request failed, falling back to local notifications',
            errorObject: e);

        // Fallback: Use platform-specific local notification permissions
        if (Platform.isAndroid) {
          final androidImplementation =
              _plugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          permissionGranted =
              await androidImplementation?.requestNotificationsPermission() ??
                  false;
        } else if (Platform.isIOS) {
          // FIXED: Use iOS implementation instead of Android
          final iosImplementation =
              _plugin.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();
          final bool? iosPermissionResult =
              await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          permissionGranted = iosPermissionResult ?? false;
        } else {
          permissionGranted = true;
        }

        AppLogger.debug(
            'Local notification permission result: $permissionGranted');
      }

      // Update cached state and emit changes
      _hasNotificationPermission = permissionGranted;
      _permissionSubject.add(permissionGranted);

      // Invalidate any cached permission state to force refresh
      _lastPermissionState = null;
      await getCurrentPermissionState();

      AppLogger.debug(
          'Permission request completed successfully: $_hasNotificationPermission');
      AppLogger.debug('=== PERMISSION REQUEST COMPLETE ===');
      return permissionGranted;
    } catch (e) {
      AppLogger.error('Error requesting permissions', errorObject: e);
      _hasNotificationPermission = false;
      _permissionSubject.add(false);

      // Update state with error information
      final errorState = PermissionState(
        granted: false,
        canShowNotifications: false,
        isWeb: false,
        platformSpecificError: e.toString(),
        lastChecked: DateTime.now(),
      );
      _permissionStateSubject.add(errorState);

      AppLogger.debug('=== PERMISSION REQUEST FAILED ===');
      return false;
    }
  }

  /// Compute current permission status using Firebase-first approach
  Future<bool> _computeCurrentPermission() async {
    try {
      final state = await _computeCurrentPermissionState();
      return state.granted && state.canShowNotifications;
    } catch (e) {
      AppLogger.error('Error computing permission status', errorObject: e);
      return false;
    }
  }

  /// Compute detailed permission state for debugging and monitoring
  Future<PermissionState> _computeCurrentPermissionState() async {
    try {
      if (kIsWeb) {
        return PermissionState(
          granted: true,
          canShowNotifications: true,
          isWeb: true,
          lastChecked: DateTime.now(),
        );
      }

      bool firebasePermissionGranted = false;
      AuthorizationStatus? firebaseStatus;
      String? platformError;

      // Primary check: Use Firebase permissions for consistency
      try {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        firebaseStatus = settings.authorizationStatus;
        firebasePermissionGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        AppLogger.debug(
            'Firebase permission check: ${settings.authorizationStatus}');
      } catch (e) {
        AppLogger.error(
            'Firebase permission check failed, using local notifications',
            errorObject: e);
        platformError = 'Firebase permission check failed: ${e.toString()}';
      }

      // Secondary check: Use local notifications as fallback or verification
      bool localPermissionGranted = false;
      try {
        if (Platform.isAndroid) {
          final androidImplementation =
              _plugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          localPermissionGranted =
              await androidImplementation?.areNotificationsEnabled() ?? false;
        } else if (Platform.isIOS) {
          // FIXED: Use iOS implementation instead of Android
          final iosImplementation =
              _plugin.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();
          final NotificationsEnabledOptions? iosPermissionResult =
              await iosImplementation?.checkPermissions();
          localPermissionGranted = (iosPermissionResult?.isEnabled) ?? false;
        } else {
          localPermissionGranted = true;
        }
        AppLogger.debug('Local permission check: $localPermissionGranted');
      } catch (e) {
        AppLogger.error('Local permission check failed', errorObject: e);
        if (platformError == null) {
          platformError = 'Local permission check failed: ${e.toString()}';
        }
      }

      // For Firebase-first approach, prioritize Firebase permissions
      // but require both for full functionality on some platforms
      bool finalGranted = false;
      bool canShowNotifications = false;

      if (firebasePermissionGranted) {
        // Firebase permissions granted - this is primary
        finalGranted = true;
        canShowNotifications = true;
      } else if (localPermissionGranted && platformError != null) {
        // Firebase failed but local works - use as fallback
        finalGranted = true;
        canShowNotifications = true;
        platformError = '$platformError (Using local permissions as fallback)';
      } else {
        // Neither permission system works
        finalGranted = false;
        canShowNotifications = false;
      }

      return PermissionState(
        granted: finalGranted,
        canShowNotifications: canShowNotifications,
        isWeb: false,
        firebaseStatus: firebaseStatus,
        platformSpecificError: platformError,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Error computing permission state', errorObject: e);
      return PermissionState(
        granted: false,
        canShowNotifications: false,
        isWeb: kIsWeb,
        platformSpecificError: 'Permission computation failed: ${e.toString()}',
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Force invalidate permission cache to trigger refresh
  void invalidatePermissionCache() {
    AppLogger.debug('Invalidating permission cache');
    _lastPermissionState = null;
    _lastPermissionCheck = null;
  }

  /// Get last permission check timestamp
  DateTime? get lastPermissionCheck => _lastPermissionCheck;

  /// Get last detailed permission state
  PermissionState? get lastPermissionState => _lastPermissionState;

  /// Checks notification permissions silently without triggering system dialog
  ///
  /// This method checks current permission status without requesting permissions,
  /// avoiding the iOS system dialog that appears on first launch.
  /// Enhanced with additional safety checks to guarantee silent behavior.
  ///
  /// Returns true if permissions are granted, false otherwise
  Future<bool> checkPermissionsSilently() async {
    if (kIsWeb) {
      AppLogger.debug('Silent check: Web platform - returning true');
      return true;
    }

    try {
      AppLogger.debug('=== Starting silent permission check ===');
      AppLogger.debug('Silent mode: $_silentInitializationMode');

      // CRITICAL: Only use getNotificationSettings() - NEVER requestPermission()
      // This guarantees no system dialog will be triggered
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final isGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      AppLogger.debug(
          'Firebase silent check: authorizationStatus=${settings.authorizationStatus}, granted=$isGranted');

      // Also check local permissions without requesting
      bool localGranted = false;
      try {
        if (Platform.isAndroid) {
          final androidImplementation =
              _plugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          // areNotificationsEnabled() is safe and doesn't trigger dialogs
          localGranted =
              await androidImplementation?.areNotificationsEnabled() ?? false;
          AppLogger.debug('Android local check: $localGranted');
        } else if (Platform.isIOS) {
          final iosImplementation =
              _plugin.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();
          // checkPermissions() is safe and doesn't trigger dialogs
          final NotificationsEnabledOptions? permissions =
              await iosImplementation?.checkPermissions();
          localGranted = permissions?.isEnabled ?? false;
          AppLogger.debug('iOS local check: $localGranted');
        } else {
          localGranted = true;
          AppLogger.debug('Other platform - defaulting to $localGranted');
        }
      } catch (e) {
        AppLogger.error('Local silent permission check failed', errorObject: e);
        // Continue with Firebase result even if local check fails
      }

      final finalResult = isGranted || localGranted;
      AppLogger.debug('=== Silent permission check complete: $finalResult ===');

      // Return combined status without triggering system dialog
      return finalResult;
    } catch (e) {
      AppLogger.error('Error checking permissions silently', errorObject: e);
      AppLogger.debug(
          '=== Silent permission check failed, returning false ===');
      return false;
    }
  }

  /// Initialize permission service with silent mode support
  ///
  /// When [silentMode] is true, the service will use enhanced silent permission
  /// checking to avoid triggering iOS system dialogs during app startup.
  Future<void> initialize({bool silentMode = false}) async {
    if (_initialized) return;

    // Set silent initialization mode before any permission checks
    _silentInitializationMode = silentMode;

    AppLogger.debug(
        'Initializing PermissionService with Firebase-first approach (silent: $silentMode)...');

    // Web platform: notifications are supported via web push APIs
    if (kIsWeb) {
      _hasNotificationPermission = true;
      _permissionSubject.add(true);
      _permissionStateSubject.add(
        PermissionState(
          granted: true,
          canShowNotifications: true,
          isWeb: true,
          lastChecked: DateTime.now(),
        ),
      );
      _initialized = true;

      // CRITICAL: Reset silent mode after initialization completes
      _silentInitializationMode = false;

      AppLogger.debug(
          'PermissionService initialized for web platform - notifications enabled');
      return;
    }

    _initialized = true;

    // Set up lifecycle listener for permission refresh
    _lifecycleListener = AppLifecycleListener(
      onShow: () {
        AppLogger.debug('App resumed - refreshing permission status');
        refreshStatus();
      },
    );

    await refreshStatus();

    // CRITICAL: Reset silent mode after initialization completes
    // This allows legitimate permission requests from UI after startup
    _silentInitializationMode = false;

    AppLogger.debug(
        'PermissionService initialized successfully (silent: $silentMode)');
  }

  void dispose() {
    _lifecycleListener?.dispose();
    _permissionSubject.close();
    _permissionStateSubject.close();
  }
}
