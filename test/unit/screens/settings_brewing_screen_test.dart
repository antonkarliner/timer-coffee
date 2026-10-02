import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/notification_mode.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/settings/settings_brewing_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/brew_alert_preference.dart';
import 'package:coffee_timer/widgets/brewing/layout_preview_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/settings_section_forwarding_test.mocks.dart';

RecipeModel _recipeWithTimedSteps() => RecipeModel(
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
      id: 'prep',
      order: 1,
      description: 'Prepare the brewer',
      time: Duration.zero,
    ),
    BrewStepModel(
      id: 'first',
      order: 2,
      description: 'Bloom with 60 g',
      time: const Duration(seconds: 45),
    ),
    BrewStepModel(
      id: 'second',
      order: 3,
      description: 'Pour to 250 g',
      time: const Duration(seconds: 30),
    ),
  ],
);

void main() {
  late AdvancedFeaturesService advanced;
  late MockRecipeProvider recipeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    BrewAlertPreference.instance.resetForTesting();
    advanced = AdvancedFeaturesService();
    await advanced.init();
    recipeProvider = MockRecipeProvider();
    when(recipeProvider.getLastUsedRecipe()).thenAnswer((_) async => null);
    // The resolved preview steps are cached for the session; reset so every
    // test starts with an unresolved first visit, as a fresh run would.
    SettingsBrewingScreen.resetSessionPreviewStepsForTesting();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
    advanced.dispose();
  });

  List<Map<String, dynamic>> eventsNamed(String name) => AnalyticsService
      .instance
      .bufferedEventsForTesting
      .where((event) => event['event_name'] == name)
      .toList();

  Widget app(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AdvancedFeaturesService>.value(value: advanced),
      ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(app(const SettingsBrewingScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the layout cards, manual step control and brew alerts', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Brewing'), findsOneWidget);
    // Section header above the layout preview cards.
    expect(find.text('Brewing screen'), findsOneWidget);
    expect(find.byType(LayoutPreviewCards), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('layoutChoiceClassicCard'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('layoutChoiceImmersiveCard'),
      findsOneWidget,
    );
    // The layout is a card pair now, not a choice row.
    expect(
      find.bySemanticsIdentifier('settingsBrewingLayoutTile'),
      findsNothing,
    );
    // The check badge marks the current (classic) card only.
    expect(find.byType(SelectionCheckBadge), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('settingsManualStepControlSwitch'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsBrewAlertsTile'),
      findsOneWidget,
    );
    // Stored default is none → "Silent" as the current value.
    expect(find.text('Silent'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Immersive'), findsOneWidget);
    expect(eventsNamed('setting_changed'), isEmpty);
  });

  testWidgets('the cards show the last recipe’s first timed step', (
    tester,
  ) async {
    when(
      recipeProvider.getLastUsedRecipe(),
    ).thenAnswer((_) async => _recipeWithTimedSteps());

    await pumpPage(tester);

    // The first timed step (and the one after it), in both cards.
    expect(find.text('Bloom with 60 g'), findsWidgets);
    expect(find.text('Pour to 250 g'), findsWidgets);
    expect(find.text('45'), findsWidgets);
    // Not the sample.
    expect(find.text('Bloom with 50 g of water'), findsNothing);
  });

  testWidgets('the cards show the sample strings when there is no last recipe', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Bloom with 50 g of water'), findsWidgets);
    expect(find.text('Pour to 150 g'), findsWidgets);
    expect(find.text('30'), findsWidgets);
  });

  testWidgets(
      'a later visit draws the remembered step first, then picks up a new '
      'last recipe', (tester) async {
    // First visit: no last recipe yet, so the sample.
    await pumpPage(tester);
    expect(find.text('Bloom with 50 g of water'), findsWidgets);

    // The user brews a recipe, then comes back to the page.
    when(
      recipeProvider.getLastUsedRecipe(),
    ).thenAnswer((_) async => _recipeWithTimedSteps());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(const SettingsBrewingScreen()));

    // First frame: the remembered steps, not the empty preview.
    expect(find.text('Bloom with 50 g of water'), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('Bloom with 60 g'), findsWidgets);
    expect(find.text('Bloom with 50 g of water'), findsNothing);
  });

  testWidgets('tapping Immersive selects it with source settings', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('layoutChoiceImmersiveCard'));
    await tester.pumpAndSettle();

    expect(advanced.pourLayoutEnabled, isTrue);
    final toggles = eventsNamed('beta_feature_toggled');
    expect(toggles, hasLength(1));
    expect(toggles.single['properties'], {
      'feature': 'pour_layout',
      'enabled': true,
      'source': 'settings',
    });
    expect(eventsNamed('setting_changed'), isEmpty);
    // No layout_choice_* events here — those belong to the Play-tap picker.
    expect(eventsNamed('layout_choice_shown'), isEmpty);
    expect(eventsNamed('layout_choice_made'), isEmpty);
  });

  testWidgets('tapping the already-selected card emits nothing', (tester) async {
    SharedPreferences.setMockInitialValues({
      AdvancedFeaturesService.kPourLayoutKey: true,
    });
    advanced = AdvancedFeaturesService();
    await advanced.init();

    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('layoutChoiceImmersiveCard'));
    await tester.pumpAndSettle();

    expect(advanced.pourLayoutEnabled, isTrue);
    expect(eventsNamed('beta_feature_toggled'), isEmpty);
  });

  testWidgets(
    'choosing Classic through the cards calls through and shows the switch-back reason row',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AdvancedFeaturesService.kPourLayoutKey: true,
      });
      advanced = AdvancedFeaturesService();
      await advanced.init();
      expect(advanced.pourLayoutEnabled, isTrue);

      await pumpPage(tester);
      expect(
        find.bySemanticsIdentifier('layoutSwitchBackReasonRow'),
        findsNothing,
      );

      await tester.tap(find.bySemanticsIdentifier('layoutChoiceClassicCard'));
      await tester.pumpAndSettle();

      expect(advanced.pourLayoutEnabled, isFalse);
      expect(
        find.bySemanticsIdentifier('layoutSwitchBackReasonRow'),
        findsOneWidget,
      );
      // The cards emit only the beta_feature_toggled that
      // setPourLayoutEnabled emits itself — no setting_changed.
      expect(eventsNamed('setting_changed'), isEmpty);
      final toggles = eventsNamed('beta_feature_toggled');
      expect(toggles, hasLength(1));
      expect(toggles.single['properties'], {
        'feature': 'pour_layout',
        'enabled': false,
        'source': 'settings',
      });
    },
  );

  testWidgets(
    'manual step switch toggles the service and emits one beta_feature_toggled',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(
        find.bySemanticsIdentifier('settingsManualStepControlSwitch'),
      );
      await tester.pumpAndSettle();

      expect(advanced.manualStepControlEnabled, isTrue);
      final toggles = eventsNamed('beta_feature_toggled');
      expect(toggles, hasLength(1));
      expect(toggles.single['properties'], {
        'feature': 'manual_step_control',
        'enabled': true,
        'source': 'settings',
      });
      expect(eventsNamed('setting_changed'), isEmpty);
    },
  );

  testWidgets(
    'choosing Vibration persists notificationMode=1 and emits one setting_changed',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.bySemanticsIdentifier('settingsBrewAlertsTile'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsIdentifier('brewAlertVibrationListTile'),
      );
      await tester.pumpAndSettle();

      expect(
        BrewAlertPreference.instance.mode.value,
        NotificationMode.vibrationOnly,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('notificationMode'), 1);
      final events = eventsNamed('setting_changed');
      expect(events, hasLength(1));
      expect(events.single['properties'], {
        'key': 'brew_alerts',
        'value': 'vibration',
        'previous': 'silent',
        'source': 'settings',
      });
    },
  );

  testWidgets('choosing the current brew-alert value emits nothing', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsBrewAlertsTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('brewAlertSilentListTile'));
    await tester.pumpAndSettle();

    expect(eventsNamed('setting_changed'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('notificationMode'), isFalse);
  });
}
