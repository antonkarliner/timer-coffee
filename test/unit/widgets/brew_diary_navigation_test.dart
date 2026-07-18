import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'brew_flow_async_context_test.mocks.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
    'deep link reaches entry 200 and opens details exactly once across locale rebuilds',
    (tester) async {
      _useDiarySurface(tester);
      final entries = List.generate(200, (index) {
        final localDay = DateTime.now()
            .subtract(Duration(days: index))
            .copyWith(hour: 8 + index % 10, minute: 30);
        return _entry(
          'stat-$index',
          localDay,
          recipeName: 'Recipe $index ${'long title ' * (index % 4)}',
          notes: index.isEven ? 'A short note' : 'A much longer tasting note',
          rating: 3 + (index % 3),
        );
      });
      final provider = MockUserStatProvider();
      _stubDiary(provider, entries);
      final observer = _PopupCountingObserver();
      final harnessKey = GlobalKey<_DiaryHarnessState>();

      await tester.pumpWidget(
        _DiaryHarness(
          key: harnessKey,
          provider: provider,
          initialStatUuid: 'stat-199',
          navigatorObserver: observer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrewDetailSheet), findsOneWidget);
      expect(find.textContaining('Recipe 199'), findsWidgets);
      expect(observer.popupPushes, 1);

      harnessKey.currentState!.setLocale(const Locale('de'));
      await tester.pumpAndSettle();
      expect(find.byType(BrewDetailSheet), findsOneWidget);
      expect(observer.popupPushes, 1);

      Navigator.of(tester.element(find.byType(BrewDetailSheet))).pop();
      await tester.pumpAndSettle();
      expect(observer.popupPushes, 1);
      expect(
        find.bySemanticsIdentifier('userStatCard_stat-199'),
        findsOneWidget,
      );
    },
  );

  testWidgets('missing deep link shows localized terminal feedback once', (
    tester,
  ) async {
    _useDiarySurface(tester);
    final provider = MockUserStatProvider();
    _stubDiary(provider, [_entry('present', DateTime.now())]);
    final harnessKey = GlobalKey<_DiaryHarnessState>();
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final observer = _PopupCountingObserver();

    await tester.pumpWidget(
      _DiaryHarness(
        key: harnessKey,
        provider: provider,
        initialStatUuid: 'deleted-stat',
        navigatorObserver: observer,
        scaffoldMessengerKey: messengerKey,
      ),
    );
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BrewDiaryScreen)),
    )!;

    expect(find.text(loc.diaryBrewNotFound), findsOneWidget);
    expect(observer.popupPushes, 0);

    harnessKey.currentState!.setLocale(const Locale('de'));
    await tester.pumpAndSettle();
    messengerKey.currentState!.hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(observer.popupPushes, 0);
  });

  testWidgets('visible filtered heatmap day scrolls without clearing filters', (
    tester,
  ) async {
    _useDiarySurface(tester);
    final now = DateTime.now();
    final entries = _multiBrewCurrentMonthEntries(now, targetRating: 5);
    final targetDay = entries
        .firstWhere((entry) => entry.statUuid == 'target-early')
        .createdAt
        .toLocal();
    final provider = MockUserStatProvider();
    _stubDiary(provider, entries);

    await tester.pumpWidget(_DiaryHarness(provider: provider));
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BrewDiaryScreen)),
    )!;
    final ratingFilter = find.widgetWithText(
      FilterChip,
      loc.diaryRatingFourPlus,
    );
    tester.widget<FilterChip>(ratingFilter).onSelected!(true);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('diaryMonthStrip'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel('${targetDay.day}, ${loc.diaryMonthBrews(3)}'),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FilterChip>(ratingFilter).selected, isTrue);
    final header = find.bySemanticsIdentifier(_dateHeaderId(targetDay));
    expect(header, findsOneWidget);
    expect(
      find.bySemanticsIdentifier('userStatCard_target-early'),
      findsOneWidget,
    );
    final listTop = tester.getTopLeft(find.byType(ScrollablePositionedList)).dy;
    expect(tester.getTopLeft(header).dy, closeTo(listTop, AppSpacing.xs));
    expect(find.text(loc.diaryFiltersClearedForDay), findsNothing);
  });

  testWidgets(
    'counted heatmap day hidden by filters clears them and scrolls to its local date',
    (tester) async {
      _useDiarySurface(tester);
      final now = DateTime.now();
      final entries = _filterResetEntries(now);
      final target = entries.firstWhere(
        (entry) => entry.statUuid == 'filter-target',
      );
      final provider = MockUserStatProvider();
      _stubDiary(provider, entries);

      await tester.pumpWidget(_DiaryHarness(provider: provider));
      await tester.pumpAndSettle();
      final loc = AppLocalizations.of(
        tester.element(find.byType(BrewDiaryScreen)),
      )!;
      final bookmarkFilter = find.widgetWithText(
        FilterChip,
        loc.diaryBookmarked,
      );
      tester.widget<FilterChip>(bookmarkFilter).onSelected!(true);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsIdentifier('userStatCard_${target.statUuid}'),
        findsNothing,
      );

      await tester.tap(find.bySemanticsIdentifier('diaryMonthStrip'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          '${target.createdAt.toLocal().day}, ${loc.diaryMonthBrews(1)}',
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(bookmarkFilter).selected, isFalse);
      expect(find.text(loc.diaryFiltersClearedForDay), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('userStatCard_${target.statUuid}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier(_dateHeaderId(target.createdAt.toLocal())),
        findsOneWidget,
      );
      final listTop = tester
          .getTopLeft(find.byType(ScrollablePositionedList))
          .dy;
      expect(
        tester
            .getTopLeft(
              find.bySemanticsIdentifier(
                _dateHeaderId(target.createdAt.toLocal()),
              ),
            )
            .dy,
        closeTo(listTop, AppSpacing.xs),
      );
    },
  );

  testWidgets(
    'up arrow restores the expanded historical calendar without changing filters',
    (tester) async {
      _useDiarySurface(tester);
      final now = DateTime.now();
      final entries = [
        for (var index = 0; index < 100; index++)
          _entry(
            'history-$index',
            now.subtract(Duration(days: index)).copyWith(hour: 8),
            rating: 5,
          ),
      ];
      final provider = MockUserStatProvider();
      _stubDiary(provider, entries);

      await tester.pumpWidget(_DiaryHarness(provider: provider));
      await tester.pumpAndSettle();
      final loc = AppLocalizations.of(
        tester.element(find.byType(BrewDiaryScreen)),
      )!;
      expect(
        find.bySemanticsIdentifier('diaryBackToCalendarButton'),
        findsNothing,
      );

      final ratingFilter = find.widgetWithText(
        FilterChip,
        loc.diaryRatingFourPlus,
      );
      tester.widget<FilterChip>(ratingFilter).onSelected!(true);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('diaryMonthStrip'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      final historicalMonth = DateTime(now.year, now.month - 1);
      final historicalLabel = DateFormat.yMMMM('en').format(historicalMonth);
      expect(find.text(historicalLabel), findsNWidgets(2));

      await tester.drag(
        find.byType(ScrollablePositionedList),
        const Offset(0, -8000),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsIdentifier('diaryBackToCalendarButton'),
        findsOneWidget,
      );
      expect(find.byTooltip(loc.diaryBackToCalendar), findsOneWidget);
      expect(find.bySemanticsIdentifier('diaryMonthStrip'), findsNothing);

      await tester.tap(find.bySemanticsIdentifier('diaryBackToCalendarButton'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('diaryMonthStrip'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text(historicalLabel), findsNWidgets(2));
      expect(tester.widget<FilterChip>(ratingFilter).selected, isTrue);
      expect(
        find.bySemanticsIdentifier('diaryBackToCalendarButton'),
        findsNothing,
      );
    },
  );

  testWidgets('up arrow remains hidden in grouped mode', (tester) async {
    _useDiarySurface(tester);
    final now = DateTime.now();
    final entries = [
      for (var index = 0; index < 80; index++)
        _entry(
          'grouped-$index',
          now.subtract(Duration(days: index)).copyWith(hour: 8),
        ),
    ];
    final provider = MockUserStatProvider();
    _stubDiary(provider, entries);

    await tester.pumpWidget(_DiaryHarness(provider: provider));
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BrewDiaryScreen)),
    )!;
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -8000),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsIdentifier('diaryBackToCalendarButton'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(Tab, loc.diaryGroupByBean));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('diaryBackToCalendarButton'),
      findsNothing,
    );
    expect(find.byType(ScrollablePositionedList), findsNothing);
    final logoSlot = find.byKey(const ValueKey('diaryGroupLogoSlot'));
    expect(logoSlot, findsOneWidget);
    expect(
      tester.getSize(logoSlot),
      const Size(
        AppSpacing.xxl + AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.sm,
      ),
    );
  });

  testWidgets(
    'current week digest is hidden and historical digest opens exact Stats week',
    (tester) async {
      _useDiarySurface(tester);
      final now = DateTime.now();
      final currentWeekStart = _weekStart(now);
      final historicalWeekStart = currentWeekStart.subtract(
        const Duration(days: 7),
      );
      final entries = [
        _entry('current-two', currentWeekStart.add(const Duration(days: 2))),
        _entry('current-one', currentWeekStart.add(const Duration(days: 1))),
        _entry(
          'historical-two',
          historicalWeekStart.add(const Duration(days: 2)),
        ),
        _entry(
          'historical-one',
          historicalWeekStart.add(const Duration(days: 1)),
        ),
      ];
      final provider = MockUserStatProvider();
      _stubDiary(provider, entries);
      final router = _RecordingStackRouter();

      await tester.pumpWidget(
        _DiaryHarness(provider: provider, router: router),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(BrewDiaryScreen));
      final loc = AppLocalizations.of(context)!;
      final formatService = Provider.of<DateTimeFormatService>(
        context,
        listen: false,
      );
      final dateFormat = DateFormat(
        formatService.datePattern(loc.dateFormat),
        'en',
      );

      expect(
        find.text(loc.diaryWeekOf(dateFormat.format(currentWeekStart))),
        findsNothing,
      );
      expect(
        find.bySemanticsIdentifier('userStatCard_current-one'),
        findsOneWidget,
      );
      final historicalTitle = loc.diaryWeekOf(
        dateFormat.format(historicalWeekStart),
      );
      expect(find.text(historicalTitle), findsOneWidget);
      final digest = find.bySemanticsIdentifier('diaryWeekDigest');
      await tester.ensureVisible(digest);
      expect(
        find.descendant(of: digest, matching: find.byIcon(Icons.chevron_right)),
        findsOneWidget,
      );

      await tester.tap(digest);
      await tester.pump();

      expect(router.pushedRoute, isA<StatsRoute>());
      final args = router.pushedRoute!.args as StatsRouteArgs;
      expect(args.initialStartDate, _civilDate(historicalWeekStart));
      expect(
        args.initialEndDate,
        _civilDate(historicalWeekStart.add(const Duration(days: 6))),
      );
    },
  );

  testWidgets('linked bean summary replaces details sheet with bean Journey', (
    tester,
  ) async {
    _useDiarySurface(tester);
    final now = DateTime.now();
    final entries = [
      _entry('journey-two', now.subtract(const Duration(days: 1))),
      _entry('journey-one', now.subtract(const Duration(days: 2))),
    ];
    final provider = MockUserStatProvider();
    _stubDiary(provider, entries);

    await tester.pumpWidget(_DiaryHarness(provider: provider));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('userStatCard_journey-two'));
    await tester.pumpAndSettle();
    expect(find.byType(BrewDetailSheet), findsOneWidget);
    expect(find.byKey(const Key('beanDetailsButton')), findsNothing);

    await tester.tap(find.byKey(const Key('beanSummaryButton')));
    await tester.pumpAndSettle();

    expect(find.byType(BrewDetailSheet), findsNothing);
    expect(find.byType(JourneyView), findsOneWidget);
    expect(find.text('Test beans'), findsWidgets);
  });

  test('screen contains no estimated-height or target GlobalKey path', () {
    final source = File(
      'lib/screens/brew_diary_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ItemScrollController'));
    expect(source, contains('ScrollablePositionedList.builder'));
    expect(source, isNot(contains('estimatedTimelineHeight')));
    expect(source, isNot(contains('_cardKeys')));
    expect(source, isNot(contains('_monthStripKey')));
    expect(source, isNot(contains('Scrollable.ensureVisible')));
    expect(source, isNot(contains('GlobalKey')));
  });
}

void _useDiarySurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _stubDiary(UserStatProvider provider, List<DiaryEntry> entries) {
  when(provider.fetchDiaryEntries('en')).thenAnswer((_) async => entries);
  when(provider.fetchDiaryEntries('de')).thenAnswer((_) async => entries);
  when(provider.topMethodsLast90Days('en')).thenAnswer((_) async => const []);
  when(provider.topMethodsLast90Days('de')).thenAnswer((_) async => const []);
}

List<DiaryEntry> _multiBrewCurrentMonthEntries(
  DateTime now, {
  required double targetRating,
}) {
  final lastDay = now.day.clamp(8, 14);
  final targetDay = (lastDay / 2).floor();
  return [
    for (var day = lastDay; day >= 1; day--)
      if (day == targetDay) ...[
        _entry(
          'target-late',
          DateTime(now.year, now.month, day, 18),
          rating: targetRating,
        ),
        _entry(
          'target-middle',
          DateTime(now.year, now.month, day, 12),
          rating: targetRating,
        ),
        _entry(
          'target-early',
          DateTime(now.year, now.month, day, 8),
          rating: targetRating,
        ),
      ] else
        _entry(
          'day-$day',
          DateTime(now.year, now.month, day, 8),
          rating: targetRating,
        ),
  ];
}

List<DiaryEntry> _filterResetEntries(DateTime now) {
  final lastDay = now.day.clamp(8, 14);
  final targetDay = (lastDay / 2).floor();
  return [
    for (var day = lastDay; day >= 1; day--)
      _entry(
        day == targetDay ? 'filter-target' : 'filter-day-$day',
        DateTime(now.year, now.month, day, 8),
        isMarked: day == lastDay,
      ),
  ];
}

String _dateHeaderId(DateTime date) {
  final local = date.toLocal();
  return 'diaryDateHeader_${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime _weekStart(DateTime date) {
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String _civilDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DiaryEntry _entry(
  String id,
  DateTime localCreatedAt, {
  String? recipeName,
  String? notes,
  double? rating,
  bool isMarked = false,
}) {
  return DiaryEntry(
    statUuid: id,
    recipeId: 'recipe-$id',
    recipeName: recipeName ?? 'Recipe $id',
    brewingMethodId: 'v60',
    methodName: 'V60',
    createdAt: localCreatedAt.toUtc(),
    coffeeAmount: 15,
    waterAmount: 250,
    grindSize: id.hashCode.isEven ? '24 clicks' : null,
    waterTemp: 93,
    tasteBalance: id.hashCode % 3,
    entrySource: 1,
    rating: rating,
    isMarked: isMarked,
    notes: notes,
    coffeeBeansUuid: 'bean-1',
    beanName: 'Test beans',
    origin: 'Kenya',
  );
}

class _PopupCountingObserver extends NavigatorObserver {
  int popupPushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PopupRoute<dynamic>) popupPushes++;
  }
}

class _DiaryHarness extends StatefulWidget {
  const _DiaryHarness({
    super.key,
    required this.provider,
    this.initialStatUuid,
    this.navigatorObserver,
    this.scaffoldMessengerKey,
    this.router,
  });

  final UserStatProvider provider;
  final String? initialStatUuid;
  final NavigatorObserver? navigatorObserver;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final StackRouter? router;

  @override
  State<_DiaryHarness> createState() => _DiaryHarnessState();
}

class _DiaryHarnessState extends State<_DiaryHarness> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    Widget app = MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatProvider>.value(value: widget.provider),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
        navigatorObservers: [?widget.navigatorObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        home: BrewDiaryScreen(
          key: const ValueKey('brewDiary'),
          initialExpandedStatUuid: widget.initialStatUuid,
        ),
      ),
    );
    if (widget.router != null) {
      app = StackRouterScope(
        controller: widget.router!,
        stateHash: 0,
        child: app,
      );
    }
    return app;
  }
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
