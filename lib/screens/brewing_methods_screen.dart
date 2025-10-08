import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../models/brewing_method_model.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe_model.dart';
import '../app_router.gr.dart';
import '../utils/icon_utils.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

@RoutePage()
class BrewingMethodsScreen extends StatelessWidget {
  const BrewingMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final allBrewingMethods = Provider.of<List<BrewingMethodModel>>(context);
    final l10n = AppLocalizations.of(context)!; // Get localizations

    // Determine which brewing methods have recipes
    final methodsWithRecipes = <String>{};
    for (var recipe in recipeProvider.recipes) {
      methodsWithRecipes.add(recipe.brewingMethodId);
    }

    // Get user preferences
    final shownIds = recipeProvider.shownBrewingMethodIds.value;
    final hiddenIds = recipeProvider.hiddenBrewingMethodIds.value;

    final filteredBrewingMethods = allBrewingMethods.where((method) {
      bool hasRecipes = methodsWithRecipes.contains(method.brewingMethodId);
      bool isShownByUser = shownIds.contains(method.brewingMethodId);
      bool isHiddenByUser = hiddenIds.contains(method.brewingMethodId);

      if (isShownByUser) return true;
      if (isHiddenByUser) return false;
      return hasRecipes;
    }).toList();

    // Calculate the bottom padding
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

    return SafeArea(
      child: Column(
        children: [
          buildFixedContent(context, recipeProvider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Divider(
              color:
                  Theme.of(context).dividerColor.withAlpha((255 * 0.3).round()),
              thickness: 0.7,
              height: 0,
              indent: 16.0,
              endIndent: 16.0,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBrewingMethods.length,
              itemBuilder: (BuildContext context, int index) {
                final brewingMethod = filteredBrewingMethods[index];
                return Semantics(
                  identifier: 'brewingMethod_${brewingMethod.brewingMethodId}',
                  label: brewingMethod.brewingMethod,
                  child: ListTile(
                    leading:
                        getIconByBrewingMethod(brewingMethod.brewingMethodId),
                    title: Text(brewingMethod.brewingMethod,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      context.router.push(RecipeListRoute(
                          brewingMethodId: brewingMethod.brewingMethodId));
                    },
                  ),
                );
              },
              // Add padding to the bottom of the ListView
              padding: EdgeInsets.only(bottom: bottomPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFixedContent(
      BuildContext context, RecipeProvider recipeProvider) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return FutureBuilder<RecipeModel?>(
      future: recipeProvider.getLastUsedRecipe(),
      builder: (context, snapshot) {
        RecipeModel? mostRecentRecipe = snapshot.data;
        return Column(
          children: [
            Semantics(
              identifier: 'favoriteRecipes',
              label: l10n.favoriterecipes,
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(l10n.favoriterecipes),
                onTap: () {
                  context.router.push(const FavoriteRecipesRoute());
                },
              ),
            ),
            Semantics(
              identifier: 'createRecipe',
              label: l10n.createRecipe,
              child: ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.createRecipe),
                onTap: () {
                  context.router.push(RecipeCreationRoute());
                },
              ),
            ),
            if (mostRecentRecipe != null)
              Semantics(
                identifier: 'lastRecipe_${mostRecentRecipe.id}',
                label: '${l10n.lastrecipe}${mostRecentRecipe.name}',
                child: ListTile(
                  leading:
                      getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                  title: Text('${l10n.lastrecipe} ${mostRecentRecipe.name}'),
                  onTap: () {
                    context.router.push(
                      RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
