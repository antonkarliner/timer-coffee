import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/env/env.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
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
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe_model.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart'; // Ensure this import is correct
import '../webhelper/web_helper.dart' as web;
import '../utils/icon_utils.dart';
import '../purchase_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../providers/user_stat_provider.dart';
import '../providers/user_recipe_provider.dart'; // Import UserRecipeProvider
import 'package:flutter_animate/flutter_animate.dart'; // Added import
import 'package:http/http.dart' as http; // Import http package
import '../screens/recipe_creation_screen.dart'; // Import for RecipeCreationScreen
import '../database/database.dart'
    show AppDatabase, Recipe; // Import AppDatabase and Recipe

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Locale initialLocale;
  bool _showBanner = false; // Banner flag
  String? _detectedCountry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      web.document.title = 'Timer.Coffee App';
      _fetchCountryAndBanner();
    }

    // Set up PurchaseManager callbacks
    PurchaseManager().setDeliverProductCallback(_showThankYouPopup);
    PurchaseManager().setPurchaseErrorCallback(_showErrorDialog);

    // Correctly obtain initialLocale from the Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure context is valid before accessing Provider
      if (mounted) {
        initialLocale = Provider.of<Locale>(context, listen: false);
        if (kIsWeb) {
          var recipeProvider =
              Provider.of<RecipeProvider>(context, listen: false);
          var tempLocale =
              const Locale('av'); // An example temporary locale for simulation
          recipeProvider.setLocale(tempLocale).then((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                // Check mounted again before accessing provider
                recipeProvider.setLocale(
                    initialLocale); // Revert to the initial app locale
              }
            });
          });
        }
      }
    });

    // Add post frame callback to check for recipes needing moderation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecipesNeedingModeration();
    });
  }

  Future<void> _checkRecipesNeedingModeration() async {
    if (!mounted) return; // Ensure the widget is still mounted

    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    // Get UserRecipeProvider instance
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    // No longer need RecipeProvider or appLocale here

    try {
      // Use the public method from DatabaseProvider
      final flaggedRecipes = await dbProvider.getRecipesNeedingModeration();

      if (flaggedRecipes.isNotEmpty && mounted) {
        // Fetch names and store brewingMethodId
        List<Map<String, String>> flaggedRecipeDetails = [];
        for (final recipe in flaggedRecipes) {
          // Fetch name using UserRecipeProvider
          final name = await userRecipeProvider.getUserRecipeName(recipe.id);
          if (name != null) {
            flaggedRecipeDetails.add({
              'id': recipe.id,
              'name': name,
              'brewingMethodId': recipe.brewingMethodId,
            });
          } else {
            // Handle case where name couldn't be fetched (optional)
            print("Could not fetch name for flagged recipe: ${recipe.id}");
            flaggedRecipeDetails.add({
              'id': recipe.id,
              'name': recipe.id, // Fallback to ID
              'brewingMethodId': recipe.brewingMethodId,
            });
          }
        }

        if (flaggedRecipeDetails.isNotEmpty && mounted) {
          final firstFlaggedRecipe = flaggedRecipeDetails.first;
          final recipeNames =
              flaggedRecipeDetails.map((r) => "'${r['name']}'").join(', ');
          final l10n = AppLocalizations.of(context)!; // Get localizations

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(l10n.moderationReviewNeededTitle),
                content: Text(l10n.moderationReviewNeededMessage(recipeNames)),
                actions: [
                  TextButton(
                    child: Text(l10n.dismiss),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(l10n.reviewRecipeButton),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Use details fetched earlier
                      context.router.push(RecipeDetailRoute(
                        recipeId: firstFlaggedRecipe['id']!,
                        brewingMethodId: firstFlaggedRecipe['brewingMethodId']!,
                      ));
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("Error checking for recipes needing moderation: $e");
      // Optionally show an error message
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PurchaseManager().setDeliverProductCallback(null);
    PurchaseManager().setPurchaseErrorCallback(null);
    super.dispose();
  }

  Future<void> _fetchCountryAndBanner() async {
    try {
      // Use HTTPS endpoint from country.is
      final response = await http.get(Uri.parse('https://api.country.is/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final detected = data['country']?.toString() ?? '';
        print('Detected country: $detected');
        if (mounted) {
          // Check mounted before setState
          setState(() {
            _detectedCountry = detected;
          });
        }

        // Read the target banner country from your Env file.
        final bannerCountry = Env.bannerCountry;
        print('Banner Country (env): $bannerCountry');

        if (bannerCountry.isNotEmpty && detected == bannerCountry) {
          if (mounted) {
            // Check mounted before setState
            setState(() {
              _showBanner = true;
            });
          }
        }
      } else {
        print('Failed to fetch country: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching country: $e');
    }
  }

  void _showThankYouPopup(PurchaseDetails details) {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!; // Get localizations
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.donationok),
            content: Text(l10n.donationtnx),
            actions: [
              TextButton(
                child: Text(l10n.ok),
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
      final l10n = AppLocalizations.of(context)!; // Get localizations
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.donationerr),
            content: Text(l10n.donationerrmsg),
            actions: [
              TextButton(
                child: Text(l10n.ok),
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
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return AutoTabsRouter.pageView(
      routes: const [
        BrewTabRoute(),
        HubTabRoute(),
      ],
      builder: (context, child, _) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          appBar: buildPlatformSpecificAppBar(),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Show banner only on web if _showBanner is true.
              if (kIsWeb && _showBanner)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Timer.Coffee stands with Palestine', // Skipped localization as requested
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                          width: 10), // Spacing between image and text.
                      // Display the image from the URL.
                      Image.network(
                        'https://i.ibb.co/4g4J6ZML/palectine-coffee.png',
                        height: 30, // Adjust height as needed.
                      ),
                    ],
                  ),
                ),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: ConvexAppBar.builder(
            count: 2,
            backgroundColor: Theme.of(context).colorScheme.onBackground,
            itemBuilder: CustomTabBuilder([
              TabItem(
                icon: Coffeico.bean,
                title: l10n.homescreenbrewcoffee,
              ),
              TabItem(
                icon: Icons.dashboard,
                title: l10n.homescreenmore,
              ),
            ], context),
            initialActiveIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
          ),
        );
      },
    );
  }

  PreferredSizeWidget buildPlatformSpecificAppBar() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoNavigationBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        middle: Text('Timer.Coffee', // Skipped localization as requested
            style: TextStyle(
                fontFamily: kIsWeb ? 'Lato' : null,
                color: Theme.of(context).appBarTheme.foregroundColor)),
      );
    } else {
      return AppBar(
        title: const Text('Timer.Coffee'), // Skipped localization as requested
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
    final allBrewingMethods = Provider.of<List<BrewingMethodModel>>(context);
    final l10n = AppLocalizations.of(context)!; // Get localizations

    // Determine which brewing methods have recipes
    final methodsWithRecipes = <String>{};
    for (var recipe in recipeProvider.recipes) {
      methodsWithRecipes.add(recipe.brewingMethodId);
    }

    // Get user preferences
    final shownIds = recipeProvider.shownBrewingMethodIds.value;
    final hiddenIds = recipeProvider.hiddenBrewingMethodIds.value;

    final filteredBrewingMethods = allBrewingMethods.where((method) {
      bool hasRecipes = methodsWithRecipes.contains(method.brewingMethodId);
      bool isShownByUser = shownIds.contains(method.brewingMethodId);
      bool isHiddenByUser = hiddenIds.contains(method.brewingMethodId);

      if (isShownByUser) return true;
      if (isHiddenByUser) return false;
      return hasRecipes;
    }).toList();

    // Calculate the bottom padding
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

    return SafeArea(
      child: Column(
        children: [
          buildFixedContent(context, recipeProvider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Divider(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              thickness: 0.7,
              height: 0,
              indent: 16.0,
              endIndent: 16.0,
            ),
          ),
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
                    title: Text(brewingMethod.brewingMethod,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      context.router.push(RecipeListRoute(
                          brewingMethodId: brewingMethod.brewingMethodId));
                    },
                  ),
                );
              },
              // Add padding to the bottom of the ListView
              padding: EdgeInsets.only(bottom: bottomPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFixedContent(
      BuildContext context, RecipeProvider recipeProvider) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return FutureBuilder<RecipeModel?>(
      future: recipeProvider.getLastUsedRecipe(),
      builder: (context, snapshot) {
        RecipeModel? mostRecentRecipe = snapshot.data;
        return Column(
          children: [
            Semantics(
              identifier: 'favoriteRecipes',
              label: l10n.favoriterecipes,
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(l10n.favoriterecipes),
                onTap: () {
                  context.router.push(const FavoriteRecipesRoute());
                },
              ),
            ),
            Semantics(
              identifier: 'createRecipe',
              label: l10n.createRecipe,
              child: ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.createRecipe),
                onTap: () {
                  context.router.push(RecipeCreationRoute());
                },
              ),
            ),
            if (mostRecentRecipe != null)
              Semantics(
                identifier: 'lastRecipe_${mostRecentRecipe.id}',
                label: '${l10n.lastrecipe}${mostRecentRecipe.name}',
                child: ListTile(
                  leading:
                      getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                  title: Text('${l10n.lastrecipe}${mostRecentRecipe.name}'),
                  onTap: () {
                    context.router.push(
                      RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id,
                      ),
                    );
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
  // Removed _isAnonymous state as StreamBuilder handles it
  late DatabaseProvider _databaseProvider;
  late UserStatProvider _userStatProvider;
  late CoffeeBeansProvider _coffeeBeansProvider;
  late UserRecipeProvider _userRecipeProvider;
  late RecipeProvider _recipeProvider;
  String? _initialUserId;
  // Removed _currentUserId as StreamBuilder provides session info

  @override
  void initState() {
    super.initState();
    _databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    _userStatProvider = Provider.of<UserStatProvider>(context, listen: false);
    _coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    _userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    _recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    _determineInitialUserId(); // Still needed for sync logic
  }

  Future<void> _determineInitialUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    // No need to call setState here as StreamBuilder handles UI updates
    _initialUserId = user?.id;
    print('Initial User ID: $_initialUserId');
    if (user != null && !user.isAnonymous) {
      await _updateOneSignalExternalId();
    }
  }

  // _loadUserData is no longer needed as StreamBuilder handles UI updates

  Future<void> _syncDataAfterLogin() async {
    // Ensure context is valid before proceeding
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get localizations

    try {
      final newUser = Supabase.instance.client.auth.currentUser;
      final newUserId = newUser?.id;

      print('Initial User ID: $_initialUserId');
      print('New User ID: $newUserId');

      if (_initialUserId != null &&
          newUserId != null &&
          _initialUserId != newUserId) {
        print(
            'User ID changed from $_initialUserId to $newUserId. Updating local recipe IDs...');
        // Update local recipe IDs BEFORE calling the edge function or syncing
        await _userRecipeProvider.updateUserRecipeIdsAfterLogin(
            _initialUserId!, newUserId);

        print('Attempting to update user ID via Edge Function...');
        // Invoke the Supabase Edge Function to update user ID
        final res = await Supabase.instance.client.functions.invoke(
          'update-id-after-signin',
          body: {'oldUserId': _initialUserId, 'newUserId': newUserId},
        );

        print('Edge Function Response: ${res.data}');

        if (res.status != 200) {
          throw Exception('Failed to update user ID: ${res.data}');
        }

        print('User ID updated successfully');
        // Update _initialUserId after successful sync/ID change
        _initialUserId = newUserId;
      } else {
        print('User ID update not required');
        // Ensure _initialUserId reflects the current user if it was null initially
        if (_initialUserId == null && newUserId != null) {
          _initialUserId = newUserId;
        }
      }

      await _databaseProvider.uploadUserPreferencesToSupabase();
      await _databaseProvider.fetchAndInsertUserPreferencesFromSupabase();
      await _userStatProvider.syncUserStats();
      await _coffeeBeansProvider.syncCoffeeBeans();

      // Sync user-created and imported recipes
      if (newUserId != null) {
        await _databaseProvider.syncUserRecipes(newUserId);
        await _databaseProvider.syncImportedRecipes(newUserId);
      }

      // Reload recipes into the provider state after sync
      await _recipeProvider.fetchAllRecipes();
      print('RecipeProvider state refreshed.');

      print('Data synchronization completed successfully');
    } catch (e) {
      print('Error syncing user data: $e');
      // Show an error message to the user
      if (mounted) {
        // Check mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSyncingData(e.toString()))),
        );
      }
    }
  }

  Future<void> _updateOneSignalExternalId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !kIsWeb) {
      await OneSignal.login(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return SafeArea(
      child: ListView(
        children: [
          // Use StreamBuilder to listen to auth changes
          StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = snapshot.data?.session;
              // Consider logged in if session exists AND user is not anonymous
              final bool isLoggedIn =
                  session != null && !session.user.isAnonymous;

              if (isLoggedIn) {
                // Show Account button if logged in
                return Semantics(
                  identifier: 'account',
                  label: l10n.account, // Use new localization key
                  child: ListTile(
                    leading:
                        const Icon(Icons.account_circle), // Or appropriate icon
                    title: Text(l10n.account), // Use new localization key
                    onTap: () => context.router.push(
                        const AccountRoute()), // Navigate to AccountScreen
                  ),
                );
              } else {
                // Show Sign In button if not logged in (or anonymous)
                return Semantics(
                  identifier: 'signIn',
                  label: l10n.signInCreate,
                  child: ListTile(
                    leading: const Icon(Icons.login),
                    title: Text(l10n.signInCreate),
                    onTap: () => _showSignInOptions(
                        context), // This modal contains Apple Sign In
                  ),
                );
              }
            },
          ),
          Semantics(
            identifier: 'brewDiary',
            label: l10n.brewdiary,
            child: ListTile(
              leading: const Icon(Icons.library_books),
              title: Text(l10n.brewdiary),
              onTap: () {
                context.router.push(const BrewDiaryRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'beansScreen',
            child: ListTile(
              leading: const Icon(Coffeico.bag_with_bean),
              title: Text(l10n.myBeans),
              onTap: () {
                context.router.push(const CoffeeBeansRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'statsScreen',
            label: l10n.statsscreen,
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(l10n.statsscreen),
              onTap: () {
                context.router.push(StatsRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'settings',
            label: l10n.settings,
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settings),
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
    final l10n = AppLocalizations.of(context)!; // Get localizations

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
                // Conditionally show Apple Sign In
                if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                  SignInButton(
                    isDarkMode ? Buttons.apple : Buttons.appleDark,
                    text: l10n.signInWithApple,
                    onPressed: () {
                      Navigator.pop(context);
                      _signInWithApple(context);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                SignInButton(
                  isDarkMode ? Buttons.google : Buttons.googleDark,
                  text: l10n.signInWithGoogle,
                  onPressed: () {
                    Navigator.pop(context);
                    _signInWithGoogle(context);
                  },
                ),
                const SizedBox(height: 16),
                SignInButtonBuilder(
                  text: l10n.signInWithEmail,
                  icon: Icons.email,
                  onPressed: () {
                    Navigator.pop(context);
                    _showEmailSignInDialog(context);
                  },
                  backgroundColor:
                      isDarkMode ? Colors.white : Colors.blueGrey.shade700,
                  textColor: isDarkMode ? Colors.black87 : Colors.white,
                  iconColor: isDarkMode ? Colors.black87 : Colors.white,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signInWithApple(BuildContext context) async {
    // Ensure context is valid before proceeding
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture scaffold messenger

    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _nativeSignInWithApple();
      } else {
        await _supabaseSignInWithApple();
      }

      // No need to call _loadUserData here, StreamBuilder handles UI update
      await _syncDataAfterLogin(); // Sync data after login attempt
      // Check mounted again before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.signInSuccessful)),
        );
      }
    } catch (e) {
      print('Error signing in with Apple: $e');
      // Check mounted again before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.signInError)),
        );
      }
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

  Future<void> _signInWithGoogle(BuildContext context) async {
    // Ensure context is valid before proceeding
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture scaffold messenger

    try {
      if (kIsWeb) {
        await _webSignInWithGoogle();
      } else {
        await _nativeGoogleSignIn();
      }

      // No need to call _loadUserData here, StreamBuilder handles UI update
      await _syncDataAfterLogin(); // Sync data after login attempt
      // Check mounted again before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.signInSuccessfulGoogle)),
        );
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Check mounted again before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.signInError)),
        );
      }
    }
  }

  Future<void> _webSignInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'https://app.timer.coffee/',
    );
  }

  Future<void> _nativeGoogleSignIn() async {
    const webClientId =
        '158450410168-i70d1cqrp1kkg9abet7nv835cbf8hmfn.apps.googleusercontent.com';
    const iosClientId =
        '158450410168-8o2bk6r3e4ik8i413ua66bc50iug45na.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  void _showEmailSignInDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final l10n = AppLocalizations.of(context)!; // Get localizations

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.enterEmail),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: l10n.emailHint,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.sendOTP),
              onPressed: () {
                Navigator.of(context).pop();
                _signInWithEmail(context, emailController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithEmail(BuildContext context, String email) async {
    // Ensure context is valid before proceeding
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture scaffold messenger

    _showOTPVerificationDialog(context, email);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'https://app.timer.coffee/',
      );
    } catch (e) {
      print('Error sending OTP: $e');
      // Check mounted again before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.otpSendError)),
        );
      }
    }
  }

  void _showOTPVerificationDialog(BuildContext context, String email) {
    final TextEditingController otpController = TextEditingController();
    final l10n = AppLocalizations.of(context)!; // Get localizations

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.enterOTP),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.otpSentMessage),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.otpHint2,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.verify),
              onPressed: () {
                // Don't pop here, _verifyOTP will handle it if successful
                _verifyOTP(context, email, otpController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyOTP(
      BuildContext context, String email, String token) async {
    // Ensure context is valid before proceeding
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture scaffold messenger

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      // Pop the OTP dialog regardless of success/failure of verification
      Navigator.of(context).pop();

      if (res.session != null) {
        // No need to call _loadUserData here, StreamBuilder handles UI update
        await _syncDataAfterLogin(); // Sync data after successful verification
        // Check mounted again before showing SnackBar
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.signInSuccessfulEmail)),
          );
        }
      } else {
        // Check mounted again before showing SnackBar
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.invalidOTP)),
          );
        }
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      // Pop the OTP dialog if it wasn't popped due to an exception before this point
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      // Check mounted again before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.otpVerificationError)),
        );
      }
    }
  }

  // Removed _signOut method as it's now handled in AccountScreen
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
