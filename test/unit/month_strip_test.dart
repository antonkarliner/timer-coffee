import 'dart:ui' show SemanticsAction;

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/widgets/brew_diary/month_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('DiaryMonthSummary', () {
    test('computes daily counts, ratings, active days, and longest streak', () {
      final entries = [
        _entry('a', DateTime(2026, 7, 1, 8), rating: 4),
        _entry('b', DateTime(2026, 7, 1, 12)),
        _entry('c', DateTime(2026, 7, 2, 8), rating: 2),
        _entry('d', DateTime(2026, 7, 4, 8), rating: 5),
        _entry('e', DateTime(2026, 7, 5, 8)),
        _entry('f', DateTime(2026, 7, 6, 8)),
        _entry('outside', DateTime(2026, 6, 30, 8), rating: 1),
      ];

      final summary = DiaryMonthSummary.fromEntries(
        entries,
        DateTime(2026, 7, 20),
      );

      expect(summary.month, DateTime(2026, 7));
      expect(summary.brewCount, 6);
      expect(summary.dayCounts[DateTime(2026, 7, 1)], 2);
      expect(summary.dayCounts[DateTime(2026, 7, 2)], 1);
      expect(summary.activeDays, 5);
      expect(summary.longestStreak, 3);
      expect(summary.averageRating, closeTo(11 / 3, 0.0001));
    });

    test('returns empty statistics for a month without brews', () {
      final summary = DiaryMonthSummary.fromEntries([
        _entry('a', DateTime(2026, 6, 30, 8), rating: 4),
      ], DateTime(2026, 7));

      expect(summary.dayCounts, isEmpty);
      expect(summary.brewCount, 0);
      expect(summary.activeDays, 0);
      expect(summary.longestStreak, 0);
      expect(summary.averageRating, isNull);
    });

    test('counts spring-forward local dates as consecutive', () {
      final summary = DiaryMonthSummary.fromEntries([
        _entry('before', DateTime(2026, 3, 7, 8)),
        _entry('transition', DateTime(2026, 3, 8, 8)),
        _entry('after', DateTime(2026, 3, 9, 8)),
      ], DateTime(2026, 3));

      expect(summary.activeDays, 3);
      expect(summary.longestStreak, 3);
    });

    test('counts fall-back local dates as consecutive', () {
      final summary = DiaryMonthSummary.fromEntries([
        _entry('transition', DateTime(2026, 11, 1, 8)),
        _entry('after', DateTime(2026, 11, 2, 8)),
      ], DateTime(2026, 11));

      expect(summary.activeDays, 2);
      expect(summary.longestStreak, 2);
    });

    test('breaks a streak when a civil calendar date is skipped', () {
      final summary = DiaryMonthSummary.fromEntries([
        _entry('first', DateTime(2026, 3, 7, 8)),
        _entry('second', DateTime(2026, 3, 8, 8)),
        _entry('skipped-date', DateTime(2026, 3, 10, 8)),
      ], DateTime(2026, 3));

      expect(summary.activeDays, 3);
      expect(summary.longestStreak, 2);
    });
  });

  test(
    'DiaryMonthBounds uses the earliest local brew month and current month',
    () {
      final bounds = DiaryMonthBounds.fromEntries([
        _entry('newer', DateTime(2024, 11, 10, 8)),
        _entry('earliest', DateTime(2022, 3, 4, 8)),
        _entry('middle', DateTime(2023, 8, 20, 8)),
      ], now: DateTime(2026, 7, 13));

      expect(bounds.earliestMonth, DateTime(2022, 3));
      expect(bounds.currentMonth, DateTime(2026, 7));
      expect(bounds.clamp(DateTime(2020, 1)), DateTime(2022, 3));
      expect(bounds.clamp(DateTime(2027, 1)), DateTime(2026, 7));
      expect(bounds.clamp(DateTime(2024, 5, 20)), DateTime(2024, 5));
    },
  );

  testWidgets('heatmap exposes interaction only for populated days', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final populatedDate = DateTime(now.year, now.month, 1);
    final emptyDate = DateTime(now.year, now.month, 2);
    final tappedDays = <DateTime>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MonthStrip(
            entries: [_entry('populated', populatedDate.copyWith(hour: 8))],
            displayedMonth: diaryMonth(now),
            expanded: true,
            onDisplayedMonthChanged: (_) {},
            onExpandedChanged: (_) {},
            onDayTap: tappedDays.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final loc = AppLocalizations.of(tester.element(find.byType(MonthStrip)))!;
    final populatedLabel = '${populatedDate.day}, ${loc.diaryMonthBrews(1)}';
    final emptyLabel = '${emptyDate.day}, ${loc.diaryMonthBrews(0)}';
    final populatedCell = find.bySemanticsLabel(populatedLabel);
    final emptyCell = find.bySemanticsLabel(emptyLabel);
    final populatedData = tester.getSemantics(populatedCell).getSemanticsData();
    final emptyData = tester.getSemantics(emptyCell).getSemanticsData();

    expect(populatedData.flagsCollection.isButton, isTrue);
    expect(populatedData.hasAction(SemanticsAction.tap), isTrue);
    expect(emptyData.flagsCollection.isButton, isFalse);
    expect(emptyData.hasAction(SemanticsAction.tap), isFalse);

    tester.semantics.tap(find.semantics.byLabel(populatedLabel));
    await tester.pump();
    expect(tappedDays, [populatedDate]);

    await tester.tap(emptyCell);
    await tester.pump();
    expect(tappedDays, [populatedDate]);
    final emptyInkWell = find.descendant(
      of: emptyCell,
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(emptyInkWell).onTap, isNull);
    semantics.dispose();
  });

  testWidgets('month and expanded state are controlled by the parent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final currentMonth = diaryMonth(now);
    final previousMonth = DateTime(now.year, now.month - 1);
    final key = GlobalKey<_ControlledMonthStripHarnessState>();

    await tester.pumpWidget(
      _ControlledMonthStripHarness(
        key: key,
        entries: [
          _entry('current', currentMonth.copyWith(day: 1, hour: 8)),
          _entry('previous', previousMonth.copyWith(day: 1, hour: 8)),
        ],
        displayedMonth: currentMonth,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMM('en').format(currentMonth)),
      findsOneWidget,
    );
    expect(find.textContaining('brew'), findsOneWidget);
    expect(find.textContaining('day'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMM('en').format(currentMonth)),
      findsNWidgets(2),
    );

    final statRects = [
      for (final key in const [
        'monthStatBrews',
        'monthStatRating',
        'monthStatStreak',
        'monthStatActiveDays',
      ])
        tester.getRect(find.byKey(Key(key))),
    ];
    for (final rect in statRects.skip(1)) {
      expect(rect.height, closeTo(statRects.first.height, 0.1));
    }
    expect(statRects[0].top, closeTo(statRects[1].top, 0.1));
    expect(statRects[2].top, closeTo(statRects[3].top, 0.1));
    expect(statRects[2].top, greaterThan(statRects[0].top));
    expect(find.byIcon(Icons.local_cafe_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(key.currentState!.displayedMonth, previousMonth);
    expect(
      find.text(DateFormat.yMMMM('en').format(previousMonth)),
      findsNWidgets(2),
    );

    key.currentState!.setControlledState(
      displayedMonth: currentMonth,
      expanded: false,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMM('en').format(previousMonth)),
      findsNothing,
    );
    expect(
      find.text(DateFormat.yMMMM('en').format(currentMonth)),
      findsOneWidget,
    );
  });

  testWidgets('Full Stats routes to the displayed historical month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = _RecordingStackRouter();
    final currentMonth = diaryMonth(DateTime.now());
    final historicalMonth = DateTime(currentMonth.year, currentMonth.month - 1);

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: MonthStrip(
              entries: [
                _entry('current', currentMonth.copyWith(day: 1, hour: 8)),
                _entry('historical', historicalMonth.copyWith(day: 1, hour: 8)),
              ],
              displayedMonth: historicalMonth,
              expanded: true,
              onDisplayedMonthChanged: (_) {},
              onExpandedChanged: (_) {},
              onDayTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final loc = AppLocalizations.of(tester.element(find.byType(MonthStrip)))!;
    await tester.tap(find.text('${loc.diaryFullStats} →'));
    await tester.pump();

    expect(router.pushedRoute, isA<StatsRoute>());
    final route = router.pushedRoute! as StatsRoute;
    expect(route.rawQueryParams, {
      'year': historicalMonth.year,
      'month': historicalMonth.month,
      'start': null,
      'end': null,
    });
  });
}

class _ControlledMonthStripHarness extends StatefulWidget {
  const _ControlledMonthStripHarness({
    super.key,
    required this.entries,
    required this.displayedMonth,
  });

  final List<DiaryEntry> entries;
  final DateTime displayedMonth;

  @override
  State<_ControlledMonthStripHarness> createState() =>
      _ControlledMonthStripHarnessState();
}

class _ControlledMonthStripHarnessState
    extends State<_ControlledMonthStripHarness> {
  late DateTime displayedMonth;
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    displayedMonth = widget.displayedMonth;
  }

  void setControlledState({
    required DateTime displayedMonth,
    required bool expanded,
  }) {
    setState(() {
      this.displayedMonth = displayedMonth;
      this.expanded = expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: MonthStrip(
          entries: widget.entries,
          displayedMonth: displayedMonth,
          expanded: expanded,
          onDisplayedMonthChanged: (month) =>
              setState(() => displayedMonth = month),
          onExpandedChanged: (value) => setState(() => expanded = value),
          onDayTap: (_) {},
        ),
      ),
    );
  }
}

DiaryEntry _entry(String id, DateTime localCreatedAt, {double? rating}) {
  return DiaryEntry(
    statUuid: id,
    recipeId: 'recipe-$id',
    recipeName: 'Recipe $id',
    brewingMethodId: 'method',
    methodName: 'Method',
    createdAt: localCreatedAt.toUtc(),
    coffeeAmount: 15,
    waterAmount: 250,
    rating: rating,
    isMarked: false,
  );
}

class _RecordingStackRouter extends Mock implements StackRouter {
  PageRouteInfo? pushedRoute;

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushedRoute = route;
    return null;
  }
}
