import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/services/recipe_verification_client.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeModel _recipe(List<String> descriptions) {
  return RecipeModel(
    id: 'r1',
    name: 'V60',
    brewingMethodId: 'v60',
    coffeeAmount: 15,
    waterAmount: 250,
    waterTemp: 93,
    grindSize: 'Medium',
    brewTime: const Duration(minutes: 3),
    shortDescription: '',
    steps: [
      for (var i = 0; i < descriptions.length; i++)
        BrewStepModel(
          id: 's$i',
          order: i + 1,
          description: descriptions[i],
          time: const Duration(seconds: 30),
        ),
    ],
  );
}

void main() {
  group('RecipeVerificationResult.fromResponseData', () {
    test('applies description_template corrections', () {
      final recipe = _recipe(['Pour 60g', 'Wait 30s']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {
            'description_template':
                'Pour (0.24 x <final_water_amount>)g water',
            'duration_seconds': 30,
          },
          {'description_template': 'Wait (1 x <final_water_amount>)s'},
        ],
        'issues': [],
      });

      expect(result.steps[0].description,
          'Pour (0.24 x <final_water_amount>)g water');
      expect(result.steps[1].description,
          'Wait (1 x <final_water_amount>)s');
      expect(result.issues, isEmpty);
      expect(result.issueDetails, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('falls back to description when no template is sent', () {
      final recipe = _recipe(['Pour 60g']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {'description': 'Pour 60 g of water'},
        ],
      });

      expect(result.steps.single.description, 'Pour 60 g of water');
    });

    test('missing corrected_steps keeps the original steps', () {
      final recipe = _recipe(['Pour 60g', 'Wait 30s']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'issues': [],
        'warnings': ['parser said something'],
      });

      expect(result.steps.map((step) => step.description), ['Pour 60g', 'Wait 30s']);
      expect(result.warnings, ['parser said something']);
    });

    test('short corrected_steps keeps the trailing original steps', () {
      final recipe = _recipe(['Pour 60g', 'Wait 30s']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {'description_template': 'Pour 60 g'},
        ],
      });

      expect(result.steps[0].description, 'Pour 60 g');
      expect(result.steps[1].description, 'Wait 30s');
    });

    test('parses issues sent as maps into details and legacy strings', () {
      final recipe = _recipe(['Pour 60g']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {'description_template': 'Pour 60g'},
        ],
        'issues': [
          {
            'code': 'unverifiable_amount',
            'field': 'description',
            'message': 'Could not verify the amount.',
          },
          {'code': 'total_brew_time_mismatch'},
        ],
      });

      expect(result.issues.length, 2);
      expect(result.issueDetails.length, 2);
      expect(result.issueDetails[0].code, 'unverifiable_amount');
      expect(result.issueDetails[0].field, 'description');
      expect(result.issueDetails[0].message, 'Could not verify the amount.');
      expect(result.issueDetails[1].code, 'total_brew_time_mismatch');
      expect(result.issueDetails[1].field, isEmpty);
    });

    test('tolerates string and malformed issues', () {
      final recipe = _recipe(['Pour 60g']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {'description_template': 'Pour 60g'},
        ],
        'issues': ['plain string issue', 42, {'no_code': true}, null],
      });

      expect(result.issues.length, 4);
      // The plain string becomes a code-only detail; malformed entries are
      // skipped without throwing.
      expect(result.issueDetails.length, 1);
      expect(result.issueDetails.single.code, 'plain string issue');
    });

    test('parses warnings and provider metadata', () {
      final recipe = _recipe(['Pour 60g']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {'description_template': 'Pour 60g'},
        ],
        'issues': [],
        'warnings': ['step 2 amount treated as water', 'range collapsed'],
        'provider_used': 'openai',
        'provider_model_used': 'gpt-x',
      });

      expect(result.warnings, [
        'step 2 amount treated as water',
        'range collapsed',
      ]);
      expect(result.providerUsed, 'openai');
      expect(result.providerModelUsed, 'gpt-x');
    });

    test('duration_seconds overrides are applied', () {
      final recipe = _recipe(['Pour 60g']);
      final result = RecipeVerificationResult.fromResponseData(recipe, {
        'corrected_steps': [
          {'description_template': 'Pour 60g', 'duration_seconds': 45.0},
        ],
      });

      expect(result.steps.single.time, const Duration(seconds: 45));
    });
  });
}
