import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/controllers/settings_controller.dart';

/// Controller-side coverage for the bean review nudge and the
/// [SettingsController.enabledReminderCount] getter that will drive the
/// Settings root row summary.
///
/// The live stream wiring (`initNotificationSettings` subscribing to
/// `NotificationSettingsService.beanReviewNudgeChanges`) cannot run in the
/// test environment: `NotificationService.initialize()` requires localized
/// channel copy and platform channels, so the controller takes its catch
/// path before subscribing. That is the same limitation the other three
/// optional-toggle subscriptions have; the setter/stream side itself is
/// covered by `test/unit/services/notification_settings_service_test.dart`.
void main() {
  group('beanReviewNudgeEnabled', () {
    test('defaults to true (product decision D4)', () {
      final controller = SettingsController();
      expect(controller.beanReviewNudgeEnabled, isTrue);
      controller.dispose();
    });

    test('still true after initNotificationSettings fails safe in tests',
        () async {
      final controller = SettingsController();
      await controller.initNotificationSettings();
      expect(controller.isLoading, isFalse);
      expect(controller.masterNotificationsEnabled, isTrue);
      expect(controller.beanReviewNudgeEnabled, isTrue);
      controller.dispose();
    });
  });

  group('enabledReminderCount', () {
    late SettingsController controller;

    setUp(() {
      controller = SettingsController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('fresh controller counts only the bean review nudge (default on)',
        () {
      expect(controller.enabledReminderCount, 1);
    });

    test('counts all four when every reminder is on', () {
      controller.morningReminderEnabled = true;
      controller.weeklySummaryEnabled = true;
      controller.beanFreshnessEnabled = true;
      controller.beanReviewNudgeEnabled = true;
      expect(controller.enabledReminderCount, 4);
    });

    test('counts zero when every reminder is off', () {
      controller.morningReminderEnabled = false;
      controller.weeklySummaryEnabled = false;
      controller.beanFreshnessEnabled = false;
      controller.beanReviewNudgeEnabled = false;
      expect(controller.enabledReminderCount, 0);
    });

    test('counts mixed states', () {
      controller.morningReminderEnabled = true;
      controller.weeklySummaryEnabled = false;
      controller.beanFreshnessEnabled = true;
      controller.beanReviewNudgeEnabled = false;
      expect(controller.enabledReminderCount, 2);
    });
  });
}
