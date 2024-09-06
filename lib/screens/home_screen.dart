import 'dart:convert';
import 'dart:io';
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
import '../app_router.gr.dart';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import '../purchase_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../providers/user_stat_provider.dart';

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
    return AutoTabsRouter.pageView(
      routes: const [
        BrewTabRoute(),
        HubTabRoute(),
      ],
      builder: (context, child, _) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          appBar: buildPlatformSpecificAppBar(),
          body: child,
          bottomNavigationBar: ConvexAppBar.builder(
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

    // Calculate the bottom padding
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

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
  late DatabaseProvider _databaseProvider;
  late UserStatProvider _userStatProvider;
  late CoffeeBeansProvider _coffeeBeansProvider;
  String? _initialUserId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    _userStatProvider = Provider.of<UserStatProvider>(context, listen: false);
    _coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    _determineInitialUserId();
  }

  Future<void> _determineInitialUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _initialUserId = user?.id;
      _currentUserId = user?.id;
      _isAnonymous = user == null || user.isAnonymous;
    });
    print('Initial User ID: $_initialUserId');
    print('Is Anonymous: $_isAnonymous');
    if (!_isAnonymous) {
      await _updateOneSignalExternalId();
    }
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isAnonymous = user == null || user.isAnonymous;
      _currentUserId = user?.id;
    });
    print('Current User ID: $_currentUserId');
    print('Is Anonymous: $_isAnonymous');
    if (!_isAnonymous) {
      await _updateOneSignalExternalId();
    }
  }

  Future<void> _syncDataAfterLogin() async {
    try {
      final newUser = Supabase.instance.client.auth.currentUser;
      final newUserId = newUser?.id;

      print('Initial User ID: $_initialUserId');
      print('New User ID: $newUserId');

      if (_initialUserId != null &&
          newUserId != null &&
          _initialUserId != newUserId) {
        print('Attempting to update user ID...');
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
      } else {
        print('User ID update not required');
      }

      await _databaseProvider.uploadUserPreferencesToSupabase();
      await _databaseProvider.fetchAndInsertUserPreferencesFromSupabase();
      await _userStatProvider.syncUserStats();
      await _coffeeBeansProvider.syncCoffeeBeans();
      print('Data synchronization completed successfully');
    } catch (e) {
      print('Error syncing user data: $e');
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing data: $e')),
      );
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
    return SafeArea(
      child: ListView(
        children: [
          if (_isAnonymous)
            Semantics(
              identifier: 'signIn',
              label: AppLocalizations.of(context)!.signInCreate,
              child: ListTile(
                leading: const Icon(Icons.login),
                title: Text(AppLocalizations.of(context)!.signInCreate),
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
                const SizedBox(height: 16),
                SignInButton(
                  isDarkMode ? Buttons.google : Buttons.googleDark,
                  text: AppLocalizations.of(context)!.signInWithGoogle,
                  onPressed: () {
                    Navigator.pop(context);
                    _signInWithGoogle(context);
                  },
                ),
                const SizedBox(height: 16),
                SignInButtonBuilder(
                  text: AppLocalizations.of(context)!.signInWithEmail,
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
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _nativeSignInWithApple();
      } else {
        await _supabaseSignInWithApple();
      }

      await _loadUserData(); // Reload user data after successful sign-in
      await _syncDataAfterLogin();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signInSuccessful)),
      );
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

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        await _webSignInWithGoogle();
      } else {
        await _nativeGoogleSignIn();
      }

      await _loadUserData(); // Reload user data after successful sign-in
      await _syncDataAfterLogin();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.signInSuccessfulGoogle)),
      );
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signInError)),
      );
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enterEmail),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.emailHint,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.sendOTP),
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
    _showOTPVerificationDialog(context, email);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'https://app.timer.coffee/',
      );
    } catch (e) {
      print('Error sending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.otpSendError)),
      );
    }
  }

  void _showOTPVerificationDialog(BuildContext context, String email) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enterOTP),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.otpSentMessage),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.otpHint2,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.verify),
              onPressed: () {
                Navigator.of(context).pop();
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
    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (res.session != null) {
        await _loadUserData();
        await _syncDataAfterLogin();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.signInSuccessfulEmail)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invalidOTP)),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      //ScaffoldMessenger.of(context).showSnackBar(
      //SnackBar(
      //content: Text(AppLocalizations.of(context)!.otpVerificationError)),
      //);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await OneSignal.logout(); // Logout from OneSignal
      await Supabase.instance.client.auth.signOut();
      await Supabase.instance.client.auth.signInAnonymously();
      _determineInitialUserId();
      await _loadUserData(); // Reload user data after sign-out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.signOutSuccessful)),
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
