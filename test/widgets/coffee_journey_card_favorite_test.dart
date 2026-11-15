// Widget tests for the journey card's "favorite a recipe" milestone tile
// (the private `_FavoriteMilestoneTile`, reached only through the public
// `CoffeeJourneyCard`).
//
// While the milestone is incomplete the tile loads the most recently brewed
// recipe; if it exists and is not tombstoned, a tap opens that recipe's
// detail screen with the heart highlight enabled. In every other state
// (loading, no brews, recipe missing/tombstoned, milestone done) a tap
// keeps the generic behaviour of pushing the favorites screen. The label
// never changes, so the interesting behaviour is the tap destination.
//
// Patterns reused from coffee_journey_card_try_recipe_test.dart:
// - in-memory Drift database: test/helpers/test_database.dart
// - user_stats seeding, router stub (`StackRouterScope` + `Mock implements
//   StackRouter`), `_letTileLoad` fixed-delay wait
// The "no DB load" assertion uses a drift `QueryInterceptor` that counts
// SELECTs on the user_stats table: with both stateful milestones done no
// tile may query, and with only the favorite tile open exactly one query
// (its fetchRecentStats) may run.

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/coffee_journey_card.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `l10n.coffeeJourneyMilestoneFavorite` (en locale). The label is the same
/// in every tile state — only the tap destination changes.
const String _favoriteLabel = 'Favorite a recipe';

/// Onboarding prefs that make the card visible on the brewing methods
/// (home) surface, with the "try another recipe" milestone already done so
/// the favorite tile's DB traffic is the only user_stats traffic.
const Map<String, Object> _visibleTryDone = {
  'onboarding_complete': true,
  'onboarding_first_brew_done': true,
  'onboarding_milestone_try_method': true,
};

/// Same, plus the favorite milestone itself already done.
const Map<String, Object> _visibleBothDone = {
  ..._visibleTryDone,
  'onboarding_milestone_favorite': true,
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

/// Seeds a recipe row plus its en localization.
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

/// Counts drift SELECTs so tests can assert which tiles hit the database.
/// Only statements touching user_stats are counted: that is the table both
/// stateful tiles read first, and the favorite tile's recipe lookup touches
/// recipes instead — counting user_stats keeps the expectation exact.
class _UserStatsSelectCounter extends drift.QueryInterceptor {
  int userStatsSelects = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    drift.QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.toLowerCase().contains('user_stats')) {
      userStatsSelects++;
    }
    return super.runSelect(executor, statement, args);
  }
}

AppDatabase _openCountedDatabase(_UserStatsSelectCounter counter) {
  return AppDatabase(
    NativeDatabase.memory().interceptWith(counter),
    enableForeignKeyConstraints: false,
  );
}

Widget _host({
  required Widget child,
  required OnboardingService onboarding,
  required AppDatabase database,
  _RecordingStackRouter? router,
}) {
  Widget app = MultiProvider(
    providers: [
      ChangeNotifierProvider<OnboardingService>.value(value: onboarding),
      Provider<AppDatabase>.value(value: database),
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

/// The favorite tile's label never changes, so there is no observable
/// completion signal for its load: waits a fixed interval — generous for an
/// in-memory SQLite database whose queries complete in under a millisecond
/// — then pumps so any resulting setState renders.
Future<void> _letTileLoad(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}

/// Records the route passed to `push` so the tile's navigation can be
/// asserted without a real router.
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

  testWidgets(
      'one brew, milestone open: tap pushes the brewed recipe with '
      'highlightFavorite, and only the favorite tile hits the DB', (
    tester,
  ) async {
    final onboarding = await _onboardingWith(_visibleTryDone);
    addTearDown(onboarding.dispose);
    final counter = _UserStatsSelectCounter();
    final db = _openCountedDatabase(counter);
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
    });

    final router = _RecordingStackRouter();
    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
      router: router,
    ));
    await _letTileLoad(tester);

    expect(find.text(_favoriteLabel), findsOneWidget);
    // Exactly one user_stats select: the favorite tile's fetchRecentStats.
    // (The try-recipe milestone is done, so its tile must not query.)
    expect(counter.userStatsSelects, 1);

    await tester.tap(find.text(_favoriteLabel));
    await tester.pump();

    expect(router.pushedRoute, isA<RecipeDetailRoute>());
    final args =
        (router.pushedRoute! as RecipeDetailRoute).args as RecipeDetailRouteArgs;
    expect(args.recipeId, 'recipe-1');
    expect(args.brewingMethodId, 'method-1');
    expect(args.highlightFavorite, isTrue);
  });

  testWidgets('no brews: tap pushes the favorites screen', (tester) async {
    final onboarding = await _onboardingWith(_visibleTryDone);
    addTearDown(onboarding.dispose);
    final db = _openCountedDatabase(_UserStatsSelectCounter());
    addTearDown(db.close);

    final router = _RecordingStackRouter();
    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
      router: router,
    ));
    await _letTileLoad(tester);

    expect(find.text(_favoriteLabel), findsOneWidget);
    await tester.tap(find.text(_favoriteLabel));
    await tester.pump();

    expect(router.pushedRoute, isA<FavoriteRecipesRoute>());
  });

  testWidgets(
      'milestone done: tap pushes the favorites screen and no DB load '
      'happens', (tester) async {
    final onboarding = await _onboardingWith(_visibleBothDone);
    addTearDown(onboarding.dispose);
    final counter = _UserStatsSelectCounter();
    final db = _openCountedDatabase(counter);
    addTearDown(db.close);
    // A brew exists that WOULD be loaded if the tile ignored the milestone.
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
    });

    final router = _RecordingStackRouter();
    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
      router: router,
    ));
    await _letTileLoad(tester);

    expect(find.text(_favoriteLabel), findsOneWidget);
    // Neither stateful tile may query when its milestone is done.
    expect(counter.userStatsSelects, 0);

    await tester.tap(find.text(_favoriteLabel));
    await tester.pump();

    expect(router.pushedRoute, isA<FavoriteRecipesRoute>());
  });

  testWidgets('last-brewed recipe tombstoned: tap pushes the favorites screen',
      (tester) async {
    final onboarding = await _onboardingWith(_visibleTryDone);
    addTearDown(onboarding.dispose);
    final db = _openCountedDatabase(_UserStatsSelectCounter());
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.userStatsDao.insertUserStat(_makeStat(
        uuid: 'stat-1',
        recipeId: 'recipe-1',
        brewingMethodId: 'method-1',
      ));
      await _seedRecipe(
        db,
        id: 'recipe-1',
        methodId: 'method-1',
        name: 'V60 Morning',
      );
      await db.recipesDao.softDeleteRecipe('recipe-1');
    });

    final router = _RecordingStackRouter();
    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
      router: router,
    ));
    await _letTileLoad(tester);

    expect(find.text(_favoriteLabel), findsOneWidget);
    await tester.tap(find.text(_favoriteLabel));
    await tester.pump();

    expect(router.pushedRoute, isA<FavoriteRecipesRoute>());
  });
}
