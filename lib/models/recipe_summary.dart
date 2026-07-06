import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';

class RecipeSummary {
  final String id;
  final String name;
  final String summary;

  RecipeSummary({required this.id, required this.name, required this.summary});

  factory RecipeSummary.fromRecipe(
    RecipeModel recipe, {
    double? currentCoffeeAmount,
    double? currentWaterAmount,
  }) {
    String summary = "";
    int cumulativeTime = 0; // total seconds

    final double coffee = currentCoffeeAmount ?? recipe.coffeeAmount;
    final double water = currentWaterAmount ?? recipe.waterAmount;
    final hasTimedSteps = recipe.steps
        .skip(1)
        .any((step) => step.time.inSeconds > 0);

    for (int i = 0; i < recipe.steps.length; i++) {
      final step = recipe.steps[i];

      // The first step is the preparation step — it carries no time. Render it
      // as a plain leading line (no timestamp, no label), and only when it has
      // real text so a blank prep step doesn't add an empty line.
      if (i == 0 && step.time.inSeconds == 0) {
        final prep = RecipeExpressionService.renderDescription(
          step.description,
          coffeeAmount: coffee,
          waterAmount: water,
        ).trim();
        if (prep.isNotEmpty) {
          summary += hasTimedSteps ? '$prep\n\n' : '$prep\n';
        }
        continue;
      }

      // Skip any remaining placeholder/zero-time steps.
      if (step.time.inSeconds == 0) {
        continue;
      }

      // Replace placeholders in step description
      String stepDescription = RecipeExpressionService.renderDescription(
        step.description,
        coffeeAmount: coffee,
        waterAmount: water,
      );

      // Add step description and time to summary
      summary += '${formatTime(cumulativeTime)} $stepDescription\n';
      cumulativeTime += step.time.inSeconds;
    }

    return RecipeSummary(id: recipe.id, name: recipe.name, summary: summary);
  }
}

String formatTime(int seconds) {
  final mins = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$mins:${remainingSeconds.toString().padLeft(2, '0')}';
}
