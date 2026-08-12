import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/extraction_math.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_entry_card.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_view.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('bean comparison stays within each method series', (
    tester,
  ) async {
    final v60Old = _entry(
      id: 'v60-1',
      methodId: 'v60',
      methodName: 'V60',
      createdAt: DateTime(2026, 7, 1, 9),
      coffeeAmount: 15,
      waterAmount: 250,
    );
    final v60New = _entry(
      id: 'v60-2',
      methodId: 'v60',
      methodName: 'V60',
      createdAt: DateTime(2026, 7, 2, 9),
      coffeeAmount: 16,
      waterAmount: 260,
    );
    final aeroOld = _entry(
      id: 'aero-1',
      methodId: 'aeropress',
      methodName: 'AeroPress',
      createdAt: DateTime(2026, 7, 1, 10),
      coffeeAmount: 20,
      waterAmount: 300,
    );
    final aeroNew = _entry(
      id: 'aero-2',
      methodId: 'aeropress',
      methodName: 'AeroPress',
      createdAt: DateTime(2026, 7, 2, 10),
      coffeeAmount: 21,
      waterAmount: 310,
    );
    await _pumpJourney(tester, entries: [v60New, aeroOld, v60Old, aeroNew]);
    final loc = _localizations(tester);

    final aeroCompare = find.byKey(const ValueKey('journeyCompare_aeropress'));
    expect(aeroCompare, findsOneWidget);
    final aeroLabels = _expectedLabels([aeroOld, aeroNew], loc);
    await tester.ensureVisible(aeroCompare);
    await tester.tap(aeroCompare);
    await tester.pumpAndSettle();
    _expectPickerLabels(tester, [
      aeroLabels[aeroOld.statUuid]!,
      aeroLabels[aeroNew.statUuid]!,
    ]);
    await _selectLabels(tester, [
      aeroLabels[aeroOld.statUuid]!,
      aeroLabels[aeroNew.statUuid]!,
    ]);
    final aeroPressSheet = find.byType(BottomSheet);
    expect(
      find.descendant(
        of: aeroPressSheet,
        matching: find.text('20\u00A0g → 300\u00A0g'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: aeroPressSheet,
        matching: find.text('15\u00A0g → 250\u00A0g'),
      ),
      findsNothing,
    );

    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    final v60Compare = find.byKey(const ValueKey('journeyCompare_v60'));
    expect(v60Compare, findsOneWidget);
    expect(find.text(v60Old.recipeName), findsOneWidget);
    expect(find.text(v60New.recipeName), findsOneWidget);
    final v60Labels = _expectedLabels([v60Old, v60New], loc);
    await tester.ensureVisible(v60Compare);
    await tester.tap(v60Compare);
    await tester.pumpAndSettle();
    _expectPickerLabels(tester, [
      v60Labels[v60Old.statUuid]!,
      v60Labels[v60New.statUuid]!,
    ]);
    await _selectLabels(tester, [
      v60Labels[v60Old.statUuid]!,
      v60Labels[v60New.statUuid]!,
    ]);
    final v60Sheet = find.byType(BottomSheet);
    expect(
      find.descendant(
        of: v60Sheet,
        matching: find.text('15\u00A0g → 250\u00A0g'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: v60Sheet,
        matching: find.text('20\u00A0g → 300\u00A0g'),
      ),
      findsNothing,
    );
  });

  testWidgets('method selector scopes progress without filtering attempts', (
    tester,
  ) async {
    final v60 = _entry(
      id: 'scope-v60',
      methodId: 'v60',
      methodName: 'V60',
      createdAt: DateTime(2026, 7, 1, 9),
    );
    final aero = _entry(
      id: 'scope-aero',
      methodId: 'aeropress',
      methodName: 'AeroPress',
      createdAt: DateTime(2026, 7, 2, 9),
    );
    await _pumpJourney(tester, entries: [v60, aero]);
    final loc = _localizations(tester);

    expect(find.text(loc.journeyMethodSelectorLabel), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('journeyAttempt_${v60.statUuid}'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('journeyAttempt_${aero.statUuid}'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('journeyProgressChartContext')),
          )
          .data,
      startsWith('AeroPress'),
    );

    await tester.tap(find.byKey(const ValueKey('journeyMethodSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journeyMethodOption_v60')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('journeyProgressChartContext')),
          )
          .data,
      startsWith('V60'),
    );
    expect(
      find.bySemanticsIdentifier('journeyAttempt_${v60.statUuid}'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('journeyAttempt_${aero.statUuid}'),
      findsOneWidget,
    );
  });

  testWidgets('bean header presents identity and opens the bean record', (
    tester,
  ) async {
    final router = _RecordingStackRouter();
    await _pumpJourney(
      tester,
      entries: [_entry(id: 'identity')],
      router: router,
    );
    final loc = _localizations(tester);

    expect(find.byIcon(Coffeico.bag_with_bean), findsOneWidget);
    expect(find.byIcon(Coffeico.bean), findsOneWidget);
    expect(find.text('Test beans'), findsNWidgets(2));
    expect(find.text('Test roaster'), findsOneWidget);
    expect(find.text('${loc.origin}: Kenya'), findsOneWidget);
    final header = find.bySemanticsIdentifier('journeyBeanHeader_bean-1');
    for (final summaryFragment in [
      loc.diaryGroupBrewCount(1),
      loc.formattedBrewingMethodCount(1),
      loc.journeyEvaluatedBrewCount(0),
    ]) {
      expect(
        find.descendant(of: header, matching: find.text(summaryFragment)),
        findsOneWidget,
      );
    }
    expect(
      find.bySemanticsIdentifier('journeyProgressSection'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    final logoSlot = find.byKey(const ValueKey('journeyBeanLogoSlot'));
    expect(
      tester.getSize(logoSlot),
      const Size(
        AppSpacing.xxl + AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.sm,
      ),
    );

    await tester.tap(find.bySemanticsIdentifier('journeyBeanHeader_bean-1'));
    await tester.pump();

    expect(router.pushedRoute, isA<CoffeeBeansDetailRoute>());
    final args = router.pushedRoute!.args as CoffeeBeansDetailRouteArgs;
    expect(args.uuid, 'bean-1');
  });

  testWidgets('bean header callback suppresses default bean-record push', (
    tester,
  ) async {
    final router = _RecordingStackRouter();
    var callbackInvoked = false;
    await _pumpJourney(
      tester,
      entries: [_entry(id: 'callback')],
      router: router,
      onBeanTap: () => callbackInvoked = true,
    );

    await tester.tap(find.bySemanticsIdentifier('journeyBeanHeader_bean-1'));
    await tester.pump();

    expect(callbackInvoked, isTrue);
    expect(router.pushedRoute, isNull);
  });

  testWidgets('attempt card reflects bookmark, notes, and extraction data', (
    tester,
  ) async {
    final entry = _entry(
      id: 'complete-state',
      isMarked: true,
      notes: 'Floral, juicy, and balanced',
      tdsPercent: 1.35,
      extractionYieldPercent: 20.4,
      tasteBalance: 0,
      rating: 4.5,
    );
    await _pumpJourney(tester, entries: [entry]);
    final loc = _localizations(tester);
    final card = find.bySemanticsIdentifier('journeyAttempt_${entry.statUuid}');

    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(BrewEntryCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.bookmark)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('journeyBookmark_${entry.statUuid}'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('Floral, juicy, and balanced'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(loc.extractionCalcDiaryLine('20.4', '1.35')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Balanced')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('★ 4.5')),
      findsOneWidget,
    );
    final extractionChip = tester.widget<Chip>(
      find.ancestor(
        of: find.text(loc.extractionCalcDiaryLine('20.4', '1.35')),
        matching: find.byType(Chip),
      ),
    );
    final tasteChip = tester.widget<Chip>(
      find.ancestor(of: find.text('Balanced'), matching: find.byType(Chip)),
    );
    final ratingChip = tester.widget<Chip>(
      find.ancestor(of: find.text('★ 4.5'), matching: find.byType(Chip)),
    );
    expect(
      extractionChip.backgroundColor,
      AppSemanticColors.extractionYield(
        ExtractionBand.target,
        Brightness.light,
      ).background,
    );
    expect(
      tasteChip.backgroundColor,
      AppSemanticColors.taste(0, Brightness.light).background,
    );
    expect(
      ratingChip.backgroundColor,
      AppSemanticColors.neutralChip(Brightness.light).background,
    );
  });

  testWidgets('methods and cards are newest-first with forward deltas', (
    tester,
  ) async {
    final v60Old = _entry(
      id: 'v60-old',
      methodId: 'v60',
      methodName: 'V60',
      createdAt: DateTime(2026, 7, 1, 9),
      coffeeAmount: 15,
    );
    final v60New = _entry(
      id: 'v60-new',
      methodId: 'v60',
      methodName: 'V60',
      createdAt: DateTime(2026, 7, 2, 9),
      coffeeAmount: 17,
    );
    final aeroLatest = _entry(
      id: 'aero-latest',
      methodId: 'aeropress',
      methodName: 'AeroPress',
      createdAt: DateTime(2026, 7, 3, 9),
    );
    await _pumpJourney(tester, entries: [v60Old, aeroLatest, v60New]);
    final loc = _localizations(tester);

    final aeroHeader = find.byKey(
      const ValueKey('journeyMethodHeader_aeropress'),
    );
    final v60Header = find.byKey(const ValueKey('journeyMethodHeader_v60'));
    expect(
      tester.getTopLeft(aeroHeader).dy,
      lessThan(tester.getTopLeft(v60Header).dy),
    );
    expect(
      tester
          .getTopLeft(
            find.bySemanticsIdentifier('journeyAttempt_${v60New.statUuid}'),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.bySemanticsIdentifier('journeyAttempt_${v60Old.statUuid}'),
            )
            .dy,
      ),
    );
    expect(find.text('${loc.coffeeamount} +2'), findsOneWidget);
  });

  testWidgets('focused evaluation targets latest and refreshes local journey', (
    tester,
  ) async {
    final stats = _RecordingRatingProvider();
    final older = _entry(id: 'older', createdAt: DateTime(2026, 7, 1, 9));
    final latest = _entry(id: 'latest', createdAt: DateTime(2026, 7, 2, 9));
    await _pumpJourney(tester, entries: [older, latest], statsProvider: stats);
    final loc = _localizations(tester);
    final latestCard = find.bySemanticsIdentifier(
      'journeyAttempt_${latest.statUuid}',
    );
    expect(
      find.descendant(
        of: latestCard,
        matching: find.text(loc.brewDiaryNotRated),
      ),
      findsNothing,
    );

    final evaluate = find.byKey(const ValueKey('journeyEvaluateLatest'));
    await tester.ensureVisible(evaluate);
    await tester.tap(evaluate);
    // The progress action stays in its loading state while the dialog is open,
    // so an indeterminate spinner intentionally prevents pumpAndSettle here.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('focusedRatingBar')));
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(stats.statUuid, latest.statUuid);
    expect(stats.rating, isNotNull);
    final header = find.bySemanticsIdentifier('journeyBeanHeader_bean-1');
    for (final summaryFragment in [
      loc.diaryGroupBrewCount(2),
      loc.formattedBrewingMethodCount(1),
      loc.journeyEvaluatedBrewCount(1),
    ]) {
      expect(
        find.descendant(of: header, matching: find.text(summaryFragment)),
        findsOneWidget,
      );
    }
    expect(find.text(loc.journeyEvaluatedCount(1, 2)), findsOneWidget);
    expect(
      find.descendant(
        of: latestCard,
        matching: find.text('★ ${stats.rating!.toStringAsFixed(1)}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('attempt card shows up to 3 tag chips plus an overflow chip', (
    tester,
  ) async {
    final entry = _entry(
      id: 'five-tags',
      tags: 'fruity, bright, floral, clean, sweet',
    );
    await _pumpJourney(tester, entries: [entry]);
    final card = find.bySemanticsIdentifier('journeyAttempt_${entry.statUuid}');

    for (final label in ['#fruity', '#bright', '#floral', '+2']) {
      expect(
        find.descendant(of: card, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: card, matching: find.text('#clean')),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('#sweet')),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('#clean')),
      findsNothing,
    );
  });

  testWidgets('derived water temp chip renders with a tilde prefix', (
    tester,
  ) async {
    final entry = _entry(id: 'derived-temp', waterTempIsDerived: true);
    await _pumpJourney(tester, entries: [entry]);

    expect(find.text('~93°'), findsOneWidget);
  });

  testWidgets('both-derived equal water temps produce no held chip', (
    tester,
  ) async {
    await _pumpJourney(
      tester,
      entries: [
        _entry(
          id: 'one',
          createdAt: DateTime(2026, 7, 1, 9),
          waterTempIsDerived: true,
        ),
        _entry(
          id: 'two',
          createdAt: DateTime(2026, 7, 2, 9),
          waterTempIsDerived: true,
        ),
      ],
    );
    final loc = _localizations(tester);

    expect(find.text(loc.journeyHeld(loc.watertemp)), findsNothing);
  });

  testWidgets('matching clicks context yields a numeric grind delta', (
    tester,
  ) async {
    await _pumpJourney(
      tester,
      entries: [
        _entry(id: 'one', grindSize: '24 clicks'),
        _entry(id: 'two', grindSize: '26 CLICKS'),
      ],
    );
    final loc = _localizations(tester);

    expect(find.text('${loc.grindsize} +2'), findsOneWidget);
  });

  testWidgets('matching parenthesized grinder context yields numeric delta', (
    tester,
  ) async {
    await _pumpJourney(
      tester,
      entries: [
        _entry(id: 'one', grindSize: '2,4 (Ode)'),
        _entry(id: 'two', grindSize: '3.0 ode'),
      ],
    );
    final loc = _localizations(tester);

    expect(find.text('${loc.grindsize} +0.6'), findsOneWidget);
  });

  testWidgets('different grind contexts show the raw transition', (
    tester,
  ) async {
    await _pumpJourney(
      tester,
      entries: [
        _entry(id: 'one', grindSize: '24 clicks'),
        _entry(id: 'two', grindSize: '2.4 (Ode)'),
      ],
    );
    final loc = _localizations(tester);

    expect(find.text('24 clicks → 2.4 (Ode)'), findsOneWidget);
    expect(find.text('${loc.grindsize} -21.6'), findsNothing);
  });

  testWidgets('journey captions follow selected date and time styles', (
    tester,
  ) async {
    final formatService = DateTimeFormatService();
    await formatService.setDateStyle(DateStyle.ymd);
    await formatService.setTimeStyle(TimeStyle.h24);
    final createdAt = DateTime.utc(2026, 7, 1, 13, 5);
    final localCreatedAt = createdAt.toLocal();

    await _pumpJourney(
      tester,
      entries: [_entry(id: 'one', createdAt: createdAt)],
      formatService: formatService,
    );
    expect(
      find.text(DateFormat('yyyy-MM-dd', 'en').format(localCreatedAt)),
      findsOneWidget,
    );
    expect(
      find.text(DateFormat('HH:mm', 'en').format(localCreatedAt)),
      findsOneWidget,
    );

    await formatService.setDateStyle(DateStyle.dmy);
    await formatService.setTimeStyle(TimeStyle.h12);
    await tester.pump();
    expect(
      find.text(DateFormat('dd/MM/yyyy', 'en').format(localCreatedAt)),
      findsOneWidget,
    );
    expect(
      find.text(DateFormat('hh:mm a', 'en').format(localCreatedAt)),
      findsOneWidget,
    );
  });

  testWidgets('ratio delta is resolved through localization', (tester) async {
    await _pumpJourney(
      tester,
      locale: const Locale('de'),
      entries: [
        _entry(id: 'one', coffeeAmount: 10, waterAmount: 150),
        _entry(id: 'two', coffeeAmount: 10, waterAmount: 160),
      ],
    );
    final loc = _localizations(tester);

    expect(find.text(loc.journeyRatioDelta('+1')), findsOneWidget);
    expect(find.text('Ratio +1'), findsNothing);
  });

  testWidgets(
    'comparison styles only changes and marks contextual best-cup values',
    (tester) async {
      final lower = _entry(
        id: 'low-rated',
        createdAt: DateTime(2026, 7, 1, 9),
        rating: 3.0,
        tasteBalance: 0,
      );
      final higher = _entry(
        id: 'high-rated',
        createdAt: DateTime(2026, 7, 2, 9),
        rating: 4.5,
        tasteBalance: 1,
      );
      await _pumpJourney(tester, entries: [lower, higher]);
      final loc = _localizations(tester);
      final labels = _expectedLabels([lower, higher], loc);

      await tester.tap(find.byKey(const ValueKey('journeyCompare_v60')));
      await tester.pumpAndSettle();
      await _selectLabels(tester, [
        labels[lower.statUuid]!,
        labels[higher.statUuid]!,
      ]);

      Container cell(String field, String side) => tester.widget<Container>(
        find.descendant(
          of: find.byKey(ValueKey('journeyComparison_${field}_$side')),
          matching: find.byType(Container),
        ),
      );

      for (final unchanged in [
        'doseWater',
        'ratio',
        'grind',
        'temperature',
        'extraction',
      ]) {
        expect(cell(unchanged, 'first').decoration, isNull);
        expect(cell(unchanged, 'second').decoration, isNull);
      }
      for (final changed in ['taste', 'rating']) {
        expect(cell(changed, 'first').decoration, isNotNull);
        expect(cell(changed, 'second').decoration, isNotNull);
      }
      final winningDecoration =
          cell('rating', 'second').decoration! as BoxDecoration;
      expect((winningDecoration.border! as Border).top.width, AppStroke.border);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journeyComparison_rating_second')),
          matching: find.byIcon(Icons.workspace_premium_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journeyComparison_taste_second')),
          matching: find.byIcon(Icons.workspace_premium_outlined),
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          '${loc.journeyChanged(loc.brewDiaryTasted)}: '
          '${loc.tasteBalanced}, ${loc.journeyBetterTaste}',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          '${loc.journeyChanged(loc.rating)}: ★4.5, ${loc.journeyBestCup}',
        ),
        findsOneWidget,
      );

      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();

      final unratedFirst = _entry(
        id: 'no-rating-1',
        createdAt: DateTime(2026, 7, 1, 9),
      );
      final unratedSecond = _entry(
        id: 'no-rating-2',
        createdAt: DateTime(2026, 7, 2, 9),
      );
      await _pumpJourney(tester, entries: [unratedFirst, unratedSecond]);
      final unratedLoc = _localizations(tester);
      final unratedLabels = _expectedLabels([
        unratedFirst,
        unratedSecond,
      ], unratedLoc);

      await tester.tap(find.byKey(const ValueKey('journeyCompare_v60')));
      await tester.pumpAndSettle();
      await _selectLabels(tester, [
        unratedLabels[unratedFirst.statUuid]!,
        unratedLabels[unratedSecond.statUuid]!,
      ]);

      expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
    },
  );

  testWidgets('comparison models missing values and ties honestly', (
    tester,
  ) async {
    final first = _entry(
      id: 'missing-first',
      grindSize: null,
      extractionYieldPercent: null,
      rating: 4,
    );
    final second = _entry(
      id: 'missing-second',
      grindSize: '24 clicks',
      extractionYieldPercent: null,
      rating: 4,
    );
    await _pumpJourney(tester, entries: [first, second]);
    final rows = buildJourneyComparisonRows(
      first,
      second,
      _localizations(tester),
    );

    expect(
      rows
          .singleWhere((row) => row.field == JourneyComparisonField.grind)
          .changed,
      isTrue,
    );
    expect(
      rows
          .singleWhere((row) => row.field == JourneyComparisonField.extraction)
          .changed,
      isFalse,
    );
    expect(rows.every((row) => row.bestCupSide == null), isTrue);
  });

  testWidgets('equal ratings give Balanced only the better-taste result', (
    tester,
  ) async {
    final sour = _entry(
      id: 'equal-sour',
      createdAt: DateTime(2026, 7, 1, 9),
      rating: 4,
      tasteBalance: -1,
    );
    final balanced = _entry(
      id: 'equal-balanced',
      createdAt: DateTime(2026, 7, 2, 9),
      rating: 4,
      tasteBalance: 0,
    );
    await _pumpJourney(tester, entries: [sour, balanced]);
    final loc = _localizations(tester);
    final labels = _expectedLabels([sour, balanced], loc);

    await tester.tap(find.byKey(const ValueKey('journeyCompare_v60')));
    await tester.pumpAndSettle();
    await _selectLabels(tester, [
      labels[sour.statUuid]!,
      labels[balanced.statUuid]!,
    ]);

    expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('journeyComparison_taste_second')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('journeyComparison_taste_first')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(
        '${loc.journeyChanged(loc.brewDiaryTasted)}: '
        '${loc.tasteBalanced}, ${loc.journeyBetterTaste}',
      ),
      findsOneWidget,
    );
    final ratingRows = buildJourneyComparisonRows(sour, balanced, loc);
    expect(ratingRows.every((row) => row.bestCupSide == null), isTrue);
    expect(
      ratingRows
          .singleWhere((row) => row.field == JourneyComparisonField.taste)
          .betterTasteSide,
      JourneyComparisonSide.second,
    );
    expect(
      ratingRows
          .where((row) => row.field != JourneyComparisonField.taste)
          .every((row) => row.betterTasteSide == null),
      isTrue,
    );
  });

  testWidgets('comparison field labels wrap between words at large text', (
    tester,
  ) async {
    // Keep the real phone width that constrains the comparison columns. The
    // taller test viewport avoids an unrelated lazy-list scroll in setup.
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entries = [
      _entry(id: 'label-first', createdAt: DateTime(2026, 7, 1, 9)),
      _entry(id: 'label-second', createdAt: DateTime(2026, 7, 2, 9)),
    ];
    await tester.pumpWidget(
      ChangeNotifierProvider<DateTimeFormatService>.value(
        value: DateTimeFormatService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: JourneyView(group: _beanGroup(entries)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final compare = find.byKey(
      const ValueKey('journeyCompare_v60'),
      skipOffstage: false,
    );
    await tester.ensureVisible(compare);
    await tester.tap(compare);
    await tester.pumpAndSettle();
    final loc = _localizations(tester);
    final labels = _expectedLabels(entries, loc);
    await _selectLabels(tester, [
      labels[entries.first.statUuid]!,
      labels[entries.last.statUuid]!,
    ]);

    final temperatureLabel = find.byKey(
      const ValueKey('journeyComparisonLabel_temperature'),
    );
    expect(
      find.descendant(of: temperatureLabel, matching: find.text('Water')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: temperatureLabel, matching: find.text('Temperature')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a journey entry card opens the brew detail sheet', (
    tester,
  ) async {
    final entry = _entry(id: 'detail', createdAt: DateTime(2026, 7, 1, 9));
    await _pumpJourney(tester, entries: [entry]);

    await tester.tap(find.text(entry.recipeName));
    await tester.pumpAndSettle();

    expect(find.byType(BrewDetailSheet), findsOneWidget);
  });

  testWidgets('rating saved in attempt details refreshes the owning journey', (
    tester,
  ) async {
    final stats = _RecordingRatingProvider();
    final entry = _entry(id: 'detail-rating');
    await _pumpJourney(tester, entries: [entry], statsProvider: stats);

    await tester.tap(find.text(entry.recipeName));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('editRatingButton')));
    await tester.tap(find.byKey(const Key('editRatingButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focusedRatingBar')));
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(stats.statUuid, entry.statUuid);
    expect(stats.rating, isNotNull);
    Navigator.of(tester.element(find.byType(BrewDetailSheet))).pop();
    await tester.pumpAndSettle();
    final card = find.bySemanticsIdentifier('journeyAttempt_${entry.statUuid}');
    expect(
      find.descendant(
        of: card,
        matching: find.text('★ ${stats.rating!.toStringAsFixed(1)}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('taste saved in attempt details refreshes the owning journey', (
    tester,
  ) async {
    final stats = _RecordingRatingProvider();
    final entry = _entry(id: 'detail-taste', tasteBalance: 0);
    await _pumpJourney(tester, entries: [entry], statsProvider: stats);

    await tester.tap(find.text(entry.recipeName));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('editTasteButton')));
    await tester.tap(find.byKey(const Key('editTasteButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Bitter'));
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(stats.tasteBalance, 1);
    Navigator.of(tester.element(find.byType(BrewDetailSheet))).pop();
    await tester.pumpAndSettle();
    final card = find.bySemanticsIdentifier('journeyAttempt_${entry.statUuid}');
    expect(
      find.descendant(of: card, matching: find.text('Bitter')),
      findsOneWidget,
    );
  });

  testWidgets('compare sheet scrolls instead of overflowing on phone screens', (
    tester,
  ) async {
    // Deliberately phone-sized: the shared _pumpJourney helper uses an
    // oversized viewport, which is exactly how the original overflow
    // (long recipe·date chip labels + comparison table) went unnoticed.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entries = [
      for (var index = 0; index < 5; index++)
        _entry(
          id: 'long-recipe-name-brew-attempt-number-$index',
          createdAt: DateTime(2026, 6, 7 + index, 9),
        ),
    ];
    await tester.pumpWidget(
      ChangeNotifierProvider<DateTimeFormatService>.value(
        value: DateTimeFormatService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: JourneyView(group: _beanGroup(entries)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final compare = find.byKey(
      const ValueKey('journeyCompare_v60'),
      skipOffstage: false,
    );
    await tester.ensureVisible(compare);
    await tester.pumpAndSettle();
    await tester.tap(compare);
    await tester.pumpAndSettle();

    final chips = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(FilterChip),
    );
    await tester.tap(chips.first);
    await tester.pumpAndSettle();
    await tester.tap(chips.at(1));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byKey(const ValueKey('journeyComparison_rating_second')),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Journey and comparison fit the four audited locales at phone text scales',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final entries = [
        _entry(
          id: 'long-recipe-identity-first',
          createdAt: DateTime(2026, 7, 1, 9),
          rating: 4,
          tasteBalance: -1,
          tags: 'qa-test, citrus',
        ),
        _entry(
          id: 'long-recipe-identity-second',
          createdAt: DateTime(2026, 7, 2, 9),
          rating: 4,
          tasteBalance: 0,
          tags: 'qa-test, floral',
        ),
      ];

      for (final locale in const [
        Locale('de'),
        Locale('ja'),
        Locale('ar'),
        Locale('ru'),
      ]) {
        for (final scale in const [1.0, 1.3]) {
          await tester.pumpWidget(
            ChangeNotifierProvider<DateTimeFormatService>.value(
              value: DateTimeFormatService(),
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: JourneyView(group: _beanGroup(entries)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final journey = find.byType(JourneyView);
          expect(
            Directionality.of(tester.element(journey)),
            locale.languageCode == 'ar'
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
          );

          final compare = find.byKey(
            const ValueKey('journeyCompare_v60'),
            skipOffstage: false,
          );
          await tester.ensureVisible(compare);
          await tester.pumpAndSettle();
          await tester.tap(compare);
          await tester.pumpAndSettle();
          final chips = find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(FilterChip),
          );
          await tester.tap(chips.first);
          await tester.pumpAndSettle();
          await tester.tap(chips.at(1));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const ValueKey('journeyComparison_rating_second')),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
          expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }
      }
    },
  );
}

Future<void> _pumpJourney(
  WidgetTester tester, {
  required List<DiaryEntry> entries,
  Locale locale = const Locale('en'),
  DateTimeFormatService? formatService,
  StackRouter? router,
  UserStatProvider? statsProvider,
  VoidCallback? onBeanTap,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final service = formatService ?? DateTimeFormatService();
  Widget app = ChangeNotifierProvider<DateTimeFormatService>.value(
    value: service,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: JourneyView(group: _beanGroup(entries), onBeanTap: onBeanTap),
    ),
  );
  if (router != null) {
    app = StackRouterScope(controller: router, stateHash: 0, child: app);
  }
  if (statsProvider != null) {
    app = ChangeNotifierProvider<UserStatProvider>.value(
      value: statsProvider,
      child: app,
    );
  }
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

AppLocalizations _localizations(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(JourneyView)))!;

/// Mirrors `_entryLabels` in journey_view.dart: "{recipeName} · {date}",
/// with the time appended to every label in the series only when two
/// entries would otherwise produce an identical label.
Map<String, String> _expectedLabels(
  List<DiaryEntry> entries,
  AppLocalizations loc, {
  bool alwaysUse24Hour = false,
  String locale = 'en',
}) {
  final fmtSvc = DateTimeFormatService();
  final dateFormat = DateFormat(fmtSvc.datePattern(loc.dateFormat), locale);
  final baseLabels = {
    for (final entry in entries)
      entry.statUuid:
          '${entry.recipeName} · ${dateFormat.format(entry.createdAt.toLocal())}',
  };
  final hasCollision = baseLabels.values.toSet().length != baseLabels.length;
  if (!hasCollision) return baseLabels;

  final use24Hour = fmtSvc.use24Hour(alwaysUse24Hour);
  final timeFormat = DateFormat(use24Hour ? 'HH:mm' : 'hh:mm a', locale);
  return {
    for (final entry in entries)
      entry.statUuid:
          '${baseLabels[entry.statUuid]} ${timeFormat.format(entry.createdAt.toLocal())}',
  };
}

void _expectPickerLabels(WidgetTester tester, List<String> labels) {
  final sheet = find.byType(BottomSheet);
  expect(sheet, findsOneWidget);
  for (final label in labels) {
    expect(
      find.descendant(of: sheet, matching: find.bySemanticsLabel(label)),
      findsOneWidget,
    );
  }
  expect(
    find.descendant(of: sheet, matching: find.byType(FilterChip)),
    findsNWidgets(labels.length),
  );
}

Future<void> _selectLabels(WidgetTester tester, List<String> labels) async {
  final sheet = find.byType(BottomSheet);
  for (final label in labels) {
    final semanticLabel = find.descendant(
      of: sheet,
      matching: find.bySemanticsLabel(label),
    );
    final chip = find.ancestor(
      of: semanticLabel,
      matching: find.byType(FilterChip),
    );
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }
}

DiaryGroup _beanGroup(List<DiaryEntry> entries) => DiaryGroup(
  key: 'bean-1',
  title: 'Test beans',
  subtitle: 'Test roaster',
  roaster: 'Test roaster',
  entries: entries,
  count: entries.length,
  avgRating: null,
  lastBrew: entries
      .map((entry) => entry.createdAt)
      .reduce((latest, date) => date.isAfter(latest) ? date : latest),
  ratingSeries: const [],
  isDialedIn: false,
);

DiaryEntry _entry({
  required String id,
  String methodId = 'v60',
  String methodName = 'V60',
  DateTime? createdAt,
  String? grindSize = '24 clicks',
  double coffeeAmount = 15,
  double waterAmount = 250,
  double? rating,
  bool isMarked = false,
  String? notes,
  double? tdsPercent,
  double? extractionYieldPercent,
  int? tasteBalance,
  double? waterTemp = 93,
  bool waterTempIsDerived = false,
  String? tags,
}) => DiaryEntry(
  statUuid: id,
  recipeId: 'recipe-$id',
  recipeName: 'Recipe $id',
  brewingMethodId: methodId,
  methodName: methodName,
  createdAt: createdAt ?? DateTime(2026, 7, id == 'two' ? 2 : 1, 9),
  coffeeAmount: coffeeAmount,
  waterAmount: waterAmount,
  grindSize: grindSize,
  waterTemp: waterTemp,
  waterTempIsDerived: waterTempIsDerived,
  tdsPercent: tdsPercent,
  extractionYieldPercent: extractionYieldPercent,
  tasteBalance: tasteBalance,
  tags: tags,
  entrySource: 1,
  rating: rating,
  isMarked: isMarked,
  notes: notes,
  coffeeBeansUuid: 'bean-1',
  beanName: 'Test beans',
  roaster: 'Test roaster',
  origin: 'Kenya',
);

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

class _RecordingRatingProvider extends Mock implements UserStatProvider {
  String? statUuid;
  double? rating;
  int? tasteBalance;

  @override
  Future<void> updateDiaryRating({
    required String statUuid,
    required double? rating,
  }) async {
    this.statUuid = statUuid;
    this.rating = rating;
  }

  @override
  Future<void> updateDiaryTasteBalance({
    required String statUuid,
    required int? tasteBalance,
  }) async {
    this.statUuid = statUuid;
    this.tasteBalance = tasteBalance;
  }
}
