import 'dart:ui' as ui;

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Journey method and chart models', () {
    test(
      'sorts source explicitly and methods by latest brew then name and id',
      () {
        final entries = [
          _entry(
            id: 'old-v60',
            methodId: 'v60',
            methodName: 'V60',
            createdAt: DateTime(2026, 7, 1),
          ),
          _entry(
            id: 'latest-z',
            methodId: 'z-method',
            methodName: 'Same',
            createdAt: DateTime(2026, 7, 4),
          ),
          _entry(
            id: 'latest-a',
            methodId: 'a-method',
            methodName: 'Same',
            createdAt: DateTime(2026, 7, 4),
          ),
          _entry(
            id: 'new-v60',
            methodId: 'v60',
            methodName: 'V60',
            createdAt: DateTime(2026, 7, 3),
          ),
          _entry(
            id: 'aero',
            methodId: 'aeropress',
            methodName: 'AeroPress',
            createdAt: DateTime(2026, 7, 2),
          ),
        ];

        final series = buildJourneyMethodSeries(entries.reversed);

        expect(series.map((method) => method.methodId), [
          'a-method',
          'z-method',
          'v60',
          'aeropress',
        ]);
        expect(
          series
              .firstWhere((method) => method.methodId == 'v60')
              .entries
              .map((entry) => entry.statUuid),
          ['old-v60', 'new-v60'],
        );
        expect(entries.first.statUuid, 'old-v60');
      },
    );

    test('sparse chart connects only known points across missing ratings', () {
      final data = JourneyChartData.fromEntries([
        _entry(id: 'latest-unrated', day: 4),
        _entry(id: 'rated-best', day: 3, rating: 5),
        _entry(id: 'gap', day: 2),
        _entry(id: 'rated-old', day: 1, rating: 3),
      ]);

      expect(data.points.map((point) => point.entry.statUuid), [
        'rated-old',
        'gap',
        'rated-best',
        'latest-unrated',
      ]);
      expect(data.evaluatedCount, 2);
      expect(data.connections, hasLength(1));
      expect(data.connections.single.fromAttemptIndex, 0);
      expect(data.connections.single.toAttemptIndex, 2);
      expect(data.bestAttemptIndex, 2);
      expect(data.points.map((point) => point.attemptLabel), [
        '#1',
        '#2',
        '#3',
        '#4',
      ]);
      expect(data.points.map((point) => point.ratingLabel), [
        '3.0',
        null,
        '5.0',
        null,
      ]);
    });

    test('zero, one, and all-rated histories produce honest connections', () {
      final zero = JourneyChartData.fromEntries([
        _entry(id: 'zero-1', day: 1),
        _entry(id: 'zero-2', day: 2),
      ]);
      final one = JourneyChartData.fromEntries([
        _entry(id: 'one-1', day: 1),
        _entry(id: 'one-2', day: 2, rating: 4),
      ]);
      final all = JourneyChartData.fromEntries([
        _entry(id: 'all-1', day: 1, rating: 2),
        _entry(id: 'all-2', day: 2, rating: 3),
        _entry(id: 'all-3', day: 3, rating: 4),
      ]);

      expect(zero.connections, isEmpty);
      expect(zero.bestAttemptIndex, isNull);
      expect(one.connections, isEmpty);
      expect(one.bestAttemptIndex, 1);
      expect(all.connections, hasLength(2));
    });

    test(
      'best-cup rating ties resolve to the newest deterministic attempt',
      () {
        final data = JourneyChartData.fromEntries([
          _entry(id: 'same-time-a', day: 1, rating: 5),
          _entry(id: 'same-time-z', day: 1, rating: 5),
          _entry(id: 'older-low', day: 0, rating: 4),
        ]);

        expect(
          data.points[data.bestAttemptIndex!].entry.statUuid,
          'same-time-z',
        );
      },
    );

    test('valley and best-cup labels stay below their points', () {
      final data = JourneyChartData.fromEntries([
        _entry(id: 'high-old', day: 1, rating: 5),
        _entry(id: 'valley', day: 2, rating: 4.5),
        _entry(id: 'high-best', day: 3, rating: 5),
      ]);

      expect(
        data.ratingLabelPlacementFor(0),
        JourneyRatingLabelPlacement.above,
      );
      expect(
        data.ratingLabelPlacementFor(1),
        JourneyRatingLabelPlacement.below,
      );
      expect(
        data.ratingLabelPlacementFor(2),
        JourneyRatingLabelPlacement.below,
      );
    });
  });

  testWidgets('bean count treats only ratings as evaluated', (tester) async {
    final semantics = tester.ensureSemantics();
    final entries = [
      _entry(id: 'rated', day: 1, rating: 4),
      _entry(id: 'taste-only', day: 2, tasteBalance: 0),
      _entry(id: 'empty', day: 3),
    ];
    await _pumpProgress(tester, entries: entries);
    final loc = _localizations(tester);

    expect(find.text(loc.journeyProgress), findsOneWidget);
    expect(find.text(loc.journeyEvaluatedCount(1, 3)), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(loc.journeyProgressChartLabel('V60', 1, 3))),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'actionable progress header owns its label and expanded semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProgress(
        tester,
        entries: [
          _entry(id: 'rated', rating: 4),
          _entry(id: 'unrated', day: 2),
        ],
      );
      final loc = _localizations(tester);
      final header = find.bySemanticsLabel(loc.journeyProgress);
      final semanticHeader = find.semantics.byLabel(loc.journeyProgress);

      expect(header, findsOneWidget);
      var data = tester.getSemantics(header).getSemanticsData();
      expect(data.label, loc.journeyProgress);
      expect(data.value, loc.journeyEvaluatedCount(1, 2));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isExpanded, ui.Tristate.isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);

      tester.semantics.tap(semanticHeader);
      await tester.pumpAndSettle();

      expect(header, findsOneWidget);
      data = tester.getSemantics(header).getSemanticsData();
      expect(data.label, loc.journeyProgress);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isExpanded, ui.Tristate.isFalse);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(
        find.byKey(const ValueKey('journeyProgressChartPaint')),
        findsNothing,
      );
      semantics.dispose();
    },
  );

  testWidgets('four methods share one newest-first selector and one chart', (
    tester,
  ) async {
    final entries = [
      _entry(
        id: 'origami',
        methodId: 'origami',
        methodName: 'Origami',
        day: 4,
        rating: 5,
      ),
      _entry(id: 'v60', methodId: 'v60', methodName: 'V60', day: 3),
      _entry(
        id: 'aero',
        methodId: 'aeropress',
        methodName: 'AeroPress',
        day: 2,
      ),
      _entry(
        id: 'press',
        methodId: 'frenchpress',
        methodName: 'French Press',
        day: 1,
      ),
    ];
    await _pumpProgress(tester, entries: entries);
    final loc = _localizations(tester);

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.text(loc.journeyMethodSelectorLabel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('journeyProgressChartPaint')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('journeyMethodName_origami')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('journeyMethodSelector')));
    await tester.pumpAndSettle();
    final optionCenters = <String, double>{
      for (final id in ['origami', 'v60', 'aeropress', 'frenchpress'])
        id: tester
            .getCenter(find.byKey(ValueKey('journeyMethodOption_$id')))
            .dy,
    };
    expect(optionCenters['origami']!, lessThan(optionCenters['v60']!));
    expect(optionCenters['v60']!, lessThan(optionCenters['aeropress']!));
    expect(
      optionCenters['aeropress']!,
      lessThan(optionCenters['frenchpress']!),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('journeyMethodOption_origami')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('collapse and expand retain the selected method', (tester) async {
    final entries = [
      _entry(id: 'new-v60', methodId: 'v60', methodName: 'V60', day: 3),
      _entry(
        id: 'aero',
        methodId: 'aeropress',
        methodName: 'AeroPress',
        day: 2,
      ),
    ];
    await _pumpProgress(tester, entries: entries);
    final loc = _localizations(tester);

    await tester.tap(find.byKey(const ValueKey('journeyMethodSelector')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('journeyMethodOption_aeropress')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('journeyMethodName_aeropress')),
      findsOneWidget,
    );

    await tester.tap(find.text(loc.journeyProgress));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('journeyMethodName_aeropress')),
      findsNothing,
    );

    await tester.tap(find.text(loc.journeyProgress));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('journeyMethodName_aeropress')),
      findsOneWidget,
    );
  });

  testWidgets('adaptive action targets the selected method latest entry', (
    tester,
  ) async {
    DiaryEntry? captured;
    final entries = [
      _entry(
        id: 'v60-latest-rated',
        methodId: 'v60',
        methodName: 'V60',
        day: 4,
        rating: 4,
      ),
      _entry(
        id: 'aero-old',
        methodId: 'aeropress',
        methodName: 'AeroPress',
        day: 1,
      ),
      _entry(
        id: 'aero-latest',
        methodId: 'aeropress',
        methodName: 'AeroPress',
        day: 3,
      ),
    ];
    await _pumpProgress(
      tester,
      entries: entries,
      onEvaluateLatest: (entry) async => captured = entry,
    );
    final loc = _localizations(tester);

    expect(find.text(loc.journeyEditLatestRating), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journeyMethodSelector')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('journeyMethodOption_aeropress')),
    );
    await tester.pumpAndSettle();
    expect(find.text(loc.journeyEvaluateLatest), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('journeyEvaluateLatest')));
    await tester.pumpAndSettle();
    expect(captured?.statUuid, 'aero-latest');
  });

  testWidgets(
    'single unrated method has no menu and exposes the unrated state',
    (tester) async {
      await _pumpProgress(
        tester,
        entries: [
          _entry(id: 'one'),
          _entry(id: 'two', day: 2),
        ],
        brightness: Brightness.dark,
      );
      final loc = _localizations(tester);

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(
        find.byKey(const ValueKey('journeyMethodSelectorSingle')),
        findsOneWidget,
      );
      final unratedState = tester.widget<Text>(
        find.byKey(const ValueKey('journeyProgressUnratedState')),
      );
      expect(unratedState.data, loc.journeyEvaluatedBrewCount(0));
      final chartContext = tester.widget<Text>(
        find.byKey(const ValueKey('journeyProgressChartContext')),
      );
      expect(chartContext.data, contains(loc.journeyEvaluatedCount(0, 2)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('taste legend and points use the semantic taste palette', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpProgress(
      tester,
      entries: [
        _entry(id: 'sour', day: 1, rating: 5, tasteBalance: -1),
        _entry(id: 'balanced', day: 2, rating: 4.5, tasteBalance: 0),
        _entry(id: 'bitter', day: 3, rating: 5, tasteBalance: 1),
      ],
    );
    final loc = _localizations(tester);
    final chartPaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('journeyProgressChartPaint')),
    );
    final painter = chartPaint.painter! as JourneyProgressPainter;
    final brightness = painter.colorScheme.brightness;

    expect(find.byKey(const ValueKey('journeyTasteLegend')), findsOneWidget);
    expect(find.text(loc.tasteSour), findsOneWidget);
    expect(find.text(loc.tasteBalanced), findsOneWidget);
    expect(find.text(loc.tasteBitter), findsOneWidget);
    for (final point in painter.data.points) {
      expect(
        painter.colorForPoint(point),
        AppSemanticColors.taste(
          point.entry.tasteBalance!,
          brightness,
        ).background,
      );
    }
    final chartSemantics = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp('${loc.tasteSour}.*${loc.tasteBalanced}.*${loc.tasteBitter}'),
      ),
    );
    expect(chartSemantics.label, contains('#2: 4.5, ${loc.tasteBalanced}'));
    semantics.dispose();
  });

  testWidgets('chart semantics announce every visible attempt', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpProgress(
      tester,
      entries: [
        _entry(id: 'one', day: 1, rating: 3, tasteBalance: -1),
        _entry(id: 'two', day: 2),
        _entry(id: 'three', day: 3, rating: 4),
        _entry(id: 'four', day: 4, rating: 4.5, tasteBalance: 0),
        _entry(id: 'five', day: 5, rating: 5),
      ],
    );
    final loc = _localizations(tester);
    final chart = tester.getSemantics(
      find.bySemanticsLabel(RegExp(loc.journeyProgressChartLabel('V60', 4, 5))),
    );

    expect(chart.label, contains('#1: 3.0, ${loc.tasteSour}'));
    expect(chart.label, contains('#2: ${loc.brewDiaryNotRated}'));
    expect(chart.label, contains('#3: 4.0'));
    expect(chart.label, contains('#4: 4.5, ${loc.tasteBalanced}'));
    expect(chart.label, contains('#5: 5.0'));
    semantics.dispose();
  });

  testWidgets('rating-only points stay neutral and omit the taste legend', (
    tester,
  ) async {
    await _pumpProgress(tester, entries: [_entry(id: 'rated', rating: 4.5)]);
    final chartPaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('journeyProgressChartPaint')),
    );
    final painter = chartPaint.painter! as JourneyProgressPainter;

    expect(find.byKey(const ValueKey('journeyTasteLegend')), findsNothing);
    expect(
      painter.colorForPoint(painter.data.points.single),
      painter.colorScheme.primary,
    );
  });

  testWidgets('dark chart uses the dark semantic taste palette', (
    tester,
  ) async {
    await _pumpProgress(
      tester,
      entries: [_entry(id: 'balanced', rating: 4.5, tasteBalance: 0)],
      brightness: Brightness.dark,
    );
    final chartPaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('journeyProgressChartPaint')),
    );
    final painter = chartPaint.painter! as JourneyProgressPainter;

    expect(
      painter.colorForPoint(painter.data.points.single),
      AppSemanticColors.taste(0, Brightness.dark).background,
    );
  });

  testWidgets(
    'long history is compact at 390 width and painter honors text scaling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final entries = [
        for (var index = 0; index < 20; index++)
          _entry(
            id: 'attempt-$index',
            methodName:
                'An exceptionally long brewing method name that must truncate',
            createdAt: DateTime(2026, 7, 1).add(Duration(days: index)),
            rating: index.isEven ? 3 + (index % 3) * 0.5 : null,
            tasteBalance: index.isEven ? index % 3 - 1 : null,
          ),
      ];

      for (final textScaler in [
        TextScaler.noScaling,
        const TextScaler.linear(1.3),
      ]) {
        await _pumpProgress(tester, entries: entries, textScaler: textScaler);

        final scroll = tester.widget<SingleChildScrollView>(
          find.byKey(const ValueKey('journeyProgressChartScroll')),
        );
        expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
        expect(
          scroll.controller!.position.pixels,
          scroll.controller!.position.maxScrollExtent,
        );
        final customPaint = tester.widget<CustomPaint>(
          find.byKey(const ValueKey('journeyProgressChartPaint')),
        );
        final painter = customPaint.painter! as JourneyProgressPainter;
        expect(painter.textScaler, textScaler);
        expect(
          painter.labelStyle,
          Theme.of(
            tester.element(
              find.byKey(const ValueKey('journeyProgressChartPaint')),
            ),
          ).textTheme.labelSmall,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}

Future<void> _pumpProgress(
  WidgetTester tester, {
  required List<DiaryEntry> entries,
  EvaluateLatestCallback? onEvaluateLatest,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: textScaler,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: JourneyProgress(
              entries: entries,
              onEvaluateLatest: onEvaluateLatest ?? (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _localizations(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(JourneyProgress)))!;

DiaryEntry _entry({
  required String id,
  String methodId = 'v60',
  String methodName = 'V60',
  int day = 1,
  DateTime? createdAt,
  double? rating,
  int? tasteBalance,
}) => DiaryEntry(
  statUuid: id,
  recipeId: 'recipe-$id',
  recipeName: 'Recipe $id',
  brewingMethodId: methodId,
  methodName: methodName,
  createdAt: createdAt ?? DateTime(2026, 7, day),
  coffeeAmount: 15,
  waterAmount: 250,
  tasteBalance: tasteBalance,
  rating: rating,
  isMarked: false,
);
