import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/app_switch_list_tile.dart';
import 'package:coffee_timer/widgets/settings/notification_toggles.dart';

NotificationToggles _toggles({
  bool morning = false,
  bool use24HourFormat = false,
  TimeOfDay time = const TimeOfDay(hour: 8, minute: 30),
  bool? beanReview = true,
  ValueChanged<bool>? onMorning,
  ValueChanged<bool>? onBeanReview,
}) {
  return NotificationToggles(
    morningReminderEnabled: morning,
    morningReminderTime: time,
    use24HourFormat: use24HourFormat,
    weeklySummaryEnabled: false,
    beanFreshnessEnabled: false,
    onMorningChanged: onMorning ?? (_) {},
    onWeeklyChanged: (_) {},
    onBeanFreshnessChanged: (_) {},
    onPickMorningTime: () {},
    beanReviewNudgeEnabled: beanReview,
    onBeanReviewNudgeChanged: onBeanReview ?? (_) {},
  );
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders all four switches when the bean-review params are given',
      (tester) async {
    await tester.pumpWidget(_app(_toggles()));

    expect(find.byType(AppSwitchListTile), findsNWidgets(4));
    expect(find.text('Morning brew reminder'), findsOneWidget);
    expect(find.text('Weekly summary'), findsOneWidget);
    expect(find.text('Freshness reminders'), findsOneWidget);
    expect(find.text('Bean review reminders'), findsOneWidget);
  });

  testWidgets(
      'renders only three switches when the bean-review params are omitted '
      '(legacy Settings root)', (tester) async {
    await tester.pumpWidget(_app(_toggles(beanReview: null)));

    expect(find.byType(AppSwitchListTile), findsNWidgets(3));
    expect(find.text('Bean review reminders'), findsNothing);
  });

  testWidgets(
      'morning-time row sits in an always-present slot: same widget type '
      'whether the morning reminder is on or off', (tester) async {
    await tester.pumpWidget(_app(_toggles()));

    // Off: the slot exists but renders nothing.
    expect(find.byType(MorningTimeSlot), findsOneWidget);
    expect(find.text('Reminder time'), findsNothing);

    await tester.pumpWidget(_app(_toggles(morning: true)));

    // On: same slot type at the same tree position, now showing the row.
    expect(find.byType(MorningTimeSlot), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.text('08:30 AM'), findsOneWidget);
  });

  testWidgets('formats the morning time in 24-hour format', (tester) async {
    await tester.pumpWidget(
      _app(_toggles(morning: true, use24HourFormat: true)),
    );

    expect(find.text('08:30'), findsOneWidget);
  });

  testWidgets('formats an afternoon time in 12-hour format', (tester) async {
    await tester.pumpWidget(
      _app(
        _toggles(morning: true, time: const TimeOfDay(hour: 20, minute: 15)),
      ),
    );

    expect(find.text('08:15 PM'), findsOneWidget);
  });

  testWidgets('formats an afternoon time in 24-hour format', (tester) async {
    await tester.pumpWidget(
      _app(
        _toggles(
          morning: true,
          use24HourFormat: true,
          time: const TimeOfDay(hour: 20, minute: 15),
        ),
      ),
    );

    expect(find.text('20:15'), findsOneWidget);
  });

  testWidgets('tapping the morning switch fires onMorningChanged',
      (tester) async {
    var changed = false;
    await tester.pumpWidget(_app(_toggles(onMorning: (v) => changed = v)));

    await tester.tap(find.text('Morning brew reminder'));
    await tester.pump();

    expect(changed, isTrue);
  });

  testWidgets('tapping the bean-review switch fires onBeanReviewNudgeChanged',
      (tester) async {
    bool? changed;
    await tester.pumpWidget(_app(_toggles(
      onBeanReview: (v) => changed = v,
    )));

    await tester.tap(find.text('Bean review reminders'));
    await tester.pump();

    expect(changed, isFalse);
  });
}
