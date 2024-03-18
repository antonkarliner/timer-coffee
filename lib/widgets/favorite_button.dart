import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';

class FavoriteButton extends StatelessWidget {
  final String recipeId;

  const FavoriteButton({
    super.key,
    required this.recipeId,
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
          onPressed: () async {
            await recipeProvider.toggleFavorite(recipeId);
            // The onToggleFavorite callback is no longer needed since the favorite status is now directly handled within the RecipeProvider.
          },
        );
      },
    );
  }
}
