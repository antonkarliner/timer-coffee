import 'package:coffee_timer/models/recipe_model.dart';
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
        // Use FutureBuilder to wait for getRecipeById to complete
        return FutureBuilder<RecipeModel>(
          future: recipeProvider.getRecipeById(recipeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Optionally, return a placeholder widget while waiting
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // Handle error state
              return const Icon(Icons.error);
            } else if (snapshot.hasData) {
              // Access isFavorite on the RecipeModel from the snapshot
              bool isFavorite = snapshot.data!.isFavorite;
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.brown : null,
                ),
                onPressed: () async {
                  await recipeProvider.toggleFavorite(recipeId);
                  // No need for a callback as you're directly modifying the state in the provider
                },
              );
            } else {
              // Handle the case where there's no data
              return const Icon(Icons.favorite_border);
            }
          },
        );
      },
    );
  }
}
