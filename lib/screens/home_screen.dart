import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'recipe_list_screen.dart';
import '../models/brewing_method.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'about_screen.dart';
import 'coffee_tips_screen.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    if (kIsWeb) {
      html.document.title = 'Timer.Coffee App';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && kIsWeb) {
      html.document.title = 'Timer.Coffee App';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final brewingMethods = Provider.of<List<BrewingMethod>>(context);

    return Scaffold(
      appBar: buildPlatformSpecificAppBar(),
      body: FutureBuilder<Recipe?>(
        future: recipeProvider.getLastUsedRecipe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Recipe? mostRecentRecipe = snapshot.data;

          return Column(
            children: [
              if (mostRecentRecipe != null)
                ListTile(
                  title: Text(
                      'Most Recently Used Recipe: ${mostRecentRecipe.name}'),
                  onTap: () {
                    context.router.push(RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id));
                  },
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: brewingMethods.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(brewingMethods[index].name),
                      onTap: () {
                        context.router.push(RecipeListRoute(
                            brewingMethodId: brewingMethods[index].id));
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: ElevatedButton(
                  child: const Text('Coffee Brewing Tips'),
                  onPressed: () {
                    context.router.push(const CoffeeTipsRoute());
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
        middle: const Text('Timer.Coffee',
            style: TextStyle(fontFamily: kIsWeb ? 'Lato' : null)),
        trailing: IconButton(
          icon: const Icon(Icons.info),
          onPressed: () {
            context.router.push(const AboutRoute());
          },
        ),
      );
    } else {
      return AppBar(
        title: const Text('Timer.Coffee'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      );
    }
  }
}
