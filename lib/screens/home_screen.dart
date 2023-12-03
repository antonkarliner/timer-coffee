import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../models/brewing_method.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'about_screen.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import '../purchase_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      html.document.title = 'Timer.Coffee App';
    }

    PurchaseManager().initialize();
    PurchaseManager().deliverProductCallback = (details) {
      _showThankYouPopup(details);
    };
  }

  void _showThankYouPopup(PurchaseDetails details) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.donationok),
          content: Text(AppLocalizations.of(context)!.donationtnx),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                  leading:
                      getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                  title: Text(
                      '${AppLocalizations.of(context)!.lastrecipe}${mostRecentRecipe.name}'),
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
                      leading: getIconByBrewingMethod(brewingMethods[index].id),
                      title: Text(brewingMethods[index].name),
                      onTap: () {
                        context.router.push(RecipeListRoute(
                            brewingMethodId: brewingMethods[index].id));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          // Navigate to the SettingsScreen using auto_route
          context.router.push(const SettingsRoute());
        },
        tooltip: 'Settings',
        child: const Icon(Icons.settings), // Using a settings icon
      ),
    );
  }

  PreferredSizeWidget buildPlatformSpecificAppBar() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoNavigationBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        middle: Text('Timer.Coffee',
            style: TextStyle(
                fontFamily: kIsWeb ? 'Lato' : null,
                color: Theme.of(context).appBarTheme.foregroundColor)),
      );
    } else {
      return AppBar(
        title: const Text('Timer.Coffee'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      );
    }
  }
}
