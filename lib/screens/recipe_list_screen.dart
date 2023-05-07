import 'package:flutter/material.dart';
import 'recipe_detail_screen.dart';
import '../models/recipe.dart';
import '../models/brewing_method.dart';

class RecipeListScreen extends StatefulWidget {
  final BrewingMethod brewingMethod;
  final List<Recipe> recipes;

  RecipeListScreen({required this.brewingMethod, required this.recipes});

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  @override
  Widget build(BuildContext context) {
    List<Recipe> recipes = widget.recipes
        .where((recipe) => recipe.brewingMethodId == widget.brewingMethod.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.brewingMethod.name)),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(recipes[index].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(
                    recipe: recipes[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
