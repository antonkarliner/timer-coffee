import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import '../widgets/favorite_button.dart';
import '../utils/icon_utils.dart';
import '../providers/user_recipe_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added import

@RoutePage()
class RecipeListScreen extends StatefulWidget {
  final String? brewingMethodId;

  const RecipeListScreen({
    Key? key,
    @PathParam('brewingMethodId') this.brewingMethodId,
  }) : super(key: key);

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  bool _isEditMode = false;

  Future<void> _deleteRecipe(RecipeModel recipe) async {
    try {
      await Provider.of<UserRecipeProvider>(context, listen: false)
          .deleteUserRecipe(recipe.id);
      await Provider.of<RecipeProvider>(context, listen: false)
          .fetchAllRecipes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.recipeDeletedSuccess)), // Changed
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .recipeDeleteError(e.toString()))), // Changed
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'recipeListBackButton',
          child: const BackButton(),
        ),
        title: Row(
          children: [
            Semantics(
              identifier: 'brewingMethodIcon_${widget.brewingMethodId}',
              child: getIconByBrewingMethod(widget.brewingMethodId),
            ),
            const SizedBox(width: 8),
            FutureBuilder<String>(
              future: Provider.of<RecipeProvider>(context, listen: false)
                  .getBrewingMethodName(widget.brewingMethodId ?? ""),
              builder: (context, snapshot) => Text(snapshot.data ??
                  AppLocalizations.of(context)!.loadingEllipsis), // Changed
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit_note),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              Provider.of<RecipeProvider>(context, listen: false)
                  .fetchAllRecipes();
            },
          ),
        ],
      ),
      body: Semantics(
        identifier: 'recipeListBody',
        child: Consumer<RecipeProvider>(
          builder: (context, recipeProvider, child) {
            // Filter recipes by brewingMethodId
            List<RecipeModel> recipes = recipeProvider.recipes
                .where(
                    (r) => r.brewingMethodId == (widget.brewingMethodId ?? ""))
                .toList()
              ..sort((a, b) {
                final aIsUser = a.id.startsWith('usr-');
                final bIsUser = b.id.startsWith('usr-');

                // System recipes first, sorted by numeric ID
                if (!aIsUser && !bIsUser) {
                  return int.parse(a.id).compareTo(int.parse(b.id));
                }

                // User recipes after system, sorted by creation time (timestamp part of ID)
                if (aIsUser && bIsUser) {
                  try {
                    // More robust timestamp extraction - get everything after the second hyphen
                    // This handles cases where user IDs might contain hyphens themselves
                    final aIdStr = a.id;
                    final bIdStr = b.id;

                    // Find the position of the second hyphen
                    final aSecondHyphen =
                        aIdStr.indexOf('-', aIdStr.indexOf('-') + 1);
                    final bSecondHyphen =
                        bIdStr.indexOf('-', bIdStr.indexOf('-') + 1);

                    // If we can find the second hyphen in both IDs
                    if (aSecondHyphen > 0 && bSecondHyphen > 0) {
                      // Extract everything after the second hyphen as the timestamp
                      final aTimestampStr = aIdStr.substring(aSecondHyphen + 1);
                      final bTimestampStr = bIdStr.substring(bSecondHyphen + 1);

                      // Try to parse as integers for comparison
                      try {
                        final aTimestamp = int.parse(aTimestampStr);
                        final bTimestamp = int.parse(bTimestampStr);
                        return aTimestamp.compareTo(bTimestamp);
                      } catch (e) {
                        // If integer parsing fails, compare as strings
                        return aTimestampStr.compareTo(bTimestampStr);
                      }
                    }
                  } catch (e) {
                    // If any exception occurs during the process, log it and fall back
                    print('Error sorting user recipes: $e');
                  }

                  // Fall back to string comparison of the entire ID
                  return a.id.compareTo(b.id);
                }

                return aIsUser
                    ? 1
                    : -1; // User recipes always come after system
              });
            if (recipes.isEmpty) {
              return Center(
                  child: Text(
                      AppLocalizations.of(context)!.noRecipesFound)); // Changed
            }
            return ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (BuildContext context, int index) {
                RecipeModel recipe = recipes[index];
                return Semantics(
                  identifier: 'recipeListItem_${recipe.id}',
                  child: ListTile(
                    title: Text(recipe.name),
                    onTap: () => navigateToRecipeDetail(recipe),
                    trailing: _isEditMode && recipe.id.startsWith('usr-')
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FavoriteButton(recipeId: recipe.id),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteRecipe(recipe),
                              ),
                            ],
                          )
                        : Semantics(
                            identifier: 'favoriteButton_${recipe.id}',
                            child: FavoriteButton(recipeId: recipe.id),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void navigateToRecipeDetail(RecipeModel recipe) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
    try {
      await Provider.of<RecipeProvider>(context, listen: false)
          .ensureDataReady();
      // Try to fetch the recipe by id to confirm it exists.
      await Provider.of<RecipeProvider>(context, listen: false)
          .getRecipeById(recipe.id);
      Navigator.pop(context);
      context.router.push(RecipeDetailRoute(
        brewingMethodId: recipe.brewingMethodId,
        recipeId: recipe.id,
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .recipeLoadError(e.toString()))), // Changed
      );
    }
  }
}
