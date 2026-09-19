// Widget tests for the end-of-brew sequence on `BrewingProcessScreen`
// (plan 061 Direction B, "pour complete" fill).
//
// Coverage:
//  * B1 — the normal-state ring swap: `BrewTimerRing` replaces the
//    `CircularProgressIndicator`, and the two Semantics identifiers the
//    Maestro screenshot suite looks up — `circularProgressIndicator` around
//    the ring and `stepTimeCounter` on the countdown — still resolve.
//  * B2 — every brew-ending trigger path (timer expiry, skip, manual next;
//    see the resync note at the bottom of this file) pushes `FinishScreen`
//    exactly once and emits `brew_finished` exactly once; pause/skip and the
//    manual arrows go inert mid-sequence; tap-to-skip jumps straight to the
//    finish screen; reduced motion shortens the hold; and during *normal*
//    brewing a body tap is inert and the FAB still toggles pause.
//
// The tests that reach `FinishScreen` mount it whole, which drags in its
// dependencies; those are handled like this:
//  * Supabase is initialized against a localhost URL in setUpAll (same
//    pattern as `finish_screen_test.dart`): `FinishScreen.initState` reads
//    `Supabase.instance.client.auth.currentUser` unguarded, which throws if
//    Supabase was never initialized. With the fake URL and empty mock prefs
//    there is no session, so every Supabase read resolves locally to null
//    without network I/O.
//  * A `coffee_facts` row for locale `en` is seeded into the in-memory
//    database: the finish screen's slot resolver awaits the coffee-fact
//    future, and an empty table would leave that future erroring.
//  * `LocalNotificationSchedulerService.testMode = true` bypasses the
//    notification platform calls the finish screen's post-frame reschedule
//    reaches on the test (macOS) host.
//  * `notif_perm_ab_shown` is pre-seeded in SharedPreferences so the finish
//    screen's permission dialog flow returns before touching
//    `NotificationService`.
//  * The wakelock Pigeon channels (`toggle` and the `enabled` getter, which
//    `FinishScreen.initState` awaits) are stubbed at the raw-bytes level:
//    Pigeon encodes requests with a private codec but accepts a plain-encoded
//    reply — `<Object?>[null]` for the void toggle, `<Object?>[false]` for
//    the bool getter.
//
// The remaining seams are the same as `brewing_skip_button_test.dart`:
//  * `NotificationMode.none` keeps just_audio and Vibration out of the flow.
//  * Live Activity / Android update / iOS background-task services all
//    early-return on a macOS host (`!Platform.isIOS && !Platform.isAndroid`).
//  * AnalyticsService runs for real so `brew_finished` is observable; the
//    periodic flush fails fast into its own catch block without network I/O.
//    Initialize() awaits PackageInfo.fromPlatform(), a real method-channel
//    call that never completes inside a testWidgets FakeAsync zone, so it is
//    done in the plain-zone setUp below.
//  * The brew timer is driven by pumping fake clock time, never by awaiting.
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/notification_mode.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brewing_process_screen.dart';
import 'package:coffee_timer/screens/finish_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/brew_recording_service.dart';
import 'package:coffee_timer/services/local_notification_scheduler_service.dart';
import 'package:coffee_timer/services/moments_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/widgets/brewing/brew_fill_ring_painter.dart';
import 'package:coffee_timer/widgets/brewing/brew_timer_ring.dart';
import 'package:coffee_timer/widgets/brewing/pour_brewing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_database.dart';

/// wakelock_plus 1.3.x Pigeon channels. Stubbed at the raw-bytes level:
/// Pigeon encodes its requests with a private codec that a plain
/// StandardMessageCodec cannot decode, but it decodes plain-encoded replies
/// just fine.
const String _kWakelockToggleChannelName =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
const String _kWakelockEnabledChannelName =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.enabled';

ByteData? _wakelockReply(Object? value) =>
    const StandardMessageCodec().encodeMessage(<Object?>[value]);

/// Counts route-level navigation so "FinishScreen pushed exactly once" is a
/// counted fact. `pushReplacement` notifies `didReplace`, not `didPush`.
class _RouteRecorder extends NavigatorObserver {
  int pushes = 0;
  int replaces = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replaces++;
  }
}

RecipeModel _recipe({required int stepCount}) => RecipeModel(
      id: 'recipe-1',
      name: 'Test recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      waterTemp: 93,
      grindSize: '24 clicks',
      brewTime: const Duration(minutes: 2),
      shortDescription: 'Test recipe',
      steps: List.generate(
        stepCount,
        (i) => BrewStepModel(
          id: 'step-$i',
          order: i,
          description: 'Step ${i + 1}',
          // One minute per step: far from any step-transition or
          // end-of-brew path during the pumped seconds, and short enough
          // that the "0/60 s" counter fits the ring with the wide-glyph
          // FlutterTest font.
          time: const Duration(minutes: 1),
        ),
      ),
    );

Widget _screen({
  required int stepCount,
  bool reduceMotion = false,
  TextScaler? textScaler,
}) {
  Widget screen = BrewingProcessScreen(
    recipe: _recipe(stepCount: stepCount),
    coffeeAmount: 15,
    waterAmount: 250,
    notificationMode: NotificationMode.none,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 1,
    brewingMethodName: 'V60',
  );
  if (textScaler != null) {
    // Same pattern as the reduce-motion wrapper below: override only the
    // text scaler while every other MediaQuery value (size, padding) keeps
    // its real value.
    screen = Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: textScaler),
          child: screen,
        );
      },
    );
  }
  if (!reduceMotion) {
    return screen;
  }
  // Wrapped so MediaQuery.disableAnimationsOf(context) is true for the
  // screen's own reads while every other MediaQuery value (size, padding)
  // keeps its real value.
  return Builder(
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(disableAnimations: true),
        child: screen,
      );
    },
  );
}

Widget _harness(
  RecipeProvider recipeProvider, {
  required AppDatabase db,
  required AdvancedFeaturesService advancedFeatures,
  required OnboardingService onboarding,
  required MomentsService moments,
  required UserStatProvider userStats,
  required CoffeeBeansProvider coffeeBeans,
  required BeanReviewProvider beanReviews,
  required BrewRecordingService brewRecording,
  _RouteRecorder? routeRecorder,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
      ChangeNotifierProvider<AdvancedFeaturesService>.value(
        value: advancedFeatures,
      ),
      // The rest is what `FinishScreen` reads — provided so the tests may
      // ride the navigation all the way onto that screen.
      Provider<AppDatabase>.value(value: db),
      ChangeNotifierProvider<UserStatProvider>.value(value: userStats),
      ChangeNotifierProvider<CoffeeBeansProvider>.value(value: coffeeBeans),
      ChangeNotifierProvider<OnboardingService>.value(value: onboarding),
      ChangeNotifierProvider<MomentsService>.value(value: moments),
      ChangeNotifierProvider<BeanReviewProvider>.value(value: beanReviews),
      Provider<BrewRecordingService>.value(value: brewRecording),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: [?routeRecorder],
      home: child,
    ),
  );
}

/// Pumps the brewing screen whole with the given number of steps.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required int stepCount,
  bool reduceMotion = false,
  bool pourLayout = false,
  Size? physicalSize,
  TextScaler? textScaler,
  AdvancedFeaturesService? advancedFeatures,
  _RouteRecorder? routeRecorder,
}) async {
  final db = openTestDatabase();
  addTearDown(db.close);

  // The finish screen's slot resolver awaits the coffee-fact future; an
  // empty coffee_facts table would leave it erroring.
  await db.into(db.coffeeFacts).insert(
        CoffeeFactsCompanion.insert(
          id: 'fact-test-1',
          fact: 'Coffee was discovered by goats.',
          locale: 'en',
        ),
      );

  final prefs = await SharedPreferences.getInstance();

  final recipeProvider = RecipeProvider(
    const Locale('en'),
    const <Locale>[],
    db,
    DatabaseProvider(db),
  );
  addTearDown(recipeProvider.dispose);

  final coffeeBeans = CoffeeBeansProvider(db, DatabaseProvider(db));
  addTearDown(coffeeBeans.dispose);

  final advanced = advancedFeatures ?? AdvancedFeaturesService();
  addTearDown(advanced.dispose);
  if (pourLayout) {
    // Must be set before the screen builds: the screen captures
    // pourLayoutEnabled once in initState with context.read, it never
    // watches the service for it.
    await advanced.setPourLayoutEnabled(true);
  }
  final onboarding = OnboardingService(prefs);
  addTearDown(onboarding.dispose);
  final moments = MomentsService(prefs: prefs, database: db);
  addTearDown(moments.dispose);
  final userStats = UserStatProvider(db, coffeeBeans);
  addTearDown(userStats.dispose);
  final beanReviews = BeanReviewProvider();
  addTearDown(beanReviews.dispose);

  tester.view.physicalSize = physicalSize ?? const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // The FlutterTest font gives every glyph the same wide advance, so the
  // step counter ("0/60 s.") inside the capped-size brew ring overflows it
  // at the default test text scale (it does not at real font metrics).
  // Half scale keeps the ring's content inside the ring box.
  tester.platformDispatcher.textScaleFactorTestValue = 0.5;
  addTearDown(() => tester.platformDispatcher.textScaleFactorTestValue = 1.0);

  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    _kWakelockToggleChannelName,
    (ByteData? message) async => _wakelockReply(null),
  );
  // FinishScreen.initState awaits WakelockPlus.enabled; reply "not enabled".
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    _kWakelockEnabledChannelName,
    (ByteData? message) async => _wakelockReply(false),
  );

  // Pre-seed the notification-permission A/B flag so the finish screen's
  // permission flow returns before touching NotificationService.
  SharedPreferences.setMockInitialValues({'notif_perm_ab_shown': true});

  await tester.pumpWidget(
    _harness(
      recipeProvider,
      db: db,
      advancedFeatures: advanced,
      onboarding: onboarding,
      moments: moments,
      userStats: userStats,
      coffeeBeans: coffeeBeans,
      beanReviews: beanReviews,
      brewRecording: BrewRecordingService(),
      routeRecorder: routeRecorder,
      child: _screen(
        stepCount: stepCount,
        reduceMotion: reduceMotion,
        textScaler: textScaler,
      ),
    ),
  );
}

/// Unmounts the tree while AnalyticsService is still initialized: the
/// screens' dispose() calls emit their events through the singleton, and the
/// unmount cancels the brew timer so no FakeAsync timer stays pending.
Future<void> _teardownTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// The live painter behind the brew ring, so a test can assert on the values
/// actually being drawn rather than on the widget tree around them.
BrewFillRingPainter _ringPainter(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(BrewTimerRing),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return paint.painter! as BrewFillRingPainter;
}

Finder _semanticsWithId(String identifier) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == identifier,
    );

List<Map<String, dynamic>> _brewFinishedEvents() => AnalyticsService
    .instance.bufferedEventsForTesting
    .where((e) => e['event_name'] == 'brew_finished')
    .toList();

/// Pumps a 1-step brew past its 60-second step, driving the timer-expiry end
/// trigger (the tick that sees elapsed == total starts the end sequence),
/// then pumps the longer of the two end sequences — classic's 2650 ms or
/// Pour's 3200 ms "last drop" — plus settle frames. Waiting past classic's
/// end is harmless: it has already navigated.
Future<void> _pumpToFinishViaTimer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 61));
  await tester.pump(const Duration(milliseconds: 3600));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // AnalyticsService must be initialized from the plain (non-FakeAsync) zone:
  // its PackageInfo.fromPlatform() await never completes under testWidgets.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    // The finish screen's post-frame notification reschedule must not reach
    // the notification plugin on the test host.
    LocalNotificationSchedulerService.testMode = true;
  });

  tearDown(() {
    LocalNotificationSchedulerService.testMode = false;
    AnalyticsService.resetForTesting();
  });

  setUpAll(() async {
    // FinishScreen.initState reads Supabase.instance.client unguarded; a
    // fake-URL instance keeps every read local and user-less. The mock prefs
    // must be installed before initialize() — supabase_flutter restores any
    // stored session through SharedPreferences at construction.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  group('brewing end animation — B1 ring swap', () {
    testWidgets(
      'mid-brew the BrewTimerRing replaces the CircularProgressIndicator and '
      'both Maestro semantics identifiers still resolve',
      (tester) async {
        await _pumpScreen(tester, stepCount: 2);
        // Settle into the middle of step 1 of 2, well clear of any
        // step-transition or end-of-brew path.
        await tester.pump(const Duration(seconds: 5));

        // The custom ring is present exactly once...
        expect(find.byType(BrewTimerRing), findsOneWidget);
        // ...the widget it replaced is gone...
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // ...and both load-bearing Semantics identifiers are intact:
        // 'circularProgressIndicator' wraps the ring and 'stepTimeCounter'
        // annotates the countdown inside it.
        expect(_semanticsWithId('circularProgressIndicator'), findsOneWidget);
        expect(_semanticsWithId('stepTimeCounter'), findsOneWidget);

        await _teardownTree(tester);
      },
    );
  });

  group('brewing end animation — arc sweep origin', () {
    testWidgets(
      'skipping mid-step starts the arc where the ring actually was, not at '
      '1.0',
      (tester) async {
        // Regression guard. `_currentArcProgress` short-circuits to 1.0 once
        // `_isEndBrewAnimating` is true, so capturing the sweep's origin
        // AFTER raising that flag silently pins it to 1.0 and the arc snaps
        // to full instead of sweeping. Every other assertion in this file
        // still passes when that happens — the bug is only visible in the
        // painter's `progress` on the sequence's first frames.
        await _pumpScreen(tester, stepCount: 1);
        // One second into a 60 s step: the arc is at ~1/60, nowhere near 1.0.
        await tester.pump(const Duration(seconds: 1));

        final double arcBefore = _ringPainter(tester).progress;
        expect(arcBefore, lessThan(0.2));

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(); // elapsed == 0 frame
        // Very early in the 0.00–0.15 arc interval, so the lerp has barely
        // advanced and must still be close to where it started.
        await tester.pump(const Duration(milliseconds: 16));

        final double arcAtStart = _ringPainter(tester).progress;
        expect(
          arcAtStart,
          lessThan(0.5),
          reason: 'arc snapped to full instead of sweeping from $arcBefore',
        );

        await _teardownTree(tester);
      },
    );
  });

  group('brewing end animation — trigger paths', () {
    testWidgets(
      'timer expiry pushes FinishScreen once and emits brew_finished once',
      (tester) async {
        final recorder = _RouteRecorder();
        await _pumpScreen(tester, stepCount: 1, routeRecorder: recorder);
        await _pumpToFinishViaTimer(tester);

        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1); // pushReplacement, not didPush

        final events = _brewFinishedEvents();
        expect(events, hasLength(1));
        expect(
          (events.single['properties'] as Map)['completion_path'],
          'timer',
        );

        // Still exactly one navigation after settling on the finish screen.
        await tester.pump(const Duration(milliseconds: 300));
        expect(recorder.replaces, 1);

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'skip on the last step pushes FinishScreen once and emits '
      'brew_finished once',
      (tester) async {
        final recorder = _RouteRecorder();
        await _pumpScreen(tester, stepCount: 1, routeRecorder: recorder);
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Finish'), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        // Settle the tap frame: a freshly-forwarded controller consumes one
        // frame with elapsed == 0, and that frame must happen before the
        // long pump below.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2900));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1);

        final events = _brewFinishedEvents();
        expect(events, hasLength(1));
        expect(
          (events.single['properties'] as Map)['completion_path'],
          'skip',
        );

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'manual next on the last step pushes FinishScreen once and emits '
      'brew_finished once',
      (tester) async {
        final recorder = _RouteRecorder();
        final advancedFeatures = AdvancedFeaturesService();
        await advancedFeatures.setManualStepControlEnabled(true);
        await _pumpScreen(
          tester,
          stepCount: 1,
          advancedFeatures: advancedFeatures,
          routeRecorder: recorder,
        );
        await tester.pump(const Duration(seconds: 2));
        // The manual arrows are visible before the tap (LTR: next points
        // right).
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_right));
        // Settle the tap frame (see the note in the skip test above).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2900));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1);

        final events = _brewFinishedEvents();
        expect(events, hasLength(1));
        expect(
          (events.single['properties'] as Map)['completion_path'],
          'manual_next',
        );

        await _teardownTree(tester);
      },
    );
  });

  group('brewing end animation — mid-sequence behaviour', () {
    testWidgets(
      'during the sequence pause and skip are inert: the FAB and the manual '
      'arrows are gone',
      (tester) async {
        final advancedFeatures = AdvancedFeaturesService();
        await advancedFeatures.setManualStepControlEnabled(true);
        final recorder = _RouteRecorder();
        await _pumpScreen(
          tester,
          stepCount: 1,
          advancedFeatures: advancedFeatures,
          routeRecorder: recorder,
        );
        await tester.pump(const Duration(seconds: 2));
        // Both affordances exist before the trigger.
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(_semanticsWithId('previousStepButton'), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        // Settle the tap frame, then ~400 ms into the 2650 ms sequence —
        // past the FAB's exit transition, still well before completion.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.byIcon(Icons.pause), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(_semanticsWithId('previousStepButton'), findsNothing);
        expect(_semanticsWithId('nextStepButton'), findsNothing);

        // The sequence still resolves to the finish screen: pump in frames
        // until it is onstage and its entrance transition has settled (ticker
        // scheduling in the test binding can push the completion beat a frame
        // later than the arithmetic suggests, so a fixed pump count is flaky).
        // 24 x 250 ms = 6 s, comfortably past the 2650 ms sequence plus its
        // 350 ms route transition. The loop breaks as soon as the route has
        // settled, so a generous cap costs nothing but stops this going
        // stale the next time the sequence is re-paced.
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 250));
          final stageEntries =
              find.byType(FinishScreen, skipOffstage: false).evaluate();
          if (stageEntries.isEmpty) continue;
          final route = ModalRoute.of(stageEntries.first);
          if (route?.animation?.status == AnimationStatus.completed) {
            break;
          }
        }
        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1);

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'tapping the body mid-sequence navigates immediately (well before the '
      'full 2650 ms)',
      (tester) async {
        final recorder = _RouteRecorder();
        await _pumpScreen(tester, stepCount: 1, routeRecorder: recorder);
        await tester.pump(const Duration(seconds: 61)); // timer expiry
        // 400 ms into the 2650 ms sequence.
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(FinishScreen), findsNothing);

        await tester.tap(find.byType(BrewTimerRing));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Navigated after ~500 ms, far short of the full 2650 ms.
        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1);

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'with reduced motion the finish screen arrives after a short hold, not '
      'the full 2650 ms',
      (tester) async {
        final recorder = _RouteRecorder();
        await _pumpScreen(
          tester,
          stepCount: 1,
          reduceMotion: true,
          routeRecorder: recorder,
        );
        await tester.pump(const Duration(seconds: 61)); // timer expiry
        // Reduced motion holds the settled end state for only 250 ms.
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1);

        final events = _brewFinishedEvents();
        expect(events, hasLength(1));
        expect(
          (events.single['properties'] as Map)['completion_path'],
          'timer',
        );

        await _teardownTree(tester);
      },
    );
  });

  group('brewing end animation — normal-state regression guard', () {
    testWidgets(
      'during normal brewing a body tap does not navigate and the FAB still '
      'toggles pause',
      (tester) async {
        final recorder = _RouteRecorder();
        await _pumpScreen(tester, stepCount: 2, routeRecorder: recorder);
        // Mid step 1 of 2.
        await tester.pump(const Duration(seconds: 5));
        expect(find.byType(FinishScreen), findsNothing);

        // A body tap in normal brewing must be inert.
        await tester.tap(find.byType(BrewTimerRing));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(FinishScreen), findsNothing);
        expect(recorder.replaces, 0);
        expect(_brewFinishedEvents(), isEmpty);

        // And the FAB still pauses the brew.
        expect(find.byIcon(Icons.pause), findsOneWidget);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(_semanticsWithId('brewPausedIndicator'), findsOneWidget);

        await _teardownTree(tester);
      },
    );
  });

  group('brewing pour layout — Pour variant (plan 066 phase 2)', () {
    testWidgets(
      'the app bar step title advances as steps complete and the Pour body '
      'shows the resolved step text',
      (tester) async {
        await _pumpScreen(tester, stepCount: 2, pourLayout: true);
        await tester.pump(const Duration(seconds: 1));

        // The Pour body is what is rendered, not the classic column.
        expect(find.byType(PourBrewingView), findsOneWidget);

        Text appBarTitle() => tester.widget<Text>(
              find.descendant(
                of: _semanticsWithId('brewingProcessTitle'),
                matching: find.byType(Text),
              ),
            );
        Text stepDescription() => tester.widget<Text>(
              find.descendant(
                of: _semanticsWithId('brewingStepDescription'),
                matching: find.byType(Text),
              ),
            );

        expect(appBarTitle().data, 'Step 1/2');
        expect(stepDescription().data, 'Step 1');

        // One minute plus a tick: the first step completes and the title
        // advances with it.
        await tester.pump(const Duration(seconds: 61));
        expect(appBarTitle().data, 'Step 2/2');
        expect(stepDescription().data, 'Step 2');

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'tapping the pause FAB shows the paused label and tapping it again '
      'hides it',
      (tester) async {
        await _pumpScreen(tester, stepCount: 2, pourLayout: true);
        await tester.pump(const Duration(seconds: 2));

        // The Pour paused label is a Visibility that keeps its size (so
        // pausing never shifts the countdown), which means the Text stays in
        // the tree while hidden. Visibility is what the user sees, so that is
        // what is asserted — a bare find.text would find the hidden one.
        bool pausedShown() => tester
            .widget<Visibility>(
              find.descendant(
                of: _semanticsWithId('brewPausedIndicator'),
                matching: find.byType(Visibility),
              ),
            )
            .visible;

        expect(pausedShown(), isFalse);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(pausedShown(), isTrue);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(pausedShown(), isFalse);

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'the skip FAB appears on the last step and finishing navigates to '
      'FinishScreen',
      (tester) async {
        final recorder = _RouteRecorder();
        await _pumpScreen(
          tester,
          stepCount: 1,
          pourLayout: true,
          routeRecorder: recorder,
        );
        await tester.pump(const Duration(seconds: 2));
        // One-step recipe: the brew starts on the last step, so the FAB is
        // the skip button from the first frame.
        expect(_semanticsWithId('skipLastStepButton'), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        // Settle the tap frame, then run out Pour's 3200 ms sequence.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3600));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(FinishScreen), findsOneWidget);
        expect(recorder.replaces, 1);

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'letting the timer run out navigates to FinishScreen after the end '
      'sequence',
      (tester) async {
        await _pumpScreen(tester, stepCount: 1, pourLayout: true);
        await _pumpToFinishViaTimer(tester);

        expect(find.byType(FinishScreen), findsOneWidget);

        await _teardownTree(tester);
      },
    );

    testWidgets(
      'brew_finished carries layout: pour (and brew_started does too)',
      (tester) async {
        await _pumpScreen(tester, stepCount: 1, pourLayout: true);
        await _pumpToFinishViaTimer(tester);

        final events = _brewFinishedEvents();
        expect(events, hasLength(1));
        expect(
          (events.single['properties'] as Map)['layout'],
          'pour',
        );
        final started = AnalyticsService.instance.bufferedEventsForTesting
            .where((e) => e['event_name'] == 'brew_started')
            .toList();
        expect(started, hasLength(1));
        expect((started.single['properties'] as Map)['layout'], 'pour');

        await _teardownTree(tester);
      },
    );

    testWidgets('brew_finished carries layout: classic', (tester) async {
      // No pourLayout: the service default (false) selects the classic
      // layout.
      await _pumpScreen(tester, stepCount: 1);
      await _pumpToFinishViaTimer(tester);

      final events = _brewFinishedEvents();
      expect(events, hasLength(1));
      expect(
        (events.single['properties'] as Map)['layout'],
        'classic',
      );

      await _teardownTree(tester);
    });
  });

  group('brewing pour layout — the end sequence actually animates', () {
    testWidgets(
      'the liquid rises to full and the view fades across the sequence',
      (tester) async {
        // Regression guard. Everything the end sequence animates is derived
        // inside _buildPourBody's AnimatedBuilder callback, because the brew
        // timer is cancelled the moment the sequence starts: no setState
        // fires for its whole duration. When these values were read in the
        // enclosing method instead, they froze at their last setState value
        // — the liquid sat still at 0.678 and the opacity never left 1.0 for
        // the entire sequence, so the "pour complete" beat rendered as a
        // still frame and then cut abruptly to the finish screen. Nothing
        // else in this file caught it: every other Pour test asserts only
        // that navigation happens.
        //
        // Three 60s steps, skipped 2s into the last one, so the brew is
        // partway done and the level has real distance to travel.
        await _pumpScreen(tester, stepCount: 3, pourLayout: true);
        await tester.pump(const Duration(seconds: 61));
        await tester.pump(const Duration(seconds: 61));
        await tester.pump(const Duration(seconds: 2));

        PourBrewingView view() =>
            tester.widget<PourBrewingView>(find.byType(PourBrewingView));

        final double levelBefore = view().level;
        expect(
          levelBefore,
          lessThan(0.9),
          reason: 'the probe needs room to rise, or it proves nothing',
        );

        // Skip the last step to trigger the sequence.
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        // Sample across the whole 3200 ms sequence while the view is still
        // mounted, every 50 ms so the drop's short fall cannot slip between
        // samples.
        final levels = <double>[];
        final opacities = <double>[];
        final shownTimes = <int>[];
        var sawDrop = false;
        var sawRipple = false;
        var sawDropAndRippleTogether = false;
        for (var i = 0; i < 70; i++) {
          if (find.byType(PourBrewingView).evaluate().isEmpty) break;
          final PourBrewingView v = view();
          levels.add(v.level);
          opacities.add(v.opacity);
          shownTimes.add(
            tester
                .widget<LocalizedNumberText>(
                  find.descendant(
                    of: _semanticsWithId('stepTimeCounter'),
                    matching: find.byType(LocalizedNumberText),
                  ),
                )
                .currentNumber,
          );
          if (v.dropProgress != null) sawDrop = true;
          if (v.rippleProgress != null) sawRipple = true;
          if (v.dropProgress != null && v.rippleProgress != null) {
            sawDropAndRippleTogether = true;
          }
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(
          levels.last,
          greaterThan(levels.first),
          reason: 'the liquid never rose: ${levels.first} -> ${levels.last}',
        );
        expect(
          levels.last,
          closeTo(1.0, 0.02),
          reason: 'the liquid should rise to a full cup — the view\'s '
              'headroom, not the level, keeps room for the last drop',
        );
        // The countdown runs on from where the skip stopped it (2 s into the
        // 60 s step) to the step total, never going backwards — instead of
        // freezing on a "not done" number over a finished screen.
        expect(shownTimes.first, 2);
        expect(shownTimes.last, 60);
        for (var i = 1; i < shownTimes.length; i++) {
          expect(
            shownTimes[i],
            greaterThanOrEqualTo(shownTimes[i - 1]),
            reason: 'the countdown ran backwards: $shownTimes',
          );
        }
        expect(sawDrop, isTrue, reason: 'the last drop never fell');
        expect(sawRipple, isTrue, reason: 'the drop landed with no ripple');
        expect(
          sawDropAndRippleTogether,
          isFalse,
          reason: 'the ripple must start when the drop lands, not while it '
              'is still falling',
        );
        expect(
          opacities.last,
          lessThan(1.0),
          reason: 'the view never started fading',
        );

        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(FinishScreen), findsOneWidget);

        await _teardownTree(tester);
      },
    );
  });

  group('brewing pour layout — the last drop honours reduced motion', () {
    testWidgets('with reduced motion there is no drop and no ripple', (
      tester,
    ) async {
      // Reduced motion replaces the whole ending with a short settled hold
      // (plan 061 R4). The drop is motion for its own sake, so it must not
      // appear at all.
      await _pumpScreen(
        tester,
        stepCount: 1,
        pourLayout: true,
        reduceMotion: true,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      var sawDropOrRipple = false;
      for (var i = 0; i < 10; i++) {
        if (find.byType(PourBrewingView).evaluate().isEmpty) break;
        final PourBrewingView v = tester.widget<PourBrewingView>(
          find.byType(PourBrewingView),
        );
        if (v.dropProgress != null || v.rippleProgress != null) {
          sawDropOrRipple = true;
        }
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(sawDropOrRipple, isFalse);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FinishScreen), findsOneWidget);

      await _teardownTree(tester);
    });
  });

  group('brewing pour layout — text colour follows the liquid line', () {
    testWidgets(
      'the cup starts empty and the countdown is still legible against the '
      'light surface',
      (tester) async {
        // The cup starts empty (operator decision, 2026-09-16), so at the
        // first frame the countdown sits on the app's surface, which in the
        // light theme is pure white. A white countdown there would be
        // contrast 1.00 — invisible. Legibility comes from PourBrewingView
        // drawing its content twice: a dry copy in onSurface, and a white
        // copy clipped to the liquid. MaterialApp defaults to the platform
        // brightness, which is light in tests. 320x568 is the smallest
        // supported screen.
        await _pumpScreen(tester, stepCount: 1, pourLayout: true);
        await tester.pump();

        final PourBrewingView view = tester.widget<PourBrewingView>(
          find.byType(PourBrewingView),
        );
        // Effectively empty, not exactly 0: the level is continuous wall-clock
        // elapsed over total, so the first frame is a few hundred microseconds
        // in (~0.0002). Asserting an exact 0 passed alone and failed under
        // full-suite load. The epsilon is still two orders of magnitude below
        // the 0.42 floor this guards against ever coming back.
        expect(
          view.level,
          closeTo(0.0, 0.01),
          reason: 'the cup must start empty — no minimum-level floor',
        );

        // Both copies of the countdown exist, in the two colours. The
        // countdown numerals are the 60px Text inside LocalizedNumberText.
        final Set<Color?> colours = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => t.style?.fontSize == 60)
            .map((t) => t.style?.color)
            .toSet();
        expect(
          colours.contains(Colors.white),
          isTrue,
          reason: 'the submerged copy is drawn in white',
        );
        expect(
          colours.any((c) => c != null && c != Colors.white),
          isTrue,
          reason: 'the dry copy is drawn in the scheme colour, not white — '
              'otherwise it is invisible on the white light-theme surface',
        );

        // ...but the identifiers still resolve exactly once, because only
        // the dry copy carries Semantics.
        expect(_semanticsWithId('stepTimeCounter'), findsOneWidget);
        expect(_semanticsWithId('circularProgressIndicator'), findsOneWidget);
        expect(_semanticsWithId('brewingStepsContent'), findsOneWidget);
        expect(_semanticsWithId('brewingStepDescription'), findsOneWidget);

        await _teardownTree(tester);
      },
    );
  });

  // NOTE on the fourth trigger path, Live Activity resync
  // (`_finishFromResync`, completion_path 'resync'): it is not drivable from
  // a widget test on this host, and no passing test is faked for it. Two
  // reasons:
  //  1. The local half of resync decides "finished" from *wall-clock* time
  //     (DateTime.now().toUtc() minus the brew anchor captured in initState).
  //     Inside testWidgets' FakeAsync zone, pumping fake time does not move
  //     DateTime.now(), so the local resync state can never reach finished
  //     deterministically.
  //  2. The backend half requires `_shouldSyncLiveActivitySession` (real
  //     `Platform.isIOS` — false on the macOS test host; dart:io Platform is
  //     not overridable), plus a `fetchSessionStatus` round-trip.
  // The ordering of `_emitBrewFinished('resync')` vs the visual start is
  // identical to the other three paths (see the R2 checklist), all of which
  // are covered above.
}
