import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'auth/native_auth_credentials.dart';
import '../utils/input_validator.dart';
import '../utils/app_logger.dart';
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
  static Future<bool> promptSignIn(
    BuildContext context, {
    String? bodyText,
  }) async {
    AppLogger.debug("AuthenticationService.promptSignIn() called");
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final migrationSession = await captureAnonymousMigrationSession();
    if (!context.mounted) return false;
    final initialUserId = migrationSession.userId;
    final initialAccessToken = migrationSession.accessToken;

    AppLogger.debug("Showing sign-in modal with direct execution");
    final SignInMethod? chosenMethod = await showModalBottomSheet<SignInMethod>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16.0,
              16.0,
              16.0,
              16.0 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.signInRequiredTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  bodyText ?? l10n.signInRequiredBodyShare,
                  textAlign: TextAlign.center,
                ),
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
                  backgroundColor: isDarkMode
                      ? Colors.white
                      : Colors.blueGrey.shade700,
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

    AppLogger.debug("Sign-in modal closed with method: $chosenMethod");

    if (!context.mounted) return false;

    try {
      bool signInSuccess = false;
      switch (chosenMethod) {
        case SignInMethod.apple:
          AppLogger.debug("Executing Apple sign-in");
          await signInWithApple();
          signInSuccess = true;
          break;
        case SignInMethod.google:
          AppLogger.debug("Executing Google sign-in");
          signInSuccess = await signInWithGoogle();
          if (!signInSuccess) {
            AppLogger.debug("Google sign-in cancelled");
            return false;
          }
          break;
        case SignInMethod.email:
          AppLogger.debug("Executing Email sign-in");
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
          AppLogger.debug("Sign-in cancelled");
          return false;
      }

      if (signInSuccess) {
        await Future.delayed(const Duration(milliseconds: 500));
        final String? newUserId = Supabase.instance.client.auth.currentUser?.id;
        if (newUserId != null && newUserId != initialUserId) {
          if (context.mounted) {
            await syncDataAfterLogin(
              context,
              initialUserId,
              newUserId,
              oldAccessToken: initialAccessToken,
            );
          }
          return true;
        } else if (newUserId != null) {
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error("Sign-in error", errorObject: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              chosenMethod == SignInMethod.google
                  ? l10n.signInErrorGoogle
                  : l10n.signInError,
            ),
          ),
        );
      }
      return false;
    }
  }

  /// Captures the current user as the source for `update-id-after-signin`,
  /// but only when that user is anonymous: a registered account must never be
  /// migrated into another one. Also returns the anonymous session's access
  /// token (refreshed if it expires within 10 minutes) as proof of the old
  /// session. Both fields are null for registered or signed-out users.
  static Future<({String? userId, String? accessToken})>
  captureAnonymousMigrationSession() async {
    final auth = Supabase.instance.client.auth;
    final user = auth.currentUser;
    if (user == null || !user.isAnonymous) {
      return (userId: null, accessToken: null);
    }

    var session = auth.currentSession;
    final expiresAt = session?.expiresAt;
    final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expiresAt != null && expiresAt <= nowInSeconds + 600) {
      try {
        final response = await auth.refreshSession();
        session = response.session ?? auth.currentSession;
      } catch (e) {
        AppLogger.error(
          'Failed to refresh anonymous session before sign-in',
          errorObject: e,
        );
      }
    }

    final currentUser = auth.currentUser;
    if (currentUser == null ||
        !currentUser.isAnonymous ||
        currentUser.id != user.id) {
      return (userId: null, accessToken: null);
    }

    return (
      userId: user.id,
      accessToken: session?.user.id == user.id ? session?.accessToken : null,
    );
  }

  /// Shows sign-in options and executes the chosen method
  /// Returns true if sign-in was successful, false otherwise
  static Future<bool> showSignInOptionsAndExecute(BuildContext context) async {
    AppLogger.debug(
      "AuthenticationService.showSignInOptionsAndExecute() called",
    );
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    AppLogger.debug(
      "DEBUG: Showing second modal bottom sheet for sign-in execution",
    );
    final SignInMethod? chosenMethod = await showModalBottomSheet<SignInMethod>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16.0,
              16.0,
              16.0,
              16.0 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.signInCreate,
                  style: Theme.of(context).textTheme.titleLarge,
                ), // Reuse title
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
                  backgroundColor: isDarkMode
                      ? Colors.white
                      : Colors.blueGrey.shade700,
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
          final didSignIn = await signInWithGoogle();
          if (!didSignIn) {
            return false;
          }
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
          SnackBar(
            content: Text(
              chosenMethod == SignInMethod.google
                  ? l10n.signInErrorGoogle
                  : l10n.signInError,
            ),
          ),
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
    final tokens = await const NativeAuthCredentials().apple();
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: tokens.idToken,
      nonce: tokens.rawNonce,
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
  static Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      await _webSignInWithGoogle();
      return true;
    } else {
      return await _nativeGoogleSignIn();
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
  static Future<bool> _nativeGoogleSignIn() async {
    final tokens = await const NativeAuthCredentials().google();
    if (tokens == null) return false;
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );

    return true;
  }

  /// Signs in with email using OTP
  static Future<void> signInWithEmail(
    BuildContext context,
    String email,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // Validate and sanitize email
    final String? validatedEmail = InputValidator.validateAndSanitizeEmail(
      email,
    );
    if (validatedEmail == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidEmailFormat)));
      }
      return;
    }

    AuthenticationDialogs.showOTPVerificationDialog(
      context,
      validatedEmail,
      (email, token) => verifyOTP(context, email, token),
    );

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: validatedEmail,
        emailRedirectTo: kIsWeb ? null : 'timercoffee://',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.otpSendError)));
      }
    }
  }

  /// Verifies OTP for email sign-in
  static Future<void> verifyOTP(
    BuildContext context,
    String email,
    String token,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // Sanitize email input
    final sanitizedEmail = InputValidator.sanitizeInput(email);
    Navigator.of(context).pop();

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: sanitizedEmail,
        token: token,
        type: OtpType.email,
      );

      if (res.session != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.signInSuccessfulEmail)));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.invalidOTP)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.otpVerificationError)));
      }
    }
  }

  /// Syncs data after successful login
  /// Handles user ID changes and synchronizes all user data
  static Future<void> syncDataAfterLogin(
    BuildContext context,
    String? oldUserId,
    String newUserId, {
    String? oldAccessToken,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      AppLogger.debug(
        'syncDataAfterLogin - Initial User ID: ${AppLogger.sanitize(oldUserId)}',
      );
      AppLogger.debug(
        'syncDataAfterLogin - New User ID: ${AppLogger.sanitize(newUserId)}',
      );

      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final userRecipeProvider = Provider.of<UserRecipeProvider>(
        context,
        listen: false,
      );
      final recipeProvider = Provider.of<RecipeProvider>(
        context,
        listen: false,
      );
      final userStatProvider = Provider.of<UserStatProvider>(
        context,
        listen: false,
      );
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );

      if (oldUserId != null && oldUserId != newUserId) {
        AppLogger.debug(
          'User ID changed from ${AppLogger.sanitize(oldUserId)} to ${AppLogger.sanitize(newUserId)}. Updating local recipe IDs...',
        );
        // Update local recipe IDs BEFORE calling the edge function or syncing
        await userRecipeProvider.updateUserRecipeIdsAfterLogin(
          oldUserId,
          newUserId,
        );

        AppLogger.debug('Attempting to update user ID via Edge Function...');
        try {
          final res = await Supabase.instance.client.functions.invoke(
            'update-id-after-signin',
            body: {
              'oldUserId': oldUserId,
              'newUserId': newUserId,
              'oldAccessToken': ?oldAccessToken,
            },
          );

          if (res.status != 200) {
            throw Exception('Failed to update user ID (status ${res.status})');
          }
        } catch (e) {
          AppLogger.error(
            'Failed to migrate anonymous user data after sign-in',
            errorObject: e,
          );
        }
      } else {
        AppLogger.debug('User ID update not required');
      }

      await dbProvider.uploadUserPreferencesToSupabase();
      await dbProvider.fetchAndInsertUserPreferencesFromSupabase();

      // Sync recipes first to satisfy FK constraints for stats
      await dbProvider.syncUserRecipes(newUserId);
      await dbProvider.syncImportedRecipes(newUserId);

      // Reload recipes into the provider state after sync
      await recipeProvider.fetchAllRecipes();

      // Stats rely on recipes being present locally
      await userStatProvider.syncUserStats();

      await coffeeBeansProvider.syncCoffeeBeans();
      AppLogger.debug('RecipeProvider state refreshed.');

      AppLogger.debug('Data synchronization completed successfully');
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.syncSuccess)));
    } catch (e) {
      AppLogger.error('Error syncing user data', errorObject: e);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.errorSyncingData(e.toString()))),
      );
    }
  }
}
