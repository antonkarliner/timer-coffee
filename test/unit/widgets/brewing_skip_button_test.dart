// Widget tests for the brewing screen's floating action button (plan 052 B,
// prototype: immediate swap): on the last step, from the moment it starts,
// the FAB must be an extended, labelled "Finish" button instead of the plain
// pause icon it shows on every other step. The Semantics identifiers are
// load-bearing for the Maestro screenshot suite and are asserted in both
// states.
//
// `BrewingProcessScreen` is pumped whole. The seams it can reach from a test
// process are handled like this:
//  * wakelock_plus (1.3.x) talks Pigeon over a BasicMessageChannel; without a
//    reply handler `WakelockPlus.enable()` throws an unhandled connection
//    error straight out of initState, so the toggle channel is stubbed below
//    with the empty reply Pigeon expects for a void method.
//  * `NotificationMode.none` keeps just_audio and Vibration out of the flow.
//  * Live Activity / Android update / iOS background-task services all
//    early-return on a macOS host (`!Platform.isIOS && !Platform.isAndroid`).
//  * AnalyticsService runs for real so the skip event is observable; Supabase
//    is deliberately NOT initialized, so the periodic flush fails fast into
//    its own catch block without ever attempting network I/O. Initialize()
//    awaits PackageInfo.fromPlatform(), a real method-channel call that never
//    completes inside a testWidgets FakeAsync zone, so it is done in the
//    plain-zone setUp below (same pattern as finish_screen_test.dart).
//  * The brew timer is driven by pumping fake clock time, never by awaiting.
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/notification_mode.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/brewing_process_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// wakelock_plus 1.3.x Pigeon channel for `WakelockPlusApi.toggle`, which is
/// what `WakelockPlus.enable()` and `.disable()` both resolve to. Stubbed at
/// the raw-bytes level: Pigeon encodes its request with a private codec that
/// a plain StandardMessageCodec cannot decode, but it decodes a plain-encoded
/// `<Object?>[null]` reply (the empty reply for a void method) just fine.
const String _kWakelockToggleChannelName =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

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

BrewingProcessScreen _screen({required int stepCount}) =>
    BrewingProcessScreen(
      recipe: _recipe(stepCount: stepCount),
      coffeeAmount: 15,
      waterAmount: 250,
      notificationMode: NotificationMode.none,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 1,
      brewingMethodName: 'V60',
    );

Widget _harness(RecipeProvider recipeProvider, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
      ChangeNotifierProvider<AdvancedFeaturesService>(
        create: (_) => AdvancedFeaturesService(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

/// Pumps the brewing screen whole with the given number of steps.
Future<void> _pumpScreen(WidgetTester tester, int stepCount) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  final recipeProvider = RecipeProvider(
    const Locale('en'),
    const <Locale>[],
    db,
    DatabaseProvider(db),
  );
  addTearDown(recipeProvider.dispose);

  tester.view.physicalSize = const Size(430, 932);
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
    (ByteData? message) async =>
        const StandardMessageCodec().encodeMessage(<Object?>[null]),
  );

  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(
    _harness(recipeProvider, _screen(stepCount: stepCount)),
  );
}

/// Unmounts the screen while AnalyticsService is still initialized: the
/// screen's dispose() emits `brew_abandoned` through the singleton, and the
/// unmount also cancels the brew timer so no FakeAsync timer stays pending.
Future<void> _teardownTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

final Finder _fab = find.byType(FloatingActionButton);

Finder _semanticsWithId(String identifier) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == identifier,
    );

void main() {
  // AnalyticsService must be initialized from the plain (non-FakeAsync) zone:
  // its PackageInfo.fromPlatform() await never completes under testWidgets.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('brewing screen skip button', () {
    testWidgets(
      'from the first frame on the last step it is the labelled finish FAB',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpScreen(tester, 1);
        // AnimatedSwitcher has nothing to switch away from on the very first
        // frame (there is no prior pause FAB to retire), so no extra settle
        // time is needed before asserting the finish FAB is present.
        await tester.pump(const Duration(seconds: 2));

        expect(_fab, findsOneWidget);
        expect(
          find.descendant(of: _fab, matching: find.text('Finish')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _fab, matching: find.byIcon(Icons.skip_next)),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.pause), findsNothing);
        expect(_semanticsWithId('skipLastStepButton'), findsOneWidget);
        expect(_semanticsWithId('togglePauseButton'), findsNothing);

        await _teardownTree(tester);
        semantics.dispose();
      },
    );

    testWidgets(
      'on a non-final step the FAB never becomes the finish button',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpScreen(tester, 2);
        await tester.pump(const Duration(seconds: 8));
        await tester.pump(const Duration(milliseconds: 400));

        // Still step 1 of 2, so the plain pause FAB must remain regardless
        // of how long this step has been running.
        expect(_fab, findsOneWidget);
        expect(find.text('Finish'), findsNothing);
        expect(
          find.descendant(of: _fab, matching: find.byIcon(Icons.pause)),
          findsOneWidget,
        );
        expect(_semanticsWithId('togglePauseButton'), findsOneWidget);
        expect(_semanticsWithId('skipLastStepButton'), findsNothing);

        await _teardownTree(tester);
        semantics.dispose();
      },
    );

    testWidgets(
      'tapping the extended FAB invokes the skip path exactly once',
      (tester) async {
        await _pumpScreen(tester, 1);
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Finish'), findsOneWidget);

        // Two taps without an intervening frame simulate a rapid double tap:
        // the first lands on the live element, the second must be absorbed
        // by _skipLastStep's end-of-brew guard rather than double-count.
        await tester.tap(_fab);
        await tester.tap(_fab);
        // Let the FAB's exit transitions (AnimatedSwitcher + the Scaffold's
        // own FAB transition) run to completion and flutter_animate's
        // end-of-brew restart timers fire, while staying well short of the
        // 1800ms end-of-brew animation that would navigate to FinishScreen.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        final skipEvents = AnalyticsService
            .instance.bufferedEventsForTesting
            .where((e) => e['event_name'] == 'last_step_skipped')
            .toList();
        expect(skipEvents, hasLength(1));
        final properties = skipEvents.single['properties'] as Map;
        expect(properties['recipe_id'], 'recipe-1');
        expect(properties['total_steps'], 1);
        expect(properties['seconds_into_step'], isA<int>());
        expect(properties['seconds_remaining'], isA<int>());

        // The skip path entered the end-of-brew animation, which removes the
        // FAB entirely (floatingActionButton: null).
        expect(_fab, findsNothing);
        expect(find.text('Finish'), findsNothing);

        await _teardownTree(tester);
      },
    );
  });
}
