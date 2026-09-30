import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/notification_mode.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/screens/preparation_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/brew_alert_preference.dart';
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BrewAlertPreference.instance.resetForTesting();
  });

  testWidgets(
      'a brew-alert mode set elsewhere updates the Preparation icon without reloading the screen',
      (tester) async {
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
    await tester.pumpAndSettle();

    // Stored default is none → muted icon from the first frame.
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    // Changed "in Settings" while Preparation stays on the stack below.
    await BrewAlertPreference.instance.set(NotificationMode.soundOnly);
    await tester.pump();

    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsNothing);

    await BrewAlertPreference.instance.set(NotificationMode.vibrationOnly);
    await tester.pump();

    expect(find.byIcon(Icons.vibration), findsOneWidget);
  });

  testWidgets('Preparation starts with the stored mode, not sound',
      (tester) async {
    SharedPreferences.setMockInitialValues({'notificationMode': 0});

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

    // The first frame already shows the stored mode (previously it started
    // at soundOnly and only corrected itself after an async prefs read).
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsNothing);
  });
}
