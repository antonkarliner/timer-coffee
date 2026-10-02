import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/screens/preparation_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/brew_alert_preference.dart';
import 'package:coffee_timer/services/collections_preferences_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/settings_section_forwarding_test.mocks.dart';

/// Plan 074 phase 13: the "All brewing settings" row at the bottom of the
/// Preparation screen's gear sheet must emit exactly one
/// `settings_shortcut_tapped{source: preparation_sheet, target: brewing}`,
/// close the sheet and push the Settings Brewing page.
void main() {
  late MockRecipeProvider recipeProvider;

  final recipe = RecipeModel(
    id: 'recipe-1',
    name: 'Test recipe',
    brewingMethodId: 'v60',
    coffeeAmount: 15,
    waterAmount: 250,
    grindSize: 'medium',
    brewTime: const Duration(minutes: 2),
    shortDescription: 'Test recipe',
    steps: [
      BrewStepModel(
        id: 'step-1',
        order: 1,
        description: 'Prepare the brewer',
        time: Duration.zero,
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
    BrewAlertPreference.instance.resetForTesting();
    recipeProvider = MockRecipeProvider();
    when(recipeProvider.recipes).thenReturn(const []);
    when(recipeProvider.currentLocale).thenReturn(const Locale('en'));
    when(recipeProvider.getLocaleName('en')).thenAnswer((_) async => 'English');
    // The pushed Settings → Brewing page resolves its layout-preview cards
    // from the last-used recipe.
    when(recipeProvider.getLastUsedRecipe()).thenAnswer((_) async => null);
    when(
      recipeProvider.shownBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(
      recipeProvider.hiddenBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  Future<_TestRouter> pumpApp(WidgetTester tester) async {
    final router = _TestRouter();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<ThemeProvider>.value(
            value: ThemeProvider(ThemeMode.system),
          ),
          Provider<List<BrewingMethodModel>>.value(value: const []),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
          ChangeNotifierProvider<CollectionsPreferencesService>(
            create: (_) => CollectionsPreferencesService(),
          ),
          ChangeNotifierProvider<AdvancedFeaturesService>(
            create: (_) => AdvancedFeaturesService(),
          ),
          ChangeNotifierProvider<AnalyticsService>.value(
            value: MockAnalyticsService(),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router.config(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The app pushes Preparation with a plain MaterialPageRoute from inside
    // a routed page; do the same so context.router resolves like it does in
    // production. The StackRouterScope sits above the navigator, so an
    // imperatively pushed page still finds it.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PreparationScreen(recipe: recipe, brewingMethodName: 'V60'),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('tapping the gear-sheet row pushes Settings → Brewing once', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    // Open the gear sheet.
    await tester.tap(
      find.bySemanticsIdentifier('preparationAdvancedFeaturesButton'),
    );
    await tester.pumpAndSettle();

    final row = find.bySemanticsIdentifier('preparationAllBrewingSettingsRow');
    expect(row, findsOneWidget);
    expect(find.text('All brewing settings'), findsOneWidget);

    final eventsBefore =
        AnalyticsService.instance.bufferedEventsForTesting.length;

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(router.stack.last.name, 'SettingsBrewingRoute');
    // The sheet closed behind the pushed page.
    expect(row, findsNothing);

    final newEvents = AnalyticsService.instance.bufferedEventsForTesting
        .sublist(eventsBefore);
    expect(newEvents, hasLength(1), reason: 'exactly one analytics event');
    expect(newEvents.single['event_name'], 'settings_shortcut_tapped');
    expect(newEvents.single['properties'], {
      'source': ShortcutSource.preparationSheet.wireName,
      'target': SettingsTarget.brewing.wireName,
    });
  });
}

/// Minimal router: a lightweight landing page plus the shortcut's target
/// (pattern from settings_section_forwarding_test.dart).
class _TestRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    RedirectRoute(path: '/', redirectTo: '/settings'),
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: SettingsBrewingRoute.page, path: '/settings/brewing'),
  ];
}
