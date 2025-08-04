import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_summary.dart';
import 'package:coffee_timer/models/recipe_model.dart';

class RecipeSummaryTile extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeSummaryTile({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(AppLocalizations.of(context)!.recipesummary),
      subtitle: Text(AppLocalizations.of(context)!.recipesummarynote),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(RecipeSummary.fromRecipe(recipe).summary),
        ),
      ],
    );
  }
}
