import '../models/brew_step_model.dart';
import 'recipe_expression_service.dart';

/// What the user chose to do with the AI review's changes.
enum RecipeAiReviewDecision { applied, kept }

/// One step whose locally processed template and AI-reviewed template
/// actually render differently.
class RecipeAiReviewStepChange {
  /// Index of the step in the recipe's step list.
  final int index;

  /// The step as it will be saved when the change is applied (the reviewed
  /// version — the local version carries the same id/order).
  final BrewStepModel step;

  /// Locally processed template of the user's original text.
  final String localTemplate;

  /// Locally processed template of the AI-corrected text.
  final String reviewedTemplate;

  const RecipeAiReviewStepChange({
    required this.index,
    required this.step,
    required this.localTemplate,
    required this.reviewedTemplate,
  });
}

/// Diff between locally processing the user's steps and locally processing
/// the AI-corrected steps.
///
/// The user's choice ("keep my version" vs "apply changes") selects which of
/// those two processing results gets saved, so the diff is computed between
/// the two *processed* results — not between raw text and templates, which
/// would flag every amount the local converter already makes scalable.
///
/// A step counts as changed only when its two templates render differently at
/// the recipe's current amounts OR at 2× (coffee×2 and water×2). Templates
/// that differ only in representation (e.g. a coffee-based vs water-based
/// multiplier yielding the same numbers) are NOT changes.
class RecipeAiReviewDiff {
  /// Locally processed result for the user's original steps.
  final RecipeExpressionProcessingResult local;

  /// Locally processed result for the AI-corrected steps.
  final RecipeExpressionProcessingResult reviewed;

  final List<RecipeAiReviewStepChange> changes;

  const RecipeAiReviewDiff({
    required this.local,
    required this.reviewed,
    required this.changes,
  });

  static RecipeAiReviewDiff compute({
    required RecipeExpressionProcessingResult local,
    required RecipeExpressionProcessingResult reviewed,
    required double coffeeAmount,
    required double waterAmount,
  }) {
    final changes = <RecipeAiReviewStepChange>[];
    final stepCount = local.steps.length < reviewed.steps.length
        ? local.steps.length
        : reviewed.steps.length;

    for (var index = 0; index < stepCount; index++) {
      final localTemplate = local.steps[index].description;
      final reviewedTemplate = reviewed.steps[index].description;
      if (localTemplate == reviewedTemplate) continue;
      if (!_rendersDifferently(
        localTemplate,
        reviewedTemplate,
        coffeeAmount,
        waterAmount,
      )) {
        continue;
      }
      changes.add(
        RecipeAiReviewStepChange(
          index: index,
          step: reviewed.steps[index],
          localTemplate: localTemplate,
          reviewedTemplate: reviewedTemplate,
        ),
      );
    }

    return RecipeAiReviewDiff(
      local: local,
      reviewed: reviewed,
      changes: changes,
    );
  }

  static bool _rendersDifferently(
    String localTemplate,
    String reviewedTemplate,
    double coffeeAmount,
    double waterAmount,
  ) {
    bool differsAt(double coffee, double water) =>
        RecipeExpressionService.renderDescription(
          localTemplate,
          coffeeAmount: coffee,
          waterAmount: water,
          compact: true,
        ) !=
        RecipeExpressionService.renderDescription(
          reviewedTemplate,
          coffeeAmount: coffee,
          waterAmount: water,
          compact: true,
        );

    // Equal at the current amounts AND at 2× means the two templates are
    // interchangeable for the user — a representation-only difference.
    return differsAt(coffeeAmount, waterAmount) ||
        differsAt(coffeeAmount * 2, waterAmount * 2);
  }

  bool get hasChanges => changes.isNotEmpty;

  int get changedStepCount => changes.length;

  /// Which processing result to save for the user's decision:
  /// [RecipeAiReviewDecision.applied] saves the AI-reviewed steps,
  /// [RecipeAiReviewDecision.kept] saves the locally processed originals.
  RecipeExpressionProcessingResult processingFor(
    RecipeAiReviewDecision decision,
  ) => decision == RecipeAiReviewDecision.applied ? reviewed : local;
}
