import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './models/brewing_method.dart';
import './providers/recipe_provider.dart';
import './app_router.dart';
import './app_router.gr.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import './models/recipe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

  List<BrewingMethod> brewingMethods = await loadBrewingMethodsFromAssets();

  final appRouter = AppRouter();
  usePathUrlStrategy();

  if (kIsWeb) {
    runApp(CoffeeTimerApp(
      brewingMethods: brewingMethods,
      appRouter: appRouter,
    ));
  } else {
    runApp(CoffeeTimerApp(
      brewingMethods: brewingMethods,
      appRouter: appRouter,
      initialRoute: isFirstLaunch ? '/firstlaunch' : '/',
    ));

    // Mark 'firstLaunch' as false after the first launch
    if (isFirstLaunch) {
      await prefs.setBool('firstLaunch', false);
    }
  }
}

class CoffeeTimerApp extends StatelessWidget {
  final AppRouter appRouter;
  final List<BrewingMethod> brewingMethods;
  final String? initialRoute;

  const CoffeeTimerApp(
      {Key? key,
      required this.appRouter,
      required this.brewingMethods,
      this.initialRoute})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecipeProvider>(
          create: (context) => RecipeProvider(),
        ),
        Provider<List<BrewingMethod>>(create: (_) => brewingMethods),
      ],
      child: MaterialApp.router(
        routerDelegate: appRouter.delegate(
          initialDeepLink: initialRoute,
        ),
        routeInformationParser: appRouter.defaultRouteParser(),
        builder: (_, router) {
          return QuickActionsManager(
            child: router!,
            appRouter: appRouter,
          );
        },
        debugShowCheckedModeBanner: false,
        title: 'Coffee Timer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color.fromRGBO(121, 85, 72, 1),
            onPrimary: Colors.white,
            secondary: Colors.white,
            onSecondary: Color.fromRGBO(121, 85, 72, 1),
            error: Colors.red,
            onError: Colors.white,
            background: Colors.white,
            onBackground: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: kIsWeb ? 'Lato' : null,
        ),
      ),
    );
  }
}

Future<List<BrewingMethod>> loadBrewingMethodsFromAssets() async {
  String jsonString =
      await rootBundle.loadString('assets/data/brewing_methods.json');
  List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((json) => BrewingMethod.fromJson(json))
      .toList()
      .cast<BrewingMethod>();
}

class QuickActionsManager extends StatefulWidget {
  final Widget child;
  final AppRouter appRouter;

  QuickActionsManager({Key? key, required this.child, required this.appRouter})
      : super(key: key);

  @override
  _QuickActionsManagerState createState() => _QuickActionsManagerState();
}

class _QuickActionsManagerState extends State<QuickActionsManager> {
  QuickActions quickActions = QuickActions();

  @override
  void initState() {
    super.initState();
    // Set quick actions
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'action_last_recipe',
          localizedTitle: 'Open last recipe',
          icon: 'icon_coffee_cup'),
    ]);

    quickActions.initialize((shortcutType) async {
      if (shortcutType == 'action_last_recipe') {
        RecipeProvider recipeProvider =
            Provider.of<RecipeProvider>(context, listen: false);
        Recipe? mostRecentRecipe = await recipeProvider.getLastUsedRecipe();
        if (mostRecentRecipe != null) {
          widget.appRouter.push(RecipeDetailRoute(
              brewingMethodId: mostRecentRecipe.brewingMethodId,
              recipeId: mostRecentRecipe.id));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
