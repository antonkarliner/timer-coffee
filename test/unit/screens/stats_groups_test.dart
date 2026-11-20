import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/beans_stats_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/stats_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/stats/beans_stat_list_card.dart';
import 'package:coffee_timer/widgets/stats/stats_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_database.dart';
import '../widgets/brew_flow_async_context_test.mocks.dart'
    show MockCoffeeBeansProvider, MockDatabaseProvider, MockRecipeProvider;

final _start = DateTime(2026, 11, 1);
final _end = DateTime(2026, 11, 30, 23, 59);

Future<void> _insertStat(
  AppDatabase db,
  String recipeId,
  int index, {
  bool deleted = false,
}) async {
  await db.into(db.userStats).insert(
    UserStatsCompanion.insert(
      statUuid: '$recipeId-$index',
      recipeId: recipeId,
      coffeeAmount: 15,
      waterAmount: 800,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 2,
      brewingMethodId: 'v60',
      createdAt: Value(DateTime(2026, 11, 15)),
      versionVector: VersionVector.initial('test-device').toString(),
      isDeleted: Value(deleted),
    ),
  );
}

void main() {
  test('top recipe counts exclude deleted brews and retain ID order', () async {
    final db = openTestDatabase();
    addTearDown(db.close);

    await _insertStat(db, 'A', 1);
    await _insertStat(db, 'A', 2);
    await _insertStat(db, 'A', 3);
    await _insertStat(db, 'B', 1);
    await _insertStat(db, 'C', 1);
    await _insertStat(db, 'C', 2);
    await _insertStat(db, 'A', 4, deleted: true);

    expect(await db.userStatsDao.fetchTopRecipesWithCounts(_start, _end), [
      (recipeId: 'A', count: 3),
      (recipeId: 'C', count: 2),
      (recipeId: 'B', count: 1),
    ]);
    expect(await db.userStatsDao.fetchTopRecipes(_start, _end), ['A', 'C', 'B']);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('stats row fits a long label and handles taps in ${mode.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);

      final theme = ThemeProvider(mode);
      addTearDown(theme.dispose);
      const label =
          'Am häufigsten verwendete Kaffeerezepte im gewählten Zeitraum';
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          themeMode: mode,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Card(
                margin: EdgeInsets.zero,
                child: StatsRow(
                  identifier: 'testStatsRow',
                  icon: Icons.coffee,
                  label: label,
                  value: '2.40 L',
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final row = find.bySemanticsIdentifier('testStatsRow');
      final value = find.text('2.40 L');
      expect(find.text(label), findsOneWidget);
      expect(value.hitTestable(), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(tester.getRect(value).right, lessThan(tester.getRect(row).right));
      await tester.tap(find.text(label));
      expect(taps, 1);
    });
  }

  group('BeansStatRow', () {
    const identifier = 'statsBeans_test';
    const label = 'Total beans brewed';
    Finder row() => find.bySemanticsIdentifier(identifier);
    final chevron = find.byIcon(Icons.chevron_right);
    final sheet = find.byType(BottomSheet);
    final colonCount = find.textContaining(
      RegExp(r' : |: \d'),
      findRichText: true,
      skipOffstage: false,
    );

    Widget app({
      required Future<int> Function(BuildContext) countFuture,
      required Future<List<int>> Function(BuildContext) fullListFuture,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BeansStatRow<int>(
            identifier: identifier,
            icon: Icons.coffee,
            label: label,
            countFuture: countFuture,
            fullListFuture: fullListFuture,
            itemBuilder: (_, item) => Text('Bean $item'),
            emptyText: 'No beans',
          ),
        ),
      );
    }

    testWidgets('positive count opens the full list', (tester) async {
      final count = Completer<int>();
      var countCalls = 0;
      var fullListCalls = 0;
      await tester.pumpWidget(
        app(
          countFuture: (_) {
            countCalls++;
            return count.future;
          },
          fullListFuture: (_) async {
            fullListCalls++;
            return [1, 2, 3];
          },
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(chevron, findsNothing);
      count.complete(3);
      await tester.pumpAndSettle();

      final value = find.text('3');
      final colors = Theme.of(tester.element(value)).colorScheme;
      expect(tester.widget<Text>(value).style?.color, colors.onSurface);
      expect(chevron, findsOneWidget);
      expect(colonCount, findsNothing);
      expect(countCalls, 1);
      expect(fullListCalls, 0);

      await tester.tap(row());
      await tester.pumpAndSettle();

      expect(sheet, findsOneWidget);
      Finder inSheet(String text) =>
          find.descendant(of: sheet, matching: find.text(text));
      expect(inSheet(label), findsOneWidget);
      expect(tester.widget<Text>(inSheet('3')).style?.color, colors.outline);
      for (final item in [1, 2, 3]) {
        expect(inSheet('Bean $item'), findsOneWidget);
      }
      expect(colonCount, findsNothing);
      expect(countCalls, 1);
      expect(fullListCalls, 1);
    });

    testWidgets('zero count is muted and cannot open the sheet', (tester) async {
      await tester.pumpWidget(
        app(
          countFuture: (_) async => 0,
          fullListFuture: (_) async => fail('The row must not load the list'),
        ),
      );
      await tester.pumpAndSettle();

      final value = find.text('0');
      final colors = Theme.of(tester.element(value)).colorScheme;
      expect(tester.widget<Text>(value).style?.color, colors.outline);
      expect(chevron, findsNothing);
      expect(colonCount, findsNothing);
      await tester.tap(row());
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    testWidgets('count error shows a muted dash without a chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          countFuture: (_) async => throw StateError('Count failed'),
          fullListFuture: (_) async => fail('The row must not load the list'),
        ),
      );
      await tester.pumpAndSettle();

      final value = find.text('—');
      final colors = Theme.of(tester.element(value)).colorScheme;
      expect(tester.widget<Text>(value).style?.color, colors.outline);
      expect(chevron, findsNothing);
      expect(colonCount, findsNothing);
    });
  });

  testWidgets('screen has three flat stats cards', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1100);
    addTearDown(tester.view.reset);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await _insertStat(db, 'A', 1);
      await _insertStat(db, 'A', 2);
      await _insertStat(db, 'missing', 1);
    });

    final database = MockDatabaseProvider();
    final recipeProvider = MockRecipeProvider();
    final recipe = RecipeModel(
      id: 'A',
      name: 'My V60 recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: '',
      steps: [],
    );
    when(recipeProvider.getRecipeById('A')).thenAnswer((_) async => recipe);
    when(recipeProvider.getRecipeById('missing')).thenAnswer((_) async => null);
    when(
      database.fetchGlobalTopRecipesAggregated(any, any),
    ).thenAnswer((_) async => ['A']);
    // Keep the initial total pending so the screen does not start realtime.
    final pendingTotal = Completer<double>();
    when(
      database.fetchGlobalBrewedCoffeeAmountAggregated(any, any),
    ).thenAnswer((_) => pendingTotal.future);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseProvider>.value(value: database),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider(
            create: (_) => UserStatProvider(db, MockCoffeeBeansProvider()),
          ),
          ChangeNotifierProvider(create: (_) => BeansStatsProvider(db)),
          ChangeNotifierProvider(create: (_) => DateTimeFormatService()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatsScreen(
            initialStartDate: '2026-11-01',
            initialEndDate: '2026-11-30',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final l10n = AppLocalizations.of(tester.element(find.byType(StatsScreen)))!;
    final groupIds = [
      'statsGroup_yours',
      'statsGroup_beans',
      'statsGroup_global',
    ];
    final cards = find.byType(Card);
    final groups = find.bySemanticsIdentifier(RegExp(r'^statsGroup_'));
    expect(groups, findsNWidgets(3));
    expect(
      find.ancestor(of: groups, matching: cards),
      findsNWidgets(3),
    );
    for (final id in groupIds) {
      final group = find.bySemanticsIdentifier(id);
      final card = find.ancestor(of: group, matching: cards);
      expect(card, findsOneWidget);
      expect(find.descendant(of: card, matching: cards), findsNothing);
      expect(tester.getTopLeft(card).dx, AppSpacing.base);
    }
    expect(
      find.descendant(of: cards, matching: cards),
      findsNothing,
    );
    expect(cards, findsNWidgets(3));
    expect(find.bySemanticsIdentifier(RegExp(r'^statsBeans_')), findsNWidgets(5));
    expect(find.text(l10n.coffeeBrewed), findsNothing);
    expect(find.text(l10n.mostUsedRecipes), findsNothing);
    expect(find.text(l10n.statsCoffeeBrewedLabel), findsNWidgets(2));
    expect(find.text('2.40 ${l10n.litersUnit}'), findsOneWidget);

    Finder inRow(String id, Finder matching) => find.descendant(
      of: find.bySemanticsIdentifier(id),
      matching: matching,
    );
    final personalRecipe = inRow('yours_statsRecipe_0', find.text(recipe.name));
    expect(personalRecipe, findsOneWidget);
    expect(inRow('yours_statsRecipe_0', find.text('2')), findsOneWidget);
    expect(
      inRow('yours_statsRecipe_1', find.text(l10n.unknownRecipe)),
      findsOneWidget,
    );
    expect(
      inRow('yours_statsRecipe_1', find.byIcon(Icons.chevron_right)),
      findsNothing,
    );
    expect(inRow('global_statsRecipe_0', find.text(recipe.name)), findsOneWidget);
    expect(inRow('global_statsRecipe_0', find.byType(Text)), findsOneWidget);
  });
}
