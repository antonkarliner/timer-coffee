import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/roaster_profile_provider.dart';
import 'package:coffee_timer/providers/user_recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/screens/coffee_beans_detail_screen.dart';
import 'package:coffee_timer/screens/coffee_beans_screen.dart';
import 'package:coffee_timer/screens/recipe_list_screen.dart';
import 'package:coffee_timer/screens/user_recipe_management_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
import 'package:coffee_timer/services/roaster_logo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'delete_undo_snackbar_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CoffeeBeansProvider>(),
  MockSpec<UserStatProvider>(),
  MockSpec<RecipeProvider>(),
  MockSpec<UserRecipeProvider>(),
  MockSpec<DatabaseProvider>(),
  MockSpec<BeanReviewProvider>(),
  MockSpec<RoasterProfileProvider>(),
  MockSpec<FeatureFlagsRepository>(),
  MockSpec<RoasterLogoService>(),
  MockSpec<StackRouter>(),
])

/// Phase 4b: every delete flow ends in the shared undo snackbar, and its
/// Undo action calls the matching restore method exactly once.
///
/// The pop-then-snackbar tests are the regression guard for the navigation
/// hazard: the `ScaffoldMessengerState` must be captured BEFORE the route
/// pops. A `ScaffoldMessenger.of(context)` looked up after the pop either
/// throws on the defunct element (failures surface via `takeException`) or
/// never shows the snackbar (the `find.text(...)` assertions fail).
void main() {
  late MockCoffeeBeansProvider coffeeBeansProvider;
  late MockUserStatProvider userStatProvider;
  late MockRecipeProvider recipeProvider;
  late MockUserRecipeProvider userRecipeProvider;
  late MockDatabaseProvider databaseProvider;
  late MockBeanReviewProvider beanReviewProvider;
  late MockRoasterProfileProvider roasterProfileProvider;
  late MockFeatureFlagsRepository featureFlags;
  late MockRoasterLogoService logoService;
  late MockStackRouter stackRouter;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    coffeeBeansProvider = MockCoffeeBeansProvider();
    userStatProvider = MockUserStatProvider();
    recipeProvider = MockRecipeProvider();
    userRecipeProvider = MockUserRecipeProvider();
    databaseProvider = MockDatabaseProvider();
    beanReviewProvider = MockBeanReviewProvider();
    roasterProfileProvider = MockRoasterProfileProvider();
    featureFlags = MockFeatureFlagsRepository();
    logoService = MockRoasterLogoService();
    stackRouter = MockStackRouter();
  });

  // AnalyticsService must be initialized from the plain (non-FakeAsync)
  // zone: its PackageInfo.fromPlatform() await never completes under
  // testWidgets, and the periodic flush timer must not be created inside
  // one either. The undo assertions below read the real buffer.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> undoEvents() => AnalyticsService
      .instance.bufferedEventsForTesting
      .where((event) => event['event_name'] == 'delete_undo_tapped')
      .toList();

  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );
  }

  Widget diaryHost(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatProvider>.value(value: userStatProvider),
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<CoffeeBeansProvider>.value(
          value: coffeeBeansProvider,
        ),
        Provider<DatabaseProvider>.value(value: databaseProvider),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
      ],
      child: localizedApp(child),
    );
  }

  Widget beansDetailHost(Widget child) {
    return StackRouterScope(
      controller: stackRouter,
      stateHash: 0,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          ChangeNotifierProvider<UserStatProvider>.value(value: userStatProvider),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<BeanReviewProvider>.value(
            value: beanReviewProvider,
          ),
          ChangeNotifierProvider<RoasterProfileProvider>.value(
            value: roasterProfileProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
          Provider<FeatureFlagsRepository>.value(value: featureFlags),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
        ],
        child: localizedApp(child),
      ),
    );
  }

  group('diary entry delete', () {
    final entry = DiaryEntry(
      statUuid: 'stat-1',
      recipeId: 'recipe-1',
      recipeName: 'Test recipe',
      methodName: 'V60',
      coffeeAmount: 15,
      waterAmount: 250,
      brewingMethodId: 'v60',
      createdAt: DateTime.utc(2026, 7, 1),
      isMarked: false,
    );

    Future<void> stubDiaryLoad() async {
      when(
        userStatProvider.fetchDiaryEntries('en'),
      ).thenAnswer((_) async => [entry]);
      when(
        userStatProvider.topMethodsLast90Days('en'),
      ).thenAnswer((_) async => const []);
    }

    /// Opens the detail sheet and confirms the delete. [deleteFuture], when
    /// given, gates `deleteUserStat` so the test can sequence around it.
    Future<void> deleteViaSheet(WidgetTester tester, {Future<void>? deleteFuture}) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await stubDiaryLoad();
      when(
        userStatProvider.deleteUserStat(entry.statUuid),
      ).thenAnswer((_) => deleteFuture ?? Future.value());
      when(
        userStatProvider.restoreUserStat(entry.statUuid),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(diaryHost(const BrewDiaryScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test recipe').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('brewDetailMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
    }

    testWidgets('snackbar appears after the sheet pops and undo restores the entry', (
      tester,
    ) async {
      await deleteViaSheet(tester);
      await tester.pumpAndSettle();

      // The sheet is gone; the snackbar is showing over the diary.
      verify(userStatProvider.deleteUserStat(entry.statUuid)).called(1);
      expect(find.byKey(const Key('brewDetailRecipeName')), findsNothing);
      expect(find.text('Entry deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(userStatProvider.restoreUserStat(entry.statUuid)).called(1);
      // The undo tap is the `delete_undo_tapped` decision input (plan 056):
      // exactly one event, and only a fixed enum — no entry text.
      final events = undoEvents();
      expect(events, hasLength(1));
      expect((events.single['properties'] as Map)['entity'], 'diary');
      expect(tester.takeException(), isNull);
    });

    testWidgets('undo snackbar still shows when the delete lands after the sheet was dismissed', (
      tester,
    ) async {
      final deletion = Completer<void>();
      await deleteViaSheet(tester, deleteFuture: deletion.future);
      await tester.pump();
      verify(userStatProvider.deleteUserStat(entry.statUuid)).called(1);

      // The user swipes the sheet away while the delete is in flight.
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pop();
      await tester.pumpAndSettle();
      expect(find.text('Entry deleted'), findsNothing);

      deletion.complete();
      await tester.pumpAndSettle();

      // Captured-before-the-pop messenger: the snackbar appears over the
      // diary even though the sheet's element is long gone. An
      // implementation that looked the messenger up after the pop would have
      // thrown on the defunct context (takeException) or shown nothing.
      expect(find.text('Entry deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();
      verify(userStatProvider.restoreUserStat(entry.statUuid)).called(1);
      expect(tester.takeException(), isNull);
    });
  });

  group('bean delete from the beans list', () {
    late CoffeeBeansModel bean;

    setUp(() {
      bean = CoffeeBeansModel(
        beansUuid: 'bean-1',
        roaster: 'Test Roaster',
        name: 'Test Beans',
        origin: 'Test Origin',
        packageWeightGrams: 250,
        versionVector: '{}',
      );
    });

    void stubBeansList() {
      when(
        coffeeBeansProvider.fetchAllDistinctRoasters(),
      ).thenAnswer((_) async => ['Test Roaster']);
      when(
        coffeeBeansProvider.fetchAllDistinctOrigins(),
      ).thenAnswer((_) async => ['Test Origin']);
      when(
        coffeeBeansProvider.fetchFilteredCoffeeBeans(),
      ).thenAnswer((_) async => [bean]);
      when(
        coffeeBeansProvider.fetchAllCoffeeBeans(),
      ).thenAnswer((_) async => [bean]);
      when(
        databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
      ).thenAnswer((_) async => {'original': null, 'mirror': null});
      when(
        coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid),
      ).thenAnswer((_) async {});
      when(
        coffeeBeansProvider.restoreCoffeeBeans(bean.beansUuid),
      ).thenAnswer((_) async {});
    }

    testWidgets('snackbar appears after delete and undo restores the bean', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'coffeeBeansGridView': false});
      stubBeansList();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CoffeeBeansProvider>.value(
              value: coffeeBeansProvider,
            ),
            Provider<DatabaseProvider>.value(value: databaseProvider),
          ],
          child: localizedApp(const CoffeeBeansScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid)).called(1);
      expect(find.text('Bean deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();
      verify(coffeeBeansProvider.restoreCoffeeBeans(bean.beansUuid)).called(1);
      final events = undoEvents();
      expect(events, hasLength(1));
      expect((events.single['properties'] as Map)['entity'], 'bean');
      expect(tester.takeException(), isNull);
    });
  });

  group('bean delete from the bean detail screen', () {
    late CoffeeBeansModel bean;

    setUp(() {
      bean = CoffeeBeansModel(
        beansUuid: 'bean-1',
        roaster: 'Test Roaster',
        name: 'Test Beans',
        origin: 'Test Origin',
        packageWeightGrams: 250,
        versionVector: '{}',
      );
    });

    testWidgets('snackbar appears after the screen pops and undo restores the bean', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      when(
        coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
      ).thenAnswer((_) async => bean);
      when(
        coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid),
      ).thenAnswer((_) async {});
      when(
        coffeeBeansProvider.restoreCoffeeBeans(bean.beansUuid),
      ).thenAnswer((_) async {});
      when(
        databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
      ).thenAnswer((_) async => {'original': null, 'mirror': null});
      when(featureFlags.roasterBackendColor).thenReturn(false);
      when(
        logoService.fetchRoasterLogos(any, bean.roaster),
      ).thenAnswer((_) async => RoasterLogoResult.success());
      when(
        userStatProvider.estimateBrewsLeft(
          beansUuid: anyNamed('beansUuid'),
          packageWeightGrams: anyNamed('packageWeightGrams'),
        ),
      ).thenAnswer((_) async => 12);
      when(
        userStatProvider.fetchStatsByBeanUuid(any),
      ).thenAnswer((_) async => <UserStatsModel>[]);
      when(stackRouter.maybePop()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        beansDetailHost(const CoffeeBeansDetailScreen(uuid: 'bean-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('deleteCoffeeBeansButton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid)).called(1);
      expect(find.text('Bean deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();
      verify(coffeeBeansProvider.restoreCoffeeBeans(bean.beansUuid)).called(1);
      expect(tester.takeException(), isNull);
    });
  });

  group('recipe delete', () {
    late RecipeModel recipe;

    setUp(() {
      recipe = RecipeModel(
        id: 'usr-user-1',
        name: 'Test V60',
        brewingMethodId: 'v60',
        coffeeAmount: 15,
        waterAmount: 250,
        grindSize: 'Medium',
        brewTime: const Duration(minutes: 3),
        shortDescription: 'Test recipe',
        steps: const [],
        isPublic: true,
      );
      when(recipeProvider.recipes).thenReturn([recipe]);
      when(recipeProvider.ensureDataReady()).thenAnswer((_) async {});
      when(recipeProvider.fetchAllRecipes()).thenAnswer((_) async {});
      when(
        recipeProvider.getBrewingMethodName('v60'),
      ).thenAnswer((_) async => 'V60');
      when(
        userRecipeProvider.deleteUserRecipe(recipe.id),
      ).thenAnswer((_) async {});
      when(
        userRecipeProvider.restoreUserRecipe(recipe.id),
      ).thenAnswer((_) async {});
    });

    Future<void> deleteViaEditPencil(
      WidgetTester tester,
      Widget screen,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
            ChangeNotifierProvider<UserRecipeProvider>.value(
              value: userRecipeProvider,
            ),
          ],
          child: localizedApp(screen),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    }

    testWidgets('recipe list: snackbar appears after delete and undo restores the recipe', (
      tester,
    ) async {
      await deleteViaEditPencil(
        tester,
        const RecipeListScreen(brewingMethodId: 'v60'),
      );

      verify(userRecipeProvider.deleteUserRecipe(recipe.id)).called(1);
      expect(find.text('Recipe deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Edit-mode toggles and screen init also refresh the list; isolate the
      // undo's own calls.
      clearInteractions(recipeProvider);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(userRecipeProvider.restoreUserRecipe(recipe.id)).called(1);
      // The undo re-fetches the combined list so the recipe reappears.
      verify(recipeProvider.fetchAllRecipes()).called(1);
      final events = undoEvents();
      expect(events, hasLength(1));
      expect((events.single['properties'] as Map)['entity'], 'recipe');
      expect(tester.takeException(), isNull);
    });

    testWidgets('management screen: snackbar appears after delete and undo restores the recipe', (
      tester,
    ) async {
      await deleteViaEditPencil(tester, const UserRecipeManagementScreen());

      verify(userRecipeProvider.deleteUserRecipe(recipe.id)).called(1);
      expect(find.text('Recipe deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Edit-mode toggles and screen init also refresh the list; isolate the
      // undo's own calls.
      clearInteractions(recipeProvider);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(userRecipeProvider.restoreUserRecipe(recipe.id)).called(1);
      // The undo re-fetches the combined list so the recipe reappears.
      verify(recipeProvider.fetchAllRecipes()).called(1);
      expect(tester.takeException(), isNull);
    });
  });
}
