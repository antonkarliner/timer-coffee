import 'dart:async';

import 'package:coffee_timer/controllers/coffee_beans_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coffee_beans_controller_async_context_test.mocks.dart';

@GenerateNiceMocks([MockSpec<CoffeeBeansProvider>(), MockSpec<StackRouter>()])
void main() {
  late ListeningMockCoffeeBeansProvider coffeeBeansProvider;
  late MockStackRouter stackRouter;
  late CoffeeBeansController controller;
  late bool controllerDisposed;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coffeeBeansProvider = ListeningMockCoffeeBeansProvider();
    stackRouter = MockStackRouter();
    controller = CoffeeBeansController();
    controllerDisposed = false;

    when(
      coffeeBeansProvider.fetchAllDistinctRoasters(),
    ).thenAnswer((_) async => ['Test Roaster']);
    when(
      coffeeBeansProvider.fetchAllDistinctOrigins(),
    ).thenAnswer((_) async => ['Test Origin']);
    when(
      coffeeBeansProvider.fetchFilteredCoffeeBeans(),
    ).thenAnswer((_) async => []);
    when(coffeeBeansProvider.fetchAllCoffeeBeans()).thenAnswer((_) async => []);
  });

  tearDown(() {
    if (!controllerDisposed) controller.dispose();
  });

  Widget buildHost() {
    return StackRouterScope(
      controller: stackRouter,
      stateHash: 0,
      child: ChangeNotifierProvider<CoffeeBeansProvider>.value(
        value: coffeeBeansProvider,
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

  testWidgets('initialization loads data without retaining BuildContext', (
    tester,
  ) async {
    final context = await pumpHost(tester);

    await controller.initialize(context);

    expect(controller.availableRoasters, ['Test Roaster']);
    expect(controller.availableOrigins, ['Test Origin']);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    verify(coffeeBeansProvider.fetchFilteredCoffeeBeans()).called(1);
    verify(coffeeBeansProvider.fetchAllCoffeeBeans()).called(1);
  });

  testWidgets('initialization stops safely when controller is disposed', (
    tester,
  ) async {
    final roasters = Completer<List<String>>();
    when(
      coffeeBeansProvider.fetchAllDistinctRoasters(),
    ).thenAnswer((_) => roasters.future);
    final context = await pumpHost(tester);

    final initialization = controller.initialize(context);
    await tester.pump();
    disposeController();
    await tester.pumpWidget(const SizedBox.shrink());
    roasters.complete(['Late Roaster']);
    await initialization;

    verifyNever(coffeeBeansProvider.fetchAllDistinctOrigins());
    verifyNever(coffeeBeansProvider.fetchFilteredCoffeeBeans());
    expect(tester.takeException(), isNull);
  });

  testWidgets('deferred provider refresh is cancelled on disposal', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await controller.initialize(context);
    clearInteractions(coffeeBeansProvider);

    coffeeBeansProvider.emitChange();
    disposeController();
    await tester.pump(const Duration(milliseconds: 60));

    verifyNever(coffeeBeansProvider.fetchFilteredCoffeeBeans());
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider notification refreshes while controller is alive', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    await controller.initialize(context);
    clearInteractions(coffeeBeansProvider);

    coffeeBeansProvider.emitChange();
    await tester.pump(const Duration(milliseconds: 60));

    verify(coffeeBeansProvider.fetchFilteredCoffeeBeans()).called(1);
    verify(coffeeBeansProvider.fetchAllCoffeeBeans()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh ignores an unmounted context', (tester) async {
    final context = await pumpHost(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    clearInteractions(coffeeBeansProvider);

    await controller.refreshData(context);

    verifyNever(coffeeBeansProvider.fetchFilteredCoffeeBeans());
    expect(tester.takeException(), isNull);
  });

  testWidgets('new-beans navigation refreshes after a successful return', (
    tester,
  ) async {
    final routeResult = Completer<Object?>();
    when(stackRouter.push<Object?>(any)).thenAnswer((_) => routeResult.future);
    final context = await pumpHost(tester);
    clearInteractions(coffeeBeansProvider);

    final navigation = controller.navigateToNewBeans(context);
    routeResult.complete('saved-bean');
    await navigation;

    verify(coffeeBeansProvider.fetchFilteredCoffeeBeans()).called(1);
    verify(coffeeBeansProvider.fetchAllCoffeeBeans()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new-beans navigation ignores a result after disposal', (
    tester,
  ) async {
    final routeResult = Completer<Object?>();
    when(stackRouter.push<Object?>(any)).thenAnswer((_) => routeResult.future);
    final context = await pumpHost(tester);

    final navigation = controller.navigateToNewBeans(context);
    disposeController();
    await tester.pumpWidget(const SizedBox.shrink());
    routeResult.complete('saved-bean');
    await navigation;

    verifyNever(coffeeBeansProvider.fetchFilteredCoffeeBeans());
    expect(tester.takeException(), isNull);
  });

  testWidgets('bean-detail navigation refreshes after a successful return', (
    tester,
  ) async {
    final routeResult = Completer<Object?>();
    when(stackRouter.push<Object?>(any)).thenAnswer((_) => routeResult.future);
    final context = await pumpHost(tester);
    clearInteractions(coffeeBeansProvider);

    controller.navigateToBeanDetail(context, 'bean-1');
    routeResult.complete('updated-bean');
    await tester.pump();

    verify(coffeeBeansProvider.fetchFilteredCoffeeBeans()).called(1);
    verify(coffeeBeansProvider.fetchAllCoffeeBeans()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bean-detail navigation ignores a result after disposal', (
    tester,
  ) async {
    final routeResult = Completer<Object?>();
    when(stackRouter.push<Object?>(any)).thenAnswer((_) => routeResult.future);
    final context = await pumpHost(tester);

    controller.navigateToBeanDetail(context, 'bean-1');
    disposeController();
    await tester.pumpWidget(const SizedBox.shrink());
    routeResult.complete('updated-bean');
    await tester.pump();

    verifyNever(coffeeBeansProvider.fetchFilteredCoffeeBeans());
    expect(tester.takeException(), isNull);
  });
}

class ListeningMockCoffeeBeansProvider extends MockCoffeeBeansProvider {
  final Set<VoidCallback> _listeners = {};

  @override
  void addListener(VoidCallback? listener) {
    if (listener != null) _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback? listener) {
    _listeners.remove(listener);
  }

  void emitChange() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}
