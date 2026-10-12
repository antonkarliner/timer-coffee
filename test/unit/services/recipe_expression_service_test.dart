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
  group('amount conversion explanations', () {
    List<RecipeAmountResolution> explain(
      String text, {
      RecipeStepKind kind = RecipeStepKind.preparation,
      double coffee = 15,
      double water = 250,
    }) => RecipeExpressionService.explainStepConversion(
      text,
      kind: kind,
      coffeeAmount: coffee,
      waterAmount: water,
    );

    final examples = <(String, RecipeStepKind, RecipeAmountResolutionReason)>[
      (
        'Add 30g coffee',
        RecipeStepKind.preparation,
        RecipeAmountResolutionReason.coffeeKeyword,
      ),
      (
        'Pour 100ml water',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.waterKeyword,
      ),
      (
        'coffee 30g water',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.keywordTie,
      ),
      // "Pour" is itself a water keyword; "Add" exercises the no-keyword path.
      (
        'Add 60g',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.brewDefaultWater,
      ),
      (
        'Weigh 30g',
        RecipeStepKind.preparation,
        RecipeAmountResolutionReason.preparationCleanScoreCoffee,
      ),
      (
        'Weigh 500ml',
        RecipeStepKind.preparation,
        RecipeAmountResolutionReason.preparationCleanScoreWater,
      ),
      (
        'Weigh 20g',
        RecipeStepKind.preparation,
        RecipeAmountResolutionReason.preparationAmbiguous,
      ),
      (
        'Add (1 x 15g)',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.skippedInsideExpression,
      ),
      (
        'Add <15g >',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.skippedInsidePlaceholder,
      ),
      (
        'Add 5 g/s',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.skippedRateContext,
      ),
      (
        'Add 0.05 g',
        RecipeStepKind.brew,
        RecipeAmountResolutionReason.skippedBelowMinimum,
      ),
    ];
    for (final example in examples) {
      test('reports ${example.$3.name}', () {
        final amount = explain(example.$1, kind: example.$2).single;
        expect(amount.reason, example.$3);
        expect(amount.isRange, isFalse);
        expect(amount.offsetsInRangeSubstitutedText, isFalse);
      });
    }

    test('exact water total takes precedence over coffee wording', () {
      for (final text in ['Pour 250 ml over the coffee', 'Add 250 ml coffee']) {
        final amount = explain(text, kind: RecipeStepKind.brew).single;
        expect(amount.placeholder, RecipeExpressionService.finalWaterAmount);
        expect(amount.reason, RecipeAmountResolutionReason.exactTotalWater);
      }
    });

    test('exact coffee total takes precedence over water wording', () {
      final amount = explain('Add 15 g to the water').single;
      expect(amount.placeholder, RecipeExpressionService.finalCoffeeAmount);
      expect(amount.reason, RecipeAmountResolutionReason.exactTotalCoffee);
    });

    test('equal recipe totals fall through to keyword resolution', () {
      final amount = explain('Add 100g coffee', coffee: 100, water: 100).single;
      expect(amount.placeholder, RecipeExpressionService.finalCoffeeAmount);
      expect(amount.reason, RecipeAmountResolutionReason.coffeeKeyword);
    });

    test('non-total amounts retain keyword resolution', () {
      final amount = explain('Add 60g water', kind: RecipeStepKind.brew).single;
      expect(amount.placeholder, RecipeExpressionService.finalWaterAmount);
      expect(amount.reason, RecipeAmountResolutionReason.waterKeyword);
    });

    test('recognizes ASCII units followed by CJK text', () {
      for (final example in [('お湯を50g注ぐ', 50.0), ('注水至100ml后', 100.0)]) {
        final amount = explain(example.$1, kind: RecipeStepKind.brew).single;
        expect(amount.value, example.$2);
        expect(amount.placeholder, RecipeExpressionService.finalWaterAmount);
        expect(amount.reason, RecipeAmountResolutionReason.waterKeyword);
      }
    });

    test('does not recognize units inside ASCII words or glued CJK units', () {
      // CJK unit words followed by CJK text remain a known detection gap.
      for (final text in ['2 grinds', '100克水']) {
        expect(explain(text, kind: RecipeStepKind.brew), isEmpty);
      }
    });

    test('recognizes ranges with ASCII units followed by CJK text', () {
      final amount = explain('40-60g注ぐ', kind: RecipeStepKind.brew).single;
      expect(amount.isRange, isTrue);
      expect(amount.value, 60);
      expect(amount.unit, 'g');
      expect(amount.placeholder, RecipeExpressionService.finalWaterAmount);
      expect(amount.reason, RecipeAmountResolutionReason.brewDefaultWater);
    });

    test('saves exact totals using their recipe total despite keywords', () {
      final processed = RecipeExpressionService.processStepsForSavingDetailed(
        [
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Add 15 g to the water',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'brew',
            order: 2,
            description: 'Add 250 ml coffee',
            time: Duration.zero,
          ),
        ],
        15,
        250,
      );
      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.first.description,
        'Add (1 x <final_coffee_amount>)g to the water',
      );
      expect(
        processed.steps.last.description,
        'Add (1 x <final_water_amount>)ml coffee',
      );
    });

    test('saves ASCII units glued to CJK text as scalable templates', () {
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
            description: 'お湯を50g注ぐ',
            time: Duration.zero,
          ),
        ],
        15,
        250,
      );
      expect(processed.hasBlockingIssues, isFalse);
      expect(
        processed.steps.last.description,
        'お湯を(0.2 x <final_water_amount>)g注ぐ',
      );
    });

    test('reports missing selected base without a final placeholder', () {
      for (final base in [0.0, -1.0]) {
        final amount = explain('Add 15g coffee', coffee: base).single;
        expect(amount.reason, RecipeAmountResolutionReason.skippedNoBaseAmount);
        expect(amount.placeholder, isNull);
      }
    });

    test('Pour wording uses the water keyword', () {
      expect(
        explain('Pour 60g', kind: RecipeStepKind.brew).single.reason,
        RecipeAmountResolutionReason.waterKeyword,
      );
    });

    test('ranges use original offsets and upper bound', () {
      final amount = explain('60-90g water', kind: RecipeStepKind.brew).single;
      expect(amount.isRange, isTrue);
      expect(amount.value, 90);
      expect(amount.start, 0);
      expect(amount.end, 6);
      expect(amount.offsetsInRangeSubstitutedText, isFalse);
      expect(amount.placeholder, RecipeExpressionService.finalWaterAmount);
    });

    test('single offsets refer to range-substituted text when flagged', () {
      const text = '60-90g water; add 15g coffee';
      final amounts = explain(text, kind: RecipeStepKind.brew);
      const intermediate =
          '(0.24 x <final_water_amount>)-'
          '(0.36 x <final_water_amount>)g water; add 15g coffee';
      expect(amounts.length, 2);
      expect(amounts.first.start, 0);
      expect(amounts.last.offsetsInRangeSubstitutedText, isTrue);
      expect(amounts.last.start, intermediate.indexOf('15g'));
      expect(amounts.last.end, intermediate.indexOf('15g') + 3);
    });

    test('reports both passes when a literal range is revisited', () {
      final amounts = explain('coffee 60-90g water', kind: RecipeStepKind.brew);
      expect(amounts.length, 2);
      expect(amounts.first.isRange, isTrue);
      expect(amounts.first.reason, RecipeAmountResolutionReason.keywordTie);
      expect(amounts.first.placeholder, isNull);
      expect(amounts.last.isRange, isFalse);
      expect(amounts.last.reason, RecipeAmountResolutionReason.waterKeyword);
      expect(amounts.last.placeholder, RecipeExpressionService.finalWaterAmount);
    });

    test('returns an immutable collection and localized numeric values', () {
      for (final text in ['Add ٦٠ مل ماء', 'Add ۶۰ گرم آب']) {
        final amounts = explain(text, kind: RecipeStepKind.brew);
        expect(amounts.single.value, 60);
        expect(
          amounts.single.reason,
          RecipeAmountResolutionReason.waterKeyword,
        );
        expect(() => amounts.clear(), throwsUnsupportedError);
      }
    });

    test('mixed amounts agree with the saved expressions', () {
      const text = 'Add 15g coffee. Add 60g water. Add 5 g/s.';
      final amounts = explain(text, kind: RecipeStepKind.brew);
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
            description: text,
            time: Duration.zero,
          ),
        ],
        15,
        250,
      );
      final placeholders = RegExp(r'x <([^>]+)>')
          .allMatches(processed.steps.last.description)
          .map((match) => match.group(1))
          .toList();
      expect(
        amounts
            .where((a) => a.placeholder != null)
            .map((a) => a.placeholder)
            .toList(),
        placeholders,
      );
      expect(amounts.last.placeholder, isNull);
    });

    test('source order survives interleaved ranges and single amounts', () {
      final amounts = explain(
        'Add 15g coffee. Add 60-90g water. Add 250ml water.',
        kind: RecipeStepKind.brew,
      );
      expect(amounts.map((a) => a.value).toList(), [15, 90, 250]);
      expect(amounts.map((a) => a.offsetsInRangeSubstitutedText).toList(), [
        true,
        false,
        true,
      ]);
    });
  });
  group('original description trace offsets', () {
    for (final text in [
      'Pour 60-90g water; add 15g coffee',
      'Add ۶۰ گرم آب',
      'coffee 60-90g water',
    ]) {
      test('maps original UTF-16 spans: $text', () {
        final amounts = RecipeExpressionService.explainStepConversion(
          text,
          kind: RecipeStepKind.brew,
          coffeeAmount: 15,
          waterAmount: 250,
        );
        final expected = text.startsWith('Pour')
            ? ['60-90g', '15g']
            : text.startsWith('Add')
            ? ['۶۰ گرم']
            : ['60-90g', '90g'];
        expect(
          amounts.map((a) => text.substring(a.originalStart, a.originalEnd)),
          expected,
        );
        final before =
            RecipeExpressionService.convertNumericValuesToExpressions(
              text,
              15,
              250,
            );
        RecipeExpressionService.explainStepConversion(
          text,
          kind: RecipeStepKind.brew,
          coffeeAmount: 15,
          waterAmount: 250,
        );
        expect(
          RecipeExpressionService.convertNumericValuesToExpressions(
            text,
            15,
            250,
          ),
          before,
        );
      });
    }
  });
}
