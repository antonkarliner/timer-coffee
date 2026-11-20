import 'package:flutter/material.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/widgets/favorite_button.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';
import 'package:coffee_timer/widgets/recipe_detail/title_bar.dart';
import 'package:coffee_timer/widgets/recipe_detail/app_bar_actions.dart';

/// Custom app bar for recipe detail screen
class RecipeDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final RecipeModel recipe;
  final String brewingMethodName;
  final String idForActions;
  final bool isSharing;
  final bool isPreview;

  /// Highlights the favorite heart (halo + pulse) until first tapped.
  /// Set when the screen is opened from the journey card's "favorite a
  /// recipe" milestone.
  final bool highlightFavorite;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback? onUnpublish;

  const RecipeDetailAppBar({
    super.key,
    required this.recipe,
    required this.brewingMethodName,
    required this.idForActions,
    required this.isSharing,
    this.isPreview = false,
    this.highlightFavorite = false,
    required this.onEdit,
    required this.onCopy,
    required this.onShare,
    this.onUnpublish,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUserRecipe = idForActions.startsWith('usr-');

    return AppBar(
      leading: const SmartBackButton(),
      title: RecipeDetailTitle(
        brewingMethodIcon: getIconByBrewingMethod(recipe.brewingMethodId),
        brewingMethodName: brewingMethodName,
      ),
      actions: [
        if (!isPreview)
          RecipeDetailAppBarActions(
            isUserRecipe: isUserRecipe,
            isSharing: isSharing,
            idForActions: idForActions,
            isPublic: recipe.isPublic,
            onEdit: onEdit,
            onCopy: onCopy,
            onShare: onShare,
            onUnpublish: onUnpublish,
            favoriteButton: FavoriteButton(
              recipeId: idForActions,
              highlight: highlightFavorite,
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
