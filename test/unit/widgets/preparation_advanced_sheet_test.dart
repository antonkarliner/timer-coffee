import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/screens/preparation_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/widgets/app_switch_list_tile.dart';
import 'package:coffee_timer/widgets/brewing/layout_preview_cards.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _recipe = RecipeModel(
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

Finder _semanticsWithId(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

/// Pumps the Preparation screen and opens the gear sheet. The text-scale
/// override sits in `MaterialApp.builder`, because a modal bottom sheet
/// inherits MediaQuery from above the Navigator, not from `home`.
Future<void> pumpSheet(
  WidgetTester tester, {
  required AdvancedFeaturesService advancedFeatures,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AdvancedFeaturesService>.value(
      value: advancedFeatures,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: PreparationScreen(recipe: _recipe, brewingMethodName: 'V60'),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(_semanticsWithId('preparationAdvancedFeaturesButton'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> eventsNamed(String name) => AnalyticsService
      .instance
      .bufferedEventsForTesting
      .where((event) => event['event_name'] == name)
      .toList();

  testWidgets(
    'gear sheet shows the layout cards, manual step switch and nav row; Immersive selects with the sheet source',
    (tester) async {
      final advancedFeatures = AdvancedFeaturesService();
      addTearDown(advancedFeatures.dispose);

      await pumpSheet(tester, advancedFeatures: advancedFeatures);

      expect(tester.takeException(), isNull);
      expect(find.text('Brewing'), findsOneWidget);
      expect(find.byType(LayoutPreviewCards), findsOneWidget);
      expect(
        _semanticsWithId('layoutChoiceClassicCard'),
        findsOneWidget,
      );
      expect(
        _semanticsWithId('layoutChoiceImmersiveCard'),
        findsOneWidget,
      );
      // The old "Immersive brewing screen" switch is gone.
      expect(_semanticsWithId('pourLayoutToggleButton'), findsNothing);
      expect(find.byType(AppSwitchListTile), findsNothing);
      expect(find.byType(SettingsSwitchRow), findsOneWidget);
      expect(_semanticsWithId('manualStepControlToggleButton'), findsOneWidget);
      expect(find.text('Manual step control'), findsOneWidget);
      expect(find.byType(SettingsNavRow), findsOneWidget);
      expect(_semanticsWithId('preparationAllBrewingSettingsRow'), findsOneWidget);
      expect(find.text('All brewing settings'), findsOneWidget);

      await tester.tap(_semanticsWithId('layoutChoiceImmersiveCard'));
      await tester.pumpAndSettle();

      expect(advancedFeatures.pourLayoutEnabled, isTrue);
      final toggles = eventsNamed('beta_feature_toggled');
      expect(toggles, hasLength(1));
      expect(toggles.single['properties'], {
        'feature': 'pour_layout',
        'enabled': true,
        'source': 'preparation_settings_sheet',
      });
      // No layout_choice_* events here — those belong to the Play-tap picker.
      expect(eventsNamed('layout_choice_shown'), isEmpty);
      expect(eventsNamed('layout_choice_made'), isEmpty);
    },
  );

  testWidgets('tapping the already-selected card emits nothing', (tester) async {
    SharedPreferences.setMockInitialValues({
      AdvancedFeaturesService.kPourLayoutKey: true,
    });
    final advancedFeatures = AdvancedFeaturesService();
    await advancedFeatures.init();
    addTearDown(advancedFeatures.dispose);

    await pumpSheet(tester, advancedFeatures: advancedFeatures);

    await tester.tap(_semanticsWithId('layoutChoiceImmersiveCard'));
    await tester.pumpAndSettle();

    expect(advancedFeatures.pourLayoutEnabled, isTrue);
    expect(eventsNamed('beta_feature_toggled'), isEmpty);
  });

  testWidgets(
    'switching Immersive → Classic through the cards shows the switch-back reason row',
    (tester) async {
      final advancedFeatures = AdvancedFeaturesService();
      addTearDown(advancedFeatures.dispose);

      await pumpSheet(tester, advancedFeatures: advancedFeatures);
      expect(_semanticsWithId('layoutSwitchBackReasonRow'), findsNothing);

      await tester.tap(_semanticsWithId('layoutChoiceImmersiveCard'));
      await tester.pumpAndSettle();
      expect(_semanticsWithId('layoutSwitchBackReasonRow'), findsNothing);

      await tester.tap(_semanticsWithId('layoutChoiceClassicCard'));
      await tester.pumpAndSettle();
      expect(_semanticsWithId('layoutSwitchBackReasonRow'), findsOneWidget);

      final toggles = eventsNamed('beta_feature_toggled');
      expect(toggles, hasLength(2));
      expect(toggles[0]['properties'], {
        'feature': 'pour_layout',
        'enabled': true,
        'source': 'preparation_settings_sheet',
      });
      expect(toggles[1]['properties'], {
        'feature': 'pour_layout',
        'enabled': false,
        'source': 'preparation_settings_sheet',
      });
    },
  );

  testWidgets(
    'no overflow at 1.3 text scale on a 375×667 screen, and the nav row is reachable',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final advancedFeatures = AdvancedFeaturesService();
      addTearDown(advancedFeatures.dispose);

      await pumpSheet(
        tester,
        advancedFeatures: advancedFeatures,
        textScaler: const TextScaler.linear(1.3),
      );

      expect(tester.takeException(), isNull);

      final row = _semanticsWithId('preparationAllBrewingSettingsRow');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(row).bottom, lessThan(667));
    },
  );
}
