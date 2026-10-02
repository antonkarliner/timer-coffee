import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/settings/settings_home_tab_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/collections_preferences_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// Widget tests for the Settings → Home screen page: the Collections switch,
/// one switch per brewing method with the shared shown/hidden/has-recipes
/// value logic and the methods' brewing icons, and the reset-to-default flow.
void main() {
  final methods = [
    BrewingMethodModel(brewingMethodId: 'v60', brewingMethod: 'V60'),
    BrewingMethodModel(brewingMethodId: 'espresso', brewingMethod: 'Espresso'),
    BrewingMethodModel(brewingMethodId: 'cold_brew', brewingMethod: 'Cold Brew'),
  ];

  // Read by setUp before AnalyticsService initializes (a plain-zone await:
  // PackageInfo.fromPlatform() never completes under testWidgets).
  var initialPrefs = const <String, Object>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
    initialPrefs = const {};
  });

  List<Map<String, dynamic>> eventsNamed(String name) => AnalyticsService
      .instance
      .bufferedEventsForTesting
      .where((event) => event['event_name'] == name)
      .toList();

  /// One seeded recipe (v60) so the default has-recipes branch is exercised.
  Future<RecipeProvider> pumpPage(
    WidgetTester tester, {
    List<BrewingMethodModel>? allMethods,
  }) async {
    // Re-stamp the store with this test's initial values. AnalyticsService
    // was initialized in the plain-zone setUp against the default store and
    // holds only its own keys, so re-stamping here does not disturb it.
    SharedPreferences.setMockInitialValues(initialPrefs);
    final db = openTestDatabase();
    addTearDown(db.close);
    await db.recipesDao.insertOrUpdateRecipe(
      RecipesCompanion.insert(
        id: 'recipe-v60',
        brewingMethodId: 'v60',
        coffeeAmount: 15,
        waterAmount: 250,
        waterTemp: 93,
        brewTime: 120,
      ),
    );
    final recipeProvider = RecipeProvider(
      const Locale('en'),
      const <Locale>[],
      db,
      DatabaseProvider(db),
    );
    addTearDown(recipeProvider.dispose);
    await recipeProvider.ensureDataReady();

    final collectionsPrefs = CollectionsPreferencesService();
    await collectionsPrefs.init();
    addTearDown(collectionsPrefs.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          Provider<List<BrewingMethodModel>>.value(value: allMethods ?? methods),
          ChangeNotifierProvider<CollectionsPreferencesService>.value(
            value: collectionsPrefs,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsHomeTabScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return recipeProvider;
  }

  bool switchValue(WidgetTester tester, String methodTitle) => tester
      .widget<SettingsSwitchRow>(
        find.ancestor(
          of: find.text(methodTitle),
          matching: find.byType(SettingsSwitchRow),
        ),
      )
      .value;

  Finder resetButton() =>
      find.bySemanticsIdentifier('settingsResetBrewingMethodsButton');

  SettingsActionRow resetRow(WidgetTester tester) =>
      tester.widget<SettingsActionRow>(
        find.ancestor(
          of: resetButton(),
          matching: find.byType(SettingsActionRow),
        ),
      );

  Finder dialogConfirmButton() =>
      find.widgetWithText(AppElevatedButton, 'Reset to default');

  testWidgets('renders the collections switch and one switch per method with '
      'the has-recipes default', (tester) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsIdentifier('settingsCollectionsSwitch'),
        findsOneWidget);
    expect(find.bySemanticsIdentifier('brewingMethodSwitch_v60'),
        findsOneWidget);
    expect(find.bySemanticsIdentifier('brewingMethodSwitch_espresso'),
        findsOneWidget);
    expect(find.bySemanticsIdentifier('brewingMethodSwitch_cold_brew'),
        findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsResetBrewingMethodsButton'),
        findsOneWidget);

    // v60 has the seeded recipe → on; the others have none → off.
    expect(switchValue(tester, 'V60'), isTrue);
    expect(switchValue(tester, 'Espresso'), isFalse);
    expect(switchValue(tester, 'Cold Brew'), isFalse);
    expect(eventsNamed('setting_changed'), isEmpty);
  });

  testWidgets('renders three sections with one header and an icon leading '
      'each method row', (tester) async {
    await pumpPage(tester);

    // Three sections; only the brewing-methods section is headed.
    expect(find.byType(SettingsSection), findsNWidgets(3));
    expect(find.byType(SettingsSectionHeader), findsOneWidget);
    expect(find.text('Brewing methods'), findsOneWidget);

    // The reset row is an action row with the reset copy.
    final row = resetRow(tester);
    expect(row.title, 'Reset to default');
    expect(row.subtitle, 'Shows only the methods you have recipes for');

    // Each method row leads with its brewing icon at the standard size, and
    // the icons differ per method.
    Icon leadingIcon(String methodTitle) => tester
        .widget<ListTile>(
          find.ancestor(
            of: find.text(methodTitle),
            matching: find.byType(ListTile),
          ),
        )
        .leading! as Icon;

    final icons = <IconData?>{};
    for (final method in methods) {
      final icon = leadingIcon(method.brewingMethod);
      expect(icon.size, AppIconSize.medium);
      expect(icon.icon, isNotNull);
      icons.add(icon.icon);
    }
    expect(icons, hasLength(methods.length));
  });

  testWidgets('an explicit user choice wins over the has-recipes default',
      (tester) async {
    initialPrefs = const {
      'shownBrewingMethodIds': ['espresso'],
      'hiddenBrewingMethodIds': ['v60'],
    };
    await pumpPage(tester);

    // Hidden by user → off despite recipes; shown by user → on despite none.
    expect(switchValue(tester, 'V60'), isFalse);
    expect(switchValue(tester, 'Espresso'), isTrue);
    expect(switchValue(tester, 'Cold Brew'), isFalse);
  });

  testWidgets('toggling a method persists the preference and emits one '
      'setting_changed', (tester) async {
    final provider = await pumpPage(tester);

    await tester
        .tap(find.bySemanticsIdentifier('brewingMethodSwitch_espresso'));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'Espresso'), isTrue);
    expect(provider.shownBrewingMethodIds.value, contains('espresso'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shownBrewingMethodIds'), contains('espresso'));

    var events = eventsNamed('setting_changed');
    expect(events, hasLength(1));
    expect(events.single['properties'], {
      'key': 'brewing_method_visible',
      'value': 'on',
      'previous': 'off',
      'source': 'settings',
      'brewing_method_id': 'espresso',
    });

    // Toggling back emits the second event with the flipped values.
    await tester
        .tap(find.bySemanticsIdentifier('brewingMethodSwitch_espresso'));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'Espresso'), isFalse);
    expect(provider.hiddenBrewingMethodIds.value, contains('espresso'));
    events = eventsNamed('setting_changed');
    expect(events, hasLength(2));
    expect(events.last['properties'], {
      'key': 'brewing_method_visible',
      'value': 'off',
      'previous': 'on',
      'source': 'settings',
      'brewing_method_id': 'espresso',
    });
  });

  testWidgets('the collections switch emits once per real change and persists',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsCollectionsSwitch'));
    await tester.pumpAndSettle();

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('collections_section_dismissed'), isTrue);
    var events = eventsNamed('collections_visibility_changed');
    expect(events, hasLength(1));
    expect(events.single['properties'], {
      'visible': false,
      'source': 'settings_home_screen',
    });

    await tester.tap(find.bySemanticsIdentifier('settingsCollectionsSwitch'));
    await tester.pumpAndSettle();

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('collections_section_dismissed'), isFalse);
    events = eventsNamed('collections_visibility_changed');
    expect(events, hasLength(2));
    expect(events.last['properties'], {
      'visible': true,
      'source': 'settings_home_screen',
    });
    expect(eventsNamed('setting_changed'), isEmpty);
  });

  testWidgets('reset → confirm clears preferences and emits one '
      'brewing_methods_reset', (tester) async {
    initialPrefs = const {
      'shownBrewingMethodIds': ['cold_brew'],
      'hiddenBrewingMethodIds': ['v60'],
    };
    final provider = await pumpPage(tester);

    await tester.tap(resetButton());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Show every brewing method that has recipes again? Your choices here '
        'will be cleared.',
      ),
      findsOneWidget,
    );
    await tester.tap(dialogConfirmButton());
    await tester.pumpAndSettle();

    expect(provider.shownBrewingMethodIds.value, isEmpty);
    expect(provider.hiddenBrewingMethodIds.value, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shownBrewingMethodIds'), isEmpty);
    expect(prefs.getStringList('hiddenBrewingMethodIds'), isEmpty);

    final events = eventsNamed('setting_changed');
    expect(events, hasLength(1));
    expect(events.single['properties'], {
      'key': 'brewing_methods_reset',
      'value': 'reset',
      'source': 'settings',
    });
    expect(find.text('Reset to default'), findsOneWidget); // dialog is gone
  });

  testWidgets('reset → cancel changes nothing and emits nothing',
      (tester) async {
    initialPrefs = const {
      'shownBrewingMethodIds': ['cold_brew'],
    };
    final provider = await pumpPage(tester);

    await tester.tap(resetButton());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(provider.shownBrewingMethodIds.value, {'cold_brew'});
    expect(provider.hiddenBrewingMethodIds.value, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shownBrewingMethodIds'), ['cold_brew']);
    expect(eventsNamed('setting_changed'), isEmpty);
  });

  testWidgets('reset is disabled with no preferences and follows the '
      'switches immediately', (tester) async {
    await pumpPage(tester);

    expect(resetRow(tester).enabled, isFalse);

    // Tapping the disabled row does nothing.
    await tester.tap(resetButton());
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Show every brewing method that has recipes again? Your choices here '
        'will be cleared.',
      ),
      findsNothing,
    );
    expect(eventsNamed('setting_changed'), isEmpty);

    // Flipping one switch changes only the ValueNotifiers; the reset row
    // must become enabled without a provider notification.
    await tester
        .tap(find.bySemanticsIdentifier('brewingMethodSwitch_espresso'));
    await tester.pump();

    expect(resetRow(tester).enabled, isTrue);
  });

  testWidgets('the reset button is reachable by scrolling with many methods',
      (tester) async {
    final many = List.generate(
      40,
      (i) => BrewingMethodModel(
        brewingMethodId: 'm$i',
        brewingMethod: 'Method $i',
      ),
    );
    initialPrefs = const {
      'shownBrewingMethodIds': ['m0'],
    };
    await pumpPage(tester, allMethods: many);

    await tester.scrollUntilVisible(resetButton(), 200);
    // The row is taller than the old button was; make sure it is fully on
    // screen before tapping its center.
    await tester.ensureVisible(resetButton());
    await tester.pumpAndSettle();
    await tester.tap(resetButton());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Show every brewing method that has recipes again? Your choices here '
        'will be cleared.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
