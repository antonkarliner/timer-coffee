import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brew_step_model.dart';
import '../models/recipe_model.dart';

/// One structured backend issue ({code, field, message}).
///
/// The edge function reports issues in English; nothing here is user-facing
/// copy — the app maps known [code]s to localized strings.
class RecipeVerificationIssue {
  final String code;
  final String field;
  final String message;

  const RecipeVerificationIssue({
    required this.code,
    this.field = '',
    this.message = '',
  });

  /// Tolerant parser: accepts maps with a `code`, or plain strings (the
  /// string becomes the code). Malformed or empty entries return null.
  static RecipeVerificationIssue? tryParse(Object? raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final code = map['code']?.toString();
      if (code == null || code.isEmpty) return null;
      return RecipeVerificationIssue(
        code: code,
        field: map['field']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
      );
    }
    if (raw is String && raw.isNotEmpty) {
      return RecipeVerificationIssue(code: raw, message: raw);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RecipeVerificationIssue &&
      other.code == code &&
      other.field == field &&
      other.message == message;

  @override
  int get hashCode => Object.hash(code, field, message);
}

class RecipeVerificationResult {
  final List<BrewStepModel> steps;

  /// Every backend issue, stringified — kept for compatibility with the
  /// original client shape.
  final List<String> issues;

  /// Structured issues, when the backend sent them as objects. May contain
  /// the string-form issues as code-only entries.
  final List<RecipeVerificationIssue> issueDetails;

  /// English free-text parser commentary. Not user-facing.
  final List<String> warnings;
  final String? providerUsed;
  final String? providerModelUsed;

  const RecipeVerificationResult({
    required this.steps,
    required this.issues,
    this.issueDetails = const [],
    this.warnings = const [],
    this.providerUsed,
    this.providerModelUsed,
  });

  /// Pure response parsing so it can be unit-tested without Supabase.
  factory RecipeVerificationResult.fromResponseData(
    RecipeModel recipe,
    Map<String, dynamic> data,
  ) {
    final correctedSteps = data['corrected_steps'];
    final rawIssues = data['issues'];
    final issues = rawIssues is List
        ? rawIssues.map((issue) => issue.toString()).toList()
        : const <String>[];
    final issueDetails = rawIssues is List
        ? rawIssues
              .map(RecipeVerificationIssue.tryParse)
              .whereType<RecipeVerificationIssue>()
              .toList()
        : const <RecipeVerificationIssue>[];
    final warnings = data['warnings'] is List
        ? (data['warnings'] as List).map((warning) => warning.toString()).toList()
        : const <String>[];

    if (correctedSteps is! List) {
      return RecipeVerificationResult(
        steps: recipe.steps,
        issues: issues,
        issueDetails: issueDetails,
        warnings: warnings,
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
      issueDetails: issueDetails,
      warnings: warnings,
      providerUsed: data['provider_used'] as String?,
      providerModelUsed: data['provider_model_used'] as String?,
    );
  }
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

    return RecipeVerificationResult.fromResponseData(
      recipe,
      response.data as Map<String, dynamic>,
    );
  }
}
