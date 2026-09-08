import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/models/recipe_summary.dart';
import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

/// Collapsible recipe summary section.
///
/// The always-visible header row shows the localized summary label, a compact
/// clock with the recipe's total brew time, and the disclosure chevron; the
/// duration stays visible in both states. The whole header is tappable.
///
/// Expanded, the summary is rendered straight from [RecipeModel.steps] with
/// the controller's current amounts — the untimed preparation as its own
/// paragraph, then one row per timed step with a fixed timestamp column and
/// the full instruction. This mirrors [RecipeSummary.fromRecipe] without
/// parsing its plain string: the first zero-time step is the preparation,
/// later zero-time steps are placeholders that are skipped, and the
/// cumulative timestamp only advances across timed steps.
class RecipeSummaryTile extends StatelessWidget {
  final RecipeModel recipe;
  final RecipeDetailController controller;

  const RecipeSummaryTile({
    super.key,
    required this.recipe,
    required this.controller,
  });

  /// Same MM:SS formatting the standalone Brew Time row used, so the header's
  /// duration semantics are unchanged.
  static String _formatBrewTime(Duration brewTime) =>
      '${brewTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${brewTime.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final durationStyle = AppTextStyles.caption.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtle divider grouping the summary after the settings rows above.
        Divider(color: colorScheme.outlineVariant),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ExpansionTile(
              // The section owns its divider in both expansion states.
              shape: const Border(),
              collapsedShape: const Border(),
              // Align the header and expanded body with the other left-aligned
              // content on the recipe detail screen — ExpansionTile otherwise
              // insets them by an extra 16px.
              tilePadding: EdgeInsets.zero,
              expandedAlignment: Alignment.centerLeft,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              title: Row(
                children: [
                  Expanded(child: Text(loc.recipesummary)),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.schedule,
                    size: AppIconSize.small,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_formatBrewTime(recipe.brewTime), style: durationStyle),
                ],
              ),
              children: _buildExpandedSummary(context, loc),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildExpandedSummary(
    BuildContext context,
    AppLocalizations loc,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = <Widget>[];
    final timedRows = <Widget>[];
    // Fixed timestamp column so instructions align; scales with the user's
    // text size so the widest timestamps never clip.
    final double timestampWidth = MediaQuery.textScalerOf(
      context,
    ).scale(AppSpacing.xxl);
    final instructionStyle = AppTextStyles.body;
    final timestampStyle = AppTextStyles.body.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    String? preparation;
    var cumulativeSeconds = 0;

    for (var i = 0; i < recipe.steps.length; i++) {
      final step = recipe.steps[i];
      final instruction = RecipeExpressionService.renderDescription(
        step.description,
        coffeeAmount: controller.currentCoffeeAmount,
        waterAmount: controller.currentWaterAmount,
      ).trim();

      // The first zero-time step is the untimed preparation paragraph.
      if (i == 0 && step.time.inSeconds == 0) {
        if (instruction.isNotEmpty) preparation = instruction;
        continue;
      }
      // Later zero-time steps are placeholders, not real instructions.
      if (step.time.inSeconds == 0) continue;

      timedRows.add(
        Padding(
          padding: EdgeInsets.only(top: timedRows.isEmpty ? 0 : AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timestampWidth,
                child: Text(
                  formatTime(cumulativeSeconds),
                  style: timestampStyle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(instruction, style: instructionStyle)),
            ],
          ),
        ),
      );
      cumulativeSeconds += step.time.inSeconds;
    }

    if (preparation != null) {
      children.addAll([
        Text(
          loc.preparation,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(preparation, style: instructionStyle),
      ]);
    }
    if (timedRows.isNotEmpty) {
      children
        ..add(const SizedBox(height: AppSpacing.base))
        ..addAll(timedRows);
    }
    return children;
  }
}
