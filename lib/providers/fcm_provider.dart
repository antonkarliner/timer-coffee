import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:coffee_timer/services/fcm_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized provider for FCM token management and notification state
///
/// This provider consolidates all FCM-related functionality including:
/// - Token state management (active/inactive)
/// - Permission status tracking
/// - Settings coordination
/// - Business logic for enable/disable cycles
class FcmProvider {
  static final FcmProvider _instance = FcmProvider._internal();
  factory FcmProvider() => _instance;
  FcmProvider._internal();

  late final FcmService _fcmService;
  late final NotificationSettingsService _settingsService;

  // State controllers
  final BehaviorSubject<bool> _isEnabledController =
      BehaviorSubject<bool>.seeded(true);
  final BehaviorSubject<bool> _hasPermissionController =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<String?> _tokenController = BehaviorSubject<String?>();
  final BehaviorSubject<bool> _isInitializedController =
      BehaviorSubject<bool>.seeded(false);
  StreamSubscription<String?>? _notificationTapSubscription;

  // Public streams
  Stream<bool> get isEnabledStream => _isEnabledController.stream.distinct();
  Stream<bool> get hasPermissionStream =>
      _hasPermissionController.stream.distinct();
  Stream<String?> get tokenStream => _tokenController.stream.distinct();
  Stream<bool> get isInitializedStream =>
      _isInitializedController.stream.distinct();

  // Current values
  bool get isEnabled => _isEnabledController.value;
  bool get hasPermission => _hasPermissionController.value;
  String? get currentToken => _tokenController.value;
  bool get isInitialized => _isInitializedController.value;

  /// Initialize FCM provider and all dependencies
  Future<void> initialize() async {
    if (_isInitializedController.value) {
      AppLogger.debug('FcmProvider already initialized');
      return;
    }

    try {
      AppLogger.debug('Initializing FcmProvider...');

      // Apply 10-second timeout to entire initialization process
      await _initializeInternal().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.warning('FcmProvider initialization timed out');
          // Set partial initialization state to allow basic functionality
          _isInitializedController.add(false);
        },
      );

      AppLogger.debug('FcmProvider initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize FcmProvider', errorObject: e);
      _isInitializedController.add(false);
      rethrow;
    }
  }

  /// Internal initialization method with timeout handling
  Future<void> _initializeInternal() async {
    // Initialize services
    _fcmService = FcmService();
    await _fcmService.initialize();
    _notificationTapSubscription =
        _fcmService.onNotificationTapped.listen(onNotificationTapped.add);
    _settingsService = NotificationSettingsService();
    await _settingsService.init();

    // Get initial state
    final masterEnabled = await _settingsService.isMasterEnabled();
    // Check actual permission status on initialization without triggering dialog
    final hasPermission =
        kIsWeb ? true : await _fcmService.checkPermissionStatus();

    // Update internal state
    _isEnabledController.add(masterEnabled);
    _hasPermissionController.add(hasPermission);
    _isInitializedController.add(true);

    // Auto-restore token on startup if notifications are enabled
    // This ensures token persistence across app restarts
    if (masterEnabled && hasPermission) {
      AppLogger.debug(
          'Notifications enabled on startup, checking for existing token only');
      await _setupInitialToken(silentMode: true);
    } else {
      AppLogger.debug(
          'Notifications not enabled on startup, skipping token setup');
    }

    AppLogger.debug(
        'Initial state - enabled: $masterEnabled, permission: $hasPermission');
  }

  /// Enable notifications for a specific user
  Future<void> enableNotifications(String? userId) async {
    if (!_isInitializedController.value) {
      throw StateError('FcmProvider not initialized');
    }

    try {
      AppLogger.debug('Enabling notifications for user: $userId');

      // Apply 5-second timeout to enable notifications process
      await _enableNotificationsInternal(userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('Enable notifications timed out');
          // Set partial state to allow retry
          _hasPermissionController.add(false);
        },
      );

      AppLogger.info('Notifications enabled for user: $userId');
    } catch (e) {
      AppLogger.error('Error enabling notifications', errorObject: e);
      rethrow;
    }
  }

  /// Internal method for enabling notifications with timeout handling
  Future<void> _enableNotificationsInternal(String? userId) async {
    // Request permissions if needed
    if (!kIsWeb && !_hasPermissionController.value) {
      final granted = await _fcmService.requestPermissions();
      if (!granted) {
        AppLogger.debug('Permission denied during enable');
        _hasPermissionController.add(false);
        return;
      }
      _hasPermissionController.add(true);
    }

    // Update settings
    await _settingsService.setMasterEnabled(true);
    _isEnabledController.add(true);

    // Setup FCM token with restoration logic
    await _setupInitialToken();
  }

  /// Disable notifications for a specific user
  Future<void> disableNotifications({String? userId}) async {
    if (!_isInitializedController.value) {
      throw StateError('FcmProvider not initialized');
    }

    try {
      final settingsMasterEnabled = await _settingsService.isMasterEnabled();
      final alreadyDisabled =
          !_isEnabledController.value && !settingsMasterEnabled;
      if (alreadyDisabled) {
        AppLogger.debug('disableNotifications skipped - already disabled');
        return;
      }

      AppLogger.debug('Disabling notifications for user: $userId');

      final cachedToken = _tokenController.valueOrNull;
      if (cachedToken != null) {
        await _markCurrentTokenInactive();
      } else {
        AppLogger.debug('Skip marking inactive - no cached token');
      }

      if (settingsMasterEnabled) {
        await _settingsService.setMasterEnabled(false);
      }

      _isEnabledController.add(false);

      // Clear local token controller but preserve token in Firebase
      // DO NOT delete token from Firebase to allow reuse
      _tokenController.add(null);

      AppLogger.info(
          'Notifications disabled for user: $userId - token preserved in Firebase');
    } catch (e) {
      AppLogger.error('Error disabling notifications', errorObject: e);
      rethrow;
    }
  }

  /// Toggle notification state
  Future<void> toggleNotifications(String? userId) async {
    if (!_isInitializedController.value) {
      throw StateError('FcmProvider not initialized');
    }

    final currentState = _isEnabledController.value;
    AppLogger.debug(
        'Toggling notifications from $currentState to ${!currentState} for user: $userId');

    if (currentState) {
      await disableNotifications(userId: userId);
    } else {
      await enableNotifications(userId);
    }
  }

  /// Setup initial FCM token if notifications are enabled and user is authenticated
  Future<void> _setupInitialToken({bool silentMode = false}) async {
    try {
      // Apply 5-second timeout to token setup process
      await _setupInitialTokenInternal().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('Initial token setup timed out');
          _tokenController.add(null);
        },
      );
    } catch (e) {
      AppLogger.error('Error setting up initial token', errorObject: e);
      _tokenController.add(null);
    }
  }

  /// Internal method for setting up initial token with timeout handling
  Future<void> _setupInitialTokenInternal({bool silentMode = false}) async {
    // Get current user to ensure we have proper ID
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      AppLogger.debug('User not authenticated, skipping FCM token setup');
      _tokenController.add(null);
      return;
    }

    final userId = user.id;

    // First, check if there's an existing active or recently inactive token in the database
    final existingToken = await _getExistingTokenForUser(userId: userId);

    if (existingToken != null) {
      AppLogger.debug(
          'Found existing token in database, reusing: ${existingToken.substring(0, 20)}...');
      // Token exists in database, reuse it
      _tokenController.add(existingToken);

      // Ensure the token is marked as active in the database
      await _reactivateToken(userId: userId, token: existingToken);
    } else {
      // No existing token found, get new one from Firebase
      // Only get new token if not in silent mode (to avoid iOS permission dialog on startup)
      if (!silentMode) {
        AppLogger.debug(
            'No existing token found, requesting new token from Firebase');
        final token = await _fcmService.getToken();

        if (token != null) {
          AppLogger.debug(
              'Got new FCM token from Firebase: ${token.substring(0, 20)}...');

          // Store the new token
          await _storeToken(userId: userId, token: token);
          _tokenController.add(token);
          AppLogger.debug('New FCM token stored for user: $userId');
        } else {
          AppLogger.warning('No FCM token available from Firebase');
          _tokenController.add(null);
        }
      }
    }
  }

  Future<void> ensureActiveToken() async {
    if (!_isInitializedController.value) {
      AppLogger.debug('ensureActiveToken skipped - provider not initialized');
      return;
    }
    if (!_isEnabledController.value) {
      AppLogger.debug('ensureActiveToken skipped - notifications disabled');
      return;
    }
    if (!_hasPermissionController.value) {
      AppLogger.debug('ensureActiveToken skipped - permission not granted');
      return;
    }
    if (_tokenController.valueOrNull != null) {
      AppLogger.debug('ensureActiveToken skipped - token already present');
      return;
    }

    AppLogger.debug('ensureActiveToken executing token restoration');

    // Apply 3-second timeout to token restoration
    await _setupInitialToken().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        AppLogger.warning('Ensure active token timed out');
      },
    );
  }

  /// Store FCM token with reuse logic
  Future<void> _storeToken(
      {required String userId, required String token}) async {
    try {
      AppLogger.debug('Storing FCM token for user: $userId');
      await _fcmService.storeToken(userId: userId, token: token);
      _tokenController.add(token);
      AppLogger.info('FCM token stored successfully');
    } catch (e) {
      AppLogger.error('Error storing FCM token', errorObject: e);
      rethrow;
    }
  }

  /// Get existing token for user from database
  /// Checks for active tokens first, then recently inactive tokens
  Future<String?> _getExistingTokenForUser({required String userId}) async {
    try {
      // Apply 3-second timeout to database queries
      return await _getExistingTokenForUserInternal(userId).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.warning('Get existing token for user timed out');
          return null;
        },
      );
    } catch (e) {
      AppLogger.error('Error getting existing token for user', errorObject: e);
      return null;
    }
  }

  /// Internal method for getting existing token with timeout handling
  Future<String?> _getExistingTokenForUserInternal(String userId) async {
    final supabase = Supabase.instance.client;
    final platform = Platform.isIOS ? 'ios' : 'android';

    AppLogger.debug(
        'Looking for existing token for user: $userId, platform: $platform');

    // First check for active tokens
    final activeToken = await supabase
        .schema('service')
        .from('user_fcm_tokens')
        .select('token')
        .eq('user_id', userId)
        .eq('device_type', platform)
        .eq('is_active', true)
        .maybeSingle();

    if (activeToken != null) {
      final token = activeToken['token'] as String?;
      if (token != null && token.isNotEmpty) {
        AppLogger.debug(
            'Found active token in database: ${token.substring(0, 20)}...');
        return token;
      }
    }

    // If no active token, check for recently inactive tokens (within 24 hours)
    final cutoffTime =
        DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
    AppLogger.debug(
        'Checking for recently inactive tokens (after: $cutoffTime)');

    final recentInactiveToken = await supabase
        .schema('service')
        .from('user_fcm_tokens')
        .select('token')
        .eq('user_id', userId)
        .eq('device_type', platform)
        .eq('is_active', false)
        .gte('updated_at', cutoffTime)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (recentInactiveToken != null) {
      final token = recentInactiveToken['token'] as String?;
      if (token != null && token.isNotEmpty) {
        AppLogger.debug(
            'Found recently inactive token in database: ${token.substring(0, 20)}...');
        return token;
      }
    }

    AppLogger.debug('No existing token found for user: $userId');
    return null;
  }

  /// Reactivate a token that was previously marked as inactive
  Future<void> _reactivateToken(
      {required String userId, required String token}) async {
    try {
      // Apply 3-second timeout to token reactivation
      await _reactivateTokenInternal(userId: userId, token: token).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.warning('Token reactivation timed out');
        },
      );

      AppLogger.debug('Reactivated token for user: $userId');
    } catch (e) {
      AppLogger.error('Error reactivating token', errorObject: e);
    }
  }

  /// Internal method for reactivating token with timeout handling
  Future<void> _reactivateTokenInternal(
      {required String userId, required String token}) async {
    final supabase = Supabase.instance.client;
    final platform = Platform.isIOS ? 'ios' : 'android';
    final now = DateTime.now().toIso8601String();

    // Mark the token as active and update timestamps
    await supabase
        .schema('service')
        .from('user_fcm_tokens')
        .update({
          'is_active': true,
          'updated_at': now,
          'last_used_at': now,
        })
        .eq('user_id', userId)
        .eq('device_type', platform)
        .eq('token', token);
  }

  /// Mark current token as inactive
  Future<void> _markCurrentTokenInactive() async {
    try {
      // Apply 3-second timeout to token deactivation
      await _markCurrentTokenInactiveInternal().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.warning('Mark current token inactive timed out');
        },
      );
    } catch (e) {
      AppLogger.error('Error marking token inactive', errorObject: e);
    }
  }

  /// Internal method for marking token inactive with timeout handling
  Future<void> _markCurrentTokenInactiveInternal() async {
    // Check if stream has value before accessing it
    if (!_tokenController.hasValue) {
      AppLogger.debug('No token available to mark inactive');
      return;
    }

    final currentToken = _tokenController.value;
    if (currentToken != null) {
      await _fcmService.markTokenInactive(token: currentToken);
      AppLogger.debug(
          'Marked current token as inactive: ${currentToken.substring(0, 20)}...');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      final granted = await _fcmService.requestPermissions();
      _hasPermissionController.add(granted);
      return granted;
    } catch (e) {
      AppLogger.error('Error requesting permissions', errorObject: e);
      return false;
    }
  }

  /// Get current permission status
  bool checkPermissionStatus() {
    return _hasPermissionController.value;
  }

  /// Stream for handling notification tap events from FCM
  /// Used by UI components to navigate when user taps a notification
  final BehaviorSubject<String?> onNotificationTapped = BehaviorSubject();

  /// Handle background FCM messages (delegated from service)
  Future<void> checkForInitialMessage() async {
    // This method can be implemented if needed for background message handling
    AppLogger.debug('checkForInitialMessage called - delegating to FcmService');
  }

  /// Handle token refresh callbacks (delegated from service)
  void onTokenRefresh(void Function(String) callback) {
    // This method can be implemented if needed for token refresh handling
    AppLogger.debug('onTokenRefresh called - delegating to FcmService');
  }

  /// Get FCM token (delegated from service)
  Future<String?> getToken() async {
    try {
      // Apply 3-second timeout to Firebase token retrieval
      return await _fcmService.getToken().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.warning('Get FCM token timed out');
          return null;
        },
      );
    } catch (e) {
      AppLogger.error('Error getting FCM token', errorObject: e);
      return null;
    }
  }

  /// Store FCM token (delegated from service)
  Future<void> storeFcmToken(String userId, String token) async {
    try {
      // Apply 5-second timeout to token storage operations
      await _storeToken(userId: userId, token: token).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('Store FCM token timed out');
        },
      );
    } catch (e) {
      AppLogger.error('Error storing FCM token', errorObject: e);
      rethrow;
    }
  }

  /// Dispose all streams and resources
  void dispose() {
    _notificationTapSubscription?.cancel();
    _isEnabledController.close();
    _hasPermissionController.close();
    _tokenController.close();
    _isInitializedController.close();
    onNotificationTapped.close();
  }
}
