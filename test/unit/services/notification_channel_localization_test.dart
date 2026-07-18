import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/local_notification_manager.dart';
import 'package:coffee_timer/services/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification locale uses the first supported system language', () {
    expect(
      resolveSupportedNotificationLocale(const [
        Locale('xx'),
        Locale('ja', 'JP'),
        Locale('fr', 'FR'),
      ]),
      const Locale('ja'),
    );
    expect(
      resolveSupportedNotificationLocale(const [Locale('xx')]),
      const Locale('en'),
    );
  });

  test('localized general-channel copy reaches Android channel details', () {
    final locale = resolveSupportedNotificationLocale(const [
      Locale('ja', 'JP'),
    ]);
    final l10n = lookupAppLocalizations(locale);
    final manager = LocalNotificationManager(
      FlutterLocalNotificationsPlugin(),
      generalChannelName: l10n.notificationChannelGeneralName,
      generalChannelDescription: l10n.notificationChannelGeneralDescription,
    );

    final channel = manager.generalChannelForTesting;
    expect(channel.id, LocalNotificationManager.CHANNEL_ID_GENERAL);
    expect(channel.name, l10n.notificationChannelGeneralName);
    expect(channel.description, l10n.notificationChannelGeneralDescription);
    expect(channel.importance, Importance.high);

    final details = manager.buildDetailsForTesting(
      title: 'Test title',
      body: 'Test body',
    );
    final android = details.android!;
    expect(android.channelId, LocalNotificationManager.CHANNEL_ID_GENERAL);
    expect(android.channelName, l10n.notificationChannelGeneralName);
    expect(
      android.channelDescription,
      l10n.notificationChannelGeneralDescription,
    );
    expect(android.importance, Importance.defaultImportance);
    expect(android.playSound, isTrue);
    expect(android.enableVibration, isTrue);
    expect(details.iOS!.presentAlert, isTrue);
    expect(details.iOS!.presentBadge, isTrue);
    expect(details.iOS!.presentSound, isTrue);
  });
}
