import '../models/brew_step_model.dart';
import '../models/recipe_model.dart';
import '../services/recipe_expression_service.dart';

String replacePlaceholders(
  String description,
  double coffeeAmount,
  double waterAmount,
  int? sweetnessSliderPosition,
  int? strengthSliderPosition,
  int? coffeeChroniclerSliderPosition,
) {
  return RecipeExpressionService.renderDescription(
    _replaceLegacyPlaceholders(
      description,
      sweetnessSliderPosition,
      strengthSliderPosition,
      coffeeChroniclerSliderPosition,
    ),
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
  );
}

String _replaceLegacyPlaceholders(
  String description,
  int? sweetnessSliderPosition,
  int? strengthSliderPosition,
  int? coffeeChroniclerSliderPosition,
) {
  final allValues = <String, double>{};

  if (sweetnessSliderPosition != null) {
    final sweetnessValues = [
      {"m1": 0.16, "m2": 0.24},
      {"m1": 0.20, "m2": 0.20},
      {"m1": 0.24, "m2": 0.16},
    ];
    allValues.addAll(sweetnessValues[sweetnessSliderPosition]);
  }

  if (strengthSliderPosition != null) {
    final strengthValues = [
      {"m3": 0.6, "m4": 0.0, "m5": 0.0},
      {"m3": 0.3, "m4": 0.3, "m5": 0.0},
      {"m3": 0.2, "m4": 0.2, "m5": 0.2},
    ];
    allValues.addAll(strengthValues[strengthSliderPosition]);
  }

  if (coffeeChroniclerSliderPosition != null) {
    final coffeeChroniclerValues = [
      {'t7': 30.0, 't8': 55.0},
      {'t7': 45.0, 't8': 70.0},
      {'t7': 75.0, 't8': 55.0},
    ];
    allValues.addAll(coffeeChroniclerValues[coffeeChroniclerSliderPosition]);
  }

  return description.replaceAllMapped(RegExp(r'<([\w_]+)>'), (match) {
    final variable = match.group(1)!.toLowerCase();
    return allValues.containsKey(variable)
        ? allValues[variable]!.toStringAsFixed(2)
        : match.group(0)!;
  });
}

Duration replaceTimePlaceholder(
  Duration time,
  int? sweetnessSliderPosition,
  int? strengthSliderPosition,
  int? coffeeChroniclerSliderPosition,
) {
  // If the time is already set, return it
  if (time != Duration.zero) {
    return time;
  }

  // Prepare all possible time values
  Map<String, int> allTimeValues = {};

  // Handle sweetness time values if applicable
  if (sweetnessSliderPosition != null) {
    List<Map<String, int>> sweetnessTimeValues = [
      {"t1": 10, "t2": 35}, // Sweetness
      {"t1": 10, "t2": 35}, // Balance
      {"t1": 10, "t2": 35}, // Acidity
    ];
    allTimeValues.addAll(sweetnessTimeValues[sweetnessSliderPosition]);
  }

  // Handle strength time values if applicable
  if (strengthSliderPosition != null) {
    List<Map<String, int>> strengthTimeValues = [
      {"t3": 0, "t4": 0, "t5": 0, "t6": 0}, // Light
      {"t3": 10, "t4": 35, "t5": 0, "t6": 0}, // Balanced
      {"t3": 10, "t4": 35, "t5": 10, "t6": 35}, // Strong
    ];
    allTimeValues.addAll(strengthTimeValues[strengthSliderPosition]);
  }

  // Handle coffeeChroniclerSwitchSlider time values if applicable
  if (coffeeChroniclerSliderPosition != null) {
    List<Map<String, int>> coffeeChroniclerTimeValues = [
      {'t7': 30, 't8': 55}, // Standard
      {'t7': 45, 't8': 70}, // Medium
      {'t7': 75, 't8': 55}, // XL
    ];
    allTimeValues.addAll(
      coffeeChroniclerTimeValues[coffeeChroniclerSliderPosition],
    );
  }

  // Replace time placeholders
  RegExp exp = RegExp(r'<(t\d+)>');
  String timeString = time.inSeconds.toString();
  var matches = exp.allMatches(timeString);

  for (var match in matches) {
    String placeholder = match.group(1)!;
    int? replacementTime = allTimeValues[placeholder];

    if (replacementTime != null && replacementTime > 0) {
      time = Duration(seconds: replacementTime);
    }
  }

  return time;
}

/// The recipe's first timed step (and the timed step after it), resolved
/// with the same placeholder replacement the preparation list uses —
/// BrewingProcessScreen filters to steps with positive time, and layout
/// previews must show what this user is about to brew with. Empty instruction
/// and 0 seconds when the recipe has no timed step, so a preview never crashes
/// on such a recipe.
({String instruction, String? nextInstruction, int stepSeconds})
layoutPreviewStepsFor(RecipeModel recipe) {
  final timedSteps = recipe.steps
      .map(
        (step) => BrewStepModel(
          id: step.id,
          order: step.order,
          description: replacePlaceholders(
            step.description,
            recipe.coffeeAmount,
            recipe.waterAmount,
            recipe.sweetnessSliderPosition,
            recipe.strengthSliderPosition,
            recipe.coffeeChroniclerSliderPosition,
          ),
          time: replaceTimePlaceholder(
            step.time,
            recipe.sweetnessSliderPosition,
            recipe.strengthSliderPosition,
            recipe.coffeeChroniclerSliderPosition,
          ),
        ),
      )
      .where((step) => step.time.inSeconds > 0)
      .toList();

  return (
    instruction: timedSteps.isNotEmpty ? timedSteps.first.description : '',
    nextInstruction: timedSteps.length > 1 ? timedSteps[1].description : null,
    stepSeconds: timedSteps.isNotEmpty ? timedSteps.first.time.inSeconds : 0,
  );
}
