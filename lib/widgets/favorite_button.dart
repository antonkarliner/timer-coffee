import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe_model.dart';

class FavoriteButton extends StatefulWidget {
  final String recipeId;

  const FavoriteButton({Key? key, required this.recipeId}) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false; // Initialize with a default value

  @override
  void initState() {
    super.initState();
    _initializeFavoriteStatus();
  }

  void _initializeFavoriteStatus() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipe = await recipeProvider.getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        // Default to false if recipe is null
        _isFavorite = recipe?.isFavorite ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: () async {
        await Provider.of<RecipeProvider>(context, listen: false)
            .toggleFavorite(widget.recipeId);
        // Re-fetch the favorite status to ensure consistency with the database
        final recipe = await Provider.of<RecipeProvider>(context, listen: false)
            .getRecipeById(widget.recipeId);
        if (mounted) {
          setState(() {
            // Default to false if recipe is null
            _isFavorite = recipe?.isFavorite ??
                false; // Update based on the latest status
          });
        }
      },
    );
  }
}
