import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class FavoriteRecipesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.favoriterecipes),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          List<Recipe> favoriteRecipes = recipeProvider
              .getRecipes()
              .where((recipe) =>
                  recipeProvider.favoriteRecipeIds.value.contains(recipe.id))
              .toList();

          return ListView.builder(
            itemCount: favoriteRecipes.length,
            itemBuilder: (BuildContext context, int index) {
              Recipe recipe = favoriteRecipes[index];
              return ListTile(
                title: Text(recipe.name),
                onTap: () => navigateToRecipeDetail(context, recipe),
                trailing: FavoriteButton(
                  recipeId: recipe.id,
                  onToggleFavorite: (bool isFavorite) {
                    recipeProvider.toggleFavorite(recipe.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void navigateToRecipeDetail(BuildContext context, Recipe recipe) {
    if (recipe.id == "106") {
      context.router.push(RecipeDetailTKRoute(
          brewingMethodId: recipe.brewingMethodId, recipeId: recipe.id));
    } else {
      context.router.push(RecipeDetailRoute(
          brewingMethodId: recipe.brewingMethodId, recipeId: recipe.id));
    }
  }
}
