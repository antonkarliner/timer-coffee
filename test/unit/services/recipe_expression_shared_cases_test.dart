import 'dart:convert';
import 'dart:io';

import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Read the canonical file directly so the app and its byte-for-byte mirror
  // exercise the same authored expectations, without generated test data.
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/recipe_expression_shared_cases.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final conversions = (fixture['convert'] as List).cast<Map<String, dynamic>>();
  final renders = (fixture['render'] as List).cast<Map<String, dynamic>>();

  test('shared fixture version and unique case IDs', () {
    expect(fixture['version'], 1);
    expect(conversions, isNotEmpty);
    expect(renders, isNotEmpty);
    final ids = [...conversions, ...renders].map((example) => example['id']);
    expect(ids.every((id) => id is String && id.isNotEmpty), isTrue);
    expect(ids.toSet().length, ids.length);
  });

  group('shared conversion cases', () {
    for (final example in conversions) {
      test(example['id'] as String, () {
        final kind = RecipeStepKind.values.byName(example['kind'] as String);
        final text = example['text'] as String;
        final coffee = (example['coffee'] as num).toDouble();
        final water = (example['water'] as num).toDouble();
        final trace = RecipeExpressionService.explainStepConversion(
          text,
          kind: kind,
          coffeeAmount: coffee,
          waterAmount: water,
        );
        expect(trace.map((amount) => amount.reason.name), example['reasons']);

        // Saving determines kind by index, so brew cases need an empty prep.
        final steps = <BrewStepModel>[
          if (kind == RecipeStepKind.brew)
            BrewStepModel(
              id: 'empty-preparation',
              order: 1,
              description: '',
              time: Duration.zero,
            ),
          BrewStepModel(
            id: example['id'] as String,
            order: kind == RecipeStepKind.preparation ? 1 : 2,
            description: text,
            time: Duration.zero,
          ),
        ];
        final result = RecipeExpressionService.processStepsForSavingDetailed(
          steps,
          coffee,
          water,
        ).stepResults.last;
        expect(result.step.description, example['template']);
        expect(result.issues.map((issue) => issue.code), example['issues']);
      });
    }
  });

  group('shared rendering cases', () {
    for (final example in renders) {
      test(example['id'] as String, () {
        for (final compact in [true, false]) {
          expect(
            RecipeExpressionService.renderDescription(
              example['template'] as String,
              coffeeAmount: (example['coffee'] as num).toDouble(),
              waterAmount: (example['water'] as num).toDouble(),
              compact: compact,
            ),
            example[compact ? 'compact' : 'full'],
            reason: compact ? 'compact rendering' : 'full rendering',
          );
        }
      });
    }
  });
}
