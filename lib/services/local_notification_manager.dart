import 'dart:io';
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
  static const String CHANNEL_NAME_GENERAL = 'General';
  static const String CHANNEL_DESC_GENERAL = 'General app notifications';

  LocalNotificationManager(this._plugin);

  Future<void> initialize() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings();

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

    final generalChannel = AndroidNotificationChannel(
      CHANNEL_ID_GENERAL,
      CHANNEL_NAME_GENERAL,
      description: CHANNEL_DESC_GENERAL,
      importance: Importance.defaultImportance,
    );

    await androidPlugin.createNotificationChannel(generalChannel);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          CHANNEL_ID_GENERAL,
          CHANNEL_NAME_GENERAL,
          channelDescription: CHANNEL_DESC_GENERAL,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

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
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          CHANNEL_ID_GENERAL,
          CHANNEL_NAME_GENERAL,
          channelDescription: CHANNEL_DESC_GENERAL,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

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

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    AppLogger.debug('Notification tapped: $payload');
    if (payload != null) {
      onNotificationTapped.add(payload);
    }
  }
}
