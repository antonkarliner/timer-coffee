import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/controllers/coffee_beans_detail_controller.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
import 'package:coffee_timer/services/roaster_logo_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'coffee_beans_detail_controller_async_context_test.mocks.dart';
import '../../helpers/test_database.dart';

@GenerateNiceMocks([
  MockSpec<CoffeeBeansProvider>(),
  MockSpec<UserStatProvider>(),
  MockSpec<FeatureFlagsRepository>(),
  MockSpec<RoasterLogoService>(),
  MockSpec<StackRouter>(),
])
void main() {
  late MockCoffeeBeansProvider coffeeBeansProvider;
  late MockUserStatProvider userStatProvider;
  late MockFeatureFlagsRepository featureFlags;
  late MockRoasterLogoService logoService;
  late MockStackRouter stackRouter;
  late CoffeeBeansDetailController controller;
  late CoffeeBeansModel bean;
  late bool controllerDisposed;

  setUp(() {
    coffeeBeansProvider = MockCoffeeBeansProvider();
    userStatProvider = MockUserStatProvider();
    featureFlags = MockFeatureFlagsRepository();
    logoService = MockRoasterLogoService();
    stackRouter = MockStackRouter();
    controller = CoffeeBeansDetailController(logoService: logoService);
    controllerDisposed = false;
    bean = CoffeeBeansModel(
      beansUuid: 'bean-1',
      roaster: 'Test Roaster',
      name: 'Test Beans',
      origin: 'Test Origin',
      packageWeightGrams: 250,
      versionVector: '{}',
    );

    when(
      coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
    ).thenAnswer((_) async => bean);
    when(
      coffeeBeansProvider.toggleFavoriteStatus(any, any),
    ).thenAnswer((_) async {});
    when(coffeeBeansProvider.updateCoffeeBeans(any)).thenAnswer((_) async {});
    when(
      logoService.fetchRoasterLogos(any, bean.roaster),
    ).thenAnswer((_) async => RoasterLogoResult.success());
    when(featureFlags.roasterBackendColor).thenReturn(false);
    when(
      userStatProvider.estimateBrewsLeft(
        beansUuid: anyNamed('beansUuid'),
        packageWeightGrams: anyNamed('packageWeightGrams'),
      ),
    ).thenAnswer((_) async => 12);
  });

  tearDown(() {
    if (!controllerDisposed) controller.dispose();
  });

  Widget buildHost() {
    return StackRouterScope(
      controller: stackRouter,
      stateHash: 0,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          ChangeNotifierProvider<UserStatProvider>.value(
            value: userStatProvider,
          ),
          Provider<FeatureFlagsRepository>.value(value: featureFlags),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: SizedBox(key: Key('controller-host'))),
        ),
      ),
    );
  }

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(buildHost());
    return tester.element(find.byKey(const Key('controller-host')));
  }

  void disposeController() {
    controller.dispose();
    controllerDisposed = true;
  }

  Future<void> initialize(WidgetTester tester, BuildContext context) async {
    await controller.initialize(context, bean.beansUuid);
    await tester.pump();
  }

  testWidgets('initialization loads bean details while mounted', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    await initialize(tester, context);
    controller.loadAncillaryData(context);
    await tester.pump();

    expect(controller.bean, bean);
    expect(controller.brewsLeft, 12);
    expect(controller.isLoading, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bean lookup completion is ignored after disposal', (
    tester,
  ) async {
    final lookup = Completer<CoffeeBeansModel?>();
    when(
      coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
    ).thenAnswer((_) => lookup.future);
    final context = await pumpHost(tester);

    final loading = controller.initialize(context, bean.beansUuid);
    await tester.pump();
    disposeController();
    await tester.pumpWidget(const SizedBox.shrink());
    lookup.complete(bean);
    await loading;

    verifyNever(logoService.fetchRoasterLogos(any, any));
    expect(tester.takeException(), isNull);
  });

  testWidgets('logo completion is ignored after controller disposal', (
    tester,
  ) async {
    final logo = Completer<RoasterLogoResult>();
    when(
      logoService.fetchRoasterLogos(any, bean.roaster),
    ).thenAnswer((_) => logo.future);
    final context = await pumpHost(tester);

    await controller.initialize(context, bean.beansUuid);
    disposeController();
    logo.complete(RoasterLogoResult.success(originalUrl: 'logo.png'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('favorite completion skips refresh after context disposal', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await initialize(tester, context);
    final toggle = Completer<void>();
    when(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).thenAnswer((_) => toggle.future);
    clearInteractions(coffeeBeansProvider);

    final result = controller.toggleFavorite(context);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    toggle.complete();

    expect(await result, isTrue);
    verifyNever(coffeeBeansProvider.fetchCoffeeBeansByUuid(any));
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete forwards the loaded bean UUID', (tester) async {
    final context = await pumpHost(tester);
    await initialize(tester, context);
    when(
      coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid),
    ).thenAnswer((_) async {});

    expect(await controller.deleteBean(context), isTrue);
    verify(coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid)).called(1);
  });

  test('legacy stat backfill stores the matched bean UUID', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await db
        .into(db.userStats)
        .insert(
          UserStatsCompanion.insert(
            statUuid: 'stat-legacy',
            id: const Value(7),
            recipeId: 'recipe-1',
            coffeeAmount: 20,
            waterAmount: 300,
            sweetnessSliderPosition: 1,
            strengthSliderPosition: 2,
            brewingMethodId: 'method-1',
            createdAt: Value(DateTime(2024)),
            coffeeBeansId: const Value(42),
            versionVector: '{}',
          ),
        );
    when(
      coffeeBeansProvider.fetchCoffeeBeansById(42),
    ).thenAnswer((_) async => bean);
    final provider = UserStatProvider(db, coffeeBeansProvider);

    await provider.backfillMissingCoffeeBeansUuids();

    final updated = await db.userStatsDao.fetchStatByUuid('stat-legacy');
    expect(updated?.coffeeBeansUuid, bean.beansUuid);
  });

  testWidgets('edit return skips refresh after context disposal', (
    tester,
  ) async {
    final routeResult = Completer<Object?>();
    when(stackRouter.push<Object?>(any)).thenAnswer((_) => routeResult.future);
    final context = await pumpHost(tester);
    await initialize(tester, context);
    clearInteractions(coffeeBeansProvider);

    final navigation = controller.navigateToEdit(context);
    await tester.pumpWidget(const SizedBox.shrink());
    routeResult.complete('saved');
    await navigation;

    verifyNever(coffeeBeansProvider.fetchCoffeeBeansByUuid(any));
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory completion skips refresh after context disposal', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await initialize(tester, context);
    final update = Completer<void>();
    when(
      coffeeBeansProvider.updateCoffeeBeans(any),
    ).thenAnswer((_) => update.future);
    clearInteractions(coffeeBeansProvider);

    final result = controller.setPackageWeightToZero(context);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    update.complete();

    expect(await result, isTrue);
    verifyNever(coffeeBeansProvider.fetchCoffeeBeansByUuid(any));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes completion skips refresh after context disposal', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await initialize(tester, context);
    final update = Completer<void>();
    when(
      coffeeBeansProvider.updateCoffeeBeans(any),
    ).thenAnswer((_) => update.future);
    clearInteractions(coffeeBeansProvider);

    final result = controller.saveNotesAndGrindSize(
      context,
      notes: 'Chocolate',
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    update.complete();

    expect(await result, isTrue);
    verifyNever(coffeeBeansProvider.fetchCoffeeBeansByUuid(any));
    expect(tester.takeException(), isNull);
  });
}
