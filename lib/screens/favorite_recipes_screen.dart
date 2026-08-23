// lib/screens/favorite_recipes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import '../widgets/smart_back_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../utils/icon_utils.dart';
import '../widgets/base_buttons.dart';

@RoutePage()
class FavoriteRecipesScreen extends StatelessWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'favoriteRecipesBackButton',
          child: const SmartBackButton(),
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
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.favoriteRecipesLoadFailed,
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Semantics(
              identifier: 'noFavoriteRecipesMessage',
              child: _buildEmptyState(context),
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

  /// Empty state shown when the user has no favorite recipes yet.
  ///
  /// Follows the app's standard empty-state layout (icon, title, supporting
  /// text, action) using theme-derived colors so it reads in both light and
  /// dark mode.
  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: AppIconSize.emptyState,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              loc.noFavoriteRecipesTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.noFavoriteRecipesMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppElevatedButton(
              label: loc.noFavoriteRecipesCta,
              // Mirrors SmartBackButton: pop back to the brewing methods
              // list, or land there directly when opened via a deep link.
              onPressed: () {
                if (context.router.canPop()) {
                  context.router.maybePop();
                } else {
                  context.router.replaceAll([const HomeRoute()]);
                }
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: AppButton.paddingMedium,
            ),
          ],
        ),
      ),
    );
  }
}
