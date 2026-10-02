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
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:coffee_timer/widgets/account/account_entry_tile.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_root_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>()])

/// Root page test for the category Settings screen (plan 074 phase 11,
/// restructured in plan 077 phase 4b: two `SettingsSection`s, no divider).
///
/// The test environment takes the same shortcuts the other Settings page
/// tests take: `NotificationService.initialize()` cannot run (the controller
/// lands on its catch path: master on, not loading) and the icon API is
/// unavailable, so the appearance summary shows the theme label only.
///
/// Two states are therefore unreachable in a widget test here:
/// - notifications master off / blocked — the row's controller is created
///   inside the screen's State and never leaves its catch path under the VM
///   runner, so those branches are pinned against the
///   `notificationsRootSubtitle` seam instead; and
/// - the appearance summary with the icon API — `iconApiAvailable` can only
///   become true through the real platform plugin, so only the
///   `settingsAppearanceSummary` string contract is asserted.
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
    Locale locale = const Locale('en'),
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
        locale: locale,
        home: const SettingsScreen(),
      ),
    );
  }

  Future<void> pumpRoot(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.system,
    AdvancedFeaturesService? advancedService,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      app(
        themeMode: themeMode,
        advancedService: advancedService,
        locale: locale,
      ),
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

  testWidgets('fa summaries print counts in Persian digits, like the date',
      (tester) async {
    when(recipeProvider.recipes).thenReturn([recipeFor('v60')]);
    when(recipeProvider.shownBrewingMethodIds)
        .thenReturn(ValueNotifier<Set<String>>({'espresso'}));

    await pumpRoot(tester, locale: const Locale('fa'));

    expect(tester.takeException(), isNull);
    // Before the placeholders carried "format": "decimalPattern" these read
    // "2 از 3 روش" and "فعال · 1 یادآوری". The separator is the Persian
    // comma: a middle dot beside "۱" reads as "۱۰".
    expect(find.text('۲ از ۳ روش'), findsOneWidget);
    expect(find.text('فعال، ۱ یادآوری'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('appearance summary without the icon API is the theme label',
      (tester) async {
    // The test environment has no icon API, so the summary is the theme
    // label alone — the with-icon "Dark · Default icon" form is unreachable
    // here (see the file header); only its string contract is pinned below.
    await pumpRoot(tester);
    expect(find.text('Automatic'), findsOneWidget);

    await pumpRoot(tester, themeMode: ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
  });

  test('appearance summary contract: "<theme> · <icon> icon"', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      l10n.settingsAppearanceSummary('Dark', 'Default'),
      'Dark · Default icon',
    );
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

  testWidgets('root is two SettingsSections with no divider', (tester) async {
    await pumpRoot(tester);

    expect(find.byType(SettingsSection), findsNWidgets(2));
    expect(find.byType(Divider), findsNothing);
    // The account card section comes first, the category rows second.
    final sections = tester
        .widgetList<SettingsSection>(find.byType(SettingsSection))
        .toList();
    expect(
      find.descendant(
        of: find.byWidget(sections.first),
        matching: find.byType(AccountEntryTile),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byWidget(sections.first),
        matching: find.text('Brewing'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byWidget(sections.last),
        matching: find.text('Brewing'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('account card opts into the Settings chevron', (tester) async {
    await pumpRoot(tester);

    final tile = tester.widget<AccountEntryTile>(
      find.byType(AccountEntryTile),
    );
    expect(tile.source, AccountEntrySource.settings);
    expect(tile.showChevron, isTrue);
    // Signed out, the tile still renders the trailing chevron.
    expect(
      find.descendant(
        of: find.byType(AccountEntryTile),
        matching: find.byIcon(Icons.chevron_right),
      ),
      findsOneWidget,
    );
  });

  testWidgets('brewing row leads with the Brew Coffee tab icon',
      (tester) async {
    await pumpRoot(tester);

    expect(find.byIcon(Coffeico.coffee_maker), findsOneWidget);
    expect(find.byIcon(Icons.coffee_maker_outlined), findsNothing);
  });

  test('notifications summary maps master-off to "Off"', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    // Unreachable through the widget: the row's controller stays on its
    // catch path (master on) under the test runner, so the branch mapping is
    // pinned on the seam instead (see the file header).
    final result = notificationsRootSubtitle(
      isLoading: false,
      systemPermissionDenied: false,
      masterEnabled: false,
      enabledReminderCount: 3,
      l10n: l10n,
    );
    expect(result.subtitle, 'Off');
    expect(result.isError, isFalse);
  });

  test('notifications summary maps the blocked state to the error colour',
      () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final result = notificationsRootSubtitle(
      isLoading: false,
      systemPermissionDenied: true,
      masterEnabled: true,
      enabledReminderCount: 3,
      l10n: l10n,
    );
    expect(result.subtitle, l10n.settingsNotificationsSummaryBlocked);
    expect(result.isError, isTrue);
  });

  test('notifications summary loading state has no subtitle', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final result = notificationsRootSubtitle(
      isLoading: true,
      systemPermissionDenied: false,
      masterEnabled: true,
      enabledReminderCount: 3,
      l10n: l10n,
    );
    expect(result.subtitle, isNull);
    expect(result.isError, isFalse);
  });
}
