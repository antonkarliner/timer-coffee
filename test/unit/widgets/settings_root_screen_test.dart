import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/screens/settings_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/brew_alert_preference.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_root_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>()])

/// Root page test for the category Settings screen (plan 074 phase 11).
///
/// The test environment takes the same shortcuts the other Settings page
/// tests take: `NotificationService.initialize()` cannot run (the controller
/// lands on its catch path: master on, not loading) and the icon API is
/// unavailable, so the appearance subtitle shows the theme label only.
///
/// Not covered here: the notifications row being absent on web — `kIsWeb` is
/// a compile-time constant and false under the VM test runner, so that state
/// cannot be simulated in a widget test.
void main() {
  late MockRecipeProvider recipeProvider;

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
    when(recipeProvider.currentLocale).thenReturn(const Locale('en'));
    when(recipeProvider.getLocaleName('en')).thenAnswer((_) async => 'English');
    when(
      recipeProvider.shownBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(
      recipeProvider.hiddenBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(recipeProvider.recipes).thenReturn(const []);
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  final methods = [
    BrewingMethodModel(brewingMethodId: 'v60', brewingMethod: 'V60'),
    BrewingMethodModel(brewingMethodId: 'espresso', brewingMethod: 'Espresso'),
    BrewingMethodModel(brewingMethodId: 'coldbrew', brewingMethod: 'Cold Brew'),
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
            time: Duration(seconds: 45),
          ),
        ],
      );

  Widget app({
    ThemeMode themeMode = ThemeMode.system,
    AdvancedFeaturesService? advancedService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: ThemeProvider(themeMode),
        ),
        ChangeNotifierProvider<AdvancedFeaturesService>.value(
          value: advancedService ?? AdvancedFeaturesService(),
        ),
        Provider<List<BrewingMethodModel>>.value(value: methods),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
        ChangeNotifierProvider<AnalyticsService>.value(
          value: AnalyticsService.instance,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SettingsScreen(),
      ),
    );
  }

  Future<void> pumpRoot(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.system,
    AdvancedFeaturesService? advancedService,
  }) async {
    await tester.pumpWidget(
      app(themeMode: themeMode, advancedService: advancedService),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the account card and all six category rows',
      (tester) async {
    await pumpRoot(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsAccountCard'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsBrewingRow'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('settingsHomeScreenRow'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsNotificationsRow'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsAppearanceRow'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsLanguageRegionRow'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsPrivacyDataRow'),
      findsOneWidget,
    );
    expect(find.text('Brewing'), findsOneWidget);
    expect(find.text('Home screen'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language & region'), findsOneWidget);
    expect(find.text('Privacy & data'), findsOneWidget);
  });

  testWidgets('brewing subtitle shows the stored defaults: Classic · Silent',
      (tester) async {
    await pumpRoot(tester);
    expect(find.text('Classic · Silent'), findsOneWidget);
  });

  testWidgets('brewing subtitle follows immersive layout and sound alerts',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      AdvancedFeaturesService.kPourLayoutKey: true,
      'notificationMode': 2,
    });
    final advanced = AdvancedFeaturesService();
    await advanced.init();

    await pumpRoot(tester, advancedService: advanced);

    expect(find.text('Immersive · Sound'), findsOneWidget);
  });

  testWidgets('home screen subtitle counts recipe-backed and explicit methods',
      (tester) async {
    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    when(recipeProvider.shownBrewingMethodIds)
        .thenReturn(ValueNotifier<Set<String>>({'espresso'}));
    when(recipeProvider.hiddenBrewingMethodIds)
        .thenReturn(ValueNotifier<Set<String>>({'coldbrew'}));

    await pumpRoot(tester);

    // v60 shown via its recipe, espresso shown explicitly, coldbrew hidden
    // explicitly.
    expect(find.text('2 of 3 methods'), findsOneWidget);
  });

  testWidgets('appearance subtitle shows the theme label', (tester) async {
    await pumpRoot(tester);
    expect(find.text('Automatic'), findsOneWidget);

    await pumpRoot(tester, themeMode: ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('language subtitle shows the language name and today',
      (tester) async {
    await pumpRoot(tester);

    expect(
      find.textContaining(RegExp(r'^English · \w+ \d+, \d{4}$')),
      findsOneWidget,
    );
  });

  testWidgets('analytics subtitle: all on', (tester) async {
    await pumpRoot(tester);
    expect(find.text('Analytics on'), findsOneWidget);
  });

  testWidgets('analytics subtitle: partly on', (tester) async {
    await AnalyticsService.instance.setBrewsEnabled(false);
    await pumpRoot(tester);
    expect(find.text('Analytics partly on'), findsOneWidget);
  });

  testWidgets('analytics subtitle: all off', (tester) async {
    await AnalyticsService.instance.setBrewsEnabled(false);
    await AnalyticsService.instance.setBeansEnabled(false);
    await AnalyticsService.instance.setGeneralEnabled(false);
    await pumpRoot(tester);
    expect(find.text('Analytics off'), findsOneWidget);
  });

  testWidgets(
      'notifications subtitle shows the reminder summary in the '
      'test-environment catch path', (tester) async {
    await pumpRoot(tester);
    // Master notifications on (default), no permission check possible, and
    // the bean-review nudge defaults to on: "On · 1 reminder".
    expect(find.text('On · 1 reminder'), findsOneWidget);
  });
}
