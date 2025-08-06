import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../models/recipe_model.dart';
import '../../../widgets/favorite_button.dart';
import '../../../utils/icon_utils.dart';
import '../../../providers/recipe_provider.dart';

class RecipeListItem extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isEditable; // only for created list
  final ValueListenable<bool>? isInEditModeListenable;

  const RecipeListItem({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onDelete,
    required this.isEditable,
    this.isInEditModeListenable,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = ValueListenableBuilder<bool>(
      valueListenable: isInEditModeListenable ?? ValueNotifier(false),
      builder: (context, isEdit, _) {
        if (isEdit && isEditable && recipe.id.startsWith('usr-')) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FavoriteButton(recipeId: recipe.id),
              IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          );
        }
        return Semantics(
          identifier: 'favoriteButton_${recipe.id}',
          child: FavoriteButton(recipeId: recipe.id),
        );
      },
    );

    return ListTile(
      leading: Semantics(
        identifier: 'brewingMethodIcon_${recipe.brewingMethodId}',
        child: getIconByBrewingMethod(recipe.brewingMethodId),
      ),
      title: Text(recipe.name),
      onTap: onTap,
      trailing: trailing,
    );
  }
}
