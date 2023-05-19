import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'recipe_list_screen.dart';
import '../models/brewing_method.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'about_screen.dart';
import 'coffee_tips_screen.dart'; // Import the CoffeeTipsScreen here

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
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: ElevatedButton(
                  child: Text('Coffee Brewing Tips'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CoffeeTipsScreen(),
                      ),
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
        middle: Text('Timer.Coffee'),
        trailing: IconButton(
          icon: Icon(Icons.info),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AboutScreen(),
              ),
            );
          },
        ),
      );
    } else {
      return AppBar(
        title: Text('Timer.coffee'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutScreen(),
                ),
              );
            },
          ),
        ],
      );
    }
  }
}
