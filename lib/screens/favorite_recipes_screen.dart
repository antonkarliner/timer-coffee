import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.favoriterecipes),
          ],
        ),
      ),
      body: FutureBuilder<List<RecipeModel>>(
        future: Provider.of<RecipeProvider>(context, listen: false)
            .fetchFavoriteRecipes(Localizations.localeOf(context).toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading favorites"));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noFavoriteRecipesMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
            );
          } else {
            List<RecipeModel> favoriteRecipes = snapshot.data!;
            return ListView.builder(
              itemCount: favoriteRecipes.length,
              itemBuilder: (BuildContext context, int index) {
                RecipeModel recipe = favoriteRecipes[index];
                return ListTile(
                  leading: getIconByBrewingMethod(recipe.brewingMethodId),
                  title: Text(recipe.name),
                  onTap: () {
                    context.router.push(RecipeDetailRoute(
                        brewingMethodId: recipe.brewingMethodId,
                        recipeId: recipe.id));
                  },
                  trailing: FavoriteButton(recipeId: recipe.id),
                );
              },
            );
          }
        },
      ),
    );
  }
}
