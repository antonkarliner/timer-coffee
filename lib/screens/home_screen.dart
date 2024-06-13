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
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late Locale initialLocale;
  late TabController _tabController;
  static const double kBottomNavigationBarHeight = 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    PurchaseManager().setDeliverProductCallback(null);
    PurchaseManager().setPurchaseErrorCallback(null);
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformSpecificAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildBrewTab(context),
          buildHubTab(context),
        ],
      ),
      bottomNavigationBar: ConvexAppBar.builder(
        count: 2,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        itemBuilder: CustomTabBuilder([
          TabItem(
              icon: Coffeico.bean,
              title: (AppLocalizations.of(context)!.homescreenbrewcoffee)),
          TabItem(
              icon: Icons.dashboard,
              title: (AppLocalizations.of(context)!.homescreenmore)),
        ], context),
        onTap: (int i) {
          _tabController.index = i;
          setState(() {});
        },
      ),
    );
  }

  Widget buildBrewTab(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final brewingMethods = Provider.of<List<BrewingMethodModel>>(context);
    final double bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;
    final filteredBrewingMethods =
        brewingMethods.where((method) => method.showOnMain).toList();

    return SafeArea(
      child: Column(
        children: [
          buildFixedContent(recipeProvider),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBrewingMethods.length,
              itemBuilder: (BuildContext context, int index) {
                final brewingMethod = filteredBrewingMethods[index];
                return Semantics(
                  identifier: 'brewingMethod_${brewingMethod.brewingMethodId}',
                  label: brewingMethod.brewingMethod,
                  child: ListTile(
                    leading:
                        getIconByBrewingMethod(brewingMethod.brewingMethodId),
                    title: Text(brewingMethod.brewingMethod),
                    onTap: () {
                      context.router.push(RecipeListRoute(
                          brewingMethodId: brewingMethod.brewingMethodId));
                    },
                  ),
                );
              },
              padding: EdgeInsets.only(bottom: bottomPadding),
            ),
          ),
          Semantics(
            identifier: 'launchPopupWidget',
            child: LaunchPopupWidget(),
          ),
        ],
      ),
    );
  }

  Widget buildFixedContent(RecipeProvider recipeProvider) {
    return FutureBuilder<RecipeModel?>(
      future: recipeProvider.getLastUsedRecipe(),
      builder: (context, snapshot) {
        RecipeModel? mostRecentRecipe = snapshot.data;
        return Column(
          children: [
            Semantics(
              identifier: 'favoriteRecipes',
              label: AppLocalizations.of(context)!.favoriterecipes,
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(AppLocalizations.of(context)!.favoriterecipes),
                onTap: () {
                  context.router.push(const FavoriteRecipesRoute());
                },
              ),
            ),
            if (mostRecentRecipe != null)
              Semantics(
                identifier: 'lastRecipe_${mostRecentRecipe.id}',
                label:
                    '${AppLocalizations.of(context)!.lastrecipe}${mostRecentRecipe.name}',
                child: ListTile(
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
              ),
          ],
        );
      },
    );
  }

  Widget buildHubTab(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
        children: [
          Semantics(
            identifier: 'brewDiary',
            label: AppLocalizations.of(context)!.brewdiary,
            child: ListTile(
              leading: const Icon(Icons.library_books),
              title: Text(AppLocalizations.of(context)!.brewdiary),
              onTap: () {
                context.router.push(const BrewDiaryRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'statsScreen',
            label: AppLocalizations.of(context)!.statsscreen,
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(AppLocalizations.of(context)!.statsscreen),
              onTap: () {
                context.router.push(StatsRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'beansScreen',
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(AppLocalizations.of(context)!.myBeans),
              onTap: () {
                context.router.push(const CoffeeBeansRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'settings',
            label: AppLocalizations.of(context)!.settings,
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                context.router.push(const SettingsRoute());
              },
            ),
          ),
        ],
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

class CustomTabBuilder extends DelegateBuilder {
  final List<TabItem> items;
  final BuildContext context;

  CustomTabBuilder(this.items, this.context);

  @override
  Widget build(BuildContext context, int index, bool active) {
    // Determine color based on the theme
    Color activeColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Colors.black;
    Color inactiveColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    var item = items[index];
    return Semantics(
      identifier: 'tabItem_$index',
      label: item.title ?? "",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            item.icon,
            color: active ? activeColor : inactiveColor,
          ),
          Text(item.title ?? "",
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
              )),
        ],
      ),
    );
  }
}
