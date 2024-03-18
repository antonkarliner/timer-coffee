import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:flutter/foundation.dart';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';

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
            // Define an empty placeholder widget that will be replaced with the actual icon or CircularProgressIndicator
            Widget leadingWidget = Container();
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a small progress indicator if the name is still loading
              leadingWidget = const SizedBox(
                width: 20, // Adjust the size to fit within your AppBar
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            } else if (snapshot.hasData) {
              // Once the data is available, show the icon
              leadingWidget = getIconByBrewingMethod(widget.brewingMethodId);
            }

            return Row(
              mainAxisSize: MainAxisSize.min, // Keep the row's content together
              children: [
                leadingWidget, // This is the dynamic leading widget (icon or progress indicator)
                const SizedBox(
                    width: 8), // Add some space between the icon and the title
                Expanded(
                  // Use Expanded to prevent overflow of the title text
                  child: Text(
                    snapshot.hasData ? '${snapshot.data}' : 'Loading...',
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                ),
              ],
            );
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
