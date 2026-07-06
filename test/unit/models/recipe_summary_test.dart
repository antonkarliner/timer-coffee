import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/models/recipe_summary.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Every recipe's first step is the preparation step: order 1 with no time.
  // Build one followed by timed brew steps, mirroring the real data shape.
  RecipeModel recipeWith({
    required String prepDescription,
    List<BrewStepModel> timedSteps = const [],
    double coffeeAmount = 18.0,
    double waterAmount = 300.0,
  }) {
    return RecipeModel(
      id: 'test-recipe',
      name: 'Test Recipe',
      brewingMethodId: 'hario_v60',
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      grindSize: 'medium-fine',
      brewTime: const Duration(minutes: 3),
      shortDescription: 'A test recipe',
      steps: [
        BrewStepModel(
          id: 'prep',
          order: 1,
          description: prepDescription,
          time: Duration.zero,
        ),
        ...timedSteps,
      ],
    );
  }

  BrewStepModel timed(int order, int seconds, String description) =>
      BrewStepModel(
        id: 'step-$order',
        order: order,
        description: description,
        time: Duration(seconds: seconds),
      );

  group('RecipeSummary.fromRecipe preparation step', () {
    test('built-in prep instructions render as a label-less leading line', () {
      final recipe = recipeWith(
        prepDescription: 'Rinse the filter and discard the water.',
        timedSteps: [
          timed(2, 30, 'Add 50g of water and let it bloom.'),
          timed(3, 60, 'Pour up to 200g.'),
        ],
      );

      // Prep comes first with no timestamp; timed steps keep their cumulative
      // times (the timeless prep step does not advance the clock).
      expect(
        RecipeSummary.fromRecipe(recipe).summary,
        'Rinse the filter and discard the water.\n\n'
        '0:00 Add 50g of water and let it bloom.\n'
        '0:30 Pour up to 200g.\n',
      );
    });

    test(
      'default "Preparation" word is still shown — only blank is hidden',
      () {
        final recipe = recipeWith(
          prepDescription: 'Preparation',
          timedSteps: [timed(2, 30, 'Add 50g of water and let it bloom.')],
        );

        expect(
          RecipeSummary.fromRecipe(recipe).summary,
          'Preparation\n\n'
          '0:00 Add 50g of water and let it bloom.\n',
        );
      },
    );

    test('prep-only summaries do not end with an extra blank line', () {
      final recipe = recipeWith(prepDescription: 'Preparation');

      expect(RecipeSummary.fromRecipe(recipe).summary, 'Preparation\n');
    });

    test('blank prep description is omitted entirely', () {
      final recipe = recipeWith(
        prepDescription: '   ',
        timedSteps: [
          timed(2, 30, 'Add 50g of water and let it bloom.'),
          timed(3, 60, 'Pour up to 200g.'),
        ],
      );

      // No leading prep line — the summary starts at the first timed step.
      expect(
        RecipeSummary.fromRecipe(recipe).summary,
        '0:00 Add 50g of water and let it bloom.\n'
        '0:30 Pour up to 200g.\n',
      );
    });

    test('placeholders in the prep line are resolved against the amounts', () {
      final recipe = recipeWith(
        prepDescription: 'Grind <coffee_amount>g of coffee.',
        coffeeAmount: 18.0,
        timedSteps: [timed(2, 30, 'Bloom.')],
      );

      final summary = RecipeSummary.fromRecipe(recipe).summary;
      final renderedAmount = RecipeExpressionService.renderDescription(
        '<coffee_amount>',
        coffeeAmount: 18.0,
        waterAmount: 300.0,
      );

      expect(summary, contains('Grind ${renderedAmount}g of coffee.'));
      expect(summary, isNot(contains('<coffee_amount>')));
    });
  });
}
