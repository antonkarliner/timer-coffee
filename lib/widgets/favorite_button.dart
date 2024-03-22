import 'package:coffee_timer/models/recipe_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';

class FavoriteButton extends StatefulWidget {
  final String recipeId;

  const FavoriteButton({Key? key, required this.recipeId}) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadInitialFavoriteStatus();
  }

  Future<void> _loadInitialFavoriteStatus() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    RecipeModel recipe = await recipeProvider.getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        _isFavorite = recipe.isFavorite;
      });
    }
  }

  void _toggleFavorite(RecipeProvider provider) async {
    await provider.toggleFavorite(widget.recipeId);
    RecipeModel updatedRecipe = await provider.getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        _isFavorite = updatedRecipe.isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.brown : null,
      ),
      onPressed: () =>
          _toggleFavorite(Provider.of<RecipeProvider>(context, listen: false)),
    );
  }
}
