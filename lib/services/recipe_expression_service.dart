import 'package:coffee_timer/l10n/app_localizations.dart';
import '../models/brew_step_model.dart';

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
    final RegExp excludeRegex = RegExp(
        r'\b\d+\s*(?:-|to)\s*\d+\s*times\b|\b\d+\s*times\b|\b\d+\s*(?:seconds?|minutes?|mins?)\b');
    if (excludeRegex.hasMatch(description)) {
      List<String> parts = [];
      int lastEnd = 0;
      for (var match in excludeRegex.allMatches(description)) {
        if (match.start > lastEnd) {
          parts.add(_processTextPart(
              description.substring(lastEnd, match.start),
              coffeeAmount,
              waterAmount,
              l10n));
        }
        parts.add(description.substring(match.start, match.end));
        lastEnd = match.end;
      }
      if (lastEnd < description.length) {
        parts.add(_processTextPart(
            description.substring(lastEnd), coffeeAmount, waterAmount, l10n));
      }
      return parts.join('');
    } else {
      return _processTextPart(description, coffeeAmount, waterAmount, l10n);
    }
  }

  static String _processTextPart(String text, double coffeeAmount,
      double waterAmount, AppLocalizations l10n) {
    final String unitsPattern = [
      l10n.unitGramsShort,
      l10n.unitMillilitersShort,
      l10n.unitGramsLong,
      l10n.unitMillilitersLong,
    ].map((unit) => RegExp.escape(unit)).join('|');

    // Regex to find numbers with optional units.
    // Group 1: The number (e.g., "100", "20.5")
    // Group 2: Optional - The unit if present (e.g., "g", "ml")
    final RegExp numberCatchRegex =
        RegExp(r'\b(\d+(?:\.\d+)?)\s*(' + unitsPattern + r')?\b');

    // Regex for contexts where numbers should NOT be converted to expressions.
    final RegExp excludeContextRegex = RegExp(
        r'\b\d+\s*(?:-|to)\s*\d+\s*times\b|\b\d+\s*times\b|\b\d+\s*(?:seconds?|minutes?|mins?)\b',
        caseSensitive: false);

    StringBuffer resultBuffer = StringBuffer();
    int currentIndex = 0;

    // Find all potential number matches in the text.
    List<Match> allNumberMatches = numberCatchRegex.allMatches(text).toList();
    // Find all exclusion zone matches.
    List<Match> allExclusionMatches =
        excludeContextRegex.allMatches(text).toList();

    for (Match numberMatch in allNumberMatches) {
      // Append text before this potential number match.
      resultBuffer.write(text.substring(currentIndex, numberMatch.start));

      String fullMatchText = numberMatch.group(0)!; // e.g., "100g" or "250"
      String numStr = numberMatch.group(1)!; // e.g., "100" or "250"
      String unit = numberMatch.group(2) ?? ''; // e.g., "g" or ""

      // Check if this numberMatch falls within any exclusion zone.
      bool isExcluded = false;
      for (Match excludeMatch in allExclusionMatches) {
        if (numberMatch.start >= excludeMatch.start &&
            numberMatch.end <= excludeMatch.end) {
          isExcluded = true;
          break;
        }
      }

      if (isExcluded) {
        resultBuffer.write(fullMatchText); // Append as is if excluded.
      } else {
        double value = double.tryParse(numStr) ?? 0;
        // Apply conversion conditions from original logic.
        bool shouldConvert = true;
        if (value < 0.1) {
          shouldConvert = false;
        } else if (unit.isEmpty && value < 10) {
          // This condition was from the old largeNumberRegex logic,
          // applied to numbers without explicit units.
          shouldConvert = false;
        }

        if (shouldConvert) {
          final multiplierInfo =
              getCleanestMultiplier(value, coffeeAmount, waterAmount);
          final String placeholder = multiplierInfo['type'] == 'coffee'
              ? '<final_coffee_amount>'
              : '<final_water_amount>';
          resultBuffer
              .write('(${multiplierInfo['formatted']} x $placeholder)$unit');
        } else {
          resultBuffer.write(fullMatchText); // Append as is if not converted.
        }
      }
      currentIndex = numberMatch.end;
    }

    // Append any remaining text after the last number match.
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
