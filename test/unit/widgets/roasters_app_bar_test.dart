// Plan 089 D4/D3: the Roasters catalogue app bar carries an icon+text title
// and the same outlined search field as My Beans, moved from the toolbar row
// into an AppBar.bottom slot under it.
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/app_bar_title.dart';
import 'package:coffee_timer/widgets/roasters/roasters_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Widget wrap({
    String searchQuery = '',
    bool hasActiveFilter = false,
    VoidCallback? onFilterPressed,
    VoidCallback? onSearchCleared,
    ValueChanged<String>? onSearchChanged,
  }) {
    return MaterialApp(
      theme: ThemeProvider(ThemeMode.light).lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        appBar: RoastersAppBar(
          searchController: controller,
          searchFocusNode: focusNode,
          searchQuery: searchQuery,
          hasActiveFilter: hasActiveFilter,
          onFilterPressed: onFilterPressed ?? () {},
          onSearchCleared: onSearchCleared ?? () {},
          onSearchChanged: onSearchChanged ?? (_) {},
        ),
        body: const SizedBox.expand(),
      ),
    );
  }

  testWidgets('title is the storefront icon + catalogue title', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byType(AppBarTitle), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.text('Roasters'), findsOneWidget);
  });

  testWidgets('search field sits below the toolbar, under the title', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    final fieldTop = tester.getTopLeft(find.byType(TextField)).dy;
    final titleBottom = tester.getBottomRight(find.byType(AppBarTitle)).dy;

    expect(fieldTop, greaterThanOrEqualTo(titleBottom));
    expect(fieldTop, greaterThanOrEqualTo(kToolbarHeight));
  });

  testWidgets('field height matches the constant and the bar preferredSize', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    final fieldHeight = tester.getSize(find.byType(TextField)).height;
    expect(fieldHeight, RoastersAppBar.searchFieldHeight);

    final bar = tester.widget<RoastersAppBar>(find.byType(RoastersAppBar));
    expect(
      bar.preferredSize.height,
      kToolbarHeight + RoastersAppBar.bottomHeight,
    );
    expect(
      RoastersAppBar.bottomHeight,
      RoastersAppBar.searchFieldHeight + AppSpacing.sm,
    );
  });

  testWidgets('field has no explicit enabled/focused border overrides', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    final deco = tester.widget<TextField>(find.byType(TextField)).decoration!;
    expect(deco.border, InputBorder.none);
    expect(deco.enabledBorder, isNull);
    expect(deco.focusedBorder, isNull);
  });

  testWidgets('typing reports onSearchChanged and updates the controller', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(wrap(onSearchChanged: queries.add));

    await tester.enterText(find.byType(TextField), 'blue bottle');

    expect(queries, ['blue bottle']);
    expect(controller.text, 'blue bottle');
  });

  testWidgets('clear button appears with a query and calls onSearchCleared', (
    tester,
  ) async {
    var cleared = 0;
    await tester.pumpWidget(
      wrap(searchQuery: 'blue', onSearchCleared: () => cleared++),
    );

    expect(find.byIcon(Icons.clear), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear));

    expect(cleared, 1);
  });

  testWidgets('no clear button without a query', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('no overflow at 320 px wide with an active filter badge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(hasActiveFilter: true));

    expect(tester.takeException(), isNull);
    final field = tester.getRect(find.byType(TextField));
    expect(field.left, greaterThanOrEqualTo(AppSpacing.base));
    expect(field.right, lessThanOrEqualTo(320 - AppSpacing.base));
  });
}
