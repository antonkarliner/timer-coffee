import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/screens/settings_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/collections_preferences_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_section_forwarding_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>(), MockSpec<AnalyticsService>()])
/// Deep-link forwarding of the Settings root (plan 074 phase 11): the legacy
/// `timercoffee:///settings?section=…` values must land on the category page
/// that now owns the section, and report exactly one
/// `settings_shortcut_tapped{source: deep_link}` each.
void main() {
  late MockRecipeProvider recipeProvider;
  late MockAnalyticsService analytics;

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
    analytics = MockAnalyticsService();
    when(recipeProvider.recipes).thenReturn(const []);
    when(recipeProvider.currentLocale).thenReturn(const Locale('en'));
    when(recipeProvider.getLocaleName('en')).thenAnswer((_) async => 'English');
    when(
      recipeProvider.shownBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(
      recipeProvider.hiddenBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(analytics.brewsEnabled).thenReturn(true);
    when(analytics.beansEnabled).thenReturn(true);
    when(analytics.generalEnabled).thenReturn(true);
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> shortcutEvents() => AnalyticsService
      .instance
      .bufferedEventsForTesting
      .where((event) => event['event_name'] == 'settings_shortcut_tapped')
      .toList();

  group('settingsTargetForLegacySection', () {
    test('maps the four legacy sections to their new pages', () {
      expect(
        settingsTargetForLegacySection('notifications', isWeb: false),
        SettingsTarget.notifications,
      );
      expect(
        settingsTargetForLegacySection('brewingMethods', isWeb: false),
        SettingsTarget.homeScreen,
      );
      expect(
        settingsTargetForLegacySection('advancedFeatures', isWeb: false),
        SettingsTarget.brewing,
      );
      expect(
        settingsTargetForLegacySection('immersiveBrewing', isWeb: false),
        SettingsTarget.brewing,
      );
    });

    test('notifications has no target on web, others keep theirs', () {
      expect(
        settingsTargetForLegacySection('notifications', isWeb: true),
        isNull,
      );
      expect(
        settingsTargetForLegacySection('brewingMethods', isWeb: true),
        SettingsTarget.homeScreen,
      );
      expect(
        settingsTargetForLegacySection('advancedFeatures', isWeb: true),
        SettingsTarget.brewing,
      );
      expect(
        settingsTargetForLegacySection('immersiveBrewing', isWeb: true),
        SettingsTarget.brewing,
      );
    });

    test('unknown values have no target', () {
      expect(settingsTargetForLegacySection('theme', isWeb: false), isNull);
      expect(settingsTargetForLegacySection('', isWeb: false), isNull);
    });
  });

  // Real-router harness: pumping the target pages too, so the assertion is
  // that the route actually landed on the stack, not just that the mapping
  // function returned the right enum.
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
          ChangeNotifierProvider<AnalyticsService>.value(value: analytics),
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
    return router;
  }

  Future<void> expectForwarded(
    WidgetTester tester,
    String section,
    String expectedRouteName,
    String expectedTarget,
  ) async {
    final router = await pumpApp(tester);
    expect(router.stack.length, 1);
    final eventsBefore =
        AnalyticsService.instance.bufferedEventsForTesting.length;

    router.push(SettingsRoute(section: section));
    await tester.pumpAndSettle();

    // Initial root + the pushed SettingsRoute(section: …) + the forwarded
    // target page on top.
    expect(router.stack.length, 3);
    expect(router.stack[1].name, 'SettingsRoute');
    expect(router.stack.last.name, expectedRouteName);
    expect(shortcutEvents(), hasLength(1));
    expect(
      AnalyticsService.instance.bufferedEventsForTesting.length - eventsBefore,
      1,
      reason: 'exactly one analytics event overall',
    );
    expect(shortcutEvents().single['properties'], {
      'source': 'deep_link',
      'target': expectedTarget,
      'section': section,
    });
  }

  testWidgets('section=notifications pushes the notifications page once', (
    tester,
  ) async {
    await expectForwarded(
      tester,
      'notifications',
      'SettingsNotificationsRoute',
      'notifications',
    );
  });

  testWidgets('section=brewingMethods pushes the home screen page once', (
    tester,
  ) async {
    await expectForwarded(
      tester,
      'brewingMethods',
      'SettingsHomeTabRoute',
      'home_screen',
    );
  });

  testWidgets('section=advancedFeatures pushes the brewing page once', (
    tester,
  ) async {
    await expectForwarded(
      tester,
      'advancedFeatures',
      'SettingsBrewingRoute',
      'brewing',
    );
  });

  testWidgets('section=immersiveBrewing pushes the brewing page once', (
    tester,
  ) async {
    await expectForwarded(
      tester,
      'immersiveBrewing',
      'SettingsBrewingRoute',
      'brewing',
    );
  });

  // A link opened while the root is already on top: the router reuses the
  // root's State (no initState), so forwarding must come from
  // didUpdateWidget. Found on the simulator, 2026-09-30.
  testWidgets('section link while the root is on top still forwards once', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    expect(router.stack.single.name, 'SettingsRoute');

    await router.navigatePath('/settings?section=brewingMethods');
    await tester.pumpAndSettle();

    expect(router.stack.last.name, 'SettingsHomeTabRoute');
    expect(shortcutEvents(), hasLength(1));
    expect(shortcutEvents().single['properties'], {
      'source': 'deep_link',
      'target': 'home_screen',
      'section': 'brewingMethods',
    });
  });

  testWidgets('unknown section stays on the root and reports nothing', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final eventsBefore =
        AnalyticsService.instance.bufferedEventsForTesting.length;

    router.push(SettingsRoute(section: 'theme'));
    await tester.pumpAndSettle();

    expect(router.stack.length, 2, reason: 'only the pushed root itself');
    expect(router.stack.last.name, 'SettingsRoute');
    expect(
      AnalyticsService.instance.bufferedEventsForTesting.length - eventsBefore,
      0,
    );
    expect(shortcutEvents(), isEmpty);
  });
}

/// Minimal router exposing the Settings root and the three forwarding
/// targets; the remaining Settings pages are irrelevant to these tests.
class _TestRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    RedirectRoute(path: '/', redirectTo: '/settings'),
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: SettingsBrewingRoute.page, path: '/settings/brewing'),
    AutoRoute(page: SettingsHomeTabRoute.page, path: '/settings/home'),
    AutoRoute(
      page: SettingsNotificationsRoute.page,
      path: '/settings/notifications',
    ),
  ];
}
