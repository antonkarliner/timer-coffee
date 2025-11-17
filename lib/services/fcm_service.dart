import 'dart:io';
import 'package:coffee_timer/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rxdart/rxdart.dart';

/// Top-level background message handler for Firebase Cloud Messaging
///
/// This function must be top-level (not a class method) because Firebase Messaging
/// calls it from a separate isolate where the class instance may not be available.
/// This is a requirement for background message handling in Firebase Messaging.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug('Handling background FCM message: ${message.messageId}');
  AppLogger.debug('Message data: ${message.data}');

  // Handle background message - show notification or process data as needed
  // This is called when app is in background or terminated
  try {
    // Initialize Firebase if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Process the message
    if (message.notification != null) {
      AppLogger.debug('Background message contains notification');
      // Background notifications are handled automatically by Firebase
    }

    if (message.data.isNotEmpty) {
      AppLogger.debug('Processing background message data');
      // Handle any data payload
    }
  } catch (e) {
    AppLogger.error('Error in background message handler', errorObject: e);
  }
}

/// Enhanced Firebase Cloud Messaging service with consolidated functionality
///
/// This service now handles all FCM operations including:
/// - Token retrieval and deletion
/// - Permission requests
/// - Token storage with reuse logic
/// - Background message handling (single handler)
/// - Foreground message handling with local notifications
/// - Notification tap handling
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _cachedToken;
  bool _isInitialized = false;

  String? get cachedToken => _cachedToken;
  bool get isInitialized => _isInitialized;

  /// Stream for handling notification tap events
  final BehaviorSubject<String?> onNotificationTapped = BehaviorSubject();

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('FcmService already initialized');
      return;
    }

    try {
      // Register background message handler FIRST (critical for Android 13+)
      // Using the top-level function _firebaseMessagingBackgroundHandler
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
        AppLogger.debug('Background message handler registered');
      }

      // Configure foreground message handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.debug(
            'Notification opened app from background: ${message.messageId}');
        _handleNotificationTap(message);
      });

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _cachedToken = token;
        AppLogger.debug('FCM token refreshed: $token');
      });

      _isInitialized = true;
      AppLogger.debug('FcmService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize FcmService', errorObject: e);
      rethrow;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      final settings = await _messaging.requestPermission();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      AppLogger.debug('Permission status: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      AppLogger.error('Error requesting FCM permissions', errorObject: e);
      return false;
    }
  }

  /// Check current permission status without triggering dialog
  Future<bool> checkPermissionStatus() async {
    if (kIsWeb) return true;

    try {
      final settings = await _messaging.getNotificationSettings();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      AppLogger.debug(
          'Checking permission status: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      AppLogger.error('Error checking FCM permission status', errorObject: e);
      return false;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      _cachedToken = token;
      AppLogger.debug(
          'FCM token retrieved: ${token != null ? 'success' : 'null'}');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', errorObject: e);
      return null;
    }
  }

  /// Delete current FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _cachedToken = null;
      AppLogger.info('FCM token deleted');
    } catch (e) {
      AppLogger.error('Error deleting FCM token', errorObject: e);
    }
  }

  /// Store FCM token with reuse logic in database
  Future<void> storeToken(
      {required String userId, required String token}) async {
    try {
      _cachedToken = token;
      final supabase = Supabase.instance.client;
      String platform = Platform.isIOS ? 'ios' : 'android';
      final now = DateTime.now().toIso8601String();

      // First, check if this specific token already exists for this user/device
      final existingTokenRecord = await supabase
          .schema('service')
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', userId)
          .eq('device_type', platform)
          .eq('token', token)
          .maybeSingle();

      if (existingTokenRecord != null) {
        // Token exists - check if it's inactive and reactivate it
        final bool isActive = existingTokenRecord['is_active'] ?? false;
        if (!isActive) {
          AppLogger.debug('Reactivating existing inactive token: $token');
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
          AppLogger.info('FCM token reactivated for user: $userId');
        } else {
          AppLogger.debug('Token already active, updating timestamp: $token');
          await supabase
              .schema('service')
              .from('user_fcm_tokens')
              .update({
                'updated_at': now,
                'last_used_at': now,
              })
              .eq('user_id', userId)
              .eq('device_type', platform)
              .eq('token', token);
        }
      } else {
        // Token doesn't exist - check for recently inactive tokens to reuse
        final recentInactiveTokens = await supabase
            .schema('service')
            .from('user_fcm_tokens')
            .select()
            .eq('user_id', userId)
            .eq('device_type', platform)
            .eq('is_active', false)
            .gte(
                'updated_at',
                DateTime.now()
                    .subtract(const Duration(hours: 24))
                    .toIso8601String())
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (recentInactiveTokens != null) {
          // Found a recent inactive token - reactivate it instead of creating new one
          final existingTokenToReactivate =
              recentInactiveTokens['token'] as String;
          AppLogger.debug(
              'Reactivating recent inactive token instead of creating new: $existingTokenToReactivate');

          await supabase
              .schema('service')
              .from('user_fcm_tokens')
              .update({
                'is_active': true,
                'updated_at': now,
                'last_used_at': now,
                'token': token, // Update to new token from Firebase
              })
              .eq('user_id', userId)
              .eq('device_type', platform)
              .eq('token', existingTokenToReactivate);

          AppLogger.info(
              'Existing FCM token reactivated with new token value for user: $userId');
        } else {
          // Check if token exists for ANY user (not just current user) before inserting
          final tokenExistsForAnyUser = await supabase
              .schema('service')
              .from('user_fcm_tokens')
              .select()
              .eq('token', token)
              .maybeSingle();

          if (tokenExistsForAnyUser != null) {
            // Token exists for different user - reassign it to current user
            AppLogger.debug(
                'Token exists for different user, reassigning to current user: $userId');
            await supabase.schema('service').from('user_fcm_tokens').update({
              'user_id': userId,
              'device_type': platform,
              'is_active': true,
              'updated_at': now,
              'last_used_at': now,
            }).eq('token', token);
            AppLogger.info('Existing FCM token reassigned to user: $userId');
          } else {
            // No recent inactive token found and token doesn't exist for any user - insert new one
            AppLogger.debug('Inserting new FCM token: $token');
            await supabase.schema('service').from('user_fcm_tokens').insert({
              'user_id': userId,
              'token': token,
              'device_type': platform,
              'is_active': true,
              'updated_at': now,
              'created_at': now,
            });
            AppLogger.info('New FCM token stored for user: $userId');
          }
        }
      }

      // Mark all other tokens for this user/device as inactive
      final otherTokens = await supabase
          .schema('service')
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', userId)
          .eq('device_type', platform)
          .neq('token', token);

      final List<Map<String, dynamic>> otherTokensList = otherTokens ?? [];
      for (final tokenData in otherTokensList) {
        final otherToken = tokenData['token'] as String?;
        if (otherToken != null && otherToken.isNotEmpty) {
          AppLogger.debug('Marking other token as inactive: $otherToken');
          await supabase
              .schema('service')
              .from('user_fcm_tokens')
              .update({
                'is_active': false,
                'updated_at': now,
                'last_used_at': now,
              })
              .eq('token', otherToken)
              .eq('device_type', platform);
        }
      }

      AppLogger.info(
          'FCM token storage completed successfully for user: $userId');
    } catch (e) {
      AppLogger.error('Error storing FCM token', errorObject: e);
      AppLogger.error('FCM token storage error details: ${e.toString()}');
      AppLogger.error('User ID being used: $userId');
      AppLogger.error('Token being stored: ${token.substring(0, 20)}...');

      // Remove special handling for anonymous users - they should be treated same as authenticated users
      // Supabase anonymous users have proper UUIDs, not the string 'anonymous'
      rethrow;
    }
  }

  /// Mark a specific token as inactive
  Future<void> markTokenInactive({required String token}) async {
    try {
      final supabase = Supabase.instance.client;
      final nowIso = DateTime.now().toIso8601String();
      final updates = {
        'is_active': false,
        'updated_at': nowIso,
        'last_used_at': nowIso,
      };

      await supabase
          .schema('service')
          .from('user_fcm_tokens')
          .update(updates)
          .eq('token', token);

      AppLogger.info('Marked FCM token as inactive: $token');
    } catch (e) {
      AppLogger.error('Error marking FCM token inactive', errorObject: e);
    }
  }

  /// Handle foreground FCM messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.debug('FCM message received in foreground: ${message.messageId}');
    AppLogger.debug(
        'FCM message content: title="${message.notification?.title}", body="${message.notification?.body}"');
    AppLogger.debug('FCM data: ${message.data}');

    // Show local notification for foreground messages
    try {
      // Import NotificationService locally to avoid circular dependency
      final notificationService = NotificationService.instance;

      final title = message.notification?.title ?? 'Timer.Coffee';
      final body = message.notification?.body ?? 'You have a new notification';

      await notificationService.showLocalNotification(
        id: message.hashCode, // Use message hash as unique ID
        title: title,
        body: body,
        payload: message.data['deep_link'],
      );

      AppLogger.debug('Local notification shown for foreground FCM message');
    } catch (e) {
      AppLogger.error('Error showing local notification for foreground message',
          errorObject: e);
    }
  }

  /// Handle notification tap events
  void _handleNotificationTap(RemoteMessage message) {
    final deepLink = message.data['deep_link'];
    if (deepLink != null) {
      AppLogger.debug('Deep link from notification: $deepLink');
      onNotificationTapped.add(deepLink);
    }
  }

  /// Check for initial message when app launches from notification
  Future<void> checkForInitialMessage() async {
    try {
      RemoteMessage? message = await _messaging.getInitialMessage();
      if (message != null) {
        AppLogger.debug(
            'App opened from terminated state via notification: ${message.messageId}');
        _handleNotificationTap(message);
      }
    } catch (e) {
      AppLogger.error('Error checking for initial message', errorObject: e);
    }
  }
}
