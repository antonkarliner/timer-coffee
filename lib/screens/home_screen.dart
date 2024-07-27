import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:coffeico/coffeico.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return AutoTabsScaffold(
      routes: const [
        BrewTabRoute(),
        HubTabRoute(),
      ],
      appBarBuilder: (_, tabsRouter) => buildPlatformSpecificAppBar(),
      bottomNavigationBuilder: (_, tabsRouter) {
        return ConvexAppBar.builder(
          count: 2,
          backgroundColor: Theme.of(context).colorScheme.onBackground,
          itemBuilder: CustomTabBuilder([
            TabItem(
              icon: Coffeico.bean,
              title: AppLocalizations.of(context)!.homescreenbrewcoffee,
            ),
            TabItem(
              icon: Icons.dashboard,
              title: AppLocalizations.of(context)!.homescreenmore,
            ),
          ], context),
          onTap: (int i) => tabsRouter.setActiveIndex(i),
        );
      },
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

@RoutePage()
class BrewTabScreen extends StatelessWidget {
  const BrewTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: AutoRouter(),
        ),
        LaunchPopupWidget(),
      ],
    );
  }
}

@RoutePage()
class BrewingMethodsScreen extends StatelessWidget {
  const BrewingMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final brewingMethods = Provider.of<List<BrewingMethodModel>>(context);
    final filteredBrewingMethods =
        brewingMethods.where((method) => method.showOnMain).toList();

    return SafeArea(
      child: Column(
        children: [
          buildFixedContent(context, recipeProvider),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFixedContent(
      BuildContext context, RecipeProvider recipeProvider) {
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
}

@RoutePage()
class HubTabScreen extends AutoRouter {
  const HubTabScreen({Key? key}) : super(key: key);
}

@RoutePage()
class HubHomeScreen extends StatefulWidget {
  const HubHomeScreen({Key? key}) : super(key: key);

  @override
  _HubHomeScreenState createState() => _HubHomeScreenState();
}

class _HubHomeScreenState extends State<HubHomeScreen> {
  bool _isAnonymous = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isAnonymous = user?.isAnonymous ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          if (_isAnonymous)
            Semantics(
              identifier: 'signIn',
              label: AppLocalizations.of(context)!.signIn,
              child: ListTile(
                leading: const Icon(Icons.login),
                title: Text(AppLocalizations.of(context)!.signIn),
                onTap: () => _showSignInOptions(context),
              ),
            )
          else
            Semantics(
              identifier: 'signOut',
              label: AppLocalizations.of(context)!.signOut,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text(AppLocalizations.of(context)!.signOut),
                onTap: () => _signOut(context),
              ),
            ),
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
            identifier: 'beansScreen',
            child: ListTile(
              leading: const Icon(Coffeico.bag_with_bean),
              title: Text(AppLocalizations.of(context)!.myBeans),
              onTap: () {
                context.router.push(const CoffeeBeansRoute());
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

  void _showSignInOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0,
                16.0 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SignInButton(
                  isDarkMode ? Buttons.apple : Buttons.appleDark,
                  text: AppLocalizations.of(context)!.signInWithApple,
                  onPressed: () {
                    Navigator.pop(context);
                    _signInWithApple(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _nativeSignInWithApple();
      } else {
        await _supabaseSignInWithApple();
      }

      await _loadUserData(); // Reload user data after successful sign-in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signInSuccessful)),
      );
      // TODO: Implement logic to sync local data with the newly created account
    } catch (e) {
      print('Error signing in with Apple: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signInError)),
      );
    }
  }

  Future<void> _nativeSignInWithApple() async {
    final rawNonce = Supabase.instance.client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
          'Could not find ID Token from generated credential.');
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> _supabaseSignInWithApple() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? 'https://app.timer.coffee/' : 'timercoffee://',
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      await _loadUserData(); // Reload user data after sign-out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully signed out')),
      );
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
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
