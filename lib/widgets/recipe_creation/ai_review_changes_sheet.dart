import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../services/recipe_ai_review_diff.dart';
import '../../services/recipe_expression_service.dart';
import '../../services/recipe_verification_client.dart';
import '../../theme/design_tokens.dart';
import '../app_switch_list_tile.dart';
import '../base_buttons.dart';

/// Confirmation sheet for the AI recipe review: shows the steps the review
/// actually changed (rendered both ways) and lets the user save the reviewed
/// version or their own.
///
/// Returns [RecipeAiReviewDecision.applied] / `.kept` from the buttons, or
/// null when the sheet is dismissed (drag down, tap outside, back).
Future<RecipeAiReviewDecision?> showAiReviewChangesSheet(
  BuildContext context, {
  required RecipeAiReviewDiff diff,
  required double coffeeAmount,
  required double waterAmount,
  List<RecipeVerificationIssue> issues = const [],
}) {
  return showModalBottomSheet<RecipeAiReviewDecision>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => AiReviewChangesSheet(
      diff: diff,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      issues: issues,
    ),
  );
}

class AiReviewChangesSheet extends StatefulWidget {
  final RecipeAiReviewDiff diff;
  final double coffeeAmount;
  final double waterAmount;
  final List<RecipeVerificationIssue> issues;

  const AiReviewChangesSheet({
    super.key,
    required this.diff,
    required this.coffeeAmount,
    required this.waterAmount,
    this.issues = const [],
  });

  @override
  State<AiReviewChangesSheet> createState() => _AiReviewChangesSheetState();
}

class _AiReviewChangesSheetState extends State<AiReviewChangesSheet> {
  bool _previewScaled = false;

  /// Localized one-line notes for the amount-related backend issues the
  /// verify path can actually act on. Other codes (timing/extraction) are
  /// about fields this path does not apply, so they are ignored. Backend
  /// `message`/`warnings` text is English parser commentary and is never
  /// shown. Each note appears once, however many issues produced it.
  List<String> _localizedIssueNotes(AppLocalizations l10n) {
    final notes = <String>[];
    for (final issue in widget.issues) {
      String? note;
      switch (issue.code) {
        case 'invalid_scalable_expression':
          note = l10n.recipeCreationFormatIssueInvalidExpression;
        case 'unverifiable_amount':
        case 'amount_provenance_mismatch':
        case 'amount_step_binding_mismatch':
        case 'range_endpoint_collapsed':
          note = l10n.recipeCreationAiReviewIssueAmountUnverified;
        default:
          note = null;
      }
      if (note != null && !notes.contains(note)) {
        notes.add(note);
      }
    }
    return notes;
  }

  /// Label exactly as `_showExpressionIssuesDialog` builds it: step 1 is the
  /// always-present preparation step, visible brew steps are numbered from 2.
  String _stepLabel(AppLocalizations l10n, int order) => order == 1
      ? l10n.recipeCreationScreenPreparationStepTitle
      : l10n.recipeCreationScreenBrewStepTitle('${order - 1}');

  Widget _renderedTemplate(
    BuildContext context,
    String template,
    double coffeeAmount,
    double waterAmount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final segments = RecipeExpressionService.renderDescriptionSegments(
      template,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      compact: true,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (final segment in segments)
            if (segment.isScalable)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(
                    segment.text,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              )
            else
              TextSpan(text: segment.text, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _versionBlock(
    BuildContext context,
    String label,
    String template,
    double coffeeAmount,
    double waterAmount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _renderedTemplate(context, template, coffeeAmount, waterAmount),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final previewCoffee = _previewScaled
        ? widget.coffeeAmount * 2
        : widget.coffeeAmount;
    final previewWater = _previewScaled
        ? widget.waterAmount * 2
        : widget.waterAmount;
    final issueNotes = _localizedIssueNotes(l10n);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.recipeCreationAiReviewChangesTitle,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.recipeCreationAiReviewChangesSummary(
                    widget.diff.changedStepCount,
                  ),
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.recipeCreationAiReviewChangesScaleHint,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    identifier: 'ai_review_preview_2x',
                    container: true,
                    child: AppSwitchListTile(
                      title: l10n.recipeCreationAiReviewPreviewScaled,
                      value: _previewScaled,
                      onChanged: (value) =>
                          setState(() => _previewScaled = value),
                    ),
                  ),
                  for (final note in issueNotes) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppIconSize.small,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            note,
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < widget.diff.changes.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: AppStroke.border,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _stepLabel(
                              l10n,
                              widget.diff.changes[i].step.order,
                            ),
                            style: AppTextStyles.itemTitle,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _versionBlock(
                            context,
                            l10n.recipeCreationAiReviewYourVersion,
                            widget.diff.changes[i].localTemplate,
                            previewCoffee,
                            previewWater,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _versionBlock(
                            context,
                            l10n.recipeCreationAiReviewReviewedVersion,
                            widget.diff.changes[i].reviewedTemplate,
                            previewCoffee,
                            previewWater,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      identifier: 'ai_review_keep',
                      button: true,
                      container: true,
                      child: AppTextButton(
                        label: l10n.recipeCreationAiReviewKeepMine,
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(RecipeAiReviewDecision.kept),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Semantics(
                      identifier: 'ai_review_apply',
                      button: true,
                      container: true,
                      child: AppElevatedButton(
                        label: l10n.recipeCreationAiReviewApply,
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(RecipeAiReviewDecision.applied),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
