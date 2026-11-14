// Widget tests for the journey card's "try another recipe" milestone tile
// (the private `_TryRecipeMilestoneTile`, reached only through the public
// `CoffeeJourneyCard`).
//
// While the milestone is incomplete the tile reads the brew history from the
// database and derives a concrete recipe suggestion via
// `suggestJourneyRecipe`; with a suggestion it names the recipe and pushes
// the recipe detail route on tap, in every other state (loading, no
// suggestion, milestone done) it renders exactly the generic, untappable
// tile it replaces.
//
// Patterns reused from existing tests:
// - in-memory Drift database: test/helpers/test_database.dart
// - user_stats seeding: the `_makeStat` helper in
//   test/unit/services/local_notification_scheduler_service_test.dart
// - recipe + localization seeding:
//   test/database/recipes_dao_soft_delete_test.dart
// - router stub (`StackRouterScope` + `Mock implements StackRouter`):
//   test/unit/month_strip_test.dart
// - analytics assertions: `AnalyticsService.bufferedEventsForTesting`

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/coffee_journey_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// `l10n.coffeeJourneyMilestoneTryMethod` — the generic, suggestion-less
/// label (en locale).
const String _genericLabel = 'Try another recipe';

/// Prefix of `l10n.coffeeJourneyMilestoneTryRecipeNamed` (en locale).
const String _namedLabelPrefix = 'Try another recipe: ';

String _namedLabel(String recipeName) => '$_namedLabelPrefix$recipeName';

/// Onboarding prefs that make the card visible on the brewing methods
/// (home) surface.
const Map<String, Object> _visibleOnHome = {
  'onboarding_complete': true,
  'onboarding_first_brew_done': true,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

UserStatsModel _makeStat({
  String uuid = 'stat-1',
  String recipeId = 'recipe-1',
  String brewingMethodId = 'method-1',
  DateTime? createdAt,
}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: recipeId,
    coffeeAmount: 15.0,
    waterAmount: 250.0,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: brewingMethodId,
    createdAt: createdAt ?? DateTime.now(),
    isMarked: false,
    versionVector: VersionVector.initial('test').toString(),
    isDeleted: false,
  );
}

/// Seeds a recipe row plus its en localization so the suggested
/// `RecipeModel.name` is deterministic.
Future<void> _seedRecipe(
  AppDatabase db, {
  required String id,
  required String methodId,
  required String name,
}) async {
  await db.recipesDao.insertOrUpdateRecipe(
    RecipesCompanion.insert(
      id: id,
      brewingMethodId: methodId,
      coffeeAmount: 15,
      waterAmount: 250,
      waterTemp: 93,
      brewTime: 240,
    ),
  );
  await db.into(db.recipeLocalizations).insert(
        RecipeLocalizationsCompanion.insert(
          id: '$id-en',
          recipeId: id,
          locale: 'en',
          name: name,
          grindSize: 'Medium',
          shortDescription: '',
        ),
      );
}

Future<OnboardingService> _onboardingWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return OnboardingService(await SharedPreferences.getInstance());
}

Widget _host({
  required Widget child,
  required OnboardingService onboarding,
  AppDatabase? database,
  _RecordingStackRouter? router,
}) {
  Widget app = MultiProvider(
    providers: [
      ChangeNotifierProvider<OnboardingService>.value(value: onboarding),
      // Only visible-card cases provide a database: the card must look it
      // up (listen:false) only after the visibility check passes, so the
      // hidden-card test deliberately leaves this provider out.
      if (database != null) Provider<AppDatabase>.value(value: database),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
  if (router != null) {
    app = StackRouterScope(controller: router, stateHash: 0, child: app);
  }
  return app;
}

/// Lets the tile's real async DB load finish: `testWidgets` runs in a fake
/// async zone, so the drift futures started in `initState` only progress
/// while a `runAsync` block is executing.
///
/// With [expectNamedLabel] the block returns as soon as the named label
/// renders. Without one there is no observable completion signal (the load
/// ends in a no-op `setState`), so it waits a fixed interval — generous for
/// an in-memory SQLite database whose queries complete in under a
/// millisecond.
Future<void> _letTileLoad(
  WidgetTester tester, {
  required bool expectNamedLabel,
}) async {
  await tester.runAsync(() async {
    if (!expectNamedLabel) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (find.textContaining(_namedLabelPrefix).evaluate().isNotEmpty) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pump();
}

List<Map<String, dynamic>> _suggestionEvents() => AnalyticsService
    .instance.bufferedEventsForTesting
    .where((e) => e['event_name'] == 'journey_milestone_suggested')
    .toList();

/// The single InkWell wrapping a milestone label (the header row's InkWell
/// is a sibling, not an ancestor).
InkWell _tileInkWell(WidgetTester tester, Finder label) {
  final wells = tester
      .widgetList<InkWell>(
        find.ancestor(of: label, matching: find.byType(InkWell)),
      )
      .toList();
  expect(wells, hasLength(1), reason: 'a milestone label has one InkWell');
  return wells.single;
}

/// Records the route passed to `push` so the tile's navigation can be
/// asserted without a real router (same pattern as month_strip_test.dart).
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  testWidgets('no brews: generic label, tile not tappable, no event', (
    tester,
  ) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: false);

    expect(find.text(_genericLabel), findsOneWidget);
    expect(find.textContaining(_namedLabelPrefix), findsNothing);
    expect(_tileInkWell(tester, find.text(_genericLabel)).onTap, isNull);
    expect(_suggestionEvents(), isEmpty);
  });

  testWidgets('one brew: generic label (too early to suggest)', (tester) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      // Another recipe exists in the method, so only the brew count keeps
      // the tile generic — without these the test would pass for the wrong
      // reason.
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
      await _seedRecipe(
        db,
        id: 'recipe-2',
        methodId: 'method-1',
        name: 'Espresso Tonic',
      );
    });

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: false);

    expect(find.text(_genericLabel), findsOneWidget);
    expect(find.textContaining(_namedLabelPrefix), findsNothing);
    expect(_tileInkWell(tester, find.text(_genericLabel)).onTap, isNull);
    expect(_suggestionEvents(), isEmpty);
  });

  testWidgets(
      'two brews of one recipe with another recipe in the method: names it, '
      'tap pushes the detail route, suggestion tracked', (tester) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-2',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
      await _seedRecipe(
        db,
        id: 'recipe-2',
        methodId: 'method-1',
        name: 'Espresso Tonic',
      );
    });

    final router = _RecordingStackRouter();
    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
      router: router,
    ));
    await _letTileLoad(tester, expectNamedLabel: true);

    expect(find.text(_namedLabel('Espresso Tonic')), findsOneWidget);
    expect(find.text(_genericLabel), findsNothing);
    final onTap = _tileInkWell(tester, find.text(_namedLabel('Espresso Tonic')))
        .onTap;
    expect(onTap, isNotNull);

    await tester.tap(find.text(_namedLabel('Espresso Tonic')));
    await tester.pump();

    expect(router.pushedRoute, isA<RecipeDetailRoute>());
    final args =
        (router.pushedRoute! as RecipeDetailRoute).args as RecipeDetailRouteArgs;
    expect(args.brewingMethodId, 'method-1');
    expect(args.recipeId, 'recipe-2');

    final events = _suggestionEvents();
    expect(events, hasLength(1), reason: 'exactly one suggestion event');
    expect(events.single['properties'], {
      'milestone': 'try_recipe',
      'recipe_id': 'recipe-2',
      'location': 'home',
    });
  });

  testWidgets('two brews of two different recipes: generic label', (
    tester,
  ) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-2',
        recipeId: 'recipe-2',
        brewingMethodId: 'method-1',
      ));
      // Even with a suggestible recipe in the method, spanning two recipes
      // means the milestone is already done.
      await _seedRecipe(
        db,
        id: 'recipe-3',
        methodId: 'method-1',
        name: 'Third Recipe',
      );
    });

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: false);

    expect(find.text(_genericLabel), findsOneWidget);
    expect(find.textContaining(_namedLabelPrefix), findsNothing);
    expect(_tileInkWell(tester, find.text(_genericLabel)).onTap, isNull);
    expect(_suggestionEvents(), isEmpty);
  });

  testWidgets('two brews of one recipe, method has no other: generic label', (
    tester,
  ) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-2',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      // Only the brewed recipe itself exists in the method.
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
    });

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: false);

    expect(find.text(_genericLabel), findsOneWidget);
    expect(find.textContaining(_namedLabelPrefix), findsNothing);
    expect(_tileInkWell(tester, find.text(_genericLabel)).onTap, isNull);
    expect(_suggestionEvents(), isEmpty);
  });

  testWidgets(
      'try-recipe milestone already done: generic label even though a '
      'suggestion would exist', (tester) async {
    final onboarding = await _onboardingWith({
      ..._visibleOnHome,
      'onboarding_milestone_try_method': true,
    });
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-2',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
      await _seedRecipe(
        db,
        id: 'recipe-2',
        methodId: 'method-1',
        name: 'Espresso Tonic',
      );
    });

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: false);

    expect(find.text(_genericLabel), findsOneWidget);
    expect(find.textContaining(_namedLabelPrefix), findsNothing);
    expect(_tileInkWell(tester, find.text(_genericLabel)).onTap, isNull);
    // The load never starts for a done milestone.
    expect(_suggestionEvents(), isEmpty);
  });

  testWidgets('hidden card pumps without AppDatabase and renders nothing', (
    tester,
  ) async {
    // Empty prefs: the journey has not started, so the card is hidden.
    final onboarding = await _onboardingWith({});
    addTearDown(onboarding.dispose);

    // No Provider<AppDatabase> in the tree — if the card looked the database
    // up before its visibility check, this pump would throw
    // ProviderNotFoundError and fail the test.
    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
    ));
    await tester.pump();

    expect(find.byType(Card), findsNothing);
    expect(find.text(_genericLabel), findsNothing);
    expect(find.textContaining(_namedLabelPrefix), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long suggested name does not overflow a 320dp surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    const longName =
        'Slow Dawn Hand-Roasted Anaerobic Natural Whole-Cherry Recipe';
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-2',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
      await _seedRecipe(
        db,
        id: 'recipe-2',
        methodId: 'method-1',
        name: longName,
      );
    });

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: true);

    expect(find.text(_namedLabel(longName)), findsOneWidget);
    // A RenderFlex overflow also fails the test on its own; this makes the
    // intent explicit.
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub variant shows the named label and tracks location hub', (
    tester,
  ) async {
    // The hub card only appears once dismissed from home, and it renders
    // collapsed by default — expand it so the milestone tiles show.
    final onboarding = await _onboardingWith({
      ..._visibleOnHome,
      'onboarding_journey_dismissed': true,
      'onboarding_hub_journey_collapsed': false,
    });
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-2',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
      await _seedRecipe(
        db,
        id: 'recipe-2',
        methodId: 'method-1',
        name: 'Espresso Tonic',
      );
    });

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(location: JourneyCardLocation.hub),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester, expectNamedLabel: true);

    expect(find.text(_namedLabel('Espresso Tonic')), findsOneWidget);
    expect(
      _tileInkWell(tester, find.text(_namedLabel('Espresso Tonic'))).onTap,
      isNotNull,
    );

    final events = _suggestionEvents();
    expect(events, hasLength(1), reason: 'exactly one suggestion event');
    expect(events.single['properties'], {
      'milestone': 'try_recipe',
      'recipe_id': 'recipe-2',
      'location': 'hub',
    });
  });
}
