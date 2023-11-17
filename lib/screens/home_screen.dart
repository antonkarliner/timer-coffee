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
        onPressed: _changeLocale,
        tooltip: 'Change Locale',
        child: Text(recipeProvider.currentLocale.languageCode.toUpperCase()),
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
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      );
    }
  }

  void _changeLocale() async {
    final result = await showModalBottomSheet<Locale>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('English'),
                onTap: () => Navigator.pop(context, const Locale('en')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Español'), // Spanish
                onTap: () => Navigator.pop(context, const Locale('es')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Português'), // Portuguese
                onTap: () => Navigator.pop(context, const Locale('pt')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Deutsch'), // German
                onTap: () => Navigator.pop(context, const Locale('de')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Français'), // French
                onTap: () => Navigator.pop(context, const Locale('fr')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Русский'), // Russian
                onTap: () => Navigator.pop(context, const Locale('ru')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Polski'), // Polish
                onTap: () => Navigator.pop(context, const Locale('pl')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('العربية'), // Arabic
                trailing: const Badge(
                  label: Text('Beta', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.brown,
                ),
                onTap: () => Navigator.pop(context, const Locale('ar')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('中文'), // Chinese
                trailing: const Badge(
                  label: Text('Beta', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.brown,
                ),
                onTap: () => Navigator.pop(context, const Locale('zh')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('日本語'), // Japanese
                trailing: const Badge(
                  label: Text('Beta', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.brown,
                ),
                onTap: () => Navigator.pop(context, const Locale('ja')),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      _setLocale(result);
    }
  }

  void _setLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.toString());

    Provider.of<RecipeProvider>(context, listen: false).setLocale(newLocale);

    // Use AutoRouter to navigate
    context.router.replace(const HomeRoute());
  }
}
