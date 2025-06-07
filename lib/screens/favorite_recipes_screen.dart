// lib/screens/favorite_recipes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../utils/icon_utils.dart';

@RoutePage()
class FavoriteRecipesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'favoriteRecipesBackButton',
          child: const BackButton(),
        ),
        title: Semantics(
          identifier: 'favoriteRecipesTitle',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.favoriterecipes),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<RecipeModel>>(
        future: Provider.of<RecipeProvider>(context, listen: false)
            .fetchFavoriteRecipes(Localizations.localeOf(context).toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Semantics(
              identifier: 'favoriteRecipesLoadingIndicator',
              child: const Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Semantics(
              identifier: 'favoriteRecipesError',
              child: Center(child: Text("Error loading favorites")),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Semantics(
              identifier: 'noFavoriteRecipesMessage',
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noFavoriteRecipesMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              ),
            );
          } else {
            List<RecipeModel> favoriteRecipes = snapshot.data!;
            return Semantics(
              identifier: 'favoriteRecipesList',
              child: ListView.builder(
                itemCount: favoriteRecipes.length,
                itemBuilder: (BuildContext context, int index) {
                  RecipeModel recipe = favoriteRecipes[index];
                  return Semantics(
                    identifier: 'favoriteRecipeTile_$index',
                    child: ListTile(
                      leading: Semantics(
                        identifier:
                            'favoriteRecipeIcon_${recipe.brewingMethodId}',
                        child: getIconByBrewingMethod(recipe.brewingMethodId),
                      ),
                      title: Semantics(
                        identifier: 'favoriteRecipeName_${recipe.id}',
                        child: Text(recipe.name),
                      ),
                      onTap: () {
                        context.router.push(RecipeDetailRoute(
                          brewingMethodId: recipe.brewingMethodId,
                          recipeId: recipe.id,
                        ));
                      },
                      trailing: Semantics(
                        identifier: 'favoriteRecipeButton_${recipe.id}',
                        child: FavoriteButton(recipeId: recipe.id),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
