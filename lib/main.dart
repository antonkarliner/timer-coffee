import 'dart:async'; // Import for StreamSubscription
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Import for In-App Purchase
import './models/brewing_method.dart';
import './providers/recipe_provider.dart';
import './providers/theme_provider.dart'; // Import ThemeProvider
import './app_router.dart';
import './app_router.gr.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import './models/recipe.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './visual/color_shemes.dart';
import './providers/snow_provider.dart';
import 'widgets/global_snow_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.remove();

  // Initialize In-App Purchase
  InAppPurchase.instance.restorePurchases();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;
  String themeModeString = prefs.getString('themeMode') ?? 'system';
  ThemeMode themeMode = ThemeMode.values.firstWhere(
    (e) => e.toString().split('.').last == themeModeString,
    orElse: () => ThemeMode.system,
  );
  String? savedLocale = prefs.getString('locale');
  Locale initialLocale = savedLocale != null
      ? Locale(savedLocale.split('_')[0])
      : WidgetsBinding.instance.window.locale;

  List<BrewingMethod> brewingMethods = await loadBrewingMethodsFromAssets();

  final appRouter = AppRouter();
  usePathUrlStrategy();

  runApp(CoffeeTimerApp(
    brewingMethods: brewingMethods,
    appRouter: appRouter,
    locale: initialLocale,
    themeMode: themeMode, // Pass the theme mode
  ));

  if (isFirstLaunch) {
    await prefs.setBool('firstLaunch', false);
  }
}

class CoffeeTimerApp extends StatelessWidget {
  final AppRouter appRouter;
  final List<BrewingMethod> brewingMethods;
  final String? initialRoute;
  final Locale locale;
  final ThemeMode themeMode; // Add this line

  const CoffeeTimerApp({
    Key? key,
    required this.appRouter,
    required this.brewingMethods,
    this.initialRoute,
    required this.locale,
    required this.themeMode, // Update constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecipeProvider>(
          create: (_) => RecipeProvider(locale),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(themeMode), // Initialize with ThemeMode
        ),
        ChangeNotifierProvider<SnowEffectProvider>(
          // Add SnowEffectProvider
          create: (_) => SnowEffectProvider(),
        ),
        Provider<List<BrewingMethod>>(create: (_) => brewingMethods),
      ],
      child: Consumer2<ThemeProvider, SnowEffectProvider>(
        builder: (context, themeProvider, snowProvider, child) {
          return MaterialApp.router(
            locale: Provider.of<RecipeProvider>(context)
                .currentLocale, // Use the locale from RecipeProvider
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
              Locale('de'),
              Locale('fr'),
              Locale('es'),
              Locale('ja'),
              Locale('zh'),
              Locale('ar'),
              Locale('pt'),
              Locale('pl'),
            ],
            routerDelegate: appRouter.delegate(
              initialDeepLink: initialRoute,
            ),
            routeInformationParser: appRouter.defaultRouteParser(),
            builder: (context, router) => Stack(
              children: [
                QuickActionsManager(
                  child: router!,
                  appRouter: appRouter,
                ),
                GlobalSnowOverlay(isSnowing: snowProvider.isSnowing),
              ],
            ),
            debugShowCheckedModeBanner: false,
            title: 'Coffee Timer App',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode, // Use ThemeMode from provider
          );
        },
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
  QuickActions quickActions = const QuickActions();
  StreamSubscription<List<PurchaseDetails>>? _subscription; // In-App Purchase

  @override
  void initState() {
    super.initState();

    // Initialize In-App Purchase
    _subscription = InAppPurchase.instance.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        final PurchaseDetails purchaseDetails = purchase;
        if (purchaseDetails.status == PurchaseStatus.purchased) {
          _deliverProduct(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });

    // Setup Quick Actions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupQuickActions();
    });
  }

  void setupQuickActions() {
    quickActions.setShortcutItems([
      ShortcutItem(
        type: 'action_last_recipe',
        localizedTitle: AppLocalizations.of(context)!.quickactionmsg,
        icon: 'icon_coffee_cup',
      ),
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

  // Deliver Product
  void _deliverProduct(PurchaseDetails purchaseDetails) {
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

  void _handleError(IAPError error) {
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
