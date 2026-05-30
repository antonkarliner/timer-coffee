import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_steps_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 640,
          child: RecipeStepsForm(
            initialSteps: [
              BrewStepModel(
                id: 'prep',
                order: 1,
                description: 'Prepare filter',
                time: Duration.zero,
              ),
              BrewStepModel(
                id: 'brew',
                order: 2,
                description: 'Pour 60g water',
                time: const Duration(seconds: 30),
              ),
            ],
            scrollController: ScrollController(),
            onStepsChanged: (_) {},
            isSaving: false,
            onSave: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('does not show AI review controls on steps page', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Verify recipe with AI'), findsNothing);
    expect(find.text('Add Step'), findsOneWidget);
    expect(find.text('Save Recipe'), findsOneWidget);
  });
}
