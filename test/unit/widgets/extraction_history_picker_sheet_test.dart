import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/extraction_calculator_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart'
    show MockRecipeProvider, MockUserStatProvider;

typedef _HistoryPick = ({UserStatsModel stat, String recipeName});

void main() {
  final first = _stat('first', day: 2);
  final second = _stat('second', day: 1);

  testWidgets('shows the sheet heading and the empty history hint', (
    tester,
  ) async {
    await _openSheet(tester);

    final bottomSheet = find.byType(BottomSheet);
    expect(bottomSheet, findsOneWidget);
    expect(tester.widget<BottomSheet>(bottomSheet).showDragHandle, isTrue);
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.bySemanticsIdentifier('extractionCalcHistoryDialogAppBar'),
      findsOneWidget,
    );
    final l10n = AppLocalizations.of(tester.element(bottomSheet))!;
    final heading = tester.widget<Text>(
      find.text(l10n.extractionCalcHistoryDialogTitle),
    );
    expect(heading.style?.fontSize, AppTextStyles.title.fontSize);
    expect(find.text(l10n.extractionCalcHistoryEmptyHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returns the first selected brew and its recipe name', (
    tester,
  ) async {
    final results = <_HistoryPick?>[];
    await _openSheet(
      tester,
      stats: [first, second],
      recipeNames: {
        first.recipeId: 'First recipe',
        second.recipeId: 'Second recipe',
      },
      onResult: results.add,
    );

    final rows = find.byType(ListTile);
    expect(rows, findsNWidgets(2));
    await tester.tap(rows.first);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(results, hasLength(1));
    expect(results.single?.stat.statUuid, first.statUuid);
    expect(results.single?.recipeName, 'First recipe');
  });

  testWidgets('Cancel closes the sheet with a null result', (tester) async {
    final results = <_HistoryPick?>[];
    await _openSheet(tester, onResult: results.add);

    final l10n = AppLocalizations.of(tester.element(find.byType(BottomSheet)))!;
    await tester.tap(find.widgetWithText(AppTextButton, l10n.cancel));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(results, [null]);
  });

  testWidgets('lays out an 80-character recipe name at 320 points wide', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final longName = 'A' * 80;

    await _openSheet(
      tester,
      stats: [first],
      recipeNames: {first.recipeId: longName},
    );

    expect(find.text(longName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openSheet(
  WidgetTester tester, {
  List<UserStatsModel> stats = const [],
  Map<String, String> recipeNames = const {},
  ValueChanged<_HistoryPick?>? onResult,
}) async {
  final userStatProvider = MockUserStatProvider();
  final recipeProvider = MockRecipeProvider();
  when(userStatProvider.fetchRecentStats()).thenAnswer((_) async => stats);
  when(
    recipeProvider.getBrewingMethodName('v60'),
  ).thenAnswer((_) async => 'V60');
  for (final recipe in recipeNames.entries) {
    when(
      recipeProvider.getLocalizedRecipeName(recipe.key),
    ).thenAnswer((_) async => recipe.value);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatProvider>.value(value: userStatProvider),
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(colorScheme: lightColorScheme),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => AppTextButton(
              label: 'Open history',
              onPressed: () async {
                final result = await showModalBottomSheet<_HistoryPick>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const ExtractionHistoryPickerSheet(),
                );
                onResult?.call(result);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open history'));
  await tester.pumpAndSettle();
}

UserStatsModel _stat(String id, {required int day}) => UserStatsModel(
  statUuid: id,
  recipeId: 'recipe-$id',
  coffeeAmount: 15,
  waterAmount: 250,
  sweetnessSliderPosition: 0,
  strengthSliderPosition: 0,
  brewingMethodId: 'v60',
  createdAt: DateTime(2026, 11, day, 9),
  isMarked: false,
  versionVector: '{}',
  isDeleted: false,
);
