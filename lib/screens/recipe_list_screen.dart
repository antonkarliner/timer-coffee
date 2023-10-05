import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
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

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Future<String> brewingMethodName = Future.value("");
  Future<List<Recipe>>? allRecipes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getBrewingMethodName();
    allRecipes = fetchAllRecipes();
  }

  getBrewingMethodName() {
    brewingMethodName = Provider.of<RecipeProvider>(context, listen: false)
        .getBrewingMethodName(widget.brewingMethodId);

    // Set state to refresh UI
    setState(() {});
  }

  Future<List<Recipe>> fetchAllRecipes() {
    return Provider.of<RecipeProvider>(context, listen: false)
        .fetchRecipes(widget.brewingMethodId);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(), // This is your back button
        title: Row(
          children: [
            getIconByBrewingMethod(
                widget.brewingMethodId), // This is your brewing method icon
            const SizedBox(
                width:
                    8), // Optional: Add a little space between the icon and text
            FutureBuilder<String>(
              future: brewingMethodName,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (kIsWeb) {
                  // Update HTML title
                  html.document.title =
                      '${snapshot.data!} recipes on Timer.Coffee';
                }
                return Text(snapshot.data!);
              },
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Recipes'),
            Tab(text: 'Favorite Recipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<Recipe>>(
            future: allRecipes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              final allRecipes = snapshot.data!;
              return _buildRecipeListView(allRecipes);
            },
          ),
          ValueListenableBuilder<Set<String>>(
            valueListenable: recipeProvider.favoriteRecipeIds,
            builder: (context, favoriteRecipeIds, child) {
              return _buildRecipeListView(recipeProvider
                  .getRecipes()
                  .where((recipe) => favoriteRecipeIds.contains(recipe.id))
                  .toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeListView(List<Recipe> recipes) {
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(recipes[index].name),
          onTap: () {
            final recipeProvider =
                Provider.of<RecipeProvider>(context, listen: false);

            recipeProvider.updateLastUsed(recipes[index].id);

            context.router.push(RecipeDetailRoute(
                brewingMethodId: recipes[index].brewingMethodId,
                recipeId: recipes[index].id));
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
  }
}
