import '../constants/scalable_units.dart';
import '../models/brew_step_model.dart';

enum RecipeStepKind { preparation, brew }

class RecipeExpressionIssue {
  final String code;
  final String message;
  final bool isBlocking;

  const RecipeExpressionIssue({
    required this.code,
    required this.message,
    this.isBlocking = true,
  });
}

class RecipeExpressionStepResult {
  final BrewStepModel originalStep;
  final BrewStepModel step;
  final String previewDescription;
  final List<RecipeExpressionIssue> issues;

  const RecipeExpressionStepResult({
    required this.originalStep,
    required this.step,
    required this.previewDescription,
    required this.issues,
  });

  bool get changed => originalStep.description != step.description;
  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);
}

class RecipeExpressionProcessingResult {
  final List<BrewStepModel> steps;
  final List<RecipeExpressionStepResult> stepResults;

  const RecipeExpressionProcessingResult({
    required this.steps,
    required this.stepResults,
  });

  List<RecipeExpressionIssue> get issues =>
      stepResults.expand((result) => result.issues).toList();

  bool get hasBlockingIssues =>
      stepResults.any((result) => result.hasBlockingIssues);

  bool get hasChanges => stepResults.any((result) => result.changed);
}

class _ConversionResult {
  final String description;
  final List<RecipeExpressionIssue> issues;

  const _ConversionResult({required this.description, required this.issues});
}

class _ResolvedPlaceholder {
  final String placeholder;
  final RecipeExpressionIssue? issue;

  const _ResolvedPlaceholder({required this.placeholder, this.issue});
}

class RecipeExpressionService {
  static const String finalCoffeeAmount = 'final_coffee_amount';
  static const String finalWaterAmount = 'final_water_amount';
  static const String coffeeAmount = 'coffee_amount';
  static const String waterAmount = 'water_amount';

  static final List<String> _unitsByLength = scalableUnits.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static final String _unitPattern = _unitsByLength
      .map(RegExp.escape)
      .join('|');

  static const String _numberPattern = r'[0-9٠-٩۰-۹]+(?:[\.,][0-9٠-٩۰-۹]+)?';

  static final RegExp _amountRangeRegex = RegExp(
    '($_numberPattern)\\s*[-–—]\\s*($_numberPattern)\\s*($_unitPattern)'
    r'(?=$|[\s,.;:!?\)\]/])',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _amountRegex = RegExp(
    '($_numberPattern)\\s*($_unitPattern)'
    r'(?=$|[\s,.;:!?\)\]/-])',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _expressionRegex = RegExp(
    r'\(\s*([0-9]+(?:\.[0-9]+)?)\s*(?:x|×)\s*<'
    r'(final_coffee_amount|final_water_amount|coffee_amount|water_amount)'
    r'>\s*\)([^\s<>().,;:!?\-–—]*)',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _canonicalExpressionRegex = RegExp(
    r'\(\s*([0-9]+(?:\.[0-9]+)?)\s*(?:x|×)\s*<'
    r'(final_coffee_amount|final_water_amount)'
    r'>\s*\)([^\s<>().,;:!?\-–—]*)',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _placeholderRegex = RegExp(r'<([^>]+)>');
  static final RegExp _knownPlaceholderRegex = RegExp(
    r'<(final_coffee_amount|final_water_amount|coffee_amount|water_amount)>',
    caseSensitive: false,
  );
  static final RegExp _danglingMultiplierRegex = RegExp(
    r'(?:^|[(\s])[\d.]+\s*(?:x|×)\s*(?=$|[),.;:]|\s)',
    caseSensitive: false,
  );
  static final RegExp _rateContextRegex = RegExp(
    r'^\s*(?:/|per\b|each\b|every\b)',
    caseSensitive: false,
  );

  static const Set<String> _coffeeContextKeywords = {
    'coffee',
    'grounds',
    'beans',
    'dose',
    'café',
    'cafe',
    'kaffee',
    'koffie',
    'caffè',
    'caffe',
    'кофе',
    'кава',
    'قهوة',
    'قهوه',
    'kahve',
    '커피',
    'コーヒー',
    '咖啡',
    'kawa',
  };

  static const Set<String> _waterContextKeywords = {
    'water',
    'pour',
    'bloom',
    'rinse',
    'prewet',
    'pre-wet',
    'eau',
    'wasser',
    'acqua',
    'agua',
    'вода',
    'воды',
    'воду',
    'води',
    'ماء',
    'آب',
    'su',
    '물',
    'お湯',
    '水',
    '水量',
    'woda',
  };

  static Map<String, dynamic> getCleanestMultiplier(
    double value,
    double coffeeAmount,
    double waterAmount,
  ) {
    final coffeeMult = value / coffeeAmount;
    final waterMult = value / waterAmount;
    final coffeeCleanScore = calculateCleanScore(coffeeMult);
    final waterCleanScore = calculateCleanScore(waterMult);
    if (coffeeCleanScore > waterCleanScore) {
      return {
        'multiplier': coffeeMult,
        'type': 'coffee',
        'formatted': formatMultiplier(coffeeMult),
      };
    }
    return {
      'multiplier': waterMult,
      'type': 'water',
      'formatted': formatMultiplier(waterMult),
    };
  }

  static double calculateCleanScore(double number) {
    if ((number - number.round()).abs() < 0.01) {
      return 100 - (number - number.round()).abs() * 100;
    }
    const simpleRatios = [
      0.06,
      0.08,
      0.1,
      0.12,
      0.16,
      0.2,
      0.24,
      0.25,
      0.33,
      0.4,
      0.5,
      0.67,
      0.75,
      1.25,
      1.33,
      1.5,
      1.67,
      1.75,
      2.5,
      3.5,
    ];
    for (final ratio in simpleRatios) {
      if ((ratio - number).abs() < 0.01) {
        return 90 - (ratio - number).abs() * 100;
      }
    }
    final decimalPlaces = number.toString().split('.').length > 1
        ? number.toString().split('.')[1].length
        : 0;
    return 80 - (decimalPlaces * 10);
  }

  static String formatMultiplier(double multiplier) {
    if ((multiplier - multiplier.round()).abs() < 0.01) {
      return multiplier.round().toString();
    }
    return multiplier.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
  }

  static String convertExpressionsToNumericValues(
    String description,
    double coffeeAmount,
    double waterAmount,
  ) {
    return renderDescription(
      description,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      compact: true,
    );
  }

  static String convertNumericValuesToExpressions(
    String description,
    double coffeeAmount,
    double waterAmount, [
    Object? _,
  ]) {
    return _convertNumericValuesToExpressionsDetailed(
      description: description,
      kind: RecipeStepKind.brew,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
    ).description;
  }

  static String renderDescription(
    String description, {
    required double coffeeAmount,
    required double waterAmount,
    bool compact = false,
  }) {
    final withExpressions = description.replaceAllMapped(_expressionRegex, (
      match,
    ) {
      final multiplier = double.tryParse(match.group(1) ?? '');
      final variable = (match.group(2) ?? '').toLowerCase();
      final unit = match.group(3) ?? '';
      if (multiplier == null) return match.group(0)!;

      final base =
          variable == finalCoffeeAmount ||
              variable == RecipeExpressionService.coffeeAmount
          ? coffeeAmount
          : waterAmount;
      return '${_formatAmount(multiplier * base, compact: compact)}$unit';
    });

    return withExpressions
        .replaceAll(
          '<${RecipeExpressionService.coffeeAmount}>',
          _formatAmount(coffeeAmount, compact: compact),
        )
        .replaceAll(
          '<${RecipeExpressionService.waterAmount}>',
          _formatAmount(waterAmount, compact: compact),
        )
        .replaceAll(
          '<$finalCoffeeAmount>',
          _formatAmount(coffeeAmount, compact: compact),
        )
        .replaceAll(
          '<$finalWaterAmount>',
          _formatAmount(waterAmount, compact: compact),
        );
  }

  static RecipeExpressionProcessingResult processStepsForSavingDetailed(
    List<BrewStepModel> steps,
    double coffeeAmount,
    double waterAmount,
  ) {
    final stepResults = <RecipeExpressionStepResult>[];
    final processedSteps = <BrewStepModel>[];

    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      final kind = index == 0
          ? RecipeStepKind.preparation
          : RecipeStepKind.brew;
      final conversion = _convertNumericValuesToExpressionsDetailed(
        description: step.description,
        kind: kind,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );
      final issues = [
        ...conversion.issues,
        ...validateTemplate(conversion.description),
      ];
      final processedDescription = conversion.description;
      final processedStep = step.copyWith(description: processedDescription);
      processedSteps.add(processedStep);
      stepResults.add(
        RecipeExpressionStepResult(
          originalStep: step,
          step: processedStep,
          previewDescription: renderDescription(
            processedDescription,
            coffeeAmount: coffeeAmount,
            waterAmount: waterAmount,
            compact: true,
          ),
          issues: issues,
        ),
      );
    }

    return RecipeExpressionProcessingResult(
      steps: processedSteps,
      stepResults: stepResults,
    );
  }

  static List<BrewStepModel> processStepsForSaving(
    List<BrewStepModel> steps,
    double coffeeAmount,
    double waterAmount, [
    Object? _,
  ]) {
    return processStepsForSavingDetailed(
      steps,
      coffeeAmount,
      waterAmount,
    ).steps;
  }

  static List<RecipeExpressionIssue> validateTemplate(String template) {
    final issues = <RecipeExpressionIssue>[];
    final unsupportedPlaceholders = <String>[];

    for (final match in _placeholderRegex.allMatches(template)) {
      final placeholder = '<${match.group(1)}>';
      if (!_isKnownPlaceholder(placeholder)) {
        unsupportedPlaceholders.add(placeholder);
      }
    }

    if (unsupportedPlaceholders.isNotEmpty) {
      issues.add(
        RecipeExpressionIssue(
          code: 'unsupported_placeholder',
          message:
              'Unsupported placeholders: ${unsupportedPlaceholders.join(', ')}',
        ),
      );
    }

    final strippedValidExpressions = template.replaceAll(
      _canonicalExpressionRegex,
      '',
    );
    if (_knownPlaceholderRegex.hasMatch(strippedValidExpressions)) {
      issues.add(
        const RecipeExpressionIssue(
          code: 'invalid_scalable_expression',
          message:
              'Coffee and water placeholders must be inside a multiplier expression.',
        ),
      );
    }

    if (!_hasBalancedParentheses(template)) {
      issues.add(
        const RecipeExpressionIssue(
          code: 'unbalanced_parentheses',
          message: 'Step description contains unbalanced parentheses.',
        ),
      );
    }

    if (_danglingMultiplierRegex.hasMatch(strippedValidExpressions)) {
      issues.add(
        const RecipeExpressionIssue(
          code: 'invalid_scalable_expression',
          message: 'Step description contains incomplete multiplier syntax.',
        ),
      );
    }

    return issues;
  }

  static _ConversionResult _convertNumericValuesToExpressionsDetailed({
    required String description,
    required RecipeStepKind kind,
    required double coffeeAmount,
    required double waterAmount,
  }) {
    if (description.trim().isEmpty) {
      return _ConversionResult(description: description, issues: const []);
    }

    final issues = <RecipeExpressionIssue>[];

    final withRanges = description.replaceAllMapped(_amountRangeRegex, (match) {
      final start = match.start;
      final lower = _parseLocalizedNumber(match.group(1)!);
      final upper = _parseLocalizedNumber(match.group(2)!);
      final unit = match.group(3)!;
      if (lower == null || upper == null || lower < 0.1 || upper < 0.1) {
        return match.group(0)!;
      }
      if (_shouldSkipAmount(description, start, match.end)) {
        return match.group(0)!;
      }

      final resolved = _resolvePlaceholder(
        description: description,
        kind: kind,
        matchStart: start,
        matchEnd: match.end,
        value: upper,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );
      final placeholder = resolved.placeholder;
      if (resolved.issue != null) issues.add(resolved.issue!);
      final baseAmount = placeholder == finalCoffeeAmount
          ? coffeeAmount
          : waterAmount;
      if (baseAmount <= 0) return match.group(0)!;

      return '(${formatMultiplier(lower / baseAmount)} x <$placeholder>)-'
          '(${formatMultiplier(upper / baseAmount)} x <$placeholder>)'
          '${unit.trim()}';
    });

    final converted = withRanges.replaceAllMapped(_amountRegex, (match) {
      final start = match.start;
      final value = _parseLocalizedNumber(match.group(1)!);
      final unit = match.group(2)!;
      if (value == null || value < 0.1) return match.group(0)!;
      if (_shouldSkipAmount(withRanges, start, match.end)) {
        return match.group(0)!;
      }

      final resolved = _resolvePlaceholder(
        description: withRanges,
        kind: kind,
        matchStart: start,
        matchEnd: match.end,
        value: value,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
      );
      final placeholder = resolved.placeholder;
      if (resolved.issue != null) issues.add(resolved.issue!);
      final baseAmount = placeholder == finalCoffeeAmount
          ? coffeeAmount
          : waterAmount;
      if (baseAmount <= 0) return match.group(0)!;

      return '(${formatMultiplier(value / baseAmount)} x <$placeholder>)'
          '${unit.trim()}';
    });

    return _ConversionResult(description: converted, issues: issues);
  }

  static _ResolvedPlaceholder _resolvePlaceholder({
    required String description,
    required RecipeStepKind kind,
    required int matchStart,
    required int matchEnd,
    required double value,
    required double coffeeAmount,
    required double waterAmount,
  }) {
    final contextStart = matchStart - 32 < 0 ? 0 : matchStart - 32;
    final contextEnd = matchEnd + 32 > description.length
        ? description.length
        : matchEnd + 32;
    final context = description
        .substring(contextStart, contextEnd)
        .toLowerCase();

    final hasCoffeeContext = _coffeeContextKeywords.any(
      (keyword) => context.contains(keyword),
    );
    final hasWaterContext = _waterContextKeywords.any(
      (keyword) => context.contains(keyword),
    );

    if (hasCoffeeContext && !hasWaterContext) {
      return const _ResolvedPlaceholder(placeholder: finalCoffeeAmount);
    }
    if (hasWaterContext && !hasCoffeeContext) {
      return const _ResolvedPlaceholder(placeholder: finalWaterAmount);
    }
    if (hasCoffeeContext && hasWaterContext) {
      return const _ResolvedPlaceholder(
        placeholder: finalWaterAmount,
        issue: RecipeExpressionIssue(
          code: 'ambiguous_amount',
          message:
              'A step amount is close to both coffee and water wording. Clarify whether it belongs to coffee or water.',
        ),
      );
    }
    if (kind == RecipeStepKind.brew) {
      return const _ResolvedPlaceholder(placeholder: finalWaterAmount);
    }

    final multiplier = getCleanestMultiplier(value, coffeeAmount, waterAmount);
    final coffeeScore = calculateCleanScore(value / coffeeAmount);
    final waterScore = calculateCleanScore(value / waterAmount);
    final isAmbiguous = (coffeeScore - waterScore).abs() < 5;
    return _ResolvedPlaceholder(
      placeholder: multiplier['type'] == 'coffee'
          ? finalCoffeeAmount
          : finalWaterAmount,
      issue: isAmbiguous
          ? const RecipeExpressionIssue(
              code: 'ambiguous_amount',
              message:
                  'A step amount could not be confidently assigned to coffee or water.',
            )
          : null,
    );
  }

  static bool _shouldSkipAmount(String text, int start, int end) {
    if (_isInsideExpression(text, start)) return true;
    if (_isInsidePlaceholder(text, start)) return true;

    final tail = text.substring(
      end,
      end + 16 > text.length ? text.length : end + 16,
    );
    if (_rateContextRegex.hasMatch(tail)) return true;

    return false;
  }

  static bool _isInsideExpression(String text, int index) {
    final prefix = text.substring(0, index);
    final lastOpen = prefix.lastIndexOf('(');
    final lastClose = prefix.lastIndexOf(')');
    if (lastOpen <= lastClose) return false;
    final current = prefix.substring(lastOpen + 1);
    return RegExp(
      r'(?:^|\s)[\d.]+\s*(?:x|×)\s*$',
      caseSensitive: false,
    ).hasMatch(current);
  }

  static bool _isInsidePlaceholder(String text, int index) {
    final prefix = text.substring(0, index);
    final lastOpen = prefix.lastIndexOf('<');
    final lastClose = prefix.lastIndexOf('>');
    return lastOpen > lastClose;
  }

  static bool _isKnownPlaceholder(String placeholder) {
    final normalized = placeholder.toLowerCase();
    return normalized == '<$finalCoffeeAmount>' ||
        normalized == '<$finalWaterAmount>' ||
        normalized == '<$coffeeAmount>' ||
        normalized == '<$waterAmount>';
  }

  static bool _hasBalancedParentheses(String template) {
    var depth = 0;
    for (final codeUnit in template.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      if (char == '(') {
        depth += 1;
      } else if (char == ')') {
        depth -= 1;
        if (depth < 0) return false;
      }
    }
    return depth == 0;
  }

  static double? _parseLocalizedNumber(String value) {
    final normalized = value
        .replaceAllMapped(RegExp(r'[٠-٩]'), (match) {
          return '${match.group(0)!.codeUnitAt(0) - 0x0660}';
        })
        .replaceAllMapped(RegExp(r'[۰-۹]'), (match) {
          return '${match.group(0)!.codeUnitAt(0) - 0x06F0}';
        })
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static String _formatAmount(double value, {required bool compact}) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) return rounded.round().toString();
    final digits = compact ? 1 : 2;
    return value.toStringAsFixed(digits).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
