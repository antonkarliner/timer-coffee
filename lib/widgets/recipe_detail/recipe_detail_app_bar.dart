import 'package:flutter/material.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/widgets/favorite_button.dart';
import 'package:coffee_timer/widgets/recipe_detail/title_bar.dart';
import 'package:coffee_timer/widgets/recipe_detail/app_bar_actions.dart';

/// Custom app bar for recipe detail screen
class RecipeDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final RecipeModel recipe;
  final String brewingMethodName;
  final String idForActions;
  final bool isSharing;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const RecipeDetailAppBar({
    Key? key,
    required this.recipe,
    required this.brewingMethodName,
    required this.idForActions,
    required this.isSharing,
    required this.onEdit,
    required this.onCopy,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUserRecipe = idForActions.startsWith('usr-');

    return AppBar(
      leading: const BackButton(),
      title: RecipeDetailTitle(
        brewingMethodIcon: getIconByBrewingMethod(recipe.brewingMethodId),
        brewingMethodName: brewingMethodName,
      ),
      actions: [
        RecipeDetailAppBarActions(
          isUserRecipe: isUserRecipe,
          isSharing: isSharing,
          idForActions: idForActions,
          onEdit: onEdit,
          onCopy: onCopy,
          onShare: onShare,
          favoriteButton: FavoriteButton(recipeId: idForActions),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
