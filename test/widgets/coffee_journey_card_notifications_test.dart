// Widget tests for the journey card's "turn on brew updates" milestone tile
// (the private `_NotificationsMilestoneTile`, reached only through the
// public `CoffeeJourneyCard`).
//
// The row renders LAST so the build loop's index-based tile selection
// (`index == 1` → try-recipe tile, `index == 3` → favorite tile) keeps the
// two existing stateful tiles at their positions — that ordering is asserted
// here. The row disappears while the OS has denied permission (hidden), and
// once done it renders struck-through and untappable like the other
// milestones.
//
// The OS permission request is injected through the card's
// `requestNotificationPermission` seam — a widget test never exercises the
// real OS permission plumbing. The tap flow is covered below (grant → done +
// events + reschedule; denial → row quietly hidden). Completion and hide
// service behavior is covered further in
// test/unit/services/onboarding_service_test.dart.
//
// Patterns reused from coffee_journey_card_favorite_test.dart /
// coffee_journey_card_try_recipe_test.dart: in-memory Drift database
// (test/helpers/test_database.dart), user_stats seeding, router stub,
// `_letTileLoad` fixed-delay wait.

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/local_notification_scheduler_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/coffee_journey_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// `l10n.coffeeJourneyMilestoneNotifications` (en locale).
const String _notificationsLabel = 'Turn on brew updates';

/// Onboarding prefs that make the card visible on the brewing methods
/// (home) surface.
const Map<String, Object> _visibleOnHome = {
  'onboarding_complete': true,
  'onboarding_first_brew_done': true,
};

/// All seven en milestone labels in card order when the notifications
/// milestone is visible (with the try-recipe tile naming its suggestion).
const List<String> _allLabelsInOrder = [
  'Complete your first brew',
  'Try another recipe: Espresso Tonic',
  'Add your first coffee beans',
  'Favorite a recipe',
  'Check your brew stats',
  'See how the world brews with you',
  _notificationsLabel,
];

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

/// The try-recipe tile's named label only renders after its async DB load:
/// waits (generous for an in-memory SQLite database) inside `runAsync`, then
/// pumps so any resulting setState renders.
Future<void> _letTileLoad(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}

/// Every `Text` in the card, in tree order — the card renders exactly one
/// header label followed by the milestone labels, so this doubles as the
/// milestone ordering.
List<String> _textsInOrder(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
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
      'milestone visible: row renders LAST with the right label, and the '
      'existing stateful tiles stay at positions 1 and 3', (tester) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);
    await tester.runAsync(() async {
      // Two brews of one recipe plus an untried recipe in the method → the
      // try-recipe tile (position 1) names the suggestion, proving it is
      // still the stateful tile at index 1.
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
    await _letTileLoad(tester);

    final texts = _textsInOrder(tester);
    expect(texts.first, 'First Steps', reason: 'card header');
    expect(texts.sublist(1), _allLabelsInOrder);
  });

  testWidgets(
      'position 3 is still the stateful favorite tile: its tap opens the '
      'last-brewed recipe with the heart highlight', (tester) async {
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

    expect(find.text(_notificationsLabel), findsOneWidget);
    await tester.tap(find.text('Favorite a recipe'));
    await tester.pump();

    expect(router.pushedRoute, isA<RecipeDetailRoute>());
    final args =
        (router.pushedRoute! as RecipeDetailRoute).args as RecipeDetailRouteArgs;
    expect(args.recipeId, 'recipe-1');
    expect(args.highlightFavorite, isTrue);
  });

  testWidgets('milestone hidden: row absent and total back to 6',
      (tester) async {
    final onboarding = await _onboardingWith({
      ..._visibleOnHome,
      'onboarding_milestone_notifications_hidden': true,
    });
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester);

    expect(find.text(_notificationsLabel), findsNothing);
    expect(onboarding.totalMilestones, 6);
    expect(_textsInOrder(tester), isNot(contains(_notificationsLabel)));
  });

  testWidgets('milestone done: row renders last, struck through, untappable',
      (tester) async {
    final onboarding = await _onboardingWith({
      ..._visibleOnHome,
      'onboarding_milestone_notifications': true,
    });
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(_host(
      child: const CoffeeJourneyCard(),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester);

    expect(find.text(_notificationsLabel), findsOneWidget);
    expect(onboarding.totalMilestones, 7);
    final text = tester.widget<Text>(find.text(_notificationsLabel));
    expect(text.style?.decoration, TextDecoration.lineThrough);
    expect(
      _tileInkWell(tester, find.text(_notificationsLabel)).onTap,
      isNull,
    );
    // Done wins over hidden: even a stale hidden flag keeps it visible.
  });

  testWidgets('tap, granted: milestone completes, events tracked',
      (tester) async {
    LocalNotificationSchedulerService.testMode = true;
    addTearDown(() => LocalNotificationSchedulerService.testMode = false);
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(_host(
      child: CoffeeJourneyCard(
        requestNotificationPermission: () async => true,
      ),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester);

    await tester.tap(find.text(_notificationsLabel));
    await tester.pump();
    // Let the post-grant unawaited rescheduleAll settle.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(onboarding.milestoneNotifications, isTrue);
    // First brew (already done in _visibleOnHome) + notifications.
    expect(onboarding.completedMilestoneCount, 2);
    final text = tester.widget<Text>(find.text(_notificationsLabel));
    expect(text.style?.decoration, TextDecoration.lineThrough);

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final shown = events
        .where((e) => e['event_name'] == 'notification_permission_shown')
        .toList();
    expect(shown, hasLength(1));
    expect(shown.single['properties'], {'source': 'journey_card'});
    final results = events
        .where((e) => e['event_name'] == 'notification_permission_result')
        .toList();
    expect(results, hasLength(1));
    expect(results.single['properties'], {
      'source': 'journey_card',
      'result': 'granted',
    });
    final milestone = events
        .where((e) => e['event_name'] == 'journey_milestone_completed')
        .toList();
    expect(milestone, hasLength(1));
    expect(milestone.single['properties'], {'milestone': 'notifications'});
  });

  testWidgets('tap, denied: no completion event, row quietly hidden',
      (tester) async {
    final onboarding = await _onboardingWith(_visibleOnHome);
    addTearDown(onboarding.dispose);
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(_host(
      child: CoffeeJourneyCard(
        requestNotificationPermission: () async => false,
      ),
      onboarding: onboarding,
      database: db,
    ));
    await _letTileLoad(tester);

    await tester.tap(find.text(_notificationsLabel));
    await tester.pump();

    expect(onboarding.milestoneNotifications, isFalse);
    expect(onboarding.notificationsMilestoneHidden, isTrue);
    expect(find.text(_notificationsLabel), findsNothing);

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final results = events
        .where((e) => e['event_name'] == 'notification_permission_result')
        .toList();
    expect(results.single['properties'], {
      'source': 'journey_card',
      'result': 'denied',
    });
    expect(
      events.where((e) => e['event_name'] == 'journey_milestone_completed'),
      isEmpty,
    );
  });
}
