import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeExpressionService', () {
    const coffeeAmount = 15.0;
    const waterAmount = 250.0;

    test('converts and renders water ranges', () {
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare filter',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'brew',
            order: 2,
            description: 'Pour 60-90g water',
            time: const Duration(seconds: 30),
          ),
        ],
        coffeeAmount,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.last.description,
        'Pour (0.24 x <final_water_amount>)-'
        '(0.36 x <final_water_amount>)g water',
      );
      expect(
        RecipeExpressionService.renderDescription(
          processed.steps.last.description,
          coffeeAmount: coffeeAmount,
          waterAmount: waterAmount,
          compact: true,
        ),
        'Pour 60-90g water',
      );
    });

    test('converts comma decimals with coffee context', () {
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Use 15,5g coffee',
            time: Duration.zero,
          ),
        ],
        15.5,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.single.description,
        'Use (1 x <final_coffee_amount>)g coffee',
      );
    });

    test('converts Arabic digits and localized water unit', () {
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare filter',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'brew',
            order: 2,
            description: 'اسكب ٦٠ مل ماء',
            time: const Duration(seconds: 30),
          ),
        ],
        coffeeAmount,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.last.description,
        'اسكب (0.24 x <final_water_amount>)مل ماء',
      );
    });

    test('keeps rate wording non-scalable', () {
      final converted =
          RecipeExpressionService.convertNumericValuesToExpressions(
            'Pour at 5g/s until the bed is covered',
            coffeeAmount,
            waterAmount,
          );

      expect(converted, 'Pour at 5g/s until the bed is covered');
    });

    test('does not double-convert existing expressions', () {
      final converted =
          RecipeExpressionService.convertNumericValuesToExpressions(
            'Pour (0.24 x <final_water_amount>)g water',
            coffeeAmount,
            waterAmount,
          );

      expect(converted, 'Pour (0.24 x <final_water_amount>)g water');
    });

    test('blocks unsupported standalone placeholders', () {
      final issues = RecipeExpressionService.validateTemplate(
        'Pour <final_water_amount>g water',
      );

      expect(
        issues.any((issue) => issue.code == 'invalid_scalable_expression'),
        isTrue,
      );
    });

    test('blocks legacy placeholders in saved expressions', () {
      final issues = RecipeExpressionService.validateTemplate(
        'Pour (0.24 x <water_amount>)g water',
      );

      expect(
        issues.any((issue) => issue.code == 'invalid_scalable_expression'),
        isTrue,
      );
    });

    test('resolves mixed context by nearest keyword', () {
      // "water" is 6 chars before the amount, "coffee" 16 chars — water wins.
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Mix coffee and water with 30g',
            time: Duration.zero,
          ),
        ],
        coffeeAmount,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.single.description,
        'Mix coffee and water with (0.12 x <final_water_amount>)g',
      );
    });

    test('assigns coffee dose between water and coffee wording to coffee', () {
      // Regression: "water. Then add 15g coffee" used to be blocking-ambiguous
      // and would have scaled the dose with the water amount.
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare filter',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'brew',
            order: 2,
            description:
                'Switch Closed Pour 50ml of 75ºC water. Then add 15g coffee. '
                'Saturate the coffee and allow to sit for 90 seconds.',
            time: const Duration(seconds: 90),
          ),
        ],
        coffeeAmount,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.last.description,
        'Switch Closed Pour (0.2 x <final_water_amount>)ml of 75ºC water. '
        'Then add (1 x <final_coffee_amount>)g coffee. '
        'Saturate the coffee and allow to sit for 90 seconds.',
      );
    });

    test('leaves exactly equidistant amounts unconverted and reports them',
        () {
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare filter',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'brew',
            order: 2,
            description: 'Add coffee 30g water',
            time: const Duration(seconds: 30),
          ),
        ],
        coffeeAmount,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isTrue);
      final issue = processed.issues
          .singleWhere((issue) => issue.code == 'ambiguous_amount');
      expect(issue.amount, '30g');
      // The amount stays a plain number so "save as is" keeps it fixed.
      expect(processed.steps.last.description, 'Add coffee 30g water');
    });

    test('converts gr unit', () {
      final converted =
          RecipeExpressionService.convertNumericValuesToExpressions(
            'Pour 100gr of water',
            coffeeAmount,
            waterAmount,
          );

      expect(converted, 'Pour (0.4 x <final_water_amount>)gr of water');
    });

    test('recognizes Romanian water wording', () {
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare filter',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'brew',
            order: 2,
            description: 'Torni 100g de apă peste cafeaua măcinată.',
            time: const Duration(seconds: 30),
          ),
        ],
        coffeeAmount,
        waterAmount,
      );

      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.last.description,
        'Torni (0.4 x <final_water_amount>)g de apă peste cafeaua măcinată.',
      );
    });
  });
}
