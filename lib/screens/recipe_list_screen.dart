import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:flutter/foundation.dart';
import "package:universal_html/html.dart" as html;

@RoutePage()
class RecipeListScreen extends StatefulWidget {
  final String? brewingMethodId;

  const RecipeListScreen({
    Key? key,
    @PathParam('brewingMethodId') this.brewingMethodId,
  }) : super(key: key);

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  Future<String> brewingMethodName = Future.value("");
  List<Recipe> _currentBrewingMethodRecipes = [];

  @override
  void initState() {
    super.initState();
    getBrewingMethodName();
    fetchRecipesForBrewingMethod();
  }

  void getBrewingMethodName() {
    brewingMethodName = Provider.of<RecipeProvider>(context, listen: false)
        .getBrewingMethodName(widget.brewingMethodId);
  }

  void fetchRecipesForBrewingMethod() async {
    if (widget.brewingMethodId != null) {
      await Provider.of<RecipeProvider>(context, listen: false)
          .fetchRecipes(widget.brewingMethodId);
      setState(() {
        _currentBrewingMethodRecipes = Provider.of<RecipeProvider>(context,
                listen: false)
            .getRecipes()
            .where((recipe) => recipe.brewingMethodId == widget.brewingMethodId)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: FutureBuilder<String>(
          future: brewingMethodName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (kIsWeb) {
              html.document.title = '${snapshot.data!} recipes on Timer.Coffee';
            }
            return Text(snapshot.data ?? 'Recipes');
          },
        ),
      ),
      body: _buildRecipeListView(),
    );
  }

  Widget _buildRecipeListView() {
    return ListView.builder(
      itemCount: _currentBrewingMethodRecipes.length,
      itemBuilder: (BuildContext context, int index) {
        Recipe recipe = _currentBrewingMethodRecipes[index];
        return ListTile(
          title: Text(recipe.name),
          onTap: () => navigateToRecipeDetail(recipe),
          trailing: FavoriteButton(
            recipeId: recipe.id,
            onToggleFavorite: (bool isFavorite) {
              Provider.of<RecipeProvider>(context, listen: false)
                  .toggleFavorite(recipe.id);
            },
          ),
        );
      },
    );
  }

  void navigateToRecipeDetail(Recipe recipe) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    recipeProvider.updateLastUsed(recipe.id);

    if (recipe.id == "106") {
      context.router.push(RecipeDetailTKRoute(
          brewingMethodId: recipe.brewingMethodId, recipeId: recipe.id));
    } else {
      context.router.push(RecipeDetailRoute(
          brewingMethodId: recipe.brewingMethodId, recipeId: recipe.id));
    }
  }
}
