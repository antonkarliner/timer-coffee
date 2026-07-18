import 'dart:async';

import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/screens/finish_screen.dart';
import 'package:coffee_timer/screens/manual_brew_entry_screen.dart';
import 'package:coffee_timer/screens/recipe_detail_screen.dart';
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
  RecipeModel recipe({double? waterTemp, double? customWaterTemp}) {
    return RecipeModel(
      id: 'recipe-1',
      name: 'Test recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      waterTemp: waterTemp,
      grindSize: '24 clicks',
      brewTime: const Duration(minutes: 3),
      shortDescription: 'Test recipe',
      steps: const [],
      customWaterTemp: customWaterTemp,
    );
  }

  RecipeModel runtimeRecipe(RecipeModel source, double? waterTemperature) {
    return buildRuntimeRecipeForBrew(
      recipe: source,
      id: source.id,
      coffeeAmount: source.coffeeAmount,
      waterAmount: source.waterAmount,
      grindSize: source.grindSize,
      waterTemperature: waterTemperature,
      sweetnessSliderPosition: null,
      strengthSliderPosition: null,
      coffeeChroniclerSliderPosition: null,
    );
  }

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

  test('guided brew carries and logs the effective temperature', () async {
    final userStatProvider = MockUserStatProvider();
    when(
      userStatProvider.insertUserStat(
        recipeId: anyNamed('recipeId'),
        coffeeAmount: anyNamed('coffeeAmount'),
        waterAmount: anyNamed('waterAmount'),
        sweetnessSliderPosition: anyNamed('sweetnessSliderPosition'),
        strengthSliderPosition: anyNamed('strengthSliderPosition'),
        brewingMethodId: anyNamed('brewingMethodId'),
        statUuid: anyNamed('statUuid'),
        coffeeBeansUuid: anyNamed('coffeeBeansUuid'),
        grindSize: anyNamed('grindSize'),
        waterTemp: anyNamed('waterTemp'),
        entrySource: anyNamed('entrySource'),
      ),
    ).thenAnswer((_) async {});

    final controller = RecipeDetailController();
    addTearDown(controller.dispose);
    final source = recipe(waterTemp: 93);
    controller.setInitialWaterTemperature(source.waterTemp);
    final builtInRuntime = runtimeRecipe(source, controller.waterTemperature);
    expect(builtInRuntime.waterTemp, 93);

    await insertGuidedBrewUserStat(
      userStatProvider: userStatProvider,
      recipe: builtInRuntime,
      coffeeAmount: 15,
      waterAmount: 250,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 2,
      statUuid: 'stat-built-in',
      coffeeBeansUuid: null,
      waterTemp: builtInRuntime.waterTemp,
    );

    verify(
      userStatProvider.insertUserStat(
        recipeId: source.id,
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 2,
        brewingMethodId: source.brewingMethodId,
        statUuid: 'stat-built-in',
        coffeeBeansUuid: null,
        grindSize: source.grindSize,
        waterTemp: 93,
        entrySource: 0,
      ),
    ).called(1);
  });

  test('manual and brew-again temperatures replace the runtime value', () {
    final controller = RecipeDetailController();
    addTearDown(controller.dispose);
    final source = recipe(waterTemp: 93, customWaterTemp: 90);

    controller.setInitialWaterTemperature(source.customWaterTemp);
    controller.markWaterTemperatureManuallyEdited(91);
    expect(runtimeRecipe(source, controller.waterTemperature).waterTemp, 91);

    controller.markWaterTemperatureManuallyEdited(null);
    expect(runtimeRecipe(source, controller.waterTemperature).waterTemp, 90);
    expect(controller.waterTemperatureFromRecipe, isTrue);

    controller.applyBrewAgainPrefill(waterTemp: 92);
    expect(runtimeRecipe(source, controller.waterTemperature).waterTemp, 92);
    expect(controller.waterTemperatureFromRecipe, isFalse);
  });

  test('null source recipe remains null at runtime and in logging', () async {
    final userStatProvider = MockUserStatProvider();
    when(
      userStatProvider.insertUserStat(
        recipeId: anyNamed('recipeId'),
        coffeeAmount: anyNamed('coffeeAmount'),
        waterAmount: anyNamed('waterAmount'),
        sweetnessSliderPosition: anyNamed('sweetnessSliderPosition'),
        strengthSliderPosition: anyNamed('strengthSliderPosition'),
        brewingMethodId: anyNamed('brewingMethodId'),
        statUuid: anyNamed('statUuid'),
        coffeeBeansUuid: anyNamed('coffeeBeansUuid'),
        grindSize: anyNamed('grindSize'),
        waterTemp: anyNamed('waterTemp'),
        entrySource: anyNamed('entrySource'),
      ),
    ).thenAnswer((_) async {});
    final controller = RecipeDetailController();
    addTearDown(controller.dispose);
    final source = recipe();
    controller.setInitialWaterTemperature(source.waterTemp);
    final runtime = runtimeRecipe(source, controller.waterTemperature);

    expect(runtime.waterTemp, isNull);
    await insertGuidedBrewUserStat(
      userStatProvider: userStatProvider,
      recipe: runtime,
      coffeeAmount: 15,
      waterAmount: 250,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 2,
      statUuid: 'stat-null',
      coffeeBeansUuid: null,
      waterTemp: runtime.waterTemp,
    );

    verify(
      userStatProvider.insertUserStat(
        recipeId: runtime.id,
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 2,
        brewingMethodId: runtime.brewingMethodId,
        statUuid: 'stat-null',
        coffeeBeansUuid: null,
        grindSize: runtime.grindSize,
        waterTemp: null,
        entrySource: 0,
      ),
    ).called(1);
  });

  testWidgets('brew detail save finishes after screen disposal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final recipeProvider = MockRecipeProvider();
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final update = Completer<void>();
    final entry = DiaryEntry(
      statUuid: 'stat-1',
      recipeId: 'recipe-1',
      recipeName: 'Test recipe',
      methodName: 'V60',
      coffeeAmount: 15,
      waterAmount: 250,
      brewingMethodId: 'v60',
      createdAt: DateTime.utc(2026, 7, 1),
      notes: 'Initial note',
      isMarked: false,
    );
    final userStatProvider = _CompletingUserStatProvider(entry, update);

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

    expect(find.bySemanticsIdentifier('userStatCard_stat-1'), findsOneWidget);
    await tester.tap(find.text('Test recipe').first);
    await tester.pumpAndSettle();
    expect(find.text('V60'), findsWidgets);
    await tester.tap(find.byKey(const Key('editNotesButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Late note');
    await tester.ensureVisible(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    update.complete();
    await tester.pump();

    expect(userStatProvider.updateCalls, 1);
    expect(userStatProvider.savedStatUuid, entry.statUuid);
    expect(userStatProvider.savedNotes, 'Late note');
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting diary entry finishes after screen disposal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final userStatProvider = MockUserStatProvider();
    final recipeProvider = MockRecipeProvider();
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final weightUpdate = Completer<double?>();
    final deletion = Completer<void>();
    final entry = DiaryEntry(
      statUuid: 'stat-with-beans',
      recipeId: 'recipe-1',
      recipeName: 'Test recipe',
      methodName: 'V60',
      coffeeAmount: 15,
      waterAmount: 250,
      brewingMethodId: 'v60',
      createdAt: DateTime.utc(2026, 7, 1),
      isMarked: false,
      coffeeBeansUuid: 'bean-1',
      roaster: 'Test Roaster',
      beanName: 'Test Beans',
    );
    when(
      userStatProvider.fetchDiaryEntries('en'),
    ).thenAnswer((_) async => [entry]);
    when(
      userStatProvider.topMethodsLast90Days('en'),
    ).thenAnswer((_) async => const []);
    when(
      userStatProvider.deleteUserStat(entry.statUuid),
    ).thenAnswer((_) => deletion.future);
    when(
      coffeeBeansProvider.updateBeanWeightAfterBrewModification(
        entry.coffeeBeansUuid!,
        entry.coffeeAmount,
      ),
    ).thenAnswer((_) => weightUpdate.future);
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(entry.roaster!),
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

    await tester.tap(find.byKey(const Key('brewDetailMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    weightUpdate.complete(265);
    await tester.pump();
    deletion.complete();
    await tester.pump();

    verify(
      coffeeBeansProvider.updateBeanWeightAfterBrewModification(
        entry.coffeeBeansUuid!,
        entry.coffeeAmount,
      ),
    ).called(1);
    verify(userStatProvider.deleteUserStat(entry.statUuid)).called(1);
    expect(tester.takeException(), isNull);
  });
}

class _CompletingUserStatProvider extends UserStatProvider {
  _CompletingUserStatProvider(this.entry, this.update)
    : super(MockAppDatabase(), MockCoffeeBeansProvider());

  final DiaryEntry entry;
  final Completer<void> update;
  int updateCalls = 0;
  String? savedStatUuid;
  String? savedNotes;

  @override
  Future<List<DiaryEntry>> fetchDiaryEntries(String locale) async => [entry];

  @override
  Future<List<({String brewingMethodId, String methodName, int count})>>
  topMethodsLast90Days(String locale) async => const [];

  @override
  Future<void> updateDiaryNotes({
    required String statUuid,
    required String notes,
  }) {
    updateCalls++;
    savedStatUuid = statUuid;
    savedNotes = notes;
    return update.future;
  }
}
