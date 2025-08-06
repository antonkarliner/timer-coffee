import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../widgets/recipe_detail/authentication_dialogs.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/database_provider.dart';
import '../providers/user_stat_provider.dart';

// Enum for sign-in method
enum SignInMethod { apple, google, email, cancel }

/// Authentication service that handles all sign-in operations
/// Provides static methods for easy integration across the app
class AuthenticationService {
  /// Prompts the user to sign in with a modal bottom sheet
  /// Returns true if sign-in was successful, false otherwise
  static Future<bool> promptSignIn(BuildContext context) async {
    print("DEBUG: AuthenticationService.promptSignIn() called");
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String? initialUserId =
        Supabase.instance.client.auth.currentUser?.id; // Store initial ID

    print("DEBUG: Showing sign-in modal with direct execution");
    final SignInMethod? chosenMethod = await showModalBottomSheet<SignInMethod>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0,
                16.0 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l10n.signInRequiredTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l10n.signInRequiredBodyShare, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                  SignInButton(
                    isDarkMode ? Buttons.apple : Buttons.appleDark,
                    text: l10n.signInWithApple,
                    onPressed: () => Navigator.pop(context, SignInMethod.apple),
                  ),
                  const SizedBox(height: 16),
                ],
                SignInButton(
                  isDarkMode ? Buttons.google : Buttons.googleDark,
                  text: l10n.signInWithGoogle,
                  onPressed: () => Navigator.pop(context, SignInMethod.google),
                ),
                const SizedBox(height: 16),
                SignInButtonBuilder(
                  text: l10n.signInWithEmail,
                  icon: Icons.email,
                  onPressed: () => Navigator.pop(context, SignInMethod.email),
                  backgroundColor:
                      isDarkMode ? Colors.white : Colors.blueGrey.shade700,
                  textColor: isDarkMode ? Colors.black87 : Colors.white,
                  iconColor: isDarkMode ? Colors.black87 : Colors.white,
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: Text(l10n.dialogCancel),
                  onPressed: () => Navigator.pop(context, SignInMethod.cancel),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    print("DEBUG: Sign-in modal closed with method: $chosenMethod");

    if (!context.mounted) return false;

    try {
      bool signInSuccess = false;
      switch (chosenMethod) {
        case SignInMethod.apple:
          print("DEBUG: Executing Apple sign-in");
          await signInWithApple();
          signInSuccess = true;
          break;
        case SignInMethod.google:
          print("DEBUG: Executing Google sign-in");
          await signInWithGoogle();
          signInSuccess = true;
          break;
        case SignInMethod.email:
          print("DEBUG: Executing Email sign-in");
          if (context.mounted) {
            AuthenticationDialogs.showEmailSignInDialog(
              context,
              (email) => signInWithEmail(context, email),
            );
          }
          signInSuccess = true;
          break;
        case SignInMethod.cancel:
        default:
          print("DEBUG: Sign-in cancelled");
          return false;
      }

      if (signInSuccess) {
        await Future.delayed(const Duration(milliseconds: 500));
        final String? newUserId = Supabase.instance.client.auth.currentUser?.id;
        if (newUserId != null && newUserId != initialUserId) {
          if (context.mounted) {
            await syncDataAfterLogin(context, initialUserId, newUserId);
          }
          return true;
        } else if (newUserId != null) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print("DEBUG: Sign-in error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInError)),
        );
      }
      return false;
    }
  }

  /// Shows sign-in options and executes the chosen method
  /// Returns true if sign-in was successful, false otherwise
  static Future<bool> showSignInOptionsAndExecute(BuildContext context) async {
    print("DEBUG: AuthenticationService.showSignInOptionsAndExecute() called");
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    print("DEBUG: Showing second modal bottom sheet for sign-in execution");
    final SignInMethod? chosenMethod = await showModalBottomSheet<SignInMethod>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0,
                16.0 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l10n.signInCreate,
                    style:
                        Theme.of(context).textTheme.titleLarge), // Reuse title
                const SizedBox(height: 24),
                if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                  SignInButton(
                    isDarkMode ? Buttons.apple : Buttons.appleDark,
                    text: l10n.signInWithApple,
                    onPressed: () => Navigator.pop(context, SignInMethod.apple),
                  ),
                  const SizedBox(height: 16),
                ],
                SignInButton(
                  isDarkMode ? Buttons.google : Buttons.googleDark,
                  text: l10n.signInWithGoogle,
                  onPressed: () => Navigator.pop(context, SignInMethod.google),
                ),
                const SizedBox(height: 16),
                SignInButtonBuilder(
                  text: l10n.signInWithEmail,
                  icon: Icons.email,
                  onPressed: () => Navigator.pop(context, SignInMethod.email),
                  backgroundColor:
                      isDarkMode ? Colors.white : Colors.blueGrey.shade700,
                  textColor: isDarkMode ? Colors.black87 : Colors.white,
                  iconColor: isDarkMode ? Colors.black87 : Colors.white,
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: Text(l10n.dialogCancel),
                  onPressed: () => Navigator.pop(context, SignInMethod.cancel),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    try {
      switch (chosenMethod) {
        case SignInMethod.apple:
          await signInWithApple();
          return true;
        case SignInMethod.google:
          await signInWithGoogle();
          return true;
        case SignInMethod.email:
          if (context.mounted) {
            AuthenticationDialogs.showEmailSignInDialog(
              context,
              (email) => signInWithEmail(context, email),
            );
          }
          return true;
        case SignInMethod.cancel:
        default:
          return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInError)),
        );
      }
      return false;
    }
  }

  /// Signs in with Apple using the appropriate method based on platform
  static Future<void> signInWithApple() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _nativeSignInWithApple();
    } else {
      await _supabaseSignInWithApple();
    }
  }

  /// Native Apple sign-in for iOS/macOS
  static Future<void> _nativeSignInWithApple() async {
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

  /// Supabase Apple sign-in for web and other platforms
  static Future<void> _supabaseSignInWithApple() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'timercoffee://',
    );
  }

  /// Signs in with Google using the appropriate method based on platform
  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _webSignInWithGoogle();
    } else {
      await _nativeGoogleSignIn();
    }
  }

  /// Web Google sign-in
  static Future<void> _webSignInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: null,
    );
  }

  /// Native Google sign-in for mobile platforms
  static Future<void> _nativeGoogleSignIn() async {
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

  /// Signs in with email using OTP
  static Future<void> signInWithEmail(
      BuildContext context, String email) async {
    final l10n = AppLocalizations.of(context)!;

    AuthenticationDialogs.showOTPVerificationDialog(
      context,
      email,
      (email, token) => verifyOTP(context, email, token),
    );

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : 'timercoffee://',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.otpSendError)),
        );
      }
    }
  }

  /// Verifies OTP for email sign-in
  static Future<void> verifyOTP(
      BuildContext context, String email, String token) async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (res.session != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signInSuccessfulEmail)),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.invalidOTP)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.otpVerificationError)),
        );
      }
    }
  }

  /// Syncs data after successful login
  /// Handles user ID changes and synchronizes all user data
  static Future<void> syncDataAfterLogin(
      BuildContext context, String? oldUserId, String newUserId) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      print('DEBUG: syncDataAfterLogin - Initial User ID: $oldUserId');
      print('DEBUG: syncDataAfterLogin - New User ID: $newUserId');

      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final userRecipeProvider =
          Provider.of<UserRecipeProvider>(context, listen: false);
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      final userStatProvider =
          Provider.of<UserStatProvider>(context, listen: false);
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);

      if (oldUserId != null && oldUserId != newUserId) {
        print(
            'DEBUG: User ID changed from $oldUserId to $newUserId. Updating local recipe IDs...');
        // Update local recipe IDs BEFORE calling the edge function or syncing
        await userRecipeProvider.updateUserRecipeIdsAfterLogin(
            oldUserId, newUserId);

        print('DEBUG: Attempting to update user ID via Edge Function...');
        // Invoke the Supabase Edge Function to update user ID
        final res = await Supabase.instance.client.functions.invoke(
          'update-id-after-signin',
          body: {'oldUserId': oldUserId, 'newUserId': newUserId},
        );

        print('DEBUG: Edge Function Response: ${res.data}');

        if (res.status != 200) {
          throw Exception('Failed to update user ID: ${res.data}');
        }

        print('DEBUG: User ID updated successfully');
      } else {
        print('DEBUG: User ID update not required');
      }

      await dbProvider.uploadUserPreferencesToSupabase();
      await dbProvider.fetchAndInsertUserPreferencesFromSupabase();
      await userStatProvider.syncUserStats();
      await coffeeBeansProvider.syncCoffeeBeans();

      // Sync user-created and imported recipes
      await dbProvider.syncUserRecipes(newUserId);
      await dbProvider.syncImportedRecipes(newUserId);

      // Reload recipes into the provider state after sync
      await recipeProvider.fetchAllRecipes();
      print('DEBUG: RecipeProvider state refreshed.');

      print('DEBUG: Data synchronization completed successfully');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.syncSuccess)),
      );
    } catch (e) {
      print('DEBUG: Error syncing user data: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error syncing data: ${e.toString()}")),
      );
    }
  }
}
