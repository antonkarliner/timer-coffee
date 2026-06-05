import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart'; // Ensure this import is correct
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:coffee_timer/services/notification_service.dart';
import '../providers/user_stat_provider.dart';
import '../providers/user_recipe_provider.dart'; // Import UserRecipeProvider
import '../theme/design_tokens.dart'; // Import design tokens for AppRadius
import '../utils/app_logger.dart'; // Import AppLogger
import '../utils/app_material_symbols.dart';
import '../widgets/base_buttons.dart';
import '../widgets/account_avatar_inline.dart';
import '../widgets/coffee_journey_card.dart';
import '../services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import 'pulse_screen.dart';
// Added import
// Import http package
// Import for RecipeCreationScreen
// Import AppDatabase and Recipe

@RoutePage()
class HubHomeScreen extends StatefulWidget {
  const HubHomeScreen({super.key});

  @override
  State<HubHomeScreen> createState() => _HubHomeScreenState();
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
    _coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    _userRecipeProvider = Provider.of<UserRecipeProvider>(
      context,
      listen: false,
    );
    _recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    _determineInitialUserId(); // Still needed for sync logic
  }

  Future<void> _determineInitialUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    // No need to call setState here as StreamBuilder handles UI updates
    _initialUserId = user?.id;
    AppLogger.debug('Initial User ID: $_initialUserId');
    if (user != null && !user.isAnonymous) {
      await _updateFcmToken();
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
          'User ID changed from $_initialUserId to $newUserId. Updating local recipe IDs...',
        );
        // Update local recipe IDs BEFORE calling the edge function or syncing
        await _userRecipeProvider.updateUserRecipeIdsAfterLogin(
          _initialUserId!,
          newUserId,
        );

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

      // Sync recipes first to satisfy FK constraints for stats
      if (newUserId != null) {
        await _databaseProvider.syncUserRecipes(newUserId);
        await _databaseProvider.syncImportedRecipes(newUserId);
      }

      // Reload recipes into the provider state after sync
      await _recipeProvider.fetchAllRecipes();

      // Stats rely on recipes being present locally
      await _userStatProvider.syncUserStats();

      // Coffee beans after stats (no FK on stats but keeps data fresh)
      await _coffeeBeansProvider.syncCoffeeBeans();
      AppLogger.debug('RecipeProvider state refreshed.');

      // Update FCM token after user ID transition
      // This ensures FCM tokens are associated with the new registered user ID
      if (newUserId != null) {
        AppLogger.debug('Updating FCM token after user ID transition...');
        await _updateFcmToken();
        AppLogger.info('FCM token updated successfully for new user ID');
      }

      // Returning user detection: auto-complete milestones based on synced data.
      await _reconcileMilestonesAfterSync();

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

  /// After login + sync, auto-complete milestones that the synced data proves
  /// the user has already achieved. Leaves undiscovered features unchecked.
  Future<void> _reconcileMilestonesAfterSync() async {
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    final database = Provider.of<AppDatabase>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await OnboardingReconciliationSnapshot.fromPersistence(
      database: database,
      prefs: prefs,
      isFirstLaunch: false,
      previousAppVersion: prefs.getString('previous_app_version'),
    );

    await onboarding.reconcileState(snapshot);

    AppLogger.debug(
      'Returning user milestones reconciled: '
      '${onboarding.completedMilestoneCount}/${OnboardingService.totalMilestones}',
    );
  }

  Future<void> _updateFcmToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !kIsWeb) {
      final notificationService = NotificationService.instance;
      final token = await notificationService.fcm.getToken();
      if (token != null) {
        await notificationService.fcm.storeFcmToken(user.id, token);
      }
      // Setup token refresh listener
      notificationService.fcm.onTokenRefresh((newToken) async {
        await notificationService.fcm.storeFcmToken(user.id, newToken);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight +
              AppSpacing.base,
        ),
        children: [
          const CoffeeJourneyCard(location: JourneyCardLocation.hub),
          _HubSection(
            title: l10n.hubSectionYourCoffee,
            children: [
              _HubListTile(
                identifier: 'brewDiary',
                label: l10n.brewdiary,
                icon: Icons.library_books,
                title: l10n.brewdiary,
                subtitle: l10n.hubBrewDiarySubtitle,
                onTap: () {
                  context.router.push(BrewDiaryRoute());
                },
              ),
              _HubListTile(
                identifier: 'stats',
                label: l10n.brewStats,
                icon: Icons.bar_chart,
                title: l10n.brewStats,
                subtitle: l10n.hubBrewStatsSubtitle,
                onTap: () {
                  context.router.push(StatsRoute());
                },
              ),
              _HubListTile(
                identifier: 'userRecipes',
                label: l10n.hubUserRecipesTitle,
                icon: Icons.bookmarks_outlined,
                title: l10n.hubUserRecipesTitle,
                subtitle: l10n.hubUserRecipesSubtitle,
                onTap: () {
                  context.router.push(const UserRecipeManagementRoute());
                },
              ),
            ],
          ),
          _HubSection(
            title: l10n.explore,
            children: [
              _HubListTile(
                identifier: 'pulse',
                label: l10n.pulseTitle,
                iconWidget: const VitalSignsIcon(),
                title: l10n.pulseTitle,
                subtitle: l10n.hubPulseSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PulseScreen()),
                  );
                },
              ),
              _HubListTile(
                identifier: 'roasters',
                label: l10n.roastersCatalogTitle,
                icon: Icons.store_outlined,
                title: l10n.roastersCatalogTitle,
                subtitle: l10n.hubRoastersSubtitle,
                onTap: () {
                  context.router.push(const RoastersRoute());
                },
              ),
            ],
          ),
          _HubSection(
            title: l10n.account,
            children: [_buildAccountTile(context, l10n)],
          ),
          _HubSection(
            title: l10n.hubSectionApp,
            children: [
              _HubListTile(
                identifier: 'settings',
                label: l10n.settings,
                icon: Icons.settings,
                title: l10n.settings,
                isCompact: true,
                onTap: () {
                  context.router.push(SettingsRoute());
                },
              ),
              _HubListTile(
                identifier: 'info',
                label: l10n.about,
                icon: Icons.info_outline,
                title: l10n.about,
                isCompact: true,
                onTap: () {
                  context.router.push(InfoRoute());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, AppLocalizations l10n) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        final isLoggedIn = session != null && !session.user.isAnonymous;

        if (isLoggedIn) {
          return _HubListTile(
            identifier: 'account',
            label: l10n.account,
            icon: Icons.account_circle,
            leading: const AccountAvatarInline(size: 24),
            title: l10n.account,
            subtitle: l10n.hubAccountSubtitle,
            onTap: () {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              AppLogger.debug(
                'Navigating to AccountRoute with userId: $userId',
              );
              if (userId != null) {
                context.router.push(AccountRoute(userId: userId));
              }
            },
          );
        }

        return _HubListTile(
          identifier: 'signIn',
          label: l10n.signInCreate,
          icon: Icons.login,
          title: l10n.signInCreate,
          subtitle: l10n.hubSignInCreateSubtitle,
          onTap: () => _showSignInOptions(context),
        );
      },
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
                AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                    backgroundColor: isDarkMode
                        ? Colors.white
                        : Colors.blueGrey.shade700,
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
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // Capture scaffold messenger

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
        'Could not find ID Token from generated credential.',
      );
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
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // Capture scaffold messenger

    try {
      bool didSignIn = true;
      if (kIsWeb) {
        await _webSignInWithGoogle();
      } else {
        didSignIn = await _nativeGoogleSignIn();
      }

      if (!didSignIn) {
        AppLogger.debug('Google sign-in canceled by user');
        return;
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
          SnackBar(content: Text(l10n.signInErrorGoogle)),
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

  Future<bool> _nativeGoogleSignIn() async {
    const webClientId =
        '158450410168-i70d1cqrp1kkg9abet7nv835cbf8hmfn.apps.googleusercontent.com';
    const iosClientId =
        '158450410168-8o2bk6r3e4ik8i413ua66bc50iug45na.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return false;
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

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

    return true;
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
            decoration: InputDecoration(hintText: l10n.emailHint),
          ),
          actions: <Widget>[
            AppTextButton(
              label: l10n.cancel,
              onPressed: () {
                Navigator.of(context).pop();
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            AppElevatedButton(
              label: l10n.sendOTP,
              onPressed: () {
                Navigator.of(context).pop();
                _signInWithEmail(context, emailController.text);
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // Capture scaffold messenger

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
                decoration: InputDecoration(hintText: l10n.otpHint2),
              ),
            ],
          ),
          actions: <Widget>[
            AppTextButton(
              label: l10n.cancel,
              onPressed: () {
                Navigator.of(context).pop();
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            AppElevatedButton(
              label: l10n.verify,
              onPressed: () {
                // Don't pop here, _verifyOTP will handle it if successful
                _verifyOTP(context, email, otpController.text);
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyOTP(
    BuildContext context,
    String email,
    String token,
  ) async {
    // Ensure context is valid before proceeding
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!; // Get localizations
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // Capture scaffold messenger
    final navigator = Navigator.of(context);

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      // Pop the OTP dialog regardless of success/failure of verification
      navigator.pop();

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
      if (navigator.canPop()) {
        navigator.pop();
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

class _HubSection extends StatelessWidget {
  const _HubSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              AppSpacing.xs,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: children),
        ],
      ),
    );
  }
}

class _HubListTile extends StatelessWidget {
  const _HubListTile({
    required this.identifier,
    required this.label,
    required this.title,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.leading,
    this.subtitle,
    this.isCompact = false,
  });

  final String identifier;
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: identifier,
      label: label,
      child: ListTile(
        dense: isCompact,
        visualDensity: isCompact ? VisualDensity.compact : null,
        leading: leading ?? iconWidget ?? Icon(icon),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
