import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/add_coffee_beans_widget.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../controllers/coffee_beans_controller_async_context_test.mocks.dart'
    show MockCoffeeBeansProvider;
import 'widget_async_context_batch_test.mocks.dart' show MockDatabaseProvider;

void main() {
  final bean = CoffeeBeansModel(
    beansUuid: 'bean-1',
    roaster: 'Test Roaster',
    name: 'Test Beans',
    origin: 'Test Origin',
    versionVector: '{}',
  );
  final selector = find.byType(AddCoffeeBeansWidget);

  Future<void> openSheet(
    WidgetTester tester, {
    required List<CoffeeBeansModel> beans,
    required ValueChanged<String> onSelect,
  }) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    when(
      coffeeBeansProvider.fetchAllCoffeeBeans(),
    ).thenAnswer((_) async => [...beans]);
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(any),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: lightColorScheme),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => AppTextButton(
                label: 'Open selector',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => AddCoffeeBeansWidget(onSelect: onSelect),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open selector'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the bean sheet and submits the selected UUID', (
    tester,
  ) async {
    final selections = <String>[];
    await openSheet(tester, beans: [bean], onSelect: selections.add);

    final bottomSheet = find.byType(BottomSheet);
    expect(bottomSheet, findsOneWidget);
    expect(tester.widget<BottomSheet>(bottomSheet).showDragHandle, isTrue);
    expect(find.byType(Dialog), findsNothing);
    final heading = tester.widget<Text>(find.text('Select Coffee Beans'));
    expect(heading.style?.fontSize, AppTextStyles.title.fontSize);
    expect(
      find.bySemanticsIdentifier('selectCoffeeBeansAppBar'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('addNewBeansTile'), findsOneWidget);
    expect(find.bySemanticsIdentifier('nextButton'), findsOneWidget);
    expect(
      find.descendant(
        of: selector,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient is LinearGradient,
        ),
      ),
      findsNothing,
    );

    final next = find.widgetWithText(ElevatedButton, 'Next');
    expect(tester.widget<ElevatedButton>(next).enabled, isFalse);
    expect(
      tester.getSize(next).width,
      tester.getSize(selector).width - 2 * AppSpacing.base,
    );
    expect(selections, isEmpty);
    await tester.tap(
      find.bySemanticsIdentifier('coffeeBeanTile_${bean.beansUuid}'),
    );
    await tester.pump();
    expect(tester.widget<ElevatedButton>(next).enabled, isTrue);
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(selections, [bean.beansUuid]);
  });

  testWidgets('shows only the add row when no beans are saved', (tester) async {
    await openSheet(tester, beans: [], onSelect: (_) {});

    final rows = find.descendant(of: selector, matching: find.byType(ListTile));
    expect(rows, findsOneWidget);
    expect(find.bySemanticsIdentifier('addNewBeansTile'), findsOneWidget);
    expect(find.text('Add New Beans'), findsOneWidget);
  });

  testWidgets('lays out an 80-character name at 320 points wide', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final longName = 'A' * 80;

    await openSheet(
      tester,
      beans: [bean.copyWith(name: longName)],
      onSelect: (_) {},
    );

    expect(find.text(longName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
