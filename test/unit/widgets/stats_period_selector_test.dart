import 'dart:ui' show Tristate;

import 'package:coffee_timer/controllers/stats_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/stats/time_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart' show MockUserStatProvider;

Finder _segment(String id) => find.bySemanticsIdentifier('statsPeriod_$id');

void main() {
  late StatsController controller;
  late MockUserStatProvider provider;

  setUp(() {
    final now = DateTime(2026, 11, 20, 12);
    controller = StatsController(clock: () => now);
    provider = MockUserStatProvider();
    when(provider.getStartOfToday()).thenReturn(DateTime(2026, 11, 20));
    when(provider.getStartOfWeek()).thenReturn(DateTime(2026, 11, 16));
    when(provider.getStartOfMonth()).thenReturn(DateTime(2026, 11));
    addTearDown(controller.dispose);
  });

  Future<void> pumpSelector(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    VoidCallback? onChanged,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StatsController>.value(value: controller),
          ChangeNotifierProvider<UserStatProvider>.value(value: provider),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: StatsTimePeriodSelector(onChanged: onChanged),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('presents four segments and switches between preset periods', (
    tester,
  ) async {
    var changes = 0;
    await pumpSelector(tester, onChanged: () => changes++);

    const labels = {
      'today': 'Today',
      'week': 'Week',
      'month': 'Month',
      'range': 'Range',
    };
    final control = find.bySemanticsIdentifier('statsPeriodSelector');
    expect(tester.getSize(control).width, 390 - 2 * AppSpacing.base);
    for (final entry in labels.entries) {
      expect(
        find.descendant(
          of: _segment(entry.key),
          matching: find.text(entry.value),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byWidgetPredicate((widget) => widget is DropdownButton),
      findsNothing,
    );

    final rangeLine = find.descendant(
      of: find.byType(StatsTimePeriodSelector),
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && !labels.containsValue(widget.data),
      ),
    );
    expect(controller.selectedPeriod, TimePeriod.today);
    expect(rangeLine, findsNothing);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(controller.selectedPeriod, TimePeriod.thisWeek);
    expect(changes, 1);
    expect(rangeLine, findsNothing);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(controller.selectedPeriod, TimePeriod.thisMonth);
    expect(rangeLine, findsNothing);
  });

  testWidgets('shows the custom range, a single day, and a calendar month', (
    tester,
  ) async {
    await pumpSelector(tester);

    final start = DateTime(2026, 11, 1);
    controller.setCustomRange(provider, start, DateTime(2026, 11, 15));
    await tester.pumpAndSettle();
    expect(find.text('Nov 1, 2026 – Nov 15, 2026'), findsOneWidget);
    expect(
      tester.getSemantics(_segment('range')).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    controller.setCustomRange(provider, start, DateTime(2026, 11, 1, 12));
    await tester.pumpAndSettle();
    expect(find.text('Nov 1, 2026'), findsOneWidget);

    controller.selectCalendarMonth(provider, 2026, 10);
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('opens Range from a preset and from an already selected range', (
    tester,
  ) async {
    var changes = 0;
    await pumpSelector(tester, onChanged: () => changes++);

    Future<void> openAndCancel(TimePeriod selection) async {
      await tester.tapAt(tester.getCenter(_segment('range')));
      await tester.pumpAndSettle();
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      final cancel = MaterialLocalizations.of(tester.element(dialog))
          .cancelButtonLabel
          .toUpperCase();
      await tester.tap(find.descendant(of: dialog, matching: find.text(cancel)));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(controller.selectedPeriod, selection);
      expect(changes, 0);
    }

    await openAndCancel(TimePeriod.today);

    final start = DateTime(2026, 11, 1);
    final end = DateTime(2026, 11, 15);
    controller.setCustomRange(provider, start, end);
    await tester.pumpAndSettle();
    await openAndCancel(TimePeriod.custom);
    expect(controller.customStartDate, start);
    expect(controller.customEndDate, end);
  });

  testWidgets('shows single-line German labels at 390 points', (tester) async {
    await pumpSelector(tester, locale: const Locale('de'));

    for (final label in ['Heute', 'Woche', 'Monat', 'Zeitraum']) {
      final texts = tester.widgetList<Text>(find.text(label));
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    }
    expect(tester.takeException(), isNull);
  });
}
