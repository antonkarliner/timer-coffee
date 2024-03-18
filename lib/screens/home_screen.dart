import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../models/brewing_method_model.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe_model.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import '../purchase_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import '../providers/snow_provider.dart';

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

    // Set up PurchaseManager callbacks
    PurchaseManager().setDeliverProductCallback(_showThankYouPopup);
    PurchaseManager().setPurchaseErrorCallback(_showErrorDialog);
  }

  void _showThankYouPopup(PurchaseDetails details) {
    if (mounted) {
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
  }

  void _showErrorDialog(IAPError error) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.donationerr),
            content: Text(AppLocalizations.of(context)!.donationerrmsg),
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // It's important to dispose the callbacks when the widget is disposed
    PurchaseManager().setDeliverProductCallback(null);
    PurchaseManager().setPurchaseErrorCallback(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final brewingMethods = Provider.of<List<BrewingMethodModel>>(context);
    //final snowEffectProvider = Provider.of<SnowEffectProvider>(context);

    return Scaffold(
      appBar: buildPlatformSpecificAppBar(),
      body: Stack(
        children: [
          buildRecipeList(recipeProvider, brewingMethods),
          //buildSnowToggleButton(snowEffectProvider),
          buildSettingsButton(),
          LaunchPopupWidget(),
        ],
      ),
    );
  }

  Widget buildRecipeList(
      RecipeProvider recipeProvider, List<BrewingMethodModel> brewingMethods) {
    return FutureBuilder<Recipe?>(
      future: recipeProvider.getLastUsedRecipe(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        Recipe? mostRecentRecipe = snapshot.data;

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(AppLocalizations.of(context)!.favoriterecipes),
              onTap: () {
                context.router
                    .push(const FavoriteRecipesRoute()); // Your routing logic
              },
            ),
            if (mostRecentRecipe != null)
              ListTile(
                leading:
                    getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                title: Text(
                    '${AppLocalizations.of(context)!.lastrecipe}${mostRecentRecipe.name}'),
                onTap: () {
                  // Add the routing logic based on recipe ID
                  if (mostRecentRecipe.id == "106") {
                    // If the recipe id is 106, navigate to RecipeDetailTKRoute
                    context.router.push(RecipeDetailTKRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id));
                  } else {
                    // For all other recipes, navigate to RecipeDetailRoute
                    context.router.push(RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id));
                  }
                },
              ),
            Expanded(
              child: ListView.builder(
                itemCount: brewingMethods.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    leading: getIconByBrewingMethod(
                        brewingMethods[index].brewingMethodId),
                    title: Text(brewingMethods[index].brewingMethod),
                    onTap: () {
                      context.router.push(RecipeListRoute(
                          brewingMethodId:
                              brewingMethods[index].brewingMethodId));
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  //Widget buildSnowToggleButton(SnowEffectProvider snowEffectProvider) {
  //return Positioned(
  //left: 20,
  //bottom: 20,
  //child: FloatingActionButton.small(
  //heroTag: 'snowToggle',
  //onPressed: snowEffectProvider.toggleSnowEffect,
  //tooltip: 'Toggle Snow',
  //backgroundColor: Colors.lightBlue[100]!,
  //foregroundColor: const Color(0xFFFFFFFF),
  //child: Icon(snowEffectProvider.isSnowing ? Icons.cloud : Icons.ac_unit),
  //),
  //);
  //}

  Widget buildSettingsButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: FloatingActionButton.small(
        heroTag: 'settingsButton',
        onPressed: () {
          context.router.push(const SettingsRoute());
        },
        tooltip: 'Settings',
        child: const Icon(Icons.settings),
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
