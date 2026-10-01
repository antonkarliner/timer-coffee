import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/collections_preferences_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/services/moments_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_database.dart';
import '../widgets/settings_section_forwarding_test.mocks.dart';

/// Plan 074 phase 13: the "Show or hide methods" row at the end of the
/// Brew Coffee method list must be the last row, and tapping it must emit
/// exactly one `settings_shortcut_tapped{source: brew_method_list,
/// target: home_screen}` and push the Settings Home screen page.
void main() {
  late MockRecipeProvider recipeProvider;
  final methods = [
    BrewingMethodModel(brewingMethodId: 'v60', brewingMethod: 'V60'),
    BrewingMethodModel(brewingMethodId: 'chemex', brewingMethod: 'Chemex'),
  ];

  RecipeModel recipeFor(String methodId) => RecipeModel(
    id: 'recipe-$methodId',
    name: 'Recipe',
    brewingMethodId: methodId,
    coffeeAmount: 15,
    waterAmount: 250,
    grindSize: 'medium',
    brewTime: const Duration(minutes: 3),
    shortDescription: '',
    steps: [
      BrewStepModel(
        id: 'step-1',
        order: 1,
        description: 'Bloom',
        time: const Duration(seconds: 45),
      ),
    ],
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    recipeProvider = MockRecipeProvider();
    when(recipeProvider.recipes).thenReturn(const []);
    when(recipeProvider.currentLocale).thenReturn(const Locale('en'));
    when(recipeProvider.getLocaleName('en')).thenAnswer((_) async => 'English');
    // Both methods explicitly shown by the user, so they pass the
    // visibility filter (the default is hidden-when-no-recipes).
    when(recipeProvider.shownBrewingMethodIds)
        .thenReturn(ValueNotifier<Set<String>>({'v60', 'chemex'}));
    when(
      recipeProvider.hiddenBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(recipeProvider.getLastUsedRecipe()).thenAnswer((_) async => null);
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  Future<_TestRouter> pumpApp(WidgetTester tester) async {
    // The pinned quick-actions header draws its opaque background with a
    // ColoredBox around its ListTiles (pre-existing). ListTile's debug check
    // reports that as a possible hidden ink effect via FlutterError — a
    // console warning in a real debug run, but the test binding records
    // reportError calls as unexpected exceptions. Swallow exactly that
    // message; everything else still fails the test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains(
            'ListTile background color or ink splashes may be invisible',
          )) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final prefs = await SharedPreferences.getInstance();
    final db = openTestDatabase();
    addTearDown(db.close);
    final onboarding = OnboardingService(prefs);
    addTearDown(onboarding.dispose);
    final moments = MomentsService(prefs: prefs, database: db)
      // Keep the Coffee Day banner out of the harness regardless of the
      // calendar date the suite runs on.
      ..testNowOverride = DateTime(2026, 9, 30);
    addTearDown(moments.dispose);

    final router = _TestRouter();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<ThemeProvider>.value(
            value: ThemeProvider(ThemeMode.system),
          ),
          Provider<List<BrewingMethodModel>>.value(value: methods),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
          ChangeNotifierProvider<CollectionsPreferencesService>(
            create: (_) => CollectionsPreferencesService(),
          ),
          ChangeNotifierProvider<AdvancedFeaturesService>(
            create: (_) => AdvancedFeaturesService(),
          ),
          ChangeNotifierProvider<OnboardingService>.value(value: onboarding),
          ChangeNotifierProvider<MomentsService>.value(value: moments),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          // BrewingMethodsScreen is a tab page: in the app a Scaffold shell
          // sits above it. Provide one here so its ListTiles find a Material.
          builder: (context, child) => Scaffold(body: child),
          routerConfig: router.config(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the show-or-hide row is the last row of the method list', (
    tester,
  ) async {
    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    await pumpApp(tester);

    final showHideRow = find.bySemanticsIdentifier('brewMethodsShowOrHideRow');
    expect(showHideRow, findsOneWidget);
    expect(find.text('Show or hide methods'), findsOneWidget);

    // Below BOTH method rows — nothing was inserted between them, and the
    // trailing row comes after the last method.
    final rowTop = tester.getTopLeft(showHideRow).dy;
    expect(
      rowTop,
      greaterThan(
        tester.getTopLeft(find.bySemanticsIdentifier('brewingMethod_v60')).dy,
      ),
    );
    expect(
      rowTop,
      greaterThan(
        tester
            .getTopLeft(find.bySemanticsIdentifier('brewingMethod_chemex'))
            .dy,
      ),
    );
  });

  testWidgets('tapping it pushes the Home screen page and reports once', (
    tester,
  ) async {
    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    final router = await pumpApp(tester);
    final eventsBefore =
        AnalyticsService.instance.bufferedEventsForTesting.length;

    await tester.tap(find.bySemanticsIdentifier('brewMethodsShowOrHideRow'));
    await tester.pumpAndSettle();

    expect(router.stack.last.name, 'SettingsHomeTabRoute');

    final newEvents = AnalyticsService.instance.bufferedEventsForTesting
        .sublist(eventsBefore);
    expect(newEvents, hasLength(1), reason: 'exactly one analytics event');
    expect(newEvents.single['event_name'], 'settings_shortcut_tapped');
    expect(newEvents.single['properties'], {
      'source': ShortcutSource.brewMethodList.wireName,
      'target': SettingsTarget.homeScreen.wireName,
    });
  });

  testWidgets('the row is absent until recipes load', (tester) async {
    await pumpApp(tester);

    expect(
      find.bySemanticsIdentifier('brewMethodsShowOrHideRow'),
      findsNothing,
    );

    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    await pumpApp(tester);

    expect(
      find.bySemanticsIdentifier('brewMethodsShowOrHideRow'),
      findsOneWidget,
    );
  });

  testWidgets('the row remains when every method is hidden', (tester) async {
    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    when(
      recipeProvider.shownBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(
      recipeProvider.hiddenBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({'v60', 'chemex'}));

    await pumpApp(tester);

    expect(find.bySemanticsIdentifier('brewingMethod_v60'), findsNothing);
    expect(find.bySemanticsIdentifier('brewingMethod_chemex'), findsNothing);
    expect(
      find.bySemanticsIdentifier('brewMethodsShowOrHideRow'),
      findsOneWidget,
    );
  });

  testWidgets('the row title has no explicit colour', (tester) async {
    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    await pumpApp(tester);

    final title = tester.widget<Text>(find.text('Show or hide methods'));
    expect(title.style?.color, isNull);
  });
}

/// Minimal router: the method list under test plus the shortcut's target
/// page (pattern from settings_section_forwarding_test.dart).
class _TestRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: BrewingMethodsRoute.page, path: '/'),
    AutoRoute(page: SettingsHomeTabRoute.page, path: '/settings/home'),
  ];
}
