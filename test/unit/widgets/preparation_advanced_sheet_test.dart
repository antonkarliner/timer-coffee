import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/screens/preparation_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/widgets/app_switch_list_tile.dart';
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

void main() {
  testWidgets('advanced sheet shows both toggles and enables pour layout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final advancedFeatures = AdvancedFeaturesService();
    addTearDown(advancedFeatures.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AdvancedFeaturesService>.value(
        value: advancedFeatures,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PreparationScreen(recipe: _recipe, brewingMethodName: 'V60'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(_semanticsWithId('preparationAdvancedFeaturesButton'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSwitchListTile), findsNWidgets(2));
    expect(_semanticsWithId('manualStepControlToggleButton'), findsOneWidget);
    expect(_semanticsWithId('pourLayoutToggleButton'), findsOneWidget);
    expect(find.text('Manual step control'), findsOneWidget);
    expect(find.text('Immersive brewing screen'), findsOneWidget);

    await tester.tap(find.text('Immersive brewing screen'));
    await tester.pump();

    expect(advancedFeatures.pourLayoutEnabled, isTrue);
  });
}
