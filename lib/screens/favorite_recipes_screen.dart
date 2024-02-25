import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/icon_utils.dart';

@RoutePage()
class FavoriteRecipesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize:
              MainAxisSize.min, // Keeps the row content tight together
          children: [
            const Icon(Icons.favorite), // The favorite icon
            const SizedBox(
                width: 8), // Space between the icon and the title text
            Text(AppLocalizations.of(context)!
                .favoriterecipes), // The title text
          ],
        ),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, child) {
          List<Recipe> favoriteRecipes = recipeProvider
              .getRecipes()
              .where((recipe) =>
                  recipeProvider.favoriteRecipeIds.value.contains(recipe.id))
              .toList();

          if (favoriteRecipes.isEmpty) {
            // Display a message when there are no favorite recipes
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noFavoriteRecipesMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: favoriteRecipes.length,
            itemBuilder: (BuildContext context, int index) {
              Recipe recipe = favoriteRecipes[index];
              return ListTile(
                leading: getIconByBrewingMethod(recipe.brewingMethodId),
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
