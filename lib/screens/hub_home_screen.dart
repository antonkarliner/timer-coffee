import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart'; // Ensure this import is correct
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'user_recipe_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../providers/user_stat_provider.dart';
import '../providers/user_recipe_provider.dart'; // Import UserRecipeProvider
import '../theme/design_tokens.dart'; // Import design tokens for AppRadius
import '../utils/app_logger.dart'; // Import AppLogger
// Added import
// Import http package
// Import for RecipeCreationScreen
// Import AppDatabase and Recipe

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
    AppLogger.debug('Initial User ID: $_initialUserId');
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

      AppLogger.debug('Initial User ID: $_initialUserId');
      AppLogger.debug('New User ID: $newUserId');

      if (_initialUserId != null &&
          newUserId != null &&
          _initialUserId != newUserId) {
        AppLogger.debug(
            'User ID changed from $_initialUserId to $newUserId. Updating local recipe IDs...');
        // Update local recipe IDs BEFORE calling the edge function or syncing
        await _userRecipeProvider.updateUserRecipeIdsAfterLogin(
            _initialUserId!, newUserId);

        AppLogger.debug('Attempting to update user ID via Edge Function...');
        // Invoke the Supabase Edge Function to update user ID
        final res = await Supabase.instance.client.functions.invoke(
          'update-id-after-signin',
          body: {'oldUserId': _initialUserId, 'newUserId': newUserId},
        );

        AppLogger.debug('Edge Function Response: ${res.data}');

        if (res.status != 200) {
          throw Exception('Failed to update user ID: ${res.data}');
        }

        AppLogger.info('User ID updated successfully');
        // Update _initialUserId after successful sync/ID change
        _initialUserId = newUserId;
      } else {
        AppLogger.debug('User ID update not required');
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
      AppLogger.debug('RecipeProvider state refreshed.');

      AppLogger.info('Data synchronization completed successfully');
    } catch (e) {
      AppLogger.error('Error syncing user data', errorObject: e);
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
                    subtitle: Text(l10n.hubAccountSubtitle),
                    onTap: () {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      AppLogger.debug(
                          'Navigating to AccountRoute with userId: $userId');
                      if (userId != null) {
                        context.router.push(AccountRoute(userId: userId));
                      }
                    }, // Navigate to AccountScreen
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
                    subtitle: Text(l10n.hubSignInCreateSubtitle),
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
              subtitle: Text(l10n.hubBrewDiarySubtitle),
              onTap: () {
                context.router.push(const BrewDiaryRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'stats',
            label: l10n.brewStats,
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(l10n.brewStats),
              subtitle: Text(l10n.hubBrewStatsSubtitle),
              onTap: () {
                context.router.push(StatsRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'userRecipes',
            label: l10n.hubUserRecipesTitle,
            child: ListTile(
              leading: const Icon(Icons.bookmarks_outlined),
              title: Text(l10n.hubUserRecipesTitle),
              subtitle: Text(l10n.hubUserRecipesSubtitle),
              onTap: () {
                // Prefer auto_route generated route if available, fallback to MaterialPageRoute
                // Use generated route if present in app_router.gr.dart; otherwise fallback.
                // ignore: unused_catch_clause
                try {
                  // If a generated route exists, this will compile.
                  // ignore: undefined_class
                  context.router.push(const UserRecipeManagementRoute());
                } on Object {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UserRecipeManagementScreen(),
                    ),
                  );
                }
              },
            ),
          ),
          Semantics(
            identifier: 'settings',
            label: l10n.settings,
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settings),
              subtitle: Text(l10n.hubSettingsSubtitle),
              onTap: () {
                context.router.push(const SettingsRoute());
              },
            ),
          ),
          Semantics(
            identifier: 'info',
            label: l10n.about,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.about),
              subtitle: Text(l10n.hubAboutSubtitle),
              onTap: () {
                context.router.push(const InfoRoute());
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
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    SizedBox(height: AppSpacing.base),
                  ],
                  SignInButton(
                    isDarkMode ? Buttons.google : Buttons.googleDark,
                    text: l10n.signInWithGoogle,
                    onPressed: () {
                      Navigator.pop(context);
                      _signInWithGoogle(context);
                    },
                  ),
                  SizedBox(height: AppSpacing.base),
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
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
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
      AppLogger.error('Error signing in with Apple', errorObject: e);
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
      AppLogger.error('Error signing in with Google', errorObject: e);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
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
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      AppLogger.error('Error sending OTP', errorObject: e);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
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
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      AppLogger.error('Error verifying OTP', errorObject: e);
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
