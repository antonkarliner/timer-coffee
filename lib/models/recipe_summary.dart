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

    for (final step in recipe.steps) {
      // Check if the step time is 0, if so, continue to the next iteration
      if (step.time.inSeconds.toInt() == 0) {
        continue;
      }

      // Replace placeholders in step description
      String stepDescription = step.description
          .replaceAll('<final_coffee_amount>', recipe.coffeeAmount.toString())
          .replaceAll('<final_water_amount>', recipe.waterAmount.toString());
    
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
