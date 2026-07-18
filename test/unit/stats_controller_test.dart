import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/controllers/stats_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  tearDown(() {
    StatsController.pendingInitialPeriod = null;
  });

  test(
    'past June uses local month boundaries through its final microsecond',
    () {
      final now = DateTime(2026, 7, 14, 10, 30, 45, 123, 456);
      final provider = _TestUserStatProvider(now);
      final controller = StatsController(clock: () => now);
      addTearDown(controller.dispose);

      controller.selectCalendarMonth(provider, 2026, DateTime.june);

      expect(controller.selectedPeriod, TimePeriod.custom);
      expect(controller.calendarMonth, DateTime(2026, DateTime.june));
      expect(controller.getStartDate(provider), DateTime(2026, DateTime.june));
      expect(
        controller.getEndDate(),
        DateTime(2026, DateTime.july).subtract(const Duration(microseconds: 1)),
      );
      expect(controller.includesToday, isFalse);
    },
  );

  test(
    'current calendar month ends at the injected now and includes today',
    () {
      final now = DateTime(2026, 7, 14, 10, 30, 45, 123, 456);
      final provider = _TestUserStatProvider(now);
      final controller = StatsController(clock: () => now);
      addTearDown(controller.dispose);

      controller.selectCalendarMonth(provider, 2026, DateTime.july);

      expect(controller.customStartDate, DateTime(2026, DateTime.july));
      expect(controller.customEndDate, now);
      expect(controller.getEndDate(), now);
      expect(controller.includesToday, isTrue);
    },
  );

  test('December month end rolls over to January', () {
    final now = DateTime(2027, 1, 10, 8);
    final provider = _TestUserStatProvider(now);
    final controller = StatsController(clock: () => now);
    addTearDown(controller.dispose);

    controller.selectCalendarMonth(provider, 2026, DateTime.december);

    expect(
      controller.getEndDate(),
      DateTime(
        2027,
        DateTime.january,
      ).subtract(const Duration(microseconds: 1)),
    );
    expect(controller.includesToday, isFalse);
  });

  test('manual custom range clears the calendar-month label', () {
    final now = DateTime(2026, 7, 14, 10);
    final provider = _TestUserStatProvider(now);
    final controller = StatsController(clock: () => now);
    final l10n = lookupAppLocalizations(const Locale('en'));
    addTearDown(controller.dispose);

    controller.selectCalendarMonth(provider, 2026, DateTime.june);
    expect(controller.labelForPeriod(l10n, TimePeriod.custom), 'June 2026');

    controller.setCustomRange(
      provider,
      DateTime(2026, 6, 3),
      DateTime(2026, 6, 9),
    );

    expect(controller.calendarMonth, isNull);
    expect(
      controller.labelForPeriod(l10n, TimePeriod.custom),
      l10n.timePeriodCustom,
    );
  });

  test('calendar-month label uses the localization locale', () {
    final now = DateTime(2026, 7, 14, 10);
    final provider = _TestUserStatProvider(now);
    final controller = StatsController(clock: () => now);
    final l10n = lookupAppLocalizations(const Locale('fr'));
    addTearDown(controller.dispose);

    controller.selectCalendarMonth(provider, 2026, DateTime.june);

    expect(
      controller.labelForPeriod(l10n, TimePeriod.custom),
      DateFormat.yMMMM('fr').format(DateTime(2026, DateTime.june)),
    );
    expect(
      controller.labelForPeriod(l10n, TimePeriod.thisWeek),
      l10n.timePeriodThisWeek,
    );
  });

  test('valid route month takes precedence over pending weekly period', () {
    final now = DateTime(2026, 7, 14, 10);
    final provider = _TestUserStatProvider(now);
    final controller = StatsController(clock: () => now);
    addTearDown(controller.dispose);
    StatsController.pendingInitialPeriod = TimePeriod.thisWeek;

    controller.initializePeriod(
      provider,
      initialYear: 2026,
      initialMonth: DateTime.june,
    );

    expect(controller.selectedPeriod, TimePeriod.custom);
    expect(controller.calendarMonth, DateTime(2026, DateTime.june));
    expect(StatsController.pendingInitialPeriod, isNull);
  });

  test('valid civil route range is inclusive and wins over month', () {
    final now = DateTime(2026, 7, 18, 10);
    final provider = _TestUserStatProvider(now);
    final controller = StatsController(clock: () => now);
    addTearDown(controller.dispose);
    StatsController.pendingInitialPeriod = TimePeriod.thisMonth;

    controller.initializePeriod(
      provider,
      initialYear: 2026,
      initialMonth: DateTime.july,
      initialStartDate: '2026-07-06',
      initialEndDate: '2026-07-12',
    );

    expect(controller.selectedPeriod, TimePeriod.custom);
    expect(controller.calendarMonth, isNull);
    expect(controller.getStartDate(provider), DateTime(2026, 7, 6));
    expect(
      controller.getEndDate(),
      DateTime(2026, 7, 13).subtract(const Duration(microseconds: 1)),
    );
    expect(controller.includesToday, isFalse);
    expect(StatsController.pendingInitialPeriod, isNull);
  });

  test('invalid civil range preserves month and pending fallbacks', () {
    final now = DateTime(2026, 7, 18, 10);
    final invalidRanges = <(String?, String?)>[
      (null, '2026-07-12'),
      ('2026-07-06', null),
      ('2026-02-30', '2026-03-08'),
      ('2026-07-13', '2026-07-12'),
    ];

    for (final (start, end) in invalidRanges) {
      final provider = _TestUserStatProvider(now);
      final controller = StatsController(clock: () => now);
      addTearDown(controller.dispose);
      StatsController.pendingInitialPeriod = TimePeriod.thisWeek;

      controller.initializePeriod(
        provider,
        initialYear: 2026,
        initialMonth: DateTime.june,
        initialStartDate: start,
        initialEndDate: end,
      );

      expect(
        controller.calendarMonth,
        DateTime(2026, DateTime.june),
        reason: 'range ($start, $end)',
      );
      expect(StatsController.pendingInitialPeriod, isNull);
    }
  });

  test('invalid or incomplete route month uses the pending fallback', () {
    final now = DateTime(2026, 7, 14, 10);
    final invalidPairs = <(int?, int?)>[
      (null, DateTime.june),
      (2026, null),
      (0, DateTime.june),
      (10000, DateTime.june),
      (2026, 0),
      (2026, 13),
    ];

    for (final (year, month) in invalidPairs) {
      final provider = _TestUserStatProvider(now);
      final controller = StatsController(clock: () => now);
      addTearDown(controller.dispose);
      StatsController.pendingInitialPeriod = TimePeriod.thisWeek;

      controller.initializePeriod(
        provider,
        initialYear: year,
        initialMonth: month,
      );

      expect(
        controller.selectedPeriod,
        TimePeriod.thisWeek,
        reason: 'pair ($year, $month)',
      );
      expect(controller.calendarMonth, isNull, reason: 'pair ($year, $month)');
      expect(StatsController.pendingInitialPeriod, isNull);
    }
  });

  test('generated StatsRoute carries year and month as query parameters', () {
    final route = StatsRoute(initialYear: 2026, initialMonth: DateTime.june);

    expect(route.rawQueryParams, {
      'year': 2026,
      'month': DateTime.june,
      'start': null,
      'end': null,
    });
    expect(route.rawPathParams, isEmpty);
    expect(route.args?.initialYear, 2026);
    expect(route.args?.initialMonth, DateTime.june);
  });

  test('generated StatsRoute carries civil range query parameters', () {
    final route = StatsRoute(
      initialStartDate: '2026-07-06',
      initialEndDate: '2026-07-12',
    );

    expect(route.rawQueryParams, {
      'year': null,
      'month': null,
      'start': '2026-07-06',
      'end': '2026-07-12',
    });
    expect(route.rawPathParams, isEmpty);
    expect(route.args?.initialStartDate, '2026-07-06');
    expect(route.args?.initialEndDate, '2026-07-12');
  });
}

class _TestUserStatProvider implements UserStatProvider {
  _TestUserStatProvider(this.now);

  final DateTime now;

  @override
  DateTime getStartOfToday() => DateTime(now.year, now.month, now.day);

  @override
  DateTime getStartOfWeek() {
    final start = now.subtract(Duration(days: now.weekday - DateTime.monday));
    return DateTime(start.year, start.month, start.day);
  }

  @override
  DateTime getStartOfMonth() => DateTime(now.year, now.month);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
