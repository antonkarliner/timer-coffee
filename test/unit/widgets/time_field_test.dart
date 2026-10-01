import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// [device24h] fakes the phone's clock setting where the picker reads it:
  /// MediaQuery above the Navigator (the picker opens in the navigator's
  /// overlay, outside any wrapper around the field) and the platform
  /// dispatcher (read in the picker's initState). The test override on the
  /// dispatcher alone does not reach MediaQuery.
  Widget testApp(
    WidgetTester tester,
    Widget child, {
    bool? device24h,
    Locale locale = const Locale('en'),
  }) {
    if (device24h != null) {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = device24h;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
    }
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: device24h == null
          ? null
          : (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: device24h),
                child: app!,
              ),
      home: Scaffold(body: child),
    );
  }

  Finder dialogDayPeriod(String label) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

  /// Taps [opener], then checks whether the open picker shows the AM/PM
  /// buttons — the 12-hour layout has them, the 24-hour one doesn't.
  Future<void> expectPickerDayPeriods(
    WidgetTester tester,
    Finder opener, {
    required bool shown,
  }) async {
    final localizations = MaterialLocalizations.of(tester.element(opener));
    await tester.tap(opener);
    await tester.pumpAndSettle();
    final matcher = shown ? findsOneWidget : findsNothing;
    expect(dialogDayPeriod(localizations.anteMeridiemAbbreviation), matcher);
    expect(dialogDayPeriod(localizations.postMeridiemAbbreviation), matcher);
  }

  Widget pickerButton(bool use24HourFormat) => Builder(
        builder: (context) => TextButton(
          onPressed: () => showAppTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 20, minute: 15),
            use24HourFormat: use24HourFormat,
          ),
          child: const Text('Open picker'),
        ),
      );

  testWidgets('TimeField formats its value with the supplied preference', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        tester,
        const TimeField(
          label: 'Time',
          initialValue: TimeOfDay(hour: 20, minute: 15),
          use24HourFormat: true,
        ),
      ),
    );

    expect(find.text('20:15'), findsOneWidget);

    await tester.pumpWidget(
      testApp(
        tester,
        const TimeField(
          label: 'Time',
          initialValue: TimeOfDay(hour: 20, minute: 15),
          use24HourFormat: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('08:15 PM'), findsOneWidget);
  });

  testWidgets('TimeField writes the 12-hour day period in the app language', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        tester,
        const TimeField(
          label: 'Time',
          initialValue: TimeOfDay(hour: 20, minute: 15),
          use24HourFormat: false,
        ),
        locale: const Locale('zh'),
      ),
    );

    expect(find.text('08:15 下午'), findsOneWidget);
  });

  testWidgets('TimeField 12-hour preference beats a 24-hour device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        tester,
        const TimeField(
          label: 'Time',
          initialValue: TimeOfDay(hour: 20, minute: 15),
          use24HourFormat: false,
        ),
        device24h: true,
      ),
    );

    expect(find.text('08:15 PM'), findsOneWidget);
    await expectPickerDayPeriods(tester, find.byType(TimeField), shown: true);
  });

  testWidgets('TimeField 24-hour preference beats a 12-hour device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        tester,
        const TimeField(
          label: 'Time',
          initialValue: TimeOfDay(hour: 20, minute: 15),
          use24HourFormat: true,
        ),
        device24h: false,
      ),
    );

    expect(find.text('20:15'), findsOneWidget);
    await expectPickerDayPeriods(tester, find.byType(TimeField), shown: false);
  });

  testWidgets('showAppTimePicker: 12-hour preference beats a 24-hour device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(tester, pickerButton(false), device24h: true),
    );

    await expectPickerDayPeriods(
      tester,
      find.text('Open picker'),
      shown: true,
    );
  });

  testWidgets('showAppTimePicker: 24-hour preference beats a 12-hour device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(tester, pickerButton(true), device24h: false),
    );

    await expectPickerDayPeriods(
      tester,
      find.text('Open picker'),
      shown: false,
    );
  });
}
