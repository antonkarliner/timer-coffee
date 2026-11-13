import 'package:coffee_timer/services/local_notification_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses exact scheduling when exact alarms are allowed', () {
    expect(
      scheduleModeFor(canScheduleExact: true),
      AndroidScheduleMode.exactAllowWhileIdle,
    );
  });

  test('uses inexact scheduling when exact alarms are not allowed', () {
    expect(
      scheduleModeFor(canScheduleExact: false),
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  });
}
