import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/screens/manual_brew_entry_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AppDatabase>(),
  MockSpec<BrewingMethodsDao>(),
  MockSpec<UserStatProvider>(),
  MockSpec<RecipeProvider>(),
  MockSpec<CoffeeBeansProvider>(),
  MockSpec<DatabaseProvider>(),
])
void main() {
  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );
  }

  testWidgets('manual entry initialization stops after disposal', (
    tester,
  ) async {
    final database = MockAppDatabase();
    final brewingMethodsDao = MockBrewingMethodsDao();
    final methods = Completer<List<BrewingMethodModel>>();
    when(database.brewingMethodsDao).thenReturn(brewingMethodsDao);
    when(
      brewingMethodsDao.getAllBrewingMethods(),
    ).thenAnswer((_) => methods.future);

    await tester.pumpWidget(
      Provider<AppDatabase>.value(
        value: database,
        child: localizedApp(const ManualBrewEntryScreen()),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    methods.complete(const []);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('delayed diary note update survives screen disposal', (
    tester,
  ) async {
    final userStatProvider = MockUserStatProvider();
    final recipeProvider = MockRecipeProvider();
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final stat = UserStatsModel(
      statUuid: 'stat-1',
      recipeId: 'recipe-1',
      coffeeAmount: 15,
      waterAmount: 250,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 1,
      brewingMethodId: 'v60',
      createdAt: DateTime.utc(2026, 7, 1),
      notes: 'Initial note',
      isMarked: false,
      versionVector: '{}',
      isDeleted: false,
    );
    when(userStatProvider.fetchAllUserStats()).thenAnswer((_) async => [stat]);
    when(
      userStatProvider.updateUserStat(
        statUuid: anyNamed('statUuid'),
        notes: anyNamed('notes'),
      ),
    ).thenAnswer((_) async {});
    when(
      recipeProvider.getBrewingMethodName(stat.brewingMethodId),
    ).thenAnswer((_) async => 'V60');
    when(
      recipeProvider.getLocalizedRecipeName(stat.recipeId),
    ).thenAnswer((_) async => 'Test recipe');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatProvider>.value(
            value: userStatProvider,
          ),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
        ],
        child: localizedApp(const BrewDiaryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test recipe').first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextFormField).last, 'Late note');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 2100));

    verify(
      userStatProvider.updateUserStat(
        statUuid: stat.statUuid,
        notes: 'Late note',
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing diary beans finishes after screen disposal', (
    tester,
  ) async {
    final userStatProvider = MockUserStatProvider();
    final recipeProvider = MockRecipeProvider();
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final weightUpdate = Completer<double?>();
    final stat = UserStatsModel(
      statUuid: 'stat-with-beans',
      recipeId: 'recipe-1',
      coffeeAmount: 15,
      waterAmount: 250,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 1,
      brewingMethodId: 'v60',
      createdAt: DateTime.utc(2026, 7, 1),
      isMarked: false,
      coffeeBeansUuid: 'bean-1',
      versionVector: '{}',
      isDeleted: false,
    );
    final bean = CoffeeBeansModel(
      beansUuid: 'bean-1',
      roaster: 'Test Roaster',
      name: 'Test Beans',
      origin: 'Test Origin',
      packageWeightGrams: 250,
      versionVector: '{}',
    );
    when(userStatProvider.fetchAllUserStats()).thenAnswer((_) async => [stat]);
    when(
      userStatProvider.updateUserStat(
        statUuid: stat.statUuid,
        clearBeans: true,
      ),
    ).thenAnswer((_) async {});
    when(
      recipeProvider.getBrewingMethodName(stat.brewingMethodId),
    ).thenAnswer((_) async => 'V60');
    when(
      recipeProvider.getLocalizedRecipeName(stat.recipeId),
    ).thenAnswer((_) async => 'Test recipe');
    when(
      coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
    ).thenAnswer((_) async => bean);
    when(
      coffeeBeansProvider.updateBeanWeightAfterBrewModification(
        bean.beansUuid,
        stat.coffeeAmount,
      ),
    ).thenAnswer((_) => weightUpdate.future);
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatProvider>.value(
            value: userStatProvider,
          ),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
        ],
        child: localizedApp(const BrewDiaryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test recipe').first);
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Remove from entry'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.tap(find.text('Remove from entry'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    weightUpdate.complete(265);
    await tester.pump();

    verify(
      userStatProvider.updateUserStat(
        statUuid: stat.statUuid,
        clearBeans: true,
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });
}
