import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../providers/database_provider.dart'; // Keep this
import '../database/database.dart'; // Added for AppDatabase access via provider
import '../screens/preparation_screen.dart';
import '../screens/recipe_creation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import '../models/recipe_summary.dart';
import 'package:auto_route/auto_route.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../webhelper/web_helper.dart' as web;
import 'dart:io';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../widgets/roaster_logo.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/user_recipe_provider.dart'; // Keep this
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added for Supabase
import 'package:sign_in_button/sign_in_button.dart'; // Added for Sign In Buttons
import 'package:google_sign_in/google_sign_in.dart'; // Added for Google Sign In
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Added for Apple Sign In
import 'dart:convert'; // Added for jsonEncode
import 'package:crypto/crypto.dart'; // Added for sha256
import '../providers/user_stat_provider.dart'; // Added for sync
import 'package:http/http.dart'
    as http; // Added for sync? (Check if needed) - Might not be needed here
import 'package:intl/intl.dart'; // Added for Intl.getCurrentLocale

// Define enum at the top level or inside the class, not inside a method
enum SignInMethod { apple, google, email, cancel }

@RoutePage(name: 'RecipeDetailRoute')
class RecipeDetailScreen extends StatelessWidget {
  final String brewingMethodId;
  final String
      recipeId; // This is the ID passed in the route (could be usr-...)

  const RecipeDetailScreen({
    Key? key,
    @PathParam('brewingMethodId') required this.brewingMethodId,
    @PathParam('recipeId') required this.recipeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pass the potentially prefixed ID to the stateful widget
    return RecipeDetailBase(
      brewingMethodId: brewingMethodId,
      initialRecipeId: recipeId,
    );
  }
}

// The base widget that contains the actual implementation
class RecipeDetailBase extends StatefulWidget {
  final String? brewingMethodId;
  final String initialRecipeId; // The ID passed from the route
  final String? vendorId; // Keep vendorId if needed elsewhere

  const RecipeDetailBase({
    Key? key,
    this.brewingMethodId,
    required this.initialRecipeId,
    this.vendorId,
  }) : super(key: key);

  @override
  _RecipeDetailBaseState createState() => _RecipeDetailBaseState();
}

class _RecipeDetailBaseState extends State<RecipeDetailBase> {
  final TextEditingController _coffeeController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  late double initialRatio = 16.0; // Default ratio
  bool _editingCoffee = false;
  double? originalCoffee;
  double? originalWater;

  RecipeModel? _updatedRecipe; // The recipe model currently displayed
  String _brewingMethodName = "";
  String? selectedBeanUuid;
  String? selectedBeanName;

  @override
  void didUpdateWidget(covariant RecipeDetailBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecipeId != widget.initialRecipeId) {
      setState(() {
        _effectiveRecipeId = widget.initialRecipeId;
        _isLoading = true;
        _importCheckComplete = false;
        _errorMessage = null;
        _updatedRecipe = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performInitialRecipeCheck();
          _loadSelectedBean();
        }
      });
    }
  }

  // Sliders for recipe id 106
  int _sweetnessSliderPosition = 1;
  int _strengthSliderPosition = 2;
  int _coffeeChroniclerSliderPosition = 0;

  // Recipe-specific variables
  String? vendorId; // Keep this if needed

  // Roaster logo URLs
  String? originalRoasterLogoUrl;
  String? mirrorRoasterLogoUrl;

  // State for import/update logic
  bool _isLoading = true;
  bool _importCheckComplete = false;
  String?
      _effectiveRecipeId; // The ID used to load the recipe (might change after import)
  String? _errorMessage;
  bool _isSharing = false; // Flag to prevent double taps on share

  // --- Sign-in related methods (adapted from home_screen.dart) ---
  Future<bool> _promptSignIn(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? signedIn = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                    onPressed: () => Navigator.pop(
                        context, true), // Signal intent to sign in
                  ),
                  const SizedBox(height: 16),
                ],
                SignInButton(
                  isDarkMode ? Buttons.google : Buttons.googleDark,
                  text: l10n.signInWithGoogle,
                  onPressed: () =>
                      Navigator.pop(context, true), // Signal intent to sign in
                ),
                const SizedBox(height: 16),
                SignInButtonBuilder(
                  text: l10n.signInWithEmail,
                  icon: Icons.email,
                  onPressed: () =>
                      Navigator.pop(context, true), // Signal intent to sign in
                  backgroundColor:
                      isDarkMode ? Colors.white : Colors.blueGrey.shade700,
                  textColor: isDarkMode ? Colors.black87 : Colors.white,
                  iconColor: isDarkMode ? Colors.black87 : Colors.white,
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: Text(l10n.dialogCancel),
                  onPressed: () => Navigator.pop(context, false), // Cancelled
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (signedIn == true) {
      // User chose a sign-in method, now show the actual options again
      // This feels redundant, let's try initiating the sign-in directly
      // based on which button was conceptually pressed.
      // For simplicity here, let's just show the options again and let user tap.
      // A better implementation would pass the chosen method back.
      final String? initialUserId =
          Supabase.instance.client.auth.currentUser?.id; // Store initial ID

      final bool signInSuccess = await _showSignInOptionsAndExecute(context);

      if (signInSuccess) {
        // Wait a moment for Supabase auth state to potentially update
        await Future.delayed(const Duration(milliseconds: 500));
        final String? newUserId = Supabase.instance.client.auth.currentUser?.id;
        if (newUserId != null && newUserId != initialUserId) {
          print("Sign-in successful, syncing data...");
          await _syncDataAfterLogin(context, initialUserId, newUserId);
          return true; // Sign-in and sync successful
        } else if (newUserId != null) {
          print("User already signed in or ID didn't change.");
          return true; // Already signed in
        }
      }
      return false; // Sign-in failed or was cancelled
    }
    return false; // User cancelled the initial prompt
  }

  // Combine showing options and executing the chosen one
  Future<bool> _showSignInOptionsAndExecute(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Enum is now defined outside the method

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

    // Execute the chosen method
    try {
      switch (chosenMethod) {
        case SignInMethod.apple:
          await _signInWithApple(context);
          return true;
        case SignInMethod.google:
          await _signInWithGoogle(context);
          return true;
        case SignInMethod.email:
          _showEmailSignInDialog(context); // Fire-and-forget style
          // Since OTP verification happens asynchronously and we don't easily await it here,
          // return true optimistically. The sync logic in _promptSignIn will run
          // if the user eventually completes the OTP flow successfully.
          // A more complex implementation could use a Completer or callback.
          return true;
        case SignInMethod.cancel:
        default:
          return false;
      }
    } catch (e) {
      print('Error during sign-in execution: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signInError)),
      );
      return false;
    }
  }

  // --- Sign-in methods ---
  Future<void> _signInWithApple(BuildContext context) async {
    // Reusing the exact logic from home_screen.dart requires Supabase instance
    // Assuming Supabase is initialized globally
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _nativeSignInWithApple();
    } else {
      await _supabaseSignInWithApple();
    }
    // No sync here, handled by _promptSignIn caller
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
      redirectTo: kIsWeb ? null : 'timercoffee://', // Adjust redirect as needed
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (kIsWeb) {
      await _webSignInWithGoogle();
    } else {
      await _nativeGoogleSignIn();
    }
    // No sync here, handled by _promptSignIn caller
  }

  Future<void> _webSignInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: null, // Let Supabase handle redirect for web
    );
  }

  Future<void> _nativeGoogleSignIn() async {
    // IMPORTANT: You need to ensure these IDs are correct and match your setup
    const webClientId =
        '158450410168-i70d1cqrp1kkg9abet7nv835cbf8hmfn.apps.googleusercontent.com'; // Replace if necessary
    const iosClientId =
        '158450410168-8o2bk6r3e4ik8i413ua66bc50iug45na.apps.googleusercontent.com'; // Replace if necessary

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

  // --- Email Sign In ---
  void _showEmailSignInDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController emailController = TextEditingController();

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
              onPressed: () => Navigator.of(context).pop(),
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
    final l10n = AppLocalizations.of(context)!;
    _showOTPVerificationDialog(context, email); // Show OTP dialog immediately

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : 'timercoffee://', // Adjust redirect
      );
      // Don't show success here, wait for OTP verification
    } catch (e) {
      print('Error sending OTP: $e');
      // Pop the OTP dialog if OTP sending failed
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpSendError)),
      );
    }
  }

  void _showOTPVerificationDialog(BuildContext context, String email) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // User must explicitly verify or cancel
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
              onPressed: () => Navigator.of(context).pop(), // Close OTP dialog
            ),
            TextButton(
              child: Text(l10n.verify),
              onPressed: () {
                // Don't pop here, _verifyOTP will handle it
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
    final l10n = AppLocalizations.of(context)!;
    // Close the OTP dialog before showing snackbar
    Navigator.of(context).pop();

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (res.session != null) {
        // Sign in successful, sync will be handled by _promptSignIn caller
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInSuccessfulEmail)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidOTP)),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpVerificationError)),
      );
    }
  }

  // --- Data Sync Logic (adapted from home_screen.dart) ---
  Future<void> _syncDataAfterLogin(
      BuildContext context, String? oldUserId, String newUserId) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture scaffold messenger
    final l10n_sync =
        AppLocalizations.of(context)!; // Get localizations for sync messages

    // Show loading indicator or disable share button while syncing
    setState(() => _isSharing = true); // Use _isSharing to indicate loading

    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final userRecipeProvider =
          Provider.of<UserRecipeProvider>(context, listen: false);
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      final userStatProvider =
          Provider.of<UserStatProvider>(context, listen: false);
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);

      print('Sync started. Old User ID: $oldUserId, New User ID: $newUserId');

      if (oldUserId != null && oldUserId != newUserId) {
        print('User ID changed. Updating local recipe IDs...');
        await userRecipeProvider.updateUserRecipeIdsAfterLogin(
            oldUserId, newUserId);

        print('Attempting to update user ID via Edge Function...');
        try {
          final res = await Supabase.instance.client.functions.invoke(
            'update-id-after-signin',
            body: {'oldUserId': oldUserId, 'newUserId': newUserId},
          );
          print('Edge Function Response Status: ${res.status}');
          print('Edge Function Response Data: ${res.data}');
          if (res.status != 200) {
            print(
                'Warning: Edge function for ID update failed or returned non-200 status.');
            // Decide if this is critical. Maybe just log and continue sync?
          } else {
            print('Edge function for ID update successful.');
          }
        } catch (e) {
          print('Error calling update-id-after-signin Edge Function: $e');
          // Decide if this is critical. Maybe just log and continue sync?
        }
      } else {
        print('User ID update not required or old ID was null.');
      }

      // Perform the rest of the sync operations
      print('Syncing preferences...');
      await dbProvider.uploadUserPreferencesToSupabase();
      await dbProvider.fetchAndInsertUserPreferencesFromSupabase();
      print('Syncing stats...');
      await userStatProvider.syncUserStats();
      print('Syncing beans...');
      await coffeeBeansProvider.syncCoffeeBeans();
      print('Syncing user recipes...');
      await dbProvider.syncUserRecipes(newUserId);
      print('Syncing imported recipes...');
      await dbProvider.syncImportedRecipes(newUserId);

      // Reload recipes into the provider state after sync
      print('Refreshing recipe provider state...');
      await recipeProvider.fetchAllRecipes();

      print('Data synchronization completed successfully');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n_sync.syncSuccess)),
      );
    } catch (e) {
      print('Error syncing user data: $e');
      // TODO: Add localization for errorSyncingData (it exists in home_screen but might need regeneration)
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content:
                Text("Error syncing data: ${e.toString()}")), // Placeholder
      );
    } finally {
      // Hide loading indicator
      if (mounted) {
        // Check if widget is still mounted
        setState(() => _isSharing = false);
      }
    }
  }

  // --- End of Sign-in methods ---

  @override
  void initState() {
    super.initState();
    _effectiveRecipeId = widget.initialRecipeId; // Start with the initial ID
    // Use WidgetsBinding to ensure context is available for AppLocalizations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _brewingMethodName =
              AppLocalizations.of(context)?.unknownBrewingMethod ??
                  "Unknown Brewing Method";
        });
        _performInitialRecipeCheck(); // Start the check
        _loadSelectedBean();
      }
    });
  }

  Future<void> _performInitialRecipeCheck() async {
    print("DEBUG: _performInitialRecipeCheck started");
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _importCheckComplete = false;
      _errorMessage = null;
    });

    final String potentialImportId = widget.initialRecipeId;
    print("DEBUG: Checking recipe with ID: $potentialImportId");

    // Ensure context is valid before accessing AppLocalizations
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // Ensure context is valid before accessing Providers
    if (!mounted) return;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    final appDb = Provider.of<AppDatabase>(context, listen: false);

    print(
        "DEBUG: Current user: ${Supabase.instance.client.auth.currentUser?.id ?? "Not logged in"}");

    try {
      // 1. First check if recipe exists directly by ID in local database
      print("DEBUG: Step 1 - Checking if recipe exists locally by ID");
      RecipeModel? localRecipe =
          await recipeProvider.getRecipeById(potentialImportId);

      if (localRecipe != null) {
        // Recipe found directly by ID, use it
        print("DEBUG: Recipe found locally with ID: $potentialImportId");
        _effectiveRecipeId = potentialImportId;
        await _loadRecipeDetails(_effectiveRecipeId!);
      } else if (potentialImportId.startsWith('usr-')) {
        // 2. If not found directly and it's a user recipe ID, check if it exists as an import_id
        print(
            "DEBUG: Step 2 - Recipe not found locally. Checking if it exists as an import_id");
        final localRecipeByImportId =
            await appDb.recipesDao.getRecipeByImportId(potentialImportId);

        if (localRecipeByImportId != null) {
          // Recipe found by import_id, use the local ID
          print(
              "DEBUG: Recipe found locally as import with ID: ${localRecipeByImportId.id} (Import ID: $potentialImportId)");
          _effectiveRecipeId = localRecipeByImportId.id;
          await _loadRecipeDetails(_effectiveRecipeId!);
        } else {
          // 3. Not found locally at all, check Supabase for import
          print(
              "DEBUG: Step 3 - Recipe not found locally. Checking Supabase for import ID: $potentialImportId");

          // Check if we can access other tables to verify authentication
          print(
              "DEBUG: Testing Supabase access by querying brewing_methods table...");
          try {
            final testResponse = await Supabase.instance.client
                .from('brewing_methods')
                .select('brewing_method_id')
                .limit(1)
                .maybeSingle();
            print(
                "DEBUG: Supabase test query result: ${testResponse != null ? "Success" : "No data"}");
          } catch (e) {
            print("DEBUG: Supabase test query error: $e");
          }

          final metadata =
              await dbProvider.getPublicUserRecipeMetadata(potentialImportId);
          print(
              "DEBUG: Metadata response: ${metadata != null ? "Found" : "Not found"}");
          if (metadata != null) {
            print("DEBUG: Recipe metadata: $metadata");
          }

          if (!mounted) return; // Check mount status

          if (metadata != null) {
            // Recipe exists in Supabase - Ask user to import
            print("DEBUG: Recipe exists in Supabase, showing import dialog");
            final bool? wantsImport =
                await _showImportDialog(metadata['name'] ?? potentialImportId);
            if (!mounted) return; // Check mount status

            if (wantsImport == true) {
              print("DEBUG: User wants to import recipe");
              setState(() => _isLoading = true); // Show loading during import
              final fullData = await dbProvider
                  .fetchFullPublicUserRecipeData(potentialImportId);
              print(
                  "DEBUG: Full recipe data: ${fullData != null ? "Found" : "Not found"}");
              if (fullData != null) {
                print("DEBUG: Recipe data keys: ${fullData.keys.join(', ')}");
                print(
                    "DEBUG: Recipe has localizations: ${(fullData['user_recipe_localizations'] as List?)?.isNotEmpty ?? false}");
                print(
                    "DEBUG: Recipe has steps: ${(fullData['user_steps'] as List?)?.isNotEmpty ?? false}");
              }

              if (!mounted) return; // Check mount status

              if (fullData != null) {
                print("DEBUG: Importing recipe into local database");
                final String? newLocalId =
                    await userRecipeProvider.importSupabaseRecipe(fullData);
                print("DEBUG: Import result - new local ID: $newLocalId");

                if (!mounted) return; // Check mount status

                if (newLocalId != null) {
                  print("DEBUG: Recipe imported successfully, loading details");
                  _effectiveRecipeId = newLocalId; // Switch to the new local ID
                  // Refresh the main recipe list after successful import
                  await Provider.of<RecipeProvider>(context, listen: false)
                      .fetchAllRecipes();
                  await _loadRecipeDetails(
                      _effectiveRecipeId!); // Load the newly imported recipe
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.recipeImportSuccess)));

                  // --- Trigger immediate sync after import ---
                  print("DEBUG: Triggering immediate sync after import...");
                  final currentUser = Supabase.instance.client.auth.currentUser;
                  if (currentUser != null && !currentUser.isAnonymous) {
                    // Ensure context is still valid before accessing provider
                    if (mounted) {
                      try {
                        await Provider.of<DatabaseProvider>(context,
                                listen: false)
                            .syncUserRecipes(currentUser.id);
                        print("DEBUG: Immediate sync triggered successfully.");
                      } catch (syncError) {
                        print("DEBUG: Error during immediate sync: $syncError");
                        // Optionally show a message, but maybe not critical here
                      }
                    } else {
                      print(
                          "DEBUG: Context not mounted, skipping immediate sync.");
                    }
                  } else {
                    print(
                        "DEBUG: User not logged in or anonymous, skipping immediate sync.");
                  }
                  // --- End immediate sync ---
                } else {
                  print("DEBUG: Failed to save imported recipe");
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.recipeImportFailedSave)));
                  setState(() => _errorMessage = l10n.recipeImportFailedSave);
                }
              } else {
                print("DEBUG: Failed to fetch full recipe data");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.recipeImportFailedFetch)));
                setState(() => _errorMessage = l10n.recipeImportFailedFetch);
              }
              if (mounted) setState(() => _isLoading = false);
            } else {
              // User declined import
              print("DEBUG: User declined to import recipe");
              setState(() => _errorMessage = l10n.recipeNotImported);
            }
          } else {
            // Recipe not found in Supabase or not public
            print("DEBUG: Recipe not found in Supabase or not public");
            setState(() => _errorMessage = l10n.recipeNotFoundCloud);
          }
        }
      } else {
        // Not a user recipe ID and not found locally
        print("DEBUG: Not a user recipe ID and not found locally");
        setState(() => _errorMessage = l10n.recipeLoadErrorGeneric);
      }
    } catch (e) {
      print("DEBUG: Error during initial recipe check: $e");
      if (e is PostgrestException) {
        print("DEBUG: Postgrest error code: ${e.code}");
        print("DEBUG: Postgrest error message: ${e.message}");
        print("DEBUG: Postgrest error details: ${e.details}");
      }
      if (mounted) {
        setState(() => _errorMessage = l10n.recipeLoadErrorGeneric);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _importCheckComplete = true;
      });
    }
    print(
        "DEBUG: _performInitialRecipeCheck completed with errorMessage: $_errorMessage");
  }

  Future<bool?> _showUpdateDialog(String recipeName) async {
    // Ensure context is valid
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.recipeUpdateAvailableTitle),
          content: Text(l10n.recipeUpdateAvailableBody(recipeName)),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.dialogCancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(l10n.dialogUpdate),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showImportDialog(String recipeName) async {
    // Ensure context is valid
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.recipeImportTitle),
          content: Text(l10n.recipeImportBody(recipeName)),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.dialogCancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(l10n.dialogImport),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  // Modified to accept recipeId
  Future<void> _loadRecipeDetails(String recipeIdToLoad) async {
    print("DEBUG: _loadRecipeDetails started for ID: $recipeIdToLoad");
    if (!mounted) return;
    // No need for loading state here, _performInitialRecipeCheck handles it
    try {
      // Ensure context is valid before accessing Providers
      if (!mounted) return;
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      print("DEBUG: Fetching recipe model from provider");
      RecipeModel? recipeModel =
          await recipeProvider.getRecipeById(recipeIdToLoad); // Use parameter

      if (!mounted) return; // Check mount status after await

      if (recipeModel == null) {
        // If recipe is null even after import/check, show error
        print("DEBUG: Recipe model is null, showing error");
        setState(() {
          _errorMessage = l10n.recipeLoadErrorGeneric;
          _updatedRecipe = null;
        });
        return; // Stop execution here
      }

      print("DEBUG: Recipe model found: ${recipeModel.name}");
      print("DEBUG: Recipe vendor ID: ${recipeModel.vendorId}");
      print("DEBUG: Recipe brewing method ID: ${recipeModel.brewingMethodId}");
      print("DEBUG: Recipe has ${recipeModel.steps.length} steps");

      String brewingMethodName = l10n.unknownBrewingMethod;
      // Check mount status before another await
      if (!mounted) return;
      brewingMethodName = await recipeProvider
          .fetchBrewingMethodName(recipeModel.brewingMethodId);
      print("DEBUG: Brewing method name: $brewingMethodName");

      if (!mounted) return; // Check mount status after await

      setState(() {
        _brewingMethodName = brewingMethodName;
        _updatedRecipe = recipeModel;
        vendorId = recipeModel.vendorId; // Update vendorId if needed

        double customCoffee =
            recipeModel.customCoffeeAmount ?? recipeModel.coffeeAmount;
        double customWater =
            recipeModel.customWaterAmount ?? recipeModel.waterAmount;
        originalCoffee = customCoffee;
        originalWater = customWater;
        // Ensure amounts are positive before calculating ratio
        if (customCoffee > 0) {
          initialRatio = customWater / customCoffee;
        } else {
          initialRatio = 16.0; // Default if coffee amount is zero or invalid
        }
        _coffeeController.text = customCoffee.toString();
        _waterController.text = customWater.toString();

        // Reset sliders based on the loaded recipe
        _sweetnessSliderPosition = recipeModel.sweetnessSliderPosition ?? 1;
        _strengthSliderPosition = recipeModel.strengthSliderPosition ?? 2;
        _coffeeChroniclerSliderPosition =
            recipeModel.coffeeChroniclerSliderPosition ?? 0;

        // Update sliders specifically for known IDs (using effective ID)
        if (recipeIdToLoad == '106') {
          // Check against the ID used to load
          _sweetnessSliderPosition = recipeModel.sweetnessSliderPosition ?? 1;
          _strengthSliderPosition = recipeModel.strengthSliderPosition ?? 2;
        }
        if (recipeIdToLoad == '1002') {
          // Check against the ID used to load
          _coffeeChroniclerSliderPosition =
              recipeModel.coffeeChroniclerSliderPosition ?? 0;
        }
        _errorMessage = null; // Clear previous errors
      });
      print("DEBUG: Recipe details loaded successfully");
    } catch (e) {
      print("DEBUG: Error loading recipe details for ID $recipeIdToLoad: $e");
      if (e is PostgrestException) {
        print("DEBUG: Postgrest error code: ${e.code}");
        print("DEBUG: Postgrest error message: ${e.message}");
        print("DEBUG: Postgrest error details: ${e.details}");
      }
      if (mounted) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context)?.recipeLoadErrorGeneric ??
                  "Error loading recipe";
          _updatedRecipe = null; // Ensure no recipe is displayed on error
        });
      }
    }
  }

  Future<void> _loadSelectedBean() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('selectedBeanUuid');
    if (uuid != null) {
      // Ensure context is valid before accessing Providers
      if (!mounted) return;
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

      if (bean == null) {
        // Bean was deleted, clear the selection
        await prefs.remove('selectedBeanUuid');
        if (mounted) {
          setState(() {
            selectedBeanUuid = null;
            selectedBeanName = null;
            originalRoasterLogoUrl = null;
            mirrorRoasterLogoUrl = null;
          });
        }
        return;
      }

      String? originalUrl;
      String? mirrorUrl;
      if (bean.roaster != null) {
        if (!mounted) return; // Check mount status
        final databaseProvider =
            Provider.of<DatabaseProvider>(context, listen: false);
        final logoUrls =
            await databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
        originalUrl = logoUrls['original'];
        mirrorUrl = logoUrls['mirror'];
      }

      if (mounted) {
        setState(() {
          selectedBeanUuid = uuid;
          selectedBeanName = bean.name;
          originalRoasterLogoUrl = originalUrl;
          mirrorRoasterLogoUrl = mirrorUrl;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          selectedBeanUuid = null;
          selectedBeanName = null;
          originalRoasterLogoUrl = null;
          mirrorRoasterLogoUrl = null;
        });
      }
    }
  }

  void _openAddBeansPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCoffeeBeansWidget(
          onSelect: (String selectedBeanUuid) async {
            await _updateSelectedBean(selectedBeanUuid);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _updateSelectedBean(String? uuid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uuid != null) {
      await prefs.setString('selectedBeanUuid', uuid);
      // Ensure context is valid before accessing Providers
      if (!mounted) return;
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

      String? originalUrl;
      String? mirrorUrl;
      if (bean != null && bean.roaster != null) {
        if (!mounted) return; // Check mount status
        final databaseProvider =
            Provider.of<DatabaseProvider>(context, listen: false);
        final logoUrls =
            await databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
        originalUrl = logoUrls['original'];
        mirrorUrl = logoUrls['mirror'];
      }

      if (mounted) {
        setState(() {
          selectedBeanUuid = uuid;
          selectedBeanName = bean?.name;
          originalRoasterLogoUrl = originalUrl;
          mirrorRoasterLogoUrl = mirrorUrl;
        });
      }
    } else {
      await prefs.remove('selectedBeanUuid');
      if (mounted) {
        setState(() {
          selectedBeanUuid = null;
          selectedBeanName = null;
          originalRoasterLogoUrl = null;
          mirrorRoasterLogoUrl = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _updateAmounts(BuildContext context, RecipeModel updatedRecipe) {
    if (_coffeeController.text.isEmpty ||
        _waterController.text.isEmpty ||
        double.tryParse(_coffeeController.text.replaceAll(',', '.')) == null ||
        double.tryParse(_waterController.text.replaceAll(',', '.')) == null) {
      return;
    }

    double newCoffee =
        double.parse(_coffeeController.text.replaceAll(',', '.'));
    double newWater = double.parse(_waterController.text.replaceAll(',', '.'));

    // Ensure initialRatio is valid before using it
    if (initialRatio <= 0) {
      if (originalCoffee != null &&
          originalCoffee! > 0 &&
          originalWater != null) {
        initialRatio = originalWater! / originalCoffee!;
      } else {
        initialRatio = 16.0; // Fallback default
      }
    }

    if (_editingCoffee) {
      double newWaterAmount = newCoffee * initialRatio;
      _waterController.text = newWaterAmount.toStringAsFixed(1);
      newWater =
          newWaterAmount; // Update newWater to reflect the adjusted value
    } else {
      double newCoffeeAmount = newWater / initialRatio;
      _coffeeController.text = newCoffeeAmount.toStringAsFixed(1);
      newCoffee =
          newCoffeeAmount; // Update newCoffee to reflect the adjusted value
    }

    // For recipe id 1002, update slider position based on amounts (use effective ID)
    if (_effectiveRecipeId == '1002') {
      int newSliderPosition = _coffeeChroniclerSliderPosition;

      if (newCoffee <= 26 || newWater <= 416) {
        newSliderPosition = 0; // Standard
      } else if ((newCoffee > 26 && newCoffee < 37) ||
          (newWater > 416 && newWater < 592)) {
        newSliderPosition = 1; // Medium
      } else if (newCoffee >= 37 || newWater >= 592) {
        newSliderPosition = 2; // XL
      }

      if (newSliderPosition != _coffeeChroniclerSliderPosition) {
        setState(() {
          _coffeeChroniclerSliderPosition = newSliderPosition;
        });
      }
    }
  }

  // --- MODIFIED _onShare METHOD ---
  void _onShare(BuildContext context) async {
    if (_isSharing) return; // Prevent double taps

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String shareRecipeId = _effectiveRecipeId ??
        widget.initialRecipeId; // Use effective ID if available

    // Use _updatedRecipe for other details, but ensure it's not null
    if (_updatedRecipe == null) {
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text(l10n.recipeLoadErrorGeneric)));
      return;
    }
    if (!mounted) return;

    setState(() => _isSharing = true); // Start loading indicator

    try {
      // --- User Recipe Sharing Logic ---
      if (shareRecipeId.startsWith('usr-')) {
        // 1. Check Authentication
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null || currentUser.isAnonymous) {
          final signedIn = await _promptSignIn(context);
          if (!signedIn) {
            setState(() => _isSharing = false); // Stop loading
            return; // User cancelled sign-in
          }
          // Re-fetch current user after potential sign-in
          final updatedUser = Supabase.instance.client.auth.currentUser;
          if (updatedUser == null || updatedUser.isAnonymous) {
            // Should not happen if _promptSignIn returns true, but safety check
            scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(l10n.signInRequiredSnackbar)));
            setState(() => _isSharing = false);
            return;
          }
          // Proceed with the updatedUser's ID
        }

        // Ensure we have the latest user ID after potential sign-in/sync
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final expectedVendorId = 'usr-$userId';

        // 2. Fetch Recipe Data from Supabase
        print(
            "Fetching recipe $shareRecipeId for user $userId from Supabase...");
        final response = await Supabase.instance.client
            .from('user_recipes')
            .select('*, user_recipe_localizations(*), user_steps(*)')
            .eq('id', shareRecipeId)
            // .eq('vendor_id', expectedVendorId) // RLS should handle ownership check
            .maybeSingle();

        if (response == null) {
          print(
              "Recipe $shareRecipeId not found in Supabase or not owned by user $userId.");
          scaffoldMessenger.showSnackBar(SnackBar(
              content:
                  Text(l10n.recipeNotFoundCloud))); // Or a more specific error
          setState(() => _isSharing = false);
          return;
        }

        final recipeData = response as Map<String, dynamic>;
        final bool isAlreadyPublic =
            recipeData['ispublic'] == true; // Check if already public

        // Only perform moderation and update if not already public
        if (!isAlreadyPublic) {
          print(
              "Recipe $shareRecipeId is not public yet. Performing moderation and update...");
          final localizations =
              recipeData['user_recipe_localizations'] as List<dynamic>? ?? [];
          final steps = recipeData['user_steps'] as List<dynamic>? ?? [];

          // 3. Prepare Moderation Text
          // Combine name, description, and step descriptions. Prioritize current locale.
          final currentLocale = Intl.getCurrentLocale().split('_')[0];
          String combinedText = "";

          final currentLocalization = localizations.firstWhere(
            (loc) => loc['locale'] == currentLocale,
            orElse: () => localizations.isNotEmpty
                ? localizations.first
                : null, // Fallback to first locale
          );

          if (currentLocalization != null) {
            combinedText += "${currentLocalization['name'] ?? ''}\n";
            combinedText +=
                "${currentLocalization['short_description'] ?? ''}\n";
            combinedText += "${currentLocalization['grind_size'] ?? ''}\n";
          }

          final currentSteps =
              steps.where((step) => step['locale'] == currentLocale).toList();
          if (currentSteps.isEmpty && steps.isNotEmpty) {
            // Fallback to steps from the first available locale if current locale steps are missing
            final firstLocale = steps.first['locale'];
            currentSteps
                .addAll(steps.where((step) => step['locale'] == firstLocale));
          }

          for (var step in currentSteps) {
            combinedText += "${step['description'] ?? ''}\n";
          }

          combinedText = combinedText.trim();

          if (combinedText.isEmpty) {
            print(
                "Warning: No text content found for moderation for recipe $shareRecipeId.");
            // Decide how to handle: proceed without moderation or show error?
            // Let's proceed for now, but log it.
          } else {
            print("Calling content moderation for recipe $shareRecipeId...");
            // 4. Call Moderation Function
            final moderationResponse =
                await Supabase.instance.client.functions.invoke(
              'content-moderation-gemini',
              body: {'text': combinedText},
            );

            print("Moderation response status: ${moderationResponse.status}");
            print("Moderation response data: ${moderationResponse.data}");

            if (moderationResponse.status != 200 ||
                moderationResponse.data == null) {
              scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.moderationErrorFunction)));
              setState(() => _isSharing = false);
              return;
            }

            final moderationResult =
                moderationResponse.data as Map<String, dynamic>;
            if (moderationResult['safe'] != true) {
              final reason =
                  moderationResult['reason'] ?? l10n.moderationReasonDefault;
              // Show specific error dialog
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.moderationFailedTitle),
                  content: Text(l10n.moderationFailedBody(reason)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.ok))
                  ],
                ),
              );
              setState(() => _isSharing = false);
              return;
            }
            print("Moderation passed for recipe $shareRecipeId.");
          }

          // 5. Make Public (only if moderation passed and it wasn't already public)
          print("Setting recipe $shareRecipeId to public...");
          await Supabase.instance.client.from('user_recipes').update({
            'ispublic': true,
            'last_modified': DateTime.now().toUtc().toIso8601String()
          }).eq('id', shareRecipeId);
          // RLS ensures only the owner can do this

          print("Recipe $shareRecipeId successfully set to public.");
        } else {
          print(
              "Recipe $shareRecipeId is already public. Skipping moderation and update.");
        }
      } // --- End of User Recipe Sharing Logic ---

      // --- Actual Sharing ---
      // Improved sharePositionOrigin calculation for iPad support
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      Rect shareOrigin;
      if (box == null) {
        // Fallback to full screen rect
        final Size screenSize = MediaQuery.of(context).size;
        shareOrigin = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
      } else if (defaultTargetPlatform == TargetPlatform.iOS &&
          MediaQuery.of(context).size.shortestSide >= 768) {
        // Likely an iPad, center the share dialog on screen
        final Size screenSize = MediaQuery.of(context).size;
        final Offset center =
            Offset(screenSize.width / 2, screenSize.height / 2);
        shareOrigin = Rect.fromCenter(center: center, width: 1, height: 1);
      } else {
        // Default behavior using widget's bounding box
        shareOrigin = box.localToGlobal(Offset.zero) & box.size;
      }

      final String textToShare =
          'https://app.timer.coffee/recipes/${_updatedRecipe!.brewingMethodId}/$shareRecipeId';

      await SharePlus.instance.share(
        ShareParams(
          text: textToShare,
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (e, stacktrace) {
      print("Error during sharing process: $e");
      print(stacktrace);
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.shareErrorGeneric(e.toString()))));
    } finally {
      if (mounted) {
        // Check mount status before setting state
        setState(() => _isSharing = false); // Stop loading indicator
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until check is complete
    if (_isLoading || !_importCheckComplete) {
      return Scaffold(
        appBar:
            AppBar(leading: const BackButton()), // Basic AppBar while loading
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if something went wrong during the check/import
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // If check is complete but recipe is still null (shouldn't happen if error handling is right, but safety check)
    if (_updatedRecipe == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
            child: Text(AppLocalizations.of(context)?.recipeLoadErrorGeneric ??
                "Error loading recipe")),
      );
    }

    // --- Main Content Build ---
    RecipeModel recipe = _updatedRecipe!;
    final l10n = AppLocalizations.of(context)!; // Define l10n here

    if (kIsWeb) {
      web.document.title = l10n.recipeDetailWebTitle(recipe.name);
    }

    final double fabHeight = 76.0 + 16.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(context, recipe), // Pass the loaded recipe
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, fabHeight),
              child: SingleChildScrollView(
                child: _buildRecipeContent(
                    context, recipe), // Pass the loaded recipe
              ),
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: _buildFloatingActionButton(
                  context, recipe), // Pass the loaded recipe
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, RecipeModel recipe) {
    final l10n = AppLocalizations.of(context)!; // Define l10n here
    // Use _effectiveRecipeId for FavoriteButton and edit/copy logic
    final String idForActions = _effectiveRecipeId ?? widget.initialRecipeId;
    final bool isUserRecipe = idForActions.startsWith('usr-');

    return AppBar(
      leading: const BackButton(),
      title: Row(
        children: [
          getIconByBrewingMethod(recipe.brewingMethodId),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _brewingMethodName, // Already set in state
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      actions: [
        // Edit button only for user recipes (based on effective ID)
        if (isUserRecipe)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.tooltipEditRecipe,
            onPressed: () => _navigateToEditRecipe(
                context, recipe), // Pass current recipe model
          ),
        // Copy button for non-user recipes (based on effective ID)
        // Also check against effective ID for 106/1002 exclusion
        if (!isUserRecipe && idForActions != '106' && idForActions != '1002')
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: l10n.tooltipCopyRecipe,
            onPressed: () => _navigateToCopyRecipe(
                context, recipe), // Pass current recipe model
          ),
        // Share Button - Disable while sharing process is active
        IconButton(
          icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
              ? CupertinoIcons.share
              : Icons.share),
          tooltip: l10n.tooltipShareRecipe,
          onPressed: _isSharing
              ? null
              : () => _onShare(
                  context), // Disable onPressed when _isSharing is true
        ),
        FavoriteButton(recipeId: idForActions), // Use effective ID
      ],
    );
  }

  void _navigateToEditRecipe(BuildContext context, RecipeModel recipe) async {
    final l10n = AppLocalizations.of(context)!;
    if (recipe.isImported == true) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.editImportedRecipeTitle),
          content: Text(l10n.editImportedRecipeBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.editImportedRecipeButtonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.editImportedRecipeButtonCopy),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final userRecipeProvider =
            Provider.of<UserRecipeProvider>(context, listen: false);
        final newRecipeId = await userRecipeProvider.copyUserRecipe(recipe);
        if (newRecipeId != null) {
          final recipeProvider =
              Provider.of<RecipeProvider>(context, listen: false);
          final updatedRecipe = await recipeProvider.getRecipeById(newRecipeId);
          await userRecipeProvider.clearImportStatus(newRecipeId);
          if (updatedRecipe != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) =>
                        RecipeCreationScreen(recipe: updatedRecipe)))
                .then((_) async {
              if (_effectiveRecipeId != null) {
                await _loadRecipeDetails(_effectiveRecipeId!);
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.recipeLoadErrorGeneric)));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  l10n.recipeCopyError(l10n.recipeCopyErrorOperationFailed))));
        }
      }
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (context) => RecipeCreationScreen(recipe: recipe)))
          .then((_) async {
        if (_effectiveRecipeId != null) {
          await _loadRecipeDetails(_effectiveRecipeId!);
        }
      });
    }
  }

  Future<void> _navigateToCopyRecipe(
      BuildContext context, RecipeModel recipeToCopy) async {
    // Copy the currently displayed recipe model
    // Ensure context is valid before accessing Providers/ScaffoldMessenger
    if (!mounted) return;
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      final String? newRecipeId = await userRecipeProvider
          .copyUserRecipe(recipeToCopy); // Pass the model

      if (!mounted) return; // Check mount status after await

      if (newRecipeId != null) {
        await recipeProvider.fetchAllRecipes();
        if (!mounted) return; // Check mount status after await
        final RecipeModel? newRecipe =
            await recipeProvider.getRecipeById(newRecipeId);

        if (!mounted) return; // Check mount status after await

        if (newRecipe != null) {
          scaffoldMessenger
              .showSnackBar(SnackBar(content: Text(l10n.recipeCopySuccess)));
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => RecipeCreationScreen(recipe: newRecipe)),
          );
        } else {
          scaffoldMessenger.showSnackBar(SnackBar(
              content:
                  Text(l10n.recipeCopyError(l10n.recipeCopyErrorLoadingEdit))));
        }
      } else {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                l10n.recipeCopyError(l10n.recipeCopyErrorOperationFailed))));
      }
    } catch (e) {
      // Check mount status before showing SnackBar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.recipeCopyError(e.toString()))));
      }
      print("Error copying recipe from detail screen: $e");
    }
  }

  Widget _buildRecipeContent(BuildContext context, RecipeModel recipe) {
    final loc = AppLocalizations.of(context)!;
    String formattedBrewTime = recipe.brewTime != null
        ? '${recipe.brewTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${recipe.brewTime.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : loc.notProvided;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildRichText(context,
            recipe.shortDescription), // Pass effective ID for link logic
        const SizedBox(height: 16),
        _buildBeanSelectionRow(context),
        const SizedBox(height: 16),
        _buildAmountFields(context, recipe),
        const SizedBox(height: 16),
        Text(
            '${loc.watertemp}: ${recipe.waterTemp?.toStringAsFixed(1) ?? loc.notProvided}ºC / ${(recipe.waterTemp != null) ? ((recipe.waterTemp! * 9 / 5) + 32).toStringAsFixed(1) : loc.notProvided}ºF'),
        const SizedBox(height: 16),
        Text('${loc.grindsize}: ${recipe.grindSize}'),
        const SizedBox(height: 16),
        Text('${loc.brewtime}: $formattedBrewTime'),
        const SizedBox(height: 16),
        // Use effective ID for slider logic
        if (_effectiveRecipeId == '1002') _buildCoffeeChroniclerSlider(context),
        if (_effectiveRecipeId == '106') _buildSliders(context),
        if (_effectiveRecipeId != '106' && _effectiveRecipeId != '1002')
          _buildRecipeSummary(context, recipe),
      ],
    );
  }

  Widget _buildBeanSelectionRow(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Give RoasterLogo a unique key that changes on every bean selection
    final roasterLogoKey = selectedBeanUuid != null
        ? ValueKey(selectedBeanUuid! +
            (originalRoasterLogoUrl ?? '') +
            (mirrorRoasterLogoUrl ?? ''))
        : null;

    const double logoHeight = 24.0;
    const double maxWidthFactor = 2.0; // 24 × 2 = 48 px max width

    return Row(
      children: [
        Text('${loc.beans}: ', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _openAddBeansPopup(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Stack(
              children: [
                Center(
                  child: selectedBeanUuid == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            loc.selectBeans,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (originalRoasterLogoUrl != null ||
                                mirrorRoasterLogoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: logoHeight,
                                  width: logoHeight * maxWidthFactor,
                                  child: RoasterLogo(
                                    key: roasterLogoKey, // <<<<<< THIS
                                    originalUrl: originalRoasterLogoUrl,
                                    mirrorUrl: mirrorRoasterLogoUrl,
                                    height: logoHeight,
                                    width: logoHeight * maxWidthFactor,
                                    borderRadius: 4,
                                    forceFit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (originalRoasterLogoUrl != null ||
                                mirrorRoasterLogoUrl != null)
                              const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedBeanName ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                ),
                if (selectedBeanUuid != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        _updateSelectedBean(null);
                      },
                      child: Container(
                        width: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.cancel,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountFields(BuildContext context, RecipeModel recipe) {
    // Ensure initialRatio is calculated based on the loaded recipe
    if (recipe.coffeeAmount > 0) {
      initialRatio = recipe.waterAmount / recipe.coffeeAmount;
    } else {
      initialRatio = 16.0; // Default
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _coffeeController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.coffeeamount,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) => _updateAmounts(context, recipe),
            onTap: () => _editingCoffee = true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _waterController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.wateramount,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) => _updateAmounts(context, recipe),
            onTap: () => _editingCoffee = false,
          ),
        ),
      ],
    );
  }

  Widget _buildSliders(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    List<String> sweetnessLabels = [
      localizations.sweet,
      localizations.balance,
      localizations.acidic,
    ];
    List<String> strengthLabels = [
      localizations.light,
      localizations.balance,
      localizations.strong,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sweetness Slider
        Text(localizations.slidertitle),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.sweet),
            Expanded(
              child: Slider(
                value: _sweetnessSliderPosition.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: sweetnessLabels[_sweetnessSliderPosition],
                onChanged: (double value) {
                  setState(() {
                    _sweetnessSliderPosition = value.toInt();
                  });
                },
              ),
            ),
            Text(localizations.acidic),
          ],
        ),
        // Strength Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.light),
            Expanded(
              child: Slider(
                value: _strengthSliderPosition.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: strengthLabels[_strengthSliderPosition],
                onChanged: (double value) {
                  setState(() {
                    _strengthSliderPosition = value.toInt();
                  });
                },
              ),
            ),
            Text(localizations.strong),
          ],
        ),
      ],
    );
  }

  Widget _buildCoffeeChroniclerSlider(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    List<String> sizeLabels = [
      localizations.sizeStandard,
      localizations.sizeMedium,
      localizations.sizeXL,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.selectSize),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.sizeStandard),
            Expanded(
              child: Slider(
                value: _coffeeChroniclerSliderPosition.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: sizeLabels[_coffeeChroniclerSliderPosition],
                onChanged: (double value) {
                  setState(() {
                    _coffeeChroniclerSliderPosition = value.toInt();

                    // Update coffee and water amounts
                    if (_updatedRecipe!.id == '1002') {
                      // Check original ID for logic
                      double newCoffeeAmount;
                      double newWaterAmount;

                      switch (_coffeeChroniclerSliderPosition) {
                        case 0:
                          newCoffeeAmount = 20;
                          newWaterAmount = 320;
                          break;
                        case 1:
                          newCoffeeAmount = 30;
                          newWaterAmount = 480;
                          break;
                        case 2:
                          newCoffeeAmount = 45;
                          newWaterAmount = 720;
                          break;
                        default:
                          newCoffeeAmount = _updatedRecipe!.coffeeAmount;
                          newWaterAmount = _updatedRecipe!.waterAmount;
                      }

                      // Update the text controllers
                      _coffeeController.text = newCoffeeAmount.toString();
                      _waterController.text = newWaterAmount.toString();

                      // Update initialRatio
                      initialRatio = newWaterAmount / newCoffeeAmount;
                    }
                  });
                },
              ),
            ),
            Text(localizations.sizeXL),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipeSummary(BuildContext context, RecipeModel recipe) {
    return ExpansionTile(
      title: Text(AppLocalizations.of(context)!.recipesummary),
      subtitle: Text(AppLocalizations.of(context)!.recipesummarynote),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(RecipeSummary.fromRecipe(recipe).summary),
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton(
      BuildContext context, RecipeModel recipe) {
    return FloatingActionButton(
      onPressed: () => _saveCustomAmountsAndNavigate(context, recipe),
      child: const Icon(Icons.arrow_forward),
    );
  }

  Future<void> _saveCustomAmountsAndNavigate(
      BuildContext context, RecipeModel recipe) async {
    // Use _effectiveRecipeId when saving
    final String idToSave = _effectiveRecipeId ?? widget.initialRecipeId;
    // Ensure context is valid before accessing Providers
    if (!mounted) return;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    double customCoffeeAmount =
        double.tryParse(_coffeeController.text.replaceAll(',', '.')) ??
            recipe.coffeeAmount;
    double customWaterAmount =
        double.tryParse(_waterController.text.replaceAll(',', '.')) ??
            recipe.waterAmount;

    await recipeProvider.saveCustomAmounts(
        idToSave, customCoffeeAmount, customWaterAmount);

    // Use effective ID for slider logic check
    if (idToSave == '106' || idToSave == '1002') {
      await recipeProvider.saveSliderPositions(
        idToSave, // Use effective ID
        sweetnessSliderPosition:
            idToSave == '106' ? _sweetnessSliderPosition : null,
        strengthSliderPosition:
            idToSave == '106' ? _strengthSliderPosition : null,
        coffeeChroniclerSliderPosition:
            idToSave == '1002' ? _coffeeChroniclerSliderPosition : null,
      );
    }

    RecipeModel updatedRecipeForNav = recipe.copyWith(
      id: idToSave, // Ensure the ID passed to next screen is the effective one
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
      sweetnessSliderPosition:
          idToSave == '106' ? _sweetnessSliderPosition : null,
      strengthSliderPosition:
          idToSave == '106' ? _strengthSliderPosition : null,
      coffeeChroniclerSliderPosition:
          idToSave == '1002' ? _coffeeChroniclerSliderPosition : null,
    );

    // Ensure context is valid before navigating
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreparationScreen(
            recipe: updatedRecipeForNav,
            brewingMethodName: _brewingMethodName,
            coffeeChroniclerSliderPosition:
                updatedRecipeForNav.coffeeChroniclerSliderPosition),
      ),
    );
  }

  Future<bool> canLaunchUrl(Uri url) async {
    return await canLaunch(url.toString());
  }

  Future<void> launchUrl(Uri url) async {
    await launch(url.toString());
  }

  Widget _buildRichText(BuildContext context, String text) {
    // Disable links based on the effective ID
    final bool isUserRecipe = _effectiveRecipeId?.startsWith('usr-') ?? false;
    if (isUserRecipe) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    final RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    final Iterable<RegExpMatch> matches = linkRegExp.allMatches(text);

    TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyLarge!;
    List<TextSpan> spanList = [];

    int lastMatchEnd = 0;

    for (final match in matches) {
      final String precedingText = text.substring(lastMatchEnd, match.start);
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;

      if (precedingText.isNotEmpty) {
        spanList.add(TextSpan(text: precedingText, style: defaultTextStyle));
      }

      spanList.add(TextSpan(
        text: linkText,
        style: defaultTextStyle.copyWith(
            color: Theme.of(context).colorScheme.secondary),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (await canLaunchUrl(Uri.parse(linkUrl))) {
              await launchUrl(Uri.parse(linkUrl));
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spanList.add(TextSpan(
          text: text.substring(lastMatchEnd), style: defaultTextStyle));
    }

    return RichText(
      text: TextSpan(children: spanList),
    );
  }
}
