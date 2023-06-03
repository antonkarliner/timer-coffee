import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';

class FavoriteButton extends StatelessWidget {
  final String recipeId;
  final ValueChanged<bool> onToggleFavorite;

  const FavoriteButton({
    super.key,
    required this.recipeId,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (context, recipeProvider, child) {
        bool isFavorite = recipeProvider.getRecipeById(recipeId).isFavorite;
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.brown : null,
          ),
          onPressed: () {
            onToggleFavorite(!isFavorite);
          },
        );
      },
    );
  }
}
