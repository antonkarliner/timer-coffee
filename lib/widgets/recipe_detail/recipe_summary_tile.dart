import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_summary.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

class RecipeSummaryTile extends StatelessWidget {
  final RecipeModel recipe;
  final RecipeDetailController controller;

  const RecipeSummaryTile({
    super.key,
    required this.recipe,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ExpansionTile(
          // Align the header and expanded body with the other left-aligned
          // content on the recipe detail screen — ExpansionTile otherwise
          // insets them by an extra 16px.
          tilePadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          title: Text(AppLocalizations.of(context)!.recipesummary),
          children: [
            Text(
              RecipeSummary.fromRecipe(
                recipe,
                currentCoffeeAmount: controller.currentCoffeeAmount,
                currentWaterAmount: controller.currentWaterAmount,
              ).summary,
            ),
          ],
        );
      },
    );
  }
}
