import 'dart:async';
import 'dart:io';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/input_validator.dart';
import '../widgets/base_buttons.dart';
import '../widgets/recipe_detail/authentication_dialogs.dart';
import 'analytics_service.dart';
import 'auth/native_auth_credentials.dart';
import 'notification_service.dart';
import 'onboarding_service.dart';

enum SignInMethod { apple, google, email, cancel }

@visibleForTesting
class PostSignInSteps {
  const PostSignInSteps({
    required this.updateRecipeIds,
    required this.migrate,
    required this.syncData,
    required this.registerFcmToken,
    required this.reconcileMilestones,
    this.onDataSyncError,
  });

  final Future<void> Function(String oldUserId, String newUserId)
  updateRecipeIds;
  final Future<void> Function(String oldUserId, String newUserId) migrate;
  final Future<void> Function() syncData;
  final Future<void> Function() registerFcmToken;
  final Future<void> Function() reconcileMilestones;
  final void Function(Object error)? onDataSyncError;
}

class _SignInSession {
  const _SignInSession({
    required this.oldUserId,
    required this.oldAccessToken,
    required this.source,
    required this.l10n,
    required this.scaffoldMessenger,
    required this.navigator,
    required this.databaseProvider,
    required this.userRecipeProvider,
    required this.recipeProvider,
    required this.userStatProvider,
    required this.coffeeBeansProvider,
    required this.onboardingService,
    required this.database,
  });

  final String? oldUserId;
  final String? oldAccessToken;
  final String source;
  final AppLocalizations l10n;
  final ScaffoldMessengerState? scaffoldMessenger;
  final NavigatorState navigator;
  final DatabaseProvider? databaseProvider;
  final UserRecipeProvider? userRecipeProvider;
  final RecipeProvider? recipeProvider;
  final UserStatProvider? userStatProvider;
  final CoffeeBeansProvider? coffeeBeansProvider;
  final OnboardingService? onboardingService;
  final AppDatabase? database;
}

/// Authentication service that handles all sign-in operations.
class AuthenticationService {
  static const _webRedirect = 'https://app.timer.coffee/';
  static const _nativeRedirect = 'timercoffee://';

  /// Prompts the user to sign in with a modal bottom sheet.
  ///
  /// Returns the same immediate result as the previous flow. In particular,
  /// choosing email can return `true` while the email-code flow is still open.
  static Future<bool> promptSignIn(
    BuildContext context, {
    String? title,
    String? bodyText,
    String source = 'unknown',
  }) async {
    AppLogger.debug('AuthenticationService.promptSignIn() called');

    // Capture every context-bound dependency before the first await. Email
    // verification can finish after the screen that opened this flow is gone.
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final databaseProvider = _maybeProvider<DatabaseProvider>(context);
    final userRecipeProvider = _maybeProvider<UserRecipeProvider>(context);
    final recipeProvider = _maybeProvider<RecipeProvider>(context);
    final userStatProvider = _maybeProvider<UserStatProvider>(context);
    final coffeeBeansProvider = _maybeProvider<CoffeeBeansProvider>(context);
    final onboardingService = _maybeProvider<OnboardingService>(context);
    final database = _maybeProvider<AppDatabase>(context);

    final migrationSession = await captureAnonymousMigrationSession();
    if (!context.mounted) return false;

    final session = _SignInSession(
      oldUserId: migrationSession.userId,
      oldAccessToken: migrationSession.accessToken,
      source: source,
      l10n: l10n,
      scaffoldMessenger: scaffoldMessenger,
      navigator: navigator,
      databaseProvider: databaseProvider,
      userRecipeProvider: userRecipeProvider,
      recipeProvider: recipeProvider,
      userStatProvider: userStatProvider,
      coffeeBeansProvider: coffeeBeansProvider,
      onboardingService: onboardingService,
      database: database,
    );

    _track('sign_in_prompt_shown', {'source': source});
    final chosenMethod = await showModalBottomSheet<SignInMethod>(
      context: context,
      builder: (sheetContext) {
        // Full width: without it the sheet shrinks to its content.
        return SizedBox(
          width: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title ?? l10n.signInRequiredTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    bodyText ?? l10n.signInRequiredBodyShare,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                    SignInButton(
                      isDarkMode ? Buttons.apple : Buttons.appleDark,
                      text: l10n.signInWithApple,
                      onPressed: () =>
                          Navigator.pop(sheetContext, SignInMethod.apple),
                    ),
                    const SizedBox(height: AppSpacing.base),
                  ],
                  SignInButton(
                    isDarkMode ? Buttons.google : Buttons.googleDark,
                    text: l10n.signInWithGoogle,
                    onPressed: () =>
                        Navigator.pop(sheetContext, SignInMethod.google),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  SignInButtonBuilder(
                    text: l10n.signInWithEmail,
                    icon: Icons.email,
                    onPressed: () =>
                        Navigator.pop(sheetContext, SignInMethod.email),
                    backgroundColor: isDarkMode
                        ? Colors.white
                        : Colors.blueGrey.shade700,
                    textColor: isDarkMode ? Colors.black87 : Colors.white,
                    iconColor: isDarkMode ? Colors.black87 : Colors.white,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AppTextButton(
                    label: l10n.dialogCancel,
                    onPressed: () =>
                        Navigator.pop(sheetContext, SignInMethod.cancel),
                    isFullWidth: false,
                    height: AppButton.heightSmall,
                    padding: AppButton.paddingSmall,
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
              ),
            ),
          ),
        );
      },
    );

    AppLogger.debug('Sign-in modal closed with method: $chosenMethod');
    if (chosenMethod == null || chosenMethod == SignInMethod.cancel) {
      return false;
    }

    final method = chosenMethod.name;
    _track('sign_in_method_chosen', {'source': source, 'method': method});

    switch (chosenMethod) {
      case SignInMethod.apple:
        try {
          await signInWithApple();
        } catch (error) {
          final cancelled =
              error is SignInWithAppleAuthorizationException &&
              error.code == AuthorizationErrorCode.canceled;
          _trackSignInFailed(
            session,
            method: method,
            stage: 'provider',
            reason: cancelled ? 'cancelled' : 'error',
          );
          AppLogger.error('Error signing in with Apple', errorObject: error);
          if (!cancelled) {
            _showSnackBar(session, l10n.signInError);
          }
          return false;
        }
        break;
      case SignInMethod.google:
        try {
          final didSignIn = await signInWithGoogle();
          if (!didSignIn) {
            _trackSignInFailed(
              session,
              method: method,
              stage: 'provider',
              reason: 'cancelled',
            );
            return false;
          }
        } catch (error) {
          _trackSignInFailed(
            session,
            method: method,
            stage: 'provider',
            reason: 'error',
          );
          AppLogger.error('Error signing in with Google', errorObject: error);
          _showSnackBar(session, l10n.signInErrorGoogle);
          return false;
        }
        break;
      case SignInMethod.email:
        if (!session.navigator.mounted) return false;
        AuthenticationDialogs.showEmailSignInDialog(
          session.navigator.context,
          (email) => unawaited(_signInWithEmail(session, email)),
          onCancel: () => _trackSignInFailed(
            session,
            method: method,
            stage: 'code_send',
            reason: 'cancelled',
          ),
        );
        break;
      case SignInMethod.cancel:
        return false;
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    final newUser = Supabase.instance.client.auth.currentUser;
    if (chosenMethod != SignInMethod.email &&
        !kIsWeb &&
        newUser != null &&
        newUser.id != session.oldUserId) {
      await _completeSignIn(session, method);
      return true;
    }

    return newUser != null;
  }

  /// Captures the anonymous user and access token used for data migration.
  static Future<({String? userId, String? accessToken})>
  captureAnonymousMigrationSession() async {
    final auth = Supabase.instance.client.auth;
    final user = auth.currentUser;
    if (user == null || !user.isAnonymous) {
      return (userId: null, accessToken: null);
    }

    var authSession = auth.currentSession;
    final expiresAt = authSession?.expiresAt;
    final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expiresAt != null && expiresAt <= nowInSeconds + 600) {
      try {
        final response = await auth.refreshSession();
        authSession = response.session ?? auth.currentSession;
      } catch (error) {
        AppLogger.error(
          'Failed to refresh anonymous session before sign-in',
          errorObject: error,
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
      accessToken: authSession?.user.id == user.id
          ? authSession?.accessToken
          : null,
    );
  }

  static Future<void> signInWithApple() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      final tokens = await const NativeAuthCredentials().apple();
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: tokens.idToken,
        nonce: tokens.rawNonce,
      );
      return;
    }

    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? _webRedirect : _nativeRedirect,
    );
  }

  static Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirect,
      );
      return true;
    }

    final tokens = await const NativeAuthCredentials().google();
    if (tokens == null) return false;
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return true;
  }

  /// Starts the email-code flow directly for legacy callers.
  static Future<void> signInWithEmail(
    BuildContext context,
    String email,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final validatedEmail = InputValidator.validateAndSanitizeEmail(email);
    if (validatedEmail == null) {
      if (scaffoldMessenger != null && scaffoldMessenger.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.invalidEmailFormat)),
        );
      }
      _track('sign_in_failed', {
        'source': 'unknown',
        'method': 'email',
        'stage': 'code_send',
        'reason': 'invalid_email',
      });
      return;
    }

    final navigator = Navigator.of(context);
    final databaseProvider = _maybeProvider<DatabaseProvider>(context);
    final userRecipeProvider = _maybeProvider<UserRecipeProvider>(context);
    final recipeProvider = _maybeProvider<RecipeProvider>(context);
    final userStatProvider = _maybeProvider<UserStatProvider>(context);
    final coffeeBeansProvider = _maybeProvider<CoffeeBeansProvider>(context);
    final onboardingService = _maybeProvider<OnboardingService>(context);
    final database = _maybeProvider<AppDatabase>(context);
    final migrationSession = await captureAnonymousMigrationSession();

    final session = _SignInSession(
      oldUserId: migrationSession.userId,
      oldAccessToken: migrationSession.accessToken,
      source: 'unknown',
      l10n: l10n,
      scaffoldMessenger: scaffoldMessenger,
      navigator: navigator,
      databaseProvider: databaseProvider,
      userRecipeProvider: userRecipeProvider,
      recipeProvider: recipeProvider,
      userStatProvider: userStatProvider,
      coffeeBeansProvider: coffeeBeansProvider,
      onboardingService: onboardingService,
      database: database,
    );
    await _signInWithEmail(session, validatedEmail);
  }

  static Future<void> _signInWithEmail(
    _SignInSession session,
    String email,
  ) async {
    final validatedEmail = InputValidator.validateAndSanitizeEmail(email);
    if (validatedEmail == null) {
      _showSnackBar(session, session.l10n.invalidEmailFormat);
      _trackSignInFailed(
        session,
        method: 'email',
        stage: 'code_send',
        reason: 'invalid_email',
      );
      return;
    }

    if (!session.navigator.mounted) return;
    AuthenticationDialogs.showOTPVerificationDialog(
      session.navigator.context,
      validatedEmail,
      (submittedEmail, token) =>
          unawaited(_verifyOtp(session, submittedEmail, token)),
      onCancel: () => _trackSignInFailed(
        session,
        method: 'email',
        stage: 'code_verify',
        reason: 'cancelled',
      ),
    );

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: validatedEmail,
        emailRedirectTo: _webRedirect,
      );
    } catch (error) {
      AppLogger.error('Error sending OTP', errorObject: error);
      if (session.navigator.mounted && session.navigator.canPop()) {
        session.navigator.pop();
      }
      _showSnackBar(session, session.l10n.otpSendError);
      _trackSignInFailed(
        session,
        method: 'email',
        stage: 'code_send',
        reason: 'error',
      );
    }
  }

  static Future<void> _verifyOtp(
    _SignInSession session,
    String email,
    String token,
  ) async {
    final sanitizedEmail = InputValidator.sanitizeInput(email);
    if (session.navigator.mounted && session.navigator.canPop()) {
      session.navigator.pop();
    }

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: sanitizedEmail,
        token: token,
        type: OtpType.email,
      );
      if (response.session == null) {
        _showSnackBar(session, session.l10n.invalidOTP);
        _trackSignInFailed(
          session,
          method: 'email',
          stage: 'code_verify',
          reason: 'invalid_code',
        );
        return;
      }

      await _completeSignIn(session, 'email');
    } on AuthException catch (error) {
      AppLogger.error('Error verifying OTP', errorObject: error);
      final invalidCode = _isInvalidOrExpiredOtp(error);
      _showSnackBar(
        session,
        invalidCode
            ? session.l10n.invalidOTP
            : session.l10n.otpVerificationError,
      );
      _trackSignInFailed(
        session,
        method: 'email',
        stage: 'code_verify',
        reason: invalidCode ? 'invalid_code' : 'error',
      );
    } catch (error) {
      AppLogger.error('Error verifying OTP', errorObject: error);
      _showSnackBar(session, session.l10n.otpVerificationError);
      _trackSignInFailed(
        session,
        method: 'email',
        stage: 'code_verify',
        reason: 'error',
      );
    }
  }

  static bool _isInvalidOrExpiredOtp(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    return code.contains('invalid') ||
        code.contains('expired') ||
        message.contains('invalid') ||
        message.contains('expired');
  }

  static Future<void> _completeSignIn(
    _SignInSession session,
    String method,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final newUserId = user.id;

    final steps = PostSignInSteps(
      updateRecipeIds: (oldUserId, migratedUserId) async {
        final provider = session.userRecipeProvider;
        if (provider == null) {
          throw StateError('UserRecipeProvider is unavailable');
        }
        await provider.updateUserRecipeIdsAfterLogin(oldUserId, migratedUserId);
      },
      migrate: (oldUserId, migratedUserId) async {
        final response = await Supabase.instance.client.functions.invoke(
          'update-id-after-signin',
          body: {
            'oldUserId': oldUserId,
            'newUserId': migratedUserId,
            'oldAccessToken': ?session.oldAccessToken,
          },
        );
        if (response.status != 200) {
          throw Exception(
            'Failed to update user ID (status ${response.status})',
          );
        }
      },
      syncData: () async {
        final databaseProvider = session.databaseProvider;
        final recipeProvider = session.recipeProvider;
        final userStatProvider = session.userStatProvider;
        final coffeeBeansProvider = session.coffeeBeansProvider;
        if (databaseProvider == null ||
            recipeProvider == null ||
            userStatProvider == null ||
            coffeeBeansProvider == null) {
          throw StateError('Post-sign-in providers are unavailable');
        }
        await databaseProvider.uploadUserPreferencesToSupabase();
        await databaseProvider.fetchAndInsertUserPreferencesFromSupabase();
        await databaseProvider.syncUserRecipes(newUserId);
        await databaseProvider.syncImportedRecipes(newUserId);
        await recipeProvider.fetchAllRecipes();
        await userStatProvider.syncUserStats();
        await coffeeBeansProvider.syncCoffeeBeans();
      },
      registerFcmToken: registerFcmTokenForCurrentUser,
      reconcileMilestones: () => _reconcileMilestonesAfterSync(session),
      onDataSyncError: (error) => _showSnackBar(
        session,
        session.l10n.errorSyncingData(error.toString()),
      ),
    );

    try {
      await runPostSignIn(
        steps: steps,
        oldUserId: session.oldUserId,
        newUserId: newUserId,
        source: session.source,
        method: method,
        userCreatedAt: DateTime.tryParse(user.createdAt),
      );
    } catch (error) {
      // Migration, data sync, and FCM failures are handled by the seam. The
      // only remaining production step is milestone reconciliation.
      AppLogger.error(
        'Failed to reconcile milestones after sign-in',
        errorObject: error,
      );
    }

    final successMessage = switch (method) {
      'google' => session.l10n.signInSuccessfulGoogle,
      'email' => session.l10n.signInSuccessfulEmail,
      _ => session.l10n.signInSuccessful,
    };
    _showSnackBar(session, successMessage);
  }

  @visibleForTesting
  static Future<void> runPostSignIn({
    required PostSignInSteps steps,
    required String? oldUserId,
    required String newUserId,
    required String source,
    required String method,
    required DateTime? userCreatedAt,
    DateTime? now,
  }) async {
    var migrated = false;
    if (oldUserId != null && oldUserId != newUserId) {
      // A failed local rename must not skip the server-side migration.
      try {
        await steps.updateRecipeIds(oldUserId, newUserId);
      } catch (error) {
        AppLogger.error(
          'Failed to rename anonymous recipes after sign-in',
          errorObject: error,
        );
        _track('sign_in_sync_failed', {'source': source, 'step': 'recipe_ids'});
      }
      try {
        await steps.migrate(oldUserId, newUserId);
        migrated = true;
      } catch (error) {
        AppLogger.error(
          'Failed to migrate anonymous user data after sign-in',
          errorObject: error,
        );
        _track('sign_in_sync_failed', {'source': source, 'step': 'migration'});
      }
    }

    final referenceTime = now ?? DateTime.now();
    final accountAge = userCreatedAt == null
        ? null
        : referenceTime.difference(userCreatedAt).abs();
    _track('sign_in_completed', {
      'source': source,
      'method': method,
      'is_new_account':
          accountAge != null && accountAge <= const Duration(minutes: 5),
      'migrated': migrated,
    });

    try {
      await steps.syncData();
    } catch (error) {
      AppLogger.error('Error syncing user data', errorObject: error);
      _track('sign_in_sync_failed', {'source': source, 'step': 'data_sync'});
      steps.onDataSyncError?.call(error);
    }

    try {
      await steps.registerFcmToken();
    } catch (error) {
      AppLogger.error(
        'Failed to update FCM token after sign-in',
        errorObject: error,
      );
    }

    await steps.reconcileMilestones();
  }

  /// Registers the current user's FCM token without affecting sign-in sync.
  static Future<void> registerFcmTokenForCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || kIsWeb) return;

      final notificationService = NotificationService.instance;
      final token = await notificationService.fcm.getToken();
      if (token != null) {
        await notificationService.fcm.storeFcmToken(user.id, token);
      }
      notificationService.fcm.onTokenRefresh((newToken) async {
        await notificationService.fcm.storeFcmToken(user.id, newToken);
      });
    } catch (error) {
      AppLogger.error(
        'Failed to register FCM token for current user',
        errorObject: error,
      );
    }
  }

  static Future<void> _reconcileMilestonesAfterSync(
    _SignInSession session,
  ) async {
    final database = session.database;
    final onboardingService = session.onboardingService;
    if (database == null || onboardingService == null) {
      throw StateError('Milestone reconciliation providers are unavailable');
    }
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await OnboardingReconciliationSnapshot.fromPersistence(
      database: database,
      prefs: prefs,
      isFirstLaunch: false,
      previousAppVersion: prefs.getString('previous_app_version'),
    );
    await onboardingService.reconcileState(snapshot);
    AppLogger.debug(
      'Returning user milestones reconciled: '
      '${onboardingService.completedMilestoneCount}/'
      '${OnboardingService.totalMilestones}',
    );
  }

  static T? _maybeProvider<T>(BuildContext context) {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  static void _showSnackBar(_SignInSession session, String message) {
    final messenger = session.scaffoldMessenger;
    if (messenger != null && messenger.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static void _trackSignInFailed(
    _SignInSession session, {
    required String method,
    required String stage,
    required String reason,
  }) {
    _track('sign_in_failed', {
      'source': session.source,
      'method': method,
      'stage': stage,
      'reason': reason,
    });
  }

  static void _track(String name, Map<String, dynamic> properties) {
    AnalyticsService.maybeInstance?.track(name, properties: properties);
  }
}
