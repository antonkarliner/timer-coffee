import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/bean_brews_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'shortcut stays hidden while loading and for error or empty data',
    (tester) async {
      final loading = Completer<List<UserStatsModel>>();
      await _pump(
        tester,
        child: BeanJourneyShortcut(
          beansUuid: 'bean-1',
          statsFuture: loading.future,
          onTap: () async {},
        ),
      );
      expect(
        find.bySemanticsIdentifier('beanJourneyShortcut_bean-1'),
        findsNothing,
      );

      final failed = Completer<List<UserStatsModel>>();
      await _pump(
        tester,
        child: BeanJourneyShortcut(
          beansUuid: 'bean-1',
          statsFuture: failed.future,
          onTap: () async {},
        ),
      );
      failed.completeError(StateError('load failed'));
      await tester.pump();
      expect(
        find.bySemanticsIdentifier('beanJourneyShortcut_bean-1'),
        findsNothing,
      );

      await _pump(
        tester,
        child: BeanJourneyShortcut(
          beansUuid: 'bean-1',
          statsFuture: Future.value([]),
          onTap: () async {},
        ),
      );
      await tester.pump();
      expect(
        find.bySemanticsIdentifier('beanJourneyShortcut_bean-1'),
        findsNothing,
      );
    },
  );

  testWidgets('shortcut shows distinct methods and the newest unsorted date', (
    tester,
  ) async {
    final stats = [
      _stat(id: 'old-v60', methodId: 'v60', day: 1),
      _stat(id: 'new-v60', methodId: 'v60', day: 9),
      _stat(id: 'middle-aero', methodId: 'aeropress', day: 5),
    ];
    await _pump(
      tester,
      child: BeanJourneyShortcut(
        beansUuid: 'bean-1',
        statsFuture: Future.value(stats),
        onTap: () async {},
      ),
    );
    await tester.pumpAndSettle();
    final loc = _localizations(tester);
    final formatService = DateTimeFormatService();
    final newestDate = DateFormat(
      formatService.datePattern(loc.dateFormat),
      'en',
    ).format(stats[1].createdAt);

    final shortcut = find.bySemanticsIdentifier('beanJourneyShortcut_bean-1');
    expect(shortcut, findsOneWidget);
    expect(find.text(loc.beanJourneyTitle), findsOneWidget);
    expect(find.textContaining(loc.diaryGroupBrewCount(3)), findsOneWidget);
    expect(
      find.textContaining(loc.formattedBrewingMethodCount(2)),
      findsOneWidget,
    );
    expect(
      find.textContaining(loc.beanJourneyLastBrewed(newestDate)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.library_books), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('shortcut tap opens the exact Bean Journey route', (
    tester,
  ) async {
    final router = _RecordingStackRouter();
    await _pump(
      tester,
      router: router,
      child: BeanJourneyShortcut(
        beansUuid: 'bean-exact',
        statsFuture: Future.value([_stat(id: 'one')]),
        onTap: () => router.push(BeanJourneyRoute(beanUuid: 'bean-exact')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsIdentifier('beanJourneyShortcut_bean-exact'),
    );
    await tester.pump();

    expect(router.pushedRoute, isA<BeanJourneyRoute>());
    final args = router.pushedRoute!.args as BeanJourneyRouteArgs;
    expect(args.beanUuid, 'bean-exact');
  });

  testWidgets('shortcut fits narrow German and Arabic layouts', (tester) async {
    for (final locale in [const Locale('de'), const Locale('ar')]) {
      for (final width in [320.0, 390.0]) {
        await _pump(
          tester,
          locale: locale,
          size: Size(width, 700),
          child: BeanJourneyShortcut(
            beansUuid: 'bean-narrow',
            statsFuture: Future.value([
              _stat(id: 'one', methodId: 'v60'),
              _stat(id: 'two', methodId: 'aeropress'),
              _stat(id: 'three', methodId: 'v60'),
              _stat(id: 'four', methodId: 'chemex'),
            ]),
            onTap: () async {},
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsIdentifier('beanJourneyShortcut_bean-narrow'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('brew list remains collapsed and rows open one expanded brew', (
    tester,
  ) async {
    final router = _RecordingStackRouter();
    final loc = await _pump(
      tester,
      router: router,
      child: BeanBrewsSection(
        beansUuid: 'bean-exact',
        statsFuture: Future.value([_stat(id: 'stat-exact')]),
        onJourneyTap: () =>
            router.push(BeanJourneyRoute(beanUuid: 'bean-exact')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('beanJourneyShortcut_bean-exact'),
      findsNothing,
    );
    expect(find.text('Recipe stat-exact'), findsNothing);
    await tester.tap(find.text(loc.brewsWithThisCoffee));
    await tester.pumpAndSettle();
    final shortcut = find.bySemanticsIdentifier(
      'beanJourneyShortcut_bean-exact',
    );
    expect(shortcut, findsOneWidget);
    expect(find.text('Recipe stat-exact'), findsOneWidget);
    expect(
      tester.getTopLeft(shortcut).dy,
      lessThan(tester.getTopLeft(find.text('Recipe stat-exact')).dy),
    );

    await tester.tap(find.text('Recipe stat-exact'));
    await tester.pump();

    expect(router.pushedRoute, isA<BrewDiaryRoute>());
    final args = router.pushedRoute!.args as BrewDiaryRouteArgs;
    expect(args.initialExpandedStatUuid, 'stat-exact');
  });
}

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  required Widget child,
  StackRouter? router,
  Locale locale = const Locale('en'),
  Size size = const Size(900, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget app = MultiProvider(
    providers: [
      ChangeNotifierProvider<DateTimeFormatService>(
        create: (_) => DateTimeFormatService(),
      ),
      ChangeNotifierProvider<RecipeProvider>.value(
        value: _StubRecipeProvider(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    ),
  );
  if (router != null) {
    app = StackRouterScope(controller: router, stateHash: 0, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pump();
  return _localizations(tester);
}

AppLocalizations _localizations(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

UserStatsModel _stat({
  required String id,
  String methodId = 'v60',
  int day = 1,
}) {
  return UserStatsModel(
    statUuid: id,
    recipeId: 'recipe-$id',
    coffeeAmount: 15,
    waterAmount: 250,
    sweetnessSliderPosition: 0,
    strengthSliderPosition: 0,
    brewingMethodId: methodId,
    createdAt: DateTime(2026, 7, day, 9),
    isMarked: false,
    versionVector: '{}',
    isDeleted: false,
  );
}

class _StubRecipeProvider extends Mock implements RecipeProvider {
  @override
  Future<String> getBrewingMethodName(String? brewingMethodId) async =>
      brewingMethodId == 'v60' ? 'V60' : 'AeroPress';

  @override
  Future<String> getLocalizedRecipeName(String recipeId) async =>
      'Recipe ${recipeId.substring('recipe-'.length)}';
}

class _RecordingStackRouter extends Mock implements StackRouter {
  PageRouteInfo? pushedRoute;

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushedRoute = route;
    return null;
  }
}
