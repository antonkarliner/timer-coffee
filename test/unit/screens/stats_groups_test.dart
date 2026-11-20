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

  testWidgets('screen has two flat stats cards and standalone bean tiles', (
    tester,
  ) async {
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
    final groupIds = ['statsGroup_yours', 'statsGroup_global'];
    final cards = find.byType(Card);
    expect(
      find.ancestor(
        of: find.bySemanticsIdentifier(RegExp(r'^statsGroup_')),
        matching: cards,
      ),
      findsNWidgets(2),
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
    expect(cards, findsNWidgets(7));
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
