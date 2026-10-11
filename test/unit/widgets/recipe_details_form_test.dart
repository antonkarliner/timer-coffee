import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_details_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController recipeNameController;
  late TextEditingController shortDescriptionController;

  setUp(() {
    recipeNameController = TextEditingController(text: 'Morning V60');
    shortDescriptionController = TextEditingController(
      text: 'Clean and bright daily brew',
    );
  });

  tearDown(() {
    recipeNameController.dispose();
    shortDescriptionController.dispose();
  });

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 900,
          child: RecipeDetailsForm(
            recipeNameController: recipeNameController,
            shortDescriptionController: shortDescriptionController,
            brewingMethods: [
              BrewingMethodModel(
                brewingMethodId: 'v60',
                brewingMethod: 'Hario V60',
              ),
            ],
            selectedBrewingMethodId: 'v60',
            coffeeAmount: 15,
            waterAmount: 250,
            waterTemp: 93,
            grindSize: 'Medium',
            brewMinutes: 3,
            brewSeconds: 0,
            onNameChanged: (_) {},
            onShortDescriptionChanged: (_) {},
            onBrewingMethodChanged: (_) {},
            onCoffeeAmountChanged: (_) {},
            onWaterAmountChanged: (_) {},
            onWaterTempChanged: (_) {},
            onGrindSizeChanged: (_) {},
            onBrewMinutesChanged: (_) {},
            onBrewSecondsChanged: (_) {},
            onContinue: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders continue button and no AI review UI', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Continue to Recipe Steps'), findsOneWidget);
    expect(find.textContaining('AI'), findsNothing);
  });
}
