import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_view_state.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/screens/coffee_beans_screen.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_bean_card.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_bean_grid_card.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_beans_grid_view.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_beans_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _CoffeeBeansProvider extends Mock implements CoffeeBeansProvider {}

class _DatabaseProvider extends Mock implements DatabaseProvider {
  @override
  Future<Map<String, String?>> fetchCachedRoasterLogoUrls(
    String roasterName,
  ) async => {'original': null, 'mirror': null};
}

void main() {
  tearDown(() {
    debugForYouOnMyBeansOverride = null;
  });

  // Exercise the screen's eligibility function without initializing its
  // controller, preferences, navigation, or recommendation services.
  test('My Beans header requires every placement condition', () {
    for (final debug in [false, true]) {
      debugForYouOnMyBeansOverride = debug;
      for (final hasBeans in [false, true]) {
        for (final searchQuery in ['', 'coffee']) {
          for (final hasActiveFilters in [false, true]) {
            for (final isEditMode in [false, true]) {
              expect(
                shouldShowForYouOnMyBeans(
                  hasBeans: hasBeans,
                  searchQuery: searchQuery,
                  hasActiveFilters: hasActiveFilters,
                  isEditMode: isEditMode,
                ),
                debug &&
                    hasBeans &&
                    searchQuery.isEmpty &&
                    !hasActiveFilters &&
                    !isEditMode,
                reason:
                    '$debug, $hasBeans, "$searchQuery", '
                    '$hasActiveFilters, $isEditMode',
              );
            }
          }
        }
      }
    }
  });

  test('without an override the dart define controls placement', () {
    debugForYouOnMyBeansOverride = null;
    expect(
      shouldShowForYouOnMyBeans(
        hasBeans: true,
        searchQuery: '',
        hasActiveFilters: false,
        isEditMode: false,
      ),
      const bool.fromEnvironment('FOR_YOU_DEBUG'),
    );
  });

  final beans = List.generate(
    30,
    (index) => CoffeeBeansModel(
      beansUuid: 'bean-$index',
      roaster: 'Roaster',
      name: 'Bean $index',
      origin: 'Origin',
      versionVector: '{}',
    ),
  );
  const headerKey = ValueKey('header');
  const header = SizedBox(key: headerKey, height: 120);

  Widget host(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<CoffeeBeansProvider>(
        create: (_) => _CoffeeBeansProvider(),
      ),
      Provider<DatabaseProvider>(create: (_) => _DatabaseProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );

  for (final mode in ViewMode.values) {
    Widget view({Widget? header, ScrollController? controller}) {
      final state = CoffeeBeansViewState(viewMode: mode);
      return mode == ViewMode.list
          ? CoffeeBeansListView(
              beans: beans,
              viewState: state,
              header: header,
              scrollController: controller,
              onDelete: (_) {},
              onFavoriteToggle: (_) {},
              onTap: (_) {},
            )
          : CoffeeBeansGridView(
              beans: beans,
              viewState: state,
              header: header,
              scrollController: controller,
              onDelete: (_) {},
              onFavoriteToggle: (_) {},
              onTap: (_) {},
            );
    }

    SliverChildBuilderDelegate beanDelegate(WidgetTester tester) =>
        mode == ViewMode.list
        ? tester.widget<ListView>(find.byType(ListView)).childrenDelegate
              as SliverChildBuilderDelegate
        : tester.widget<SliverGrid>(find.byType(SliverGrid)).delegate
              as SliverChildBuilderDelegate;

    testWidgets('${mode.name}: header is first, full width, and scrolls away', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(view(header: header, controller: controller)),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(headerKey);
      final firstBean = find.byKey(ValueKey(beans.first.beansUuid));
      final before = tester.getRect(headerFinder);
      expect(before.bottom, lessThanOrEqualTo(tester.getTopLeft(firstBean).dy));
      expect(before.left, 0);
      expect(before.width, tester.getSize(find.byType(Scaffold)).width);
      expect(controller.position.physics, isA<AlwaysScrollableScrollPhysics>());

      final delegate = beanDelegate(tester);
      final offset = mode == ViewMode.list ? 1 : 0;
      expect(delegate.childCount, beans.length + offset);
      final context = tester.element(firstBean);
      for (var index = 0; index < beans.length; index++) {
        final item = delegate.builder(context, index + offset)!;
        final card = item is Padding ? item.child! : item;
        expect(card.key, ValueKey(beans[index].beansUuid));
      }

      // A small scroll moves the header by the same distance...
      controller.jumpTo(20);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(headerFinder).dy, before.top - 20);

      // ...and a larger one takes it off screen. Lazy lists drop children
      // that leave the viewport, so it is gone from the tree, not pinned.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(headerFinder.hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '${mode.name}: null header preserves bean count, keys and padding',
      (tester) async {
        await tester.pumpWidget(host(view()));
        await tester.pumpAndSettle();
        expect(find.byKey(headerKey), findsNothing);
        final delegate = beanDelegate(tester);
        expect(delegate.childCount, beans.length);
        final firstBean = find.byKey(ValueKey(beans.first.beansUuid));
        final context = tester.element(firstBean);
        for (var index = 0; index < beans.length; index++) {
          final item = delegate.builder(context, index)!;
          final card = item is Padding ? item.child! : item;
          expect(card.key, ValueKey(beans[index].beansUuid));
          if (mode == ViewMode.list) {
            expect((card as CoffeeBeanCard).bean, same(beans[index]));
          } else {
            expect((card as CoffeeBeanGridCard).bean, same(beans[index]));
          }
        }
        expect(
          tester.getTopLeft(firstBean),
          const Offset(AppSpacing.base, AppSpacing.base),
        );
        if (mode == ViewMode.list) {
          expect(
            tester.widget<ListView>(find.byType(ListView)).padding,
            const EdgeInsets.all(AppSpacing.base),
          );
        } else {
          expect(find.byType(SliverToBoxAdapter), findsNothing);
          final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
          final layout =
              grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
          expect(layout.crossAxisCount, 2);
          expect(layout.childAspectRatio, 0.65);
          expect(layout.crossAxisSpacing, AppSpacing.base);
          expect(layout.mainAxisSpacing, AppSpacing.base);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
