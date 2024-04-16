import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:coffeico/coffeico.dart';
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
  late Locale initialLocale;
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

    // Correctly obtain initialLocale from the Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialLocale = Provider.of<Locale>(context, listen: false);

      if (kIsWeb) {
        var recipeProvider =
            Provider.of<RecipeProvider>(context, listen: false);
        var tempLocale =
            const Locale('av'); // An example temporary locale for simulation
        recipeProvider.setLocale(tempLocale).then((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            recipeProvider
                .setLocale(initialLocale); // Revert to the initial app locale
          });
        });
      }
    });
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
          buildBrewDiaryButton(),
          buildSettingsButton(),
          LaunchPopupWidget(),
        ],
      ),
    );
  }

  Widget buildRecipeList(
      RecipeProvider recipeProvider, List<BrewingMethodModel> brewingMethods) {
    final filteredBrewingMethods =
        brewingMethods.where((method) => method.showOnMain).toList();
    return FutureBuilder<RecipeModel?>(
      future: recipeProvider.getLastUsedRecipe(),
      builder: (context, snapshot) {
        RecipeModel? mostRecentRecipe = snapshot.data;

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(AppLocalizations.of(context)!.favoriterecipes),
              onTap: () {
                context.router.push(const FavoriteRecipesRoute());
              },
            ),
            //ListTile(
            //leading: const Icon(Coffeico.bean),
            //title: Text(AppLocalizations.of(context)!.explore),
            //onTap: () {
            //context.router.push(const VendorsRoute());
            //},
            //),
            if (mostRecentRecipe != null)
              ListTile(
                leading:
                    getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                title: Text(
                    '${AppLocalizations.of(context)!.lastrecipe}${mostRecentRecipe.name}'),
                onTap: () {
                  // Check if the recipe ID contains only numbers
                  bool isNumericId =
                      RegExp(r'^\d+$').hasMatch(mostRecentRecipe.id);

                  // Add the routing logic based on recipe ID
                  if (mostRecentRecipe.id == "106") {
                    // If the recipe id is 106, navigate to RecipeDetailTKRoute
                    context.router.push(RecipeDetailTKRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id));
                  } else if (!isNumericId) {
                    // If the recipe ID contains letters, navigate to VendorRecipeDetailRoute
                    context.router.push(VendorRecipeDetailRoute(
                        recipeId: mostRecentRecipe.id,
                        vendorId: mostRecentRecipe.vendorId!));
                  } else {
                    // For all other numeric recipe IDs, navigate to RecipeDetailRoute
                    context.router.push(RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id));
                  }
                },
              ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredBrewingMethods.length,
                itemBuilder: (BuildContext context, int index) {
                  final brewingMethod = filteredBrewingMethods[index];
                  return ListTile(
                    leading:
                        getIconByBrewingMethod(brewingMethod.brewingMethodId),
                    title: Text(brewingMethod.brewingMethod),
                    onTap: () {
                      context.router.push(RecipeListRoute(
                          brewingMethodId: brewingMethod.brewingMethodId));
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

  Widget buildBrewDiaryButton() {
    return Positioned(
      left: 20,
      bottom: 20,
      child: FloatingActionButton.small(
          heroTag: 'brewDiaryButton',
          onPressed: () {
            context.router.push(const BrewDiaryRoute());
          },
          tooltip: 'Brew Diary',
          child: const Icon(Icons.history)),
    );
  }

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
      // For iOS using CupertinoNavigationBar
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
