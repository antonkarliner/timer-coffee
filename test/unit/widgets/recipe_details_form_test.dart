import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_ai_review_card.dart';
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

  Widget buildSubject({
    required bool aiReviewAvailable,
    required bool aiReviewEnabled,
    required ValueChanged<bool> onAiReviewChanged,
    VoidCallback? onAiReviewInfoPressed,
  }) {
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
            aiReviewEnabled: aiReviewEnabled,
            aiReviewAvailable: aiReviewAvailable,
            onAiReviewChanged: onAiReviewChanged,
            onAiReviewInfoPressed: onAiReviewInfoPressed ?? () {},
            onContinue: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows unavailable copy when AI review requires sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        aiReviewAvailable: false,
        aiReviewEnabled: false,
        onAiReviewChanged: (_) {},
      ),
    );
    await tester.pump();

    expect(find.text('Verify recipe with AI'), findsOneWidget);
    expect(
      find.text('Sign in to use AI to check recipe syntax'),
      findsOneWidget,
    );
  });

  testWidgets('calls toggle callback when signed-out AI review is tapped', (
    tester,
  ) async {
    bool? changedValue;
    await tester.pumpWidget(
      buildSubject(
        aiReviewAvailable: false,
        aiReviewEnabled: false,
        onAiReviewChanged: (value) => changedValue = value,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Verify recipe with AI'));
    await tester.tap(find.text('Verify recipe with AI'));
    await tester.pump();

    expect(changedValue, isTrue);
  });

  testWidgets('shows AI review card and calls info callback', (tester) async {
    var infoPressed = false;
    await tester.pumpWidget(
      buildSubject(
        aiReviewAvailable: true,
        aiReviewEnabled: false,
        onAiReviewChanged: (_) {},
        onAiReviewInfoPressed: () => infoPressed = true,
      ),
    );
    await tester.pump();

    expect(find.byType(RecipeAiReviewCard), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.info_outline));
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump();

    expect(infoPressed, isTrue);
  });

  testWidgets('calls toggle callback when AI review is available', (
    tester,
  ) async {
    bool? changedValue;
    await tester.pumpWidget(
      buildSubject(
        aiReviewAvailable: true,
        aiReviewEnabled: false,
        onAiReviewChanged: (value) => changedValue = value,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Verify recipe with AI'));
    await tester.tap(find.text('Verify recipe with AI'));
    await tester.pump();

    expect(changedValue, isTrue);
  });
}
