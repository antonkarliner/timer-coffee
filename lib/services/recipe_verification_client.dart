import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brew_step_model.dart';
import '../models/recipe_model.dart';

class RecipeVerificationResult {
  final List<BrewStepModel> steps;
  final List<String> issues;
  final String? providerUsed;
  final String? providerModelUsed;

  const RecipeVerificationResult({
    required this.steps,
    required this.issues,
    this.providerUsed,
    this.providerModelUsed,
  });
}

class RecipeVerificationClient {
  final SupabaseClient supabase;

  const RecipeVerificationClient(this.supabase);

  Future<RecipeVerificationResult> verifyRecipe({
    required RecipeModel recipe,
    required String appLocale,
    String? sourceLanguageHint,
    required bool consentToDiagnostics,
  }) async {
    final response = await supabase.functions.invoke(
      'verify-user-recipe-draft',
      body: {
        'app_locale': appLocale,
        'source_language_hint': sourceLanguageHint,
        'consent_to_diagnostics': consentToDiagnostics,
        'recipe': {
          'name': recipe.name,
          'brewing_method_id': recipe.brewingMethodId,
          'coffee_amount': recipe.coffeeAmount,
          'water_amount': recipe.waterAmount,
          'water_temp': recipe.waterTemp,
          'brew_time_seconds': recipe.brewTime.inSeconds,
          'grind_size': recipe.grindSize,
          'short_description': recipe.shortDescription,
        },
        'steps': recipe.steps
            .map(
              (step) => {
                'order': step.order,
                'kind': step.order == 1 ? 'preparation' : 'brew',
                'description': step.description,
                'duration_seconds': step.time.inSeconds,
              },
            )
            .toList(),
      },
    );

    if (response.status != 200 || response.data is! Map<String, dynamic>) {
      throw Exception(
        'Recipe verification failed with status ${response.status}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final correctedSteps = data['corrected_steps'];
    final issues =
        (data['issues'] as List<dynamic>?)
            ?.map((issue) => issue.toString())
            .toList() ??
        const <String>[];

    if (correctedSteps is! List) {
      return RecipeVerificationResult(
        steps: recipe.steps,
        issues: issues,
        providerUsed: data['provider_used'] as String?,
        providerModelUsed: data['provider_model_used'] as String?,
      );
    }

    final nextSteps = <BrewStepModel>[];
    for (var index = 0; index < recipe.steps.length; index++) {
      final original = recipe.steps[index];
      final correction =
          index < correctedSteps.length && correctedSteps[index] is Map
          ? Map<String, dynamic>.from(correctedSteps[index] as Map)
          : const <String, dynamic>{};
      final description =
          correction['description_template'] as String? ??
          correction['description'] as String? ??
          original.description;
      final seconds = correction['duration_seconds'] is num
          ? (correction['duration_seconds'] as num).round()
          : original.time.inSeconds;
      nextSteps.add(
        original.copyWith(
          description: description,
          time: Duration(seconds: seconds),
        ),
      );
    }

    return RecipeVerificationResult(
      steps: nextSteps,
      issues: issues,
      providerUsed: data['provider_used'] as String?,
      providerModelUsed: data['provider_model_used'] as String?,
    );
  }
}
