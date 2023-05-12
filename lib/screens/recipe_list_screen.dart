import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'recipe_detail_screen.dart';
import '../models/recipe.dart';
import '../models/brewing_method.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';

class RecipeListScreen extends StatefulWidget {
  final BrewingMethod brewingMethod;
  final List<Recipe> recipes;

  RecipeListScreen({required this.brewingMethod, required this.recipes});

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brewingMethod.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Recipes'),
            Tab(text: 'Favorite Recipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Consumer<RecipeProvider>(
            builder: (context, recipeProvider, child) {
              List<Recipe> allRecipes = recipeProvider
                  .getRecipes()
                  .where((recipe) =>
                      recipe.brewingMethodId == widget.brewingMethod.id)
                  .toList();
              return _buildRecipeListView(allRecipes);
            },
          ),
          Consumer<RecipeProvider>(
            builder: (context, recipeProvider, child) {
              List<Recipe> favoriteRecipes = recipeProvider
                  .getRecipes()
                  .where((recipe) =>
                      recipe.brewingMethodId == widget.brewingMethod.id &&
                      recipe.isFavorite)
                  .toList();
              return _buildRecipeListView(favoriteRecipes);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeListView(List<Recipe> recipes) {
    return Consumer<RecipeProvider>(
      builder: (context, recipeProvider, child) {
        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(recipes[index].name),
              onTap: () {
                final recipeProvider =
                    Provider.of<RecipeProvider>(context, listen: false);
                recipeProvider.updateLastUsed(recipes[index].id);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(
                      recipe: recipes[index],
                    ),
                  ),
                );
              },
              trailing: FavoriteButton(
                recipeId: recipes[index]
                    .id, // Use recipes[index].id to access the id of the current recipe
                onToggleFavorite: (bool isFavorite) {
                  Provider.of<RecipeProvider>(context, listen: false)
                      .toggleFavorite(recipes[index]
                          .id); // Use recipes[index].id to access the id of the current recipe
                },
              ),
            );
          },
        );
      },
    );
  }
}
