import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:coffee_timer/services/fcm_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/services/resolved_app_locale.dart';
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
  FcmProvider._internal()
    : _serviceOverride = null,
      _currentUserId = _authenticatedUserId;

  @visibleForTesting
  FcmProvider.forTesting(FcmService service, String? Function() currentUserId)
    : _serviceOverride = service,
      _currentUserId = currentUserId;

  static String? _authenticatedUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } on Error {
      // Notification setup runs before Supabase.initialize during startup.
      return null;
    }
  }

  final String? Function() _currentUserId;
  final FcmService? _serviceOverride;
  late final FcmService _fcmService = _serviceOverride ?? FcmService();
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();
  Future<void>? _initialization;

  // State controllers
  final BehaviorSubject<bool> _isEnabledController =
      BehaviorSubject<bool>.seeded(true);
  final BehaviorSubject<bool> _hasPermissionController =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<String?> _tokenController = BehaviorSubject<String?>();
  final BehaviorSubject<bool> _isInitializedController =
      BehaviorSubject<bool>.seeded(false);
  StreamSubscription<String?>? _notificationTapSubscription;

  StreamSubscription<String>? _refreshSubscription;
  Future<void> _registrations = Future.value();
  String? _detachingOwner;
  String? _tokenOwner;
  Future<void>? _invalidation;
  static const _pendingInvalidation = 'fcm_pending_device_invalidation';

  // Serialize registration with opt-out and sign-out. A slow registration
  // must finish before the corresponding revocation is acknowledged.
  Future<void> _serialize(Future<void> Function() operation) {
    final next = _registrations.then((_) => operation());
    _registrations = next.catchError((Object _) {});
    return next;
  }

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
  String? get currentToken => _tokenOwner != null && _tokenOwner == _currentUserId()
      ? _tokenController.valueOrNull
      : null;
  bool get isInitialized => _isInitializedController.value;

  /// Initialize FCM provider and all dependencies
  Future<void> initialize() {
    if (isInitialized) return Future.value();
    return _initialization ??= _initializeInternal().whenComplete(
      () => _initialization = null,
    );
  }

  Future<void> _initializeInternal() async {
    await _fcmService.initialize();
    _notificationTapSubscription ??= _fcmService.onNotificationTapped.listen(
      onNotificationTapped.add,
    );
    await _settingsService.init();
    // Notification setup runs before main.dart resolves the app locale, and
    // the user can change language later; either way the token row follows.
    ResolvedAppLocale.languageCode.addListener(_onAppLocaleChanged);

    // Get initial state
    final masterEnabled = await _settingsService.isMasterEnabled();
    // Check actual permission status on initialization without triggering dialog
    final hasPermission = kIsWeb
        ? true
        : await _fcmService.checkPermissionStatus();

    // Update internal state
    _isEnabledController.add(masterEnabled);
    _hasPermissionController.add(hasPermission);
    _isInitializedController.add(true);

    if (!kIsWeb) {
      _refreshSubscription ??= _fcmService.tokenRefreshes.listen((_) {
        unawaited(ensureActiveToken());
      });
      await _retryInvalidation();
      if (masterEnabled && hasPermission) await ensureActiveToken();
    }

    AppLogger.debug(
      'Initial state - enabled: $masterEnabled, permission: $hasPermission',
    );
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
    await ensureActiveToken();
  }

  /// Disable notifications for a specific user
  Future<void> disableNotifications({String? userId}) async {
    if (!_isInitializedController.value) {
      throw StateError('FcmProvider not initialized');
    }

    _isEnabledController.add(false);
    await _settingsService.setMasterEnabled(false);
    if (kIsWeb) return;
    final owner = _currentUserId();
    await _serialize(() async {
      final token = _tokenOwner == owner
          ? currentToken ?? await getToken()
          : await getToken();
      _tokenOwner = null;
      _tokenController.add(null);
      if (token != null && owner != null && _currentUserId() == owner) {
        try {
          await _fcmService
              .markTokenInactive(userId: owner, token: token)
              .timeout(const Duration(seconds: 5));
          return;
        } catch (_) {
          // Invalidate the delivery address if remote deactivation fails.
        }
      }
      await _invalidateInstallation();
    });
  }

  /// Toggle notification state
  Future<void> toggleNotifications(String? userId) async {
    if (!_isInitializedController.value) {
      throw StateError('FcmProvider not initialized');
    }

    final currentState = _isEnabledController.value;
    AppLogger.debug(
      'Toggling notifications from $currentState to ${!currentState} for user: $userId',
    );

    if (currentState) {
      await disableNotifications(userId: userId);
    } else {
      await enableNotifications(userId);
    }
  }

  Future<void> ensureActiveToken() async {
    if (kIsWeb || !isInitialized) return;
    final owner = _currentUserId();
    if (owner == null || owner == _detachingOwner) return;
    try {
      await _serialize(() async {
        if (!await _retryInvalidation() ||
            !await _settingsService.isMasterEnabled() ||
            !await _fcmService.checkPermissionStatus()) {
          return;
        }
        bool stillEligible() =>
            isEnabled && _detachingOwner != owner && _currentUserId() == owner;
        if (!stillEligible()) return;
        var token = await getToken();
        if (token == null || !stillEligible()) return;

        final oldToken = _tokenOwner == owner ? currentToken : null;
        if (oldToken == token) return;
        try {
          await _fcmService.storeToken(userId: owner, token: token);
        } on PostgrestException catch (error) {
          if (!stillEligible() ||
              (error.code != '42501' && error.code != '23505')) {
            rethrow;
          }
          // A globally unique Firebase token can remain bound to a prior
          // owner. Generate a fresh SDK token without taking over that row.
          await _invalidateInstallation();
          if (!stillEligible() || !await _retryInvalidation()) return;
          final replacement = await getToken();
          if (replacement == null || replacement == token || !stillEligible()) {
            return;
          }
          token = replacement;
          await _fcmService.storeToken(userId: owner, token: token);
        }

        if (oldToken != null &&
            oldToken != token &&
            _currentUserId() == owner) {
          try {
            await _fcmService
                .markTokenInactive(userId: owner, token: oldToken)
                .timeout(const Duration(seconds: 5));
          } catch (_) {
            // A rotated SDK token is independently invalidated by Firebase.
          }
        }
        if (_currentUserId() != owner) return;
        // Leave an in-flight registration visible to the queued detach.
        _tokenOwner = owner;
        _tokenController.add(token);
      });
    } catch (e) {
      AppLogger.error('Unable to register this installation', errorObject: e);
    }
  }

  void _onAppLocaleChanged() {
    if (kIsWeb) return;
    final languageCode = ResolvedAppLocale.languageCode.value;
    final token = _tokenController.valueOrNull;
    final owner = _currentUserId();
    if (languageCode == null ||
        token == null ||
        owner == null ||
        owner != _tokenOwner ||
        owner == _detachingOwner ||
        !isEnabled) {
      return;
    }
    unawaited(
      _serialize(() async {
        if (_currentUserId() == owner &&
            currentToken == token &&
            _detachingOwner != owner &&
            isEnabled) {
          await _fcmService
              .syncTokenContext(token: token, userId: owner)
              .timeout(const Duration(seconds: 5));
        }
      }).catchError((Object _) {}),
    );
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

  Future<void> _invalidateInstallation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingInvalidation, true);
    await _retryInvalidation();
  }

  Future<bool> _retryInvalidation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pendingInvalidation) != true) return true;
    try {
      final request = _invalidation ??= _fcmService.deleteToken().whenComplete(
        () {
          _invalidation = null;
        },
      );
      await request.timeout(const Duration(seconds: 5));
      await prefs.remove(_pendingInvalidation);
      return true;
    } catch (e) {
      AppLogger.warning('Installation token invalidation pending');
      return false;
    }
  }

  Future<void> signOutAfterDetaching(Future<void> Function() signOut) async {
    final userId = _currentUserId();
    if (kIsWeb || userId == null) return signOut();
    _detachingOwner = userId;
    try {
      await _serialize(() async {
        final token = _tokenOwner == userId
            ? currentToken ?? await getToken()
            : await getToken();
        _tokenOwner = null;
        _tokenController.add(null);
        if (token != null && _currentUserId() == userId) {
          try {
            await _fcmService
                .deleteTokenForUser(userId: userId, token: token)
                .timeout(const Duration(seconds: 5));
            return;
          } catch (_) {
            // Deletion could not be confirmed while this owner was signed in.
          }
        }
        await _invalidateInstallation();
      });
      if (_currentUserId() == userId) await signOut();
    } finally {
      _detachingOwner = null;
    }
  }

  /// Dispose all streams and resources
  void dispose() {
    ResolvedAppLocale.languageCode.removeListener(_onAppLocaleChanged);
    _notificationTapSubscription?.cancel();
    _refreshSubscription?.cancel();
    _isEnabledController.close();
    _hasPermissionController.close();
    _tokenController.close();
    _isInitializedController.close();
    onNotificationTapped.close();
  }
}
