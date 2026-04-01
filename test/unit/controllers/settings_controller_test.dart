import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/controllers/settings_controller.dart';

void main() {
  late SettingsController controller;

  setUp(() {
    controller = SettingsController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('initial state', () {
    test('isAnonymous defaults to true', () {
      expect(controller.isAnonymous, isTrue);
    });

    test('userId defaults to null', () {
      expect(controller.userId, isNull);
    });

    test('icon state defaults to unavailable', () {
      expect(controller.iconApiAvailable, isFalse);
      expect(controller.currentIconName, isNull);
      expect(controller.localIconState, isNull);
    });

    test('isLoading defaults to true', () {
      expect(controller.isLoading, isTrue);
    });

    test('masterNotificationsEnabled defaults to true', () {
      expect(controller.masterNotificationsEnabled, isTrue);
    });

    test('notificationsEnabled defaults to true', () {
      expect(controller.notificationsEnabled, isTrue);
    });

    test('systemPermissionDenied defaults to false', () {
      expect(controller.systemPermissionDenied, isFalse);
    });

    test('optional toggles default to false', () {
      expect(controller.morningReminderEnabled, isFalse);
      expect(controller.weeklySummaryEnabled, isFalse);
      expect(controller.beanFreshnessEnabled, isFalse);
    });

    test('morningReminderTime defaults to 8:30', () {
      expect(controller.morningReminderTime,
          const TimeOfDay(hour: 8, minute: 30));
    });
  });

  group('isDefaultIcon', () {
    test('returns true when localIconState is null', () {
      controller.localIconState = null;
      expect(controller.isDefaultIcon, isTrue);
    });

    test('returns true when localIconState is "Default"', () {
      controller.localIconState = 'Default';
      expect(controller.isDefaultIcon, isTrue);
    });

    test('returns false when localIconState is "Legacy"', () {
      controller.localIconState = 'Legacy';
      expect(controller.isDefaultIcon, isFalse);
    });

    test('returns false for any non-Default value', () {
      controller.localIconState = 'SomeOtherIcon';
      expect(controller.isDefaultIcon, isFalse);
    });
  });

  group('setIcon', () {
    test('returns false immediately when iconApiAvailable is false', () async {
      controller.iconApiAvailable = false;
      final result = await controller.setIcon('Legacy');
      expect(result, isFalse);
      // State should be unchanged
      expect(controller.localIconState, isNull);
    });
  });

  group('ChangeNotifier', () {
    test('notifies listeners when notification state fields change directly',
        () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // Simulate what initNotificationSettings does after loading
      controller.masterNotificationsEnabled = false;
      controller.isLoading = false;
      controller.notifyListeners();

      expect(notifyCount, 1);
      expect(controller.masterNotificationsEnabled, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('multiple listeners are all notified', () {
      int countA = 0;
      int countB = 0;
      controller.addListener(() => countA++);
      controller.addListener(() => countB++);

      controller.notifyListeners();

      expect(countA, 1);
      expect(countB, 1);
    });
  });

  group('dispose', () {
    test('does not throw when no subscriptions are active', () {
      // Create a separate controller for this test to avoid double-dispose
      final c = SettingsController();
      expect(() => c.dispose(), returnsNormally);
    });

    test('controller is no longer usable after dispose', () {
      final c = SettingsController();
      c.dispose();
      // After dispose, adding listeners should throw
      expect(
        () => c.addListener(() {}),
        throwsFlutterError,
      );
    });
  });

  group('ToggleNotificationResult', () {
    test('enum has expected values', () {
      expect(ToggleNotificationResult.values, hasLength(3));
      expect(ToggleNotificationResult.values,
          contains(ToggleNotificationResult.success));
      expect(ToggleNotificationResult.values,
          contains(ToggleNotificationResult.permissionDenied));
      expect(ToggleNotificationResult.values,
          contains(ToggleNotificationResult.error));
    });
  });
}
