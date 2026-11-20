import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/screens/coffee_beans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/brew_flow_async_context_test.mocks.dart';

final _bean = CoffeeBeansModel(
  beansUuid: 'bean-1',
  roaster: 'Test Roaster',
  name: 'Test Beans',
  origin: 'Test Origin',
  versionVector: '{}',
);

final _addButton = find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.identifier == 'addCoffeeBeansButton',
);

Future<AppLocalizations> _pumpMyBeans(
  WidgetTester tester,
  List<CoffeeBeansModel> beans,
) async {
  final beansProvider = MockCoffeeBeansProvider();
  final databaseProvider = MockDatabaseProvider();
  when(beansProvider.fetchAllDistinctRoasters()).thenAnswer((_) async => []);
  when(beansProvider.fetchAllDistinctOrigins()).thenAnswer((_) async => []);
  when(beansProvider.fetchAllCoffeeBeans()).thenAnswer((_) async => beans);
  when(beansProvider.fetchFilteredCoffeeBeans()).thenAnswer((_) async => beans);
  when(beansProvider.fetchFilteredCoffeeBeans(isFavorite: true))
      .thenAnswer((_) async => []);
  when(databaseProvider.fetchCachedRoasterLogoUrls(_bean.roaster))
      .thenAnswer((_) async => {'original': null, 'mirror': null});

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beansProvider),
        Provider<DatabaseProvider>.value(value: databaseProvider),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CoffeeBeansScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(CoffeeBeansScreen)))!;
}

void _expectAddButton(WidgetTester tester, {required bool visible}) {
  final opacity = tester.widget<AnimatedOpacity>(
    find.ancestor(of: _addButton, matching: find.byType(AnimatedOpacity)),
  );
  final pointer = tester.widget<IgnorePointer>(find.byWidget(opacity.child!));
  expect(opacity.opacity, visible ? 1.0 : 0.0);
  expect(pointer.ignoring, !visible);
  expect(_addButton.hitTestable(), visible ? findsOneWidget : findsNothing);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the docked add button is hidden for an empty inventory', (
    tester,
  ) async {
    final l10n = await _pumpMyBeans(tester, []);

    expect(find.text(l10n.nocoffeebeans), findsOneWidget);
    _expectAddButton(tester, visible: false);
  });

  testWidgets('the docked add button is visible when a filter finds no beans', (
    tester,
  ) async {
    final l10n = await _pumpMyBeans(tester, [_bean]);

    await tester.tap(find.byTooltip(l10n.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.showFavoritesOnly));
    await tester.tap(find.text(l10n.apply));
    await tester.pumpAndSettle();

    expect(find.text(l10n.noBeansMatchSearch), findsOneWidget);
    _expectAddButton(tester, visible: true);
  });

  testWidgets('the docked add button is visible when inventory has beans', (
    tester,
  ) async {
    await _pumpMyBeans(tester, [_bean]);

    expect(find.text(_bean.name), findsOneWidget);
    _expectAddButton(tester, visible: true);
  });
}
