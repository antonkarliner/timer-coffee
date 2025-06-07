import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';

class FavoriteButton extends StatefulWidget {
  final String recipeId;

  const FavoriteButton({Key? key, required this.recipeId}) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false; // Initialize with a default value
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFavoriteStatus();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeFavoriteStatus() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipe = await recipeProvider.getRecipeById(widget.recipeId);
    if (mounted) {
      setState(() {
        _isFavorite = recipe?.isFavorite ?? false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await Provider.of<RecipeProvider>(context, listen: false)
        .toggleFavorite(widget.recipeId);
    final recipe = await Provider.of<RecipeProvider>(context, listen: false)
        .getRecipeById(widget.recipeId);
    if (mounted) {
      bool newStatus = recipe?.isFavorite ?? false;
      setState(() {
        _isFavorite = newStatus;
      });
      // If changed to favorite, trigger the pop-up scale animation.
      if (newStatus) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite
              ? (Theme.of(context).brightness == Brightness.light
                  ? const Color(0xff8e2e2d)
                  : const Color(0xffc66564))
              : null,
        ),
        onPressed: _toggleFavorite,
      ),
    );
  }
}
