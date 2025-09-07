import 'package:coffee_timer/models/recipe_model.dart';

class RecipeSummary {
  final String id;
  final String name;
  final String summary;

  RecipeSummary({
    required this.id,
    required this.name,
    required this.summary,
  });

  factory RecipeSummary.fromRecipe(
    RecipeModel recipe, {
    double? currentCoffeeAmount,
    double? currentWaterAmount,
  }) {
    String summary = "";
    int cumulativeTime = 0; // total seconds

    final double coffee = currentCoffeeAmount ?? recipe.coffeeAmount;
    final double water = currentWaterAmount ?? recipe.waterAmount;

    String replacePlaceholders(
        String description, double coffeeAmount, double waterAmount) {
      RegExp exp = RegExp(
          r'\((\d+(?:\.\d+)?)\s*(?:x|×)\s*<(final_coffee_amount|final_water_amount|coffee_amount|water_amount)>\s*\)(\w*)');
      String replacedText = description.replaceAllMapped(exp, (match) {
        double multiplier = double.parse(match.group(1)!);
        String variableName = match.group(2)!;
        String unit = match.group(3) ?? '';
        double baseAmount;

        if (variableName == 'final_coffee_amount' ||
            variableName == 'coffee_amount') {
          baseAmount = coffeeAmount;
        } else {
          // final_water_amount or water_amount
          baseAmount = waterAmount;
        }
        double result = multiplier * baseAmount;
        return '${result.toStringAsFixed(1)}$unit'; // Append the unit
      });

      // These standalone replacements handle placeholders not within complex expressions.
      replacedText = replacedText
          .replaceAll('<coffee_amount>', coffeeAmount.toStringAsFixed(1))
          .replaceAll('<water_amount>', waterAmount.toStringAsFixed(1))
          .replaceAll('<final_coffee_amount>', coffeeAmount.toStringAsFixed(1))
          .replaceAll('<final_water_amount>', waterAmount.toStringAsFixed(1));

      return replacedText;
    }

    for (final step in recipe.steps) {
      // Skip step if time is a placeholder or zero
      if (step.time is String || (step.time as Duration).inSeconds == 0) {
        continue;
      }

      // Replace placeholders in step description
      String stepDescription = replacePlaceholders(
        step.description,
        coffee,
        water,
      );

      // Add step description and time to summary
      summary += '${formatTime(cumulativeTime)} $stepDescription\n';
      cumulativeTime +=
          (step.time as Duration).inSeconds; // Add seconds, casting to Duration
    }

    return RecipeSummary(
      id: recipe.id,
      name: recipe.name,
      summary: summary,
    );
  }
}

String formatTime(int seconds) {
  final mins = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$mins:${remainingSeconds.toString().padLeft(2, '0')}';
}
