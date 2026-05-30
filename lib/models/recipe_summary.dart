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

    for (final step in recipe.steps) {
      // Skip step if time is a placeholder or zero
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
