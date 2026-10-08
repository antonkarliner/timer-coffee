import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/services/recipe_ai_review_diff.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeExpressionProcessingResult _processing(List<String> templates) {
  final steps = <BrewStepModel>[];
  final stepResults = <RecipeExpressionStepResult>[];
  for (var i = 0; i < templates.length; i++) {
    final original = BrewStepModel(
      id: 's$i',
      order: i + 1,
      description: 'raw $i',
      time: const Duration(seconds: 30),
    );
    final step = original.copyWith(description: templates[i]);
    steps.add(step);
    stepResults.add(
      RecipeExpressionStepResult(
        originalStep: original,
        step: step,
        previewDescription: '',
        issues: const [],
      ),
    );
  }
  return RecipeExpressionProcessingResult(
    steps: steps,
    stepResults: stepResults,
  );
}

void main() {
  const coffeeAmount = 15.0;
  const waterAmount = 250.0;

  group('RecipeAiReviewDiff', () {
    test('identical templates produce no changes', () {
      final local = _processing([
        'Pour (0.24 x <final_water_amount>)g water',
        'Add (1 x <final_coffee_amount>)g coffee',
      ]);
      final reviewed = _processing([
        'Pour (0.24 x <final_water_amount>)g water',
        'Add (1 x <final_coffee_amount>)g coffee',
      ]);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      expect(diff.hasChanges, isFalse);
      expect(diff.changes, isEmpty);
      expect(diff.changedStepCount, 0);
    });

    test('representation-only difference is not a change', () {
      // Coffee-based vs water-based multiplier — both render 15g at the
      // recipe amounts and 30g at 2×, so they are interchangeable.
      final local = _processing(['Add (1 x <final_coffee_amount>)g coffee']);
      final reviewed = _processing([
        'Add (0.06 x <final_water_amount>)g coffee',
      ]);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      expect(diff.hasChanges, isFalse);
    });

    test('literal amount made scalable counts as a change', () {
      // Ambiguous amounts are left literal by local processing; if the AI
      // made one scalable, the difference only shows at 2× (250 stays 250,
      // the scalable one doubles to 500).
      final local = _processing(['Rinse with 250ml water']);
      final reviewed = _processing([
        'Rinse with (1 x <final_water_amount>)ml water',
      ]);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      expect(diff.hasChanges, isTrue);
      expect(diff.changedStepCount, 1);
      expect(diff.changes.single.index, 0);
      expect(diff.changes.single.localTemplate, 'Rinse with 250ml water');
      expect(
        diff.changes.single.reviewedTemplate,
        'Rinse with (1 x <final_water_amount>)ml water',
      );
    });

    test('changed wording counts as a change', () {
      final local = _processing(['Pour water slowly']);
      final reviewed = _processing(['Pour filtered water slowly']);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      expect(diff.hasChanges, isTrue);
      expect(diff.changes.single.step.order, 1);
    });

    test('multiple steps: exactly the changed indices are reported', () {
      final local = _processing([
        'Grind (1 x <final_coffee_amount>)g coffee',
        'Pour (0.24 x <final_water_amount>)g water',
        'Wait 30 seconds',
        '250ml fixed amount here',
      ]);
      final reviewed = _processing([
        'Grind (1 x <final_coffee_amount>)g coffee',
        'Pour (0.24 x <final_water_amount>)g water in circles',
        'Wait 45 seconds',
        '(1 x <final_water_amount>)ml scalable here',
      ]);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      expect(diff.changedStepCount, 3);
      expect(diff.changes.map((change) => change.index).toList(), [1, 2, 3]);
    });

    test('processingFor returns the reviewed result for applied', () {
      final local = _processing(['a']);
      final reviewed = _processing(['b']);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      expect(
        identical(diff.processingFor(RecipeAiReviewDecision.applied), reviewed),
        isTrue,
      );
      expect(
        identical(diff.processingFor(RecipeAiReviewDecision.kept), local),
        isTrue,
      );
    });

    test('mismatched step counts are guarded by the shorter list', () {
      final local = _processing(['a', 'b', 'c']);
      final reviewed = _processing(['x']);

      final diff = RecipeAiReviewDiff.compute(
        local: local,
        reviewed: reviewed,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );

      // No crash; only the aligned index range is compared.
      expect(diff.changedStepCount, 1);
      expect(diff.changes.single.index, 0);
    });
  });
}
