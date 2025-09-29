import 'package:coffee_timer/l10n/app_localizations.dart';
import '../models/brew_step_model.dart';
import '../constants/scalable_units.dart';

class RecipeExpressionService {
  static Map<String, dynamic> getCleanestMultiplier(
      double value, double coffeeAmount, double waterAmount) {
    double coffeeMult = value / coffeeAmount;
    double waterMult = value / waterAmount;
    double coffeeCleanScore = calculateCleanScore(coffeeMult);
    double waterCleanScore = calculateCleanScore(waterMult);
    if (coffeeCleanScore > waterCleanScore) {
      return {
        'multiplier': coffeeMult,
        'type': 'coffee',
        'formatted': formatMultiplier(coffeeMult)
      };
    } else {
      return {
        'multiplier': waterMult,
        'type': 'water',
        'formatted': formatMultiplier(waterMult)
      };
    }
  }

  static double calculateCleanScore(double number) {
    if ((number - number.round()).abs() < 0.01) {
      return 100 - (number - number.round()).abs() * 100;
    }
    List<double> simpleRatios = [
      0.25,
      0.33,
      0.5,
      0.67,
      0.75,
      1.25,
      1.33,
      1.5,
      1.67,
      1.75,
      2.5,
      3.5
    ];
    for (double ratio in simpleRatios) {
      if ((ratio - number).abs() < 0.01) {
        return 90 - (ratio - number).abs() * 100;
      }
    }
    int decimalPlaces = number.toString().split('.').length > 1
        ? number.toString().split('.')[1].length
        : 0;
    return 80 - (decimalPlaces * 10);
  }

  static String formatMultiplier(double multiplier) {
    if ((multiplier - multiplier.round()).abs() < 0.01) {
      return multiplier.round().toString();
    }
    return multiplier.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  static String convertExpressionsToNumericValues(
      String description, double coffeeAmount, double waterAmount) {
    final RegExp expressionRegex = RegExp(
        r'\((\d+(?:\.\d+)?)\s*(?:x|×)\s*<final_\s*(?:coffee|water)\s*_amount\s*>\)(\w*)');
    return description.replaceAllMapped(expressionRegex, (match) {
      String multiplierStr = match.group(1)!;
      String unit = match.group(2) ?? '';
      double multiplier = double.tryParse(multiplierStr) ?? 0;
      String placeholder = match.group(0)!; // Full matched string

      double value;
      if (placeholder.contains('<final_coffee_amount>')) {
        value = multiplier * coffeeAmount;
      } else if (placeholder.contains('<final_water_amount>')) {
        value = multiplier * waterAmount;
      } else {
        // This case should ideally not be reached if the regex and placeholder names are correct.
        // Consider logging an error or handling it more gracefully if it occurs.
        value =
            multiplier * waterAmount; // Fallback to water or handle as an error
      }

      String formattedValue;
      if (value == value.roundToDouble()) {
        formattedValue = value.round().toString();
      } else {
        formattedValue =
            value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      }
      return '$formattedValue$unit';
    });
  }

  static String convertNumericValuesToExpressions(String description,
      double coffeeAmount, double waterAmount, AppLocalizations l10n) {
    return _processTextPart(description, coffeeAmount, waterAmount, l10n);
  }

  static String _processTextPart(String text, double coffeeAmount,
      double waterAmount, AppLocalizations l10n) {
    // Global set of all scalable unit variants across languages
    final String unitsPattern = scalableUnits.map(RegExp.escape).join('|');

    // Regex to find numbers followed by a scalable unit (inclusion-based)
    // Group 1: The number (e.g., "100", "20.5")
    // Group 2: The unit (required, e.g., "g", "ml")
    final RegExp numberCatchRegex = RegExp(
        r'\b(\d+(?:\.\d+)?)\s*(' + unitsPattern + r')\b',
        caseSensitive: false);

    StringBuffer resultBuffer = StringBuffer();
    int currentIndex = 0;

    for (Match numberMatch in numberCatchRegex.allMatches(text)) {
      // Append text before this number + unit match.
      resultBuffer.write(text.substring(currentIndex, numberMatch.start));

      String numStr = numberMatch.group(1)!; // e.g., "100" or "250"
      String unit = numberMatch.group(2)!; // e.g., "g" or "ml"

      double value = double.tryParse(numStr) ?? 0;

      // Only convert if value is reasonable (avoid very small numbers)
      if (value >= 0.1) {
        final multiplierInfo =
            getCleanestMultiplier(value, coffeeAmount, waterAmount);
        final String placeholder = multiplierInfo['type'] == 'coffee'
            ? '<final_coffee_amount>'
            : '<final_water_amount>';
        final String formattedMultiplier =
            multiplierInfo['formatted'] as String;
        resultBuffer.write('($formattedMultiplier x $placeholder)$unit');
      } else {
        // If value is too small, keep original
        resultBuffer.write('${numberMatch.group(0)}');
      }

      currentIndex = numberMatch.end;
    }

    // Append any remaining text after the last match.
    resultBuffer.write(text.substring(currentIndex));

    return resultBuffer.toString();
  }

  static List<BrewStepModel> processStepsForSaving(List<BrewStepModel> steps,
      double coffeeAmount, double waterAmount, AppLocalizations l10n) {
    return steps.map((step) {
      String processedDescription = convertNumericValuesToExpressions(
          step.description, coffeeAmount, waterAmount, l10n);
      return step.copyWith(description: processedDescription);
    }).toList();
  }
}
