import 'package:coffee_timer/models/recipe.dart';

class RecipeSummary {
  final String id;
  final String name;
  final String summary;

  RecipeSummary({
    required this.id,
    required this.name,
    required this.summary,
  });

  factory RecipeSummary.fromRecipe(Recipe recipe) {
    String summary = "";
    int cumulativeTime = 0; // total seconds

    String replacePlaceholders(String description, double coffeeAmount, double waterAmount) {
      RegExp exp = RegExp(
          r'\(([\d.]+) x <(coffee_amount|water_amount|final_coffee_amount|final_water_amount)>\)');
      String replacedText = description.replaceAllMapped(exp, (match) {
        double multiplier = double.parse(match.group(1)!);
        String variable = match.group(2)!;
        double result;

        if (variable == 'coffee_amount' || variable == 'final_coffee_amount') {
          result = multiplier * coffeeAmount;
        } else {
          result = multiplier * waterAmount;
        }

        return result.toStringAsFixed(1);
      });

      replacedText = replacedText
          .replaceAll('<coffee_amount>', coffeeAmount.toStringAsFixed(1))
          .replaceAll('<water_amount>', waterAmount.toStringAsFixed(1))
          .replaceAll('<final_coffee_amount>', coffeeAmount.toStringAsFixed(1))
          .replaceAll('<final_water_amount>', waterAmount.toStringAsFixed(1));

      return replacedText;
    }

    for (final step in recipe.steps) {
      // Check if the step time is 0, if so, continue to the next iteration
      if (step.time.inSeconds.toInt() == 0) {
        continue;
      }

      // Replace placeholders in step description
      String stepDescription = replacePlaceholders(
        step.description,
        recipe.coffeeAmount,
        recipe.waterAmount,
      );

      // Add step description and time to summary
      summary += '${formatTime(cumulativeTime)} $stepDescription\n';
      cumulativeTime += step.time.inSeconds.toInt(); // add seconds
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
