import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'recipe_list_screen.dart';
import '../models/brewing_method.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<BrewingMethod> brewingMethods;

  HomeScreen({required this.brewingMethods});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);

    return Scaffold(
      appBar: buildPlatformSpecificAppBar(),
      body: FutureBuilder<Recipe?>(
        future: recipeProvider.getLastUsedRecipe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          Recipe? mostRecentRecipe = snapshot.data;

          return Column(
            children: [
              if (mostRecentRecipe != null)
                ListTile(
                  title: Text(
                      'Most Recently Used Recipe: ${mostRecentRecipe.name}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(
                          recipe: mostRecentRecipe,
                        ),
                      ),
                    );
                  },
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.brewingMethods.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(widget.brewingMethods[index].name),
                      onTap: () async {
                        final recipes = await recipeProvider
                            .fetchRecipes(widget.brewingMethods[index].id);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeListScreen(
                              brewingMethod: widget.brewingMethods[index],
                              recipes: recipes,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget buildPlatformSpecificAppBar() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoNavigationBar(
        middle: Text('Coffee Timer'),
      );
    } else {
      return AppBar(
        title: Text('Coffee Timer'),
      );
    }
  }
}
