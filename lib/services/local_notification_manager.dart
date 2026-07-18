import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';

// Needs to be a top-level function to be accessible from background isolates.
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  AppLogger.debug('Background notification tapped: $payload');
  // The main app stream will handle the navigation
}

class LocalNotificationManager {
  final FlutterLocalNotificationsPlugin _plugin;
  final BehaviorSubject<String?> onNotificationTapped = BehaviorSubject();

  static const String CHANNEL_ID_GENERAL = 'general_channel';
  final String _generalChannelName;
  final String _generalChannelDescription;

  LocalNotificationManager(
    this._plugin, {
    required String generalChannelName,
    required String generalChannelDescription,
  }) : _generalChannelName = generalChannelName,
       _generalChannelDescription = generalChannelDescription;

  Future<void> initialize() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // CRITICAL: Explicitly disable all auto-permission requests on iOS
      // This prevents the iOS system dialog from showing during app startup
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: false,
        requestProvisionalPermission: false,
      );

      final initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTap,
      );

      if (Platform.isAndroid) {
        await _createAndroidChannels();
      }

      // Check if app was launched by tapping a notification (terminated state).
      // onDidReceiveNotificationResponse does NOT fire for cold starts —
      // getNotificationAppLaunchDetails() is the only way to retrieve the payload.
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          AppLogger.debug(
              'App launched from notification tap (terminated), payload: $payload');
          onNotificationTapped.add(payload);
        }
      }

      AppLogger.debug('LocalNotificationManager initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize LocalNotificationManager',
          errorObject: e);
      rethrow;
    }
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(_buildGeneralChannel());
  }

  AndroidNotificationChannel _buildGeneralChannel() {
    return AndroidNotificationChannel(
      CHANNEL_ID_GENERAL,
      _generalChannelName,
      description: _generalChannelDescription,
      importance: Importance
          .high, // Changed from defaultImportance to high for better visibility
    );
  }

  @visibleForTesting
  AndroidNotificationChannel get generalChannelForTesting =>
      _buildGeneralChannel();

  NotificationDetails _buildDetails({
    required String title,
    required String body,
    String? imagePath,
  }) {
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        CHANNEL_ID_GENERAL,
        _generalChannelName,
        channelDescription: _generalChannelDescription,
        importance: Importance.defaultImportance,
        largeIcon: hasImage ? FilePathAndroidBitmap(imagePath) : null,
        styleInformation: hasImage
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imagePath),
                largeIcon: FilePathAndroidBitmap(imagePath),
                contentTitle: title,
                summaryText: body,
                hideExpandedLargeIcon: true,
              )
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: hasImage ? [DarwinNotificationAttachment(imagePath)] : null,
      ),
    );
  }

  @visibleForTesting
  NotificationDetails buildDetailsForTesting({
    required String title,
    required String body,
    String? imagePath,
  }) => _buildDetails(title: title, body: body, imagePath: imagePath);

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imagePath,
  }) async {
    try {
      final details =
          _buildDetails(title: title, body: body, imagePath: imagePath);

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      AppLogger.debug('Local notification shown with id: $id');
    } catch (e) {
      AppLogger.error('Failed to show local notification', errorObject: e);
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String? imagePath,
  }) async {
    try {
      final details =
          _buildDetails(title: title, body: body, imagePath: imagePath);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      AppLogger.debug('Local notification scheduled for: $scheduledDate');
    } catch (e) {
      AppLogger.error('Failed to schedule local notification', errorObject: e);
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      AppLogger.debug('Local notification cancelled with id: $id');
    } catch (e) {
      AppLogger.error('Failed to cancel local notification', errorObject: e);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    AppLogger.debug('Notification tapped: $payload');
    if (payload != null) {
      onNotificationTapped.add(payload);
    }
  }
}
