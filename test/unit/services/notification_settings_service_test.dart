import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';

Map<String, dynamic> _toggledEvent(List<Map<String, dynamic>> events) {
  final matches =
      events.where((e) => e['event_name'] == 'notification_setting_toggled');
  expect(matches.length, 1,
      reason: 'expected exactly one notification_setting_toggled event, '
          'got: $events');
  return matches.first;
}

void main() {
  late SharedPreferences prefs;

  // Rebinds both singletons' caches so state does not leak between tests.
  // Does NOT call NotificationSettingsService.instance.dispose() — that
  // closes the singleton's BehaviorSubjects permanently for the whole run.
  Future<void> reinit(Map<String, Object> initialValues) async {
    SharedPreferences.setMockInitialValues(initialValues);
    prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
    await NotificationSettingsService.instance.init();
  }

  setUp(() async {
    await reinit({});
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('setter -> analytics wiring (flip away from default)', () {
    test('setMasterEnabled(true) emits setting=master enabled=true source=user',
        () async {
      await NotificationSettingsService.instance.setMasterEnabled(true);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'master');
      expect(properties['enabled'], isTrue);
      expect(properties['source'], 'user');
    });

    test(
        'setMorningReminderEnabled(true) emits setting=morning_reminder enabled=true',
        () async {
      await NotificationSettingsService.instance
          .setMorningReminderEnabled(true);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'morning_reminder');
      expect(properties['enabled'], isTrue);
      expect(properties['source'], 'user');
    });

    test(
        'setWeeklySummaryEnabled(true) emits setting=weekly_summary enabled=true',
        () async {
      await NotificationSettingsService.instance
          .setWeeklySummaryEnabled(true);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'weekly_summary');
      expect(properties['enabled'], isTrue);
      expect(properties['source'], 'user');
    });

    test(
        'setBeanFreshnessEnabled(true) emits setting=bean_freshness enabled=true',
        () async {
      await NotificationSettingsService.instance
          .setBeanFreshnessEnabled(true);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'bean_freshness');
      expect(properties['enabled'], isTrue);
      expect(properties['source'], 'user');
    });

    test(
        'setBeanReviewNudgeEnabled(false) emits setting=bean_review_nudge enabled=false '
        '(default is true, so false is the flip-away value)', () async {
      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(false);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'bean_review_nudge');
      expect(properties['enabled'], isFalse);
      expect(properties['source'], 'user');
    });
  });

  group('change guard: idempotent re-writes emit nothing', () {
    test('setMorningReminderEnabled(false) on a fresh install (already false) emits nothing',
        () async {
      await NotificationSettingsService.instance
          .setMorningReminderEnabled(false);

      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
    });

    test('setMasterEnabled(true) called twice emits exactly one event, not two',
        () async {
      await NotificationSettingsService.instance.setMasterEnabled(true);
      await NotificationSettingsService.instance.setMasterEnabled(true);

      final events = AnalyticsService.instance.bufferedEventsForTesting
          .where((e) => e['event_name'] == 'notification_setting_toggled')
          .toList();
      expect(events.length, 1);
    });

    test('writing the value already stored on disk emits nothing', () async {
      // Pre-existing stored value: master already true.
      await reinit({'notifications_master_enabled': true});

      await NotificationSettingsService.instance.setMasterEnabled(true);

      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
    });

    test('a genuine change after a no-op still emits (guard only suppresses equal values)',
        () async {
      await NotificationSettingsService.instance
          .setWeeklySummaryEnabled(false); // no-op, default already false
      await NotificationSettingsService.instance
          .setWeeklySummaryEnabled(true); // genuine change

      final events = AnalyticsService.instance.bufferedEventsForTesting
          .where((e) => e['event_name'] == 'notification_setting_toggled')
          .toList();
      expect(events.length, 1);
      final properties = events.first['properties'] as Map<String, dynamic>;
      expect(properties['enabled'], isTrue);
    });
  });

  group('source parameter', () {
    test("source: 'migration' is recorded when passed explicitly", () async {
      await NotificationSettingsService.instance
          .setMasterEnabled(true, source: 'migration');

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['source'], 'migration');
    });

    test("defaults to source: 'user' when omitted", () async {
      await NotificationSettingsService.instance.setBeanFreshnessEnabled(true);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['source'], 'user');
    });
  });

  group('bean_review_nudge default-true trap', () {
    test('setBeanReviewNudgeEnabled(true) on a fresh install emits nothing (already true)',
        () async {
      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(true);

      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
    });

    test('setBeanReviewNudgeEnabled(false) on a fresh install emits enabled=false',
        () async {
      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(false);

      final event = _toggledEvent(
          AnalyticsService.instance.bufferedEventsForTesting);
      final properties = event['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'bean_review_nudge');
      expect(properties['enabled'], isFalse);
    });
  });

  group('persistence still happens even when no event is emitted', () {
    test('setMasterEnabled(false) on a fresh install (no-op) still writes false to prefs',
        () async {
      await NotificationSettingsService.instance.setMasterEnabled(false);

      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
      expect(prefs.getBool(KEY_MASTER_ENABLED), isFalse);
    });

    test('setBeanReviewNudgeEnabled(true) on a fresh install (no-op) still writes true to prefs',
        () async {
      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(true);

      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
      expect(prefs.getBool(KEY_BEAN_REVIEW_NUDGE), isTrue);
    });

    test('setMorningReminderEnabled(true) writes to KEY_MORNING_REMINDER and emits',
        () async {
      await NotificationSettingsService.instance
          .setMorningReminderEnabled(true);

      expect(prefs.getBool(KEY_MORNING_REMINDER), isTrue);
      _toggledEvent(AnalyticsService.instance.bufferedEventsForTesting);
    });

    test('setWeeklySummaryEnabled(true) writes to KEY_WEEKLY_SUMMARY and emits',
        () async {
      await NotificationSettingsService.instance
          .setWeeklySummaryEnabled(true);

      expect(prefs.getBool(KEY_WEEKLY_SUMMARY), isTrue);
      _toggledEvent(AnalyticsService.instance.bufferedEventsForTesting);
    });

    test('setBeanFreshnessEnabled(true) writes to KEY_BEAN_FRESHNESS and emits',
        () async {
      await NotificationSettingsService.instance
          .setBeanFreshnessEnabled(true);

      expect(prefs.getBool(KEY_BEAN_FRESHNESS), isTrue);
      _toggledEvent(AnalyticsService.instance.bufferedEventsForTesting);
    });
  });

  group('setMorningReminderTime is not instrumented', () {
    test('emits no notification_setting_toggled event', () async {
      await NotificationSettingsService.instance
          .setMorningReminderTime(const TimeOfDay(hour: 7, minute: 15));

      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
    });

    test('still persists hour/minute and updates morningTimeChanges', () async {
      final emitted = <TimeOfDay>[];
      final sub = NotificationSettingsService.instance.morningTimeChanges
          .listen(emitted.add);

      await NotificationSettingsService.instance
          .setMorningReminderTime(const TimeOfDay(hour: 7, minute: 15));
      // Stream delivery to listeners is scheduled asynchronously (rxdart's
      // BehaviorSubject is not a sync controller) — pump the event queue so
      // the pending event lands before we cancel and assert.
      await pumpEventQueue();
      await sub.cancel();

      expect(prefs.getInt(KEY_MORNING_REMINDER_HOUR), 7);
      expect(prefs.getInt(KEY_MORNING_REMINDER_MINUTE), 15);
      expect(emitted.last, const TimeOfDay(hour: 7, minute: 15));
    });
  });

  group('regression guard: BehaviorSubject streams still fire', () {
    // Stream delivery to listeners is scheduled asynchronously (rxdart's
    // BehaviorSubject is not a sync controller), so each test pumps the
    // event queue between the write and the assertion/cancel.

    test('setMasterEnabled pushes to masterChanges', () async {
      final emitted = <bool>[];
      final sub = NotificationSettingsService.instance.masterChanges
          .listen(emitted.add);

      await NotificationSettingsService.instance.setMasterEnabled(true);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.last, isTrue);
    });

    test('setMorningReminderEnabled pushes to morningChanges', () async {
      final emitted = <bool>[];
      final sub = NotificationSettingsService.instance.morningChanges
          .listen(emitted.add);

      await NotificationSettingsService.instance
          .setMorningReminderEnabled(true);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.last, isTrue);
    });

    test('setWeeklySummaryEnabled pushes to weeklyChanges', () async {
      final emitted = <bool>[];
      final sub = NotificationSettingsService.instance.weeklyChanges
          .listen(emitted.add);

      await NotificationSettingsService.instance.setWeeklySummaryEnabled(true);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.last, isTrue);
    });

    test('setBeanFreshnessEnabled pushes to beanFreshnessChanges', () async {
      final emitted = <bool>[];
      final sub = NotificationSettingsService.instance.beanFreshnessChanges
          .listen(emitted.add);

      await NotificationSettingsService.instance
          .setBeanFreshnessEnabled(true);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.last, isTrue);
    });

    test('setBeanReviewNudgeEnabled pushes to beanReviewNudgeChanges',
        () async {
      final emitted = <bool>[];
      final sub = NotificationSettingsService.instance.beanReviewNudgeChanges
          .listen(emitted.add);

      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(false);
      await pumpEventQueue();
      await sub.cancel();

      expect(emitted.last, isFalse);
    });
  });

  group('no event when analytics is unavailable', () {
    test('setter does not throw when AnalyticsService was never initialized',
        () async {
      // Simulates the notification migration running before analytics init.
      AnalyticsService.resetForTesting();
      expect(AnalyticsService.maybeInstance, isNull);

      await NotificationSettingsService.instance.setMasterEnabled(true);
      // No assertion beyond "did not throw" — there is nowhere to buffer
      // the event without an AnalyticsService instance.
    });
  });
}
