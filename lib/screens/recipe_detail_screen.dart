import 'dart:async';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../screens/preparation_screen.dart';
import '../screens/recipe_creation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import '../widgets/recipe_detail/rich_text_links.dart';
import '../widgets/recipe_detail/amount_fields.dart';
import '../widgets/recipe_detail/meta_info_section.dart';
import '../widgets/recipe_detail/title_bar.dart';
import '../widgets/recipe_detail/recipe_summary_tile.dart';
import '../widgets/recipe_detail/sliders_106.dart';
import '../widgets/recipe_detail/slider_chronicler_1002.dart';
import '../widgets/recipe_detail/floating_nav_button.dart';
import '../widgets/recipe_detail/app_bar_actions.dart';
import '../widgets/recipe_detail/bean_selection_row.dart';
import '../controllers/recipe_detail_controller.dart';
import 'package:auto_route/auto_route.dart';
import '../webhelper/web_helper.dart' as web;
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../providers/user_recipe_provider.dart';
import '../utils/beans/bean_selection_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import '../providers/coffee_beans_provider.dart';
import '../providers/database_provider.dart';
import '../providers/user_stat_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';

// Enum for sign-in method (must be at top-level, not inside a function)
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
  const RecipeDetailBase({
    Key? key,
    this.brewingMethodId,
    required this.initialRecipeId,
  }) : super(key: key);

  @override
  _RecipeDetailBaseState createState() => _RecipeDetailBaseState();
}

class _RecipeDetailBaseState extends State<RecipeDetailBase> {
  final RecipeDetailController _controller = RecipeDetailController();

  RecipeModel? _updatedRecipe; // The recipe model currently displayed
  String _brewingMethodName = "";

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

  // Sliders moved to controller (sweetness/strength for 106, size for 1002)

  // Recipe-specific variables

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
      final String? initialUserId =
          Supabase.instance.client.auth.currentUser?.id; // Store initial ID

      final bool signInSuccess = await _showSignInOptionsAndExecute(context);

      if (signInSuccess) {
        await Future.delayed(const Duration(milliseconds: 500));
        final String? newUserId = Supabase.instance.client.auth.currentUser?.id;
        if (newUserId != null && newUserId != initialUserId) {
          await _syncDataAfterLogin(context, initialUserId, newUserId);
          return true;
        } else if (newUserId != null) {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  // Enum for sign-in method (must be at top-level, not inside a function)
  // (Moved to top-level below imports)
  Future<bool> _showSignInOptionsAndExecute(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          await _signInWithApple(context);
          return true;
        case SignInMethod.google:
          await _signInWithGoogle(context);
          return true;
        case SignInMethod.email:
          _showEmailSignInDialog(context);
          return true;
        case SignInMethod.cancel:
        default:
          return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signInError)),
      );
      return false;
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _nativeSignInWithApple();
    } else {
      await _supabaseSignInWithApple();
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
      redirectTo: kIsWeb ? null : 'timercoffee://',
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (kIsWeb) {
      await _webSignInWithGoogle();
    } else {
      await _nativeGoogleSignIn();
    }
  }

  Future<void> _webSignInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: null,
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
    _showOTPVerificationDialog(context, email);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : 'timercoffee://',
      );
    } catch (e) {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(l10n.verify),
              onPressed: () {
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
    Navigator.of(context).pop();

    try {
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (res.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInSuccessfulEmail)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidOTP)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpVerificationError)),
      );
    }
  }

  Future<void> _syncDataAfterLogin(
      BuildContext context, String? oldUserId, String newUserId) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n_sync = AppLocalizations.of(context)!;

    setState(() => _isSharing = true);

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

      if (oldUserId != null && oldUserId != newUserId) {
        await userRecipeProvider.updateUserRecipeIdsAfterLogin(
            oldUserId, newUserId);

        try {
          final res = await Supabase.instance.client.functions.invoke(
            'update-id-after-signin',
            body: {'oldUserId': oldUserId, 'newUserId': newUserId},
          );
          if (res.status != 200) {
            // Optionally handle non-200 status
          }
        } catch (e) {
          // Optionally handle error
        }
      }

      await dbProvider.uploadUserPreferencesToSupabase();
      await dbProvider.fetchAndInsertUserPreferencesFromSupabase();
      await userStatProvider.syncUserStats();
      await coffeeBeansProvider.syncCoffeeBeans();
      await dbProvider.syncUserRecipes(newUserId);
      await dbProvider.syncImportedRecipes(newUserId);

      await recipeProvider.fetchAllRecipes();

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n_sync.syncSuccess)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error syncing data: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
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

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) return;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    // Access the Drift database instance with an explicit generic type
    final appDb = Provider.of<AppDatabase>(context, listen: false);

    print(
        "DEBUG: Current user: ${Supabase.instance.client.auth.currentUser?.id ?? "Not logged in"}");

    try {
      // 1. First check if recipe exists directly by ID in local database
      print("DEBUG: Step 1 - Checking if recipe exists locally by ID");
      RecipeModel? localRecipe =
          await recipeProvider.getRecipeById(potentialImportId);

      if (localRecipe != null) {
        print("DEBUG: Recipe found locally with ID: $potentialImportId");
        _effectiveRecipeId = potentialImportId;
        await _loadRecipeDetails(_effectiveRecipeId!);
      } else if (potentialImportId.startsWith('usr-')) {
        print(
            "DEBUG: Step 2 - Recipe not found locally. Checking if it exists as an import_id");
        final localRecipeByImportId =
            await appDb.recipesDao.getRecipeByImportId(potentialImportId);

        if (localRecipeByImportId != null) {
          print(
              "DEBUG: Recipe found locally as import with ID: ${localRecipeByImportId.id} (Import ID: $potentialImportId)");
          _effectiveRecipeId = localRecipeByImportId.id;
          await _loadRecipeDetails(_effectiveRecipeId!);
        } else {
          print(
              "DEBUG: Step 3 - Recipe not found locally. Checking Supabase for import ID: $potentialImportId");

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

          if (!mounted) return;

          if (metadata != null) {
            print("DEBUG: Recipe exists in Supabase, showing import dialog");
            final bool? wantsImport =
                await _showImportDialog(metadata['name'] ?? potentialImportId);
            if (!mounted) return;

            if (wantsImport == true) {
              print("DEBUG: User wants to import recipe");
              setState(() => _isLoading = true);
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

              if (!mounted) return;

              if (fullData != null) {
                print("DEBUG: Importing recipe into local database");
                final String? newLocalId =
                    await userRecipeProvider.importSupabaseRecipe(fullData);
                print("DEBUG: Import result - new local ID: $newLocalId");

                if (!mounted) return;

                if (newLocalId != null) {
                  print("DEBUG: Recipe imported successfully, loading details");
                  _effectiveRecipeId = newLocalId;

                  // Additional diagnostics to ensure local visibility after import
                  try {
                    final appDb =
                        Provider.of<AppDatabase>(context, listen: false);
                    final byImport = await appDb.recipesDao
                        .getRecipeByImportId(potentialImportId);
                    print(
                        "DEBUG: Post-import local lookup by import_id present: ${byImport != null} (id: ${byImport?.id})");
                  } catch (e) {
                    print("DEBUG: Post-import diagnostic lookup error: $e");
                  }

                  // Ensure provider state is refreshed before loading
                  await Provider.of<RecipeProvider>(context, listen: false)
                      .fetchAllRecipes();

                  // Small delay to tolerate any pending SQLite commit scheduling
                  await Future.delayed(const Duration(milliseconds: 20));

                  await _loadRecipeDetails(_effectiveRecipeId!);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.recipeImportSuccess)));

                  print("DEBUG: Triggering immediate sync after import...");
                  final currentUser = Supabase.instance.client.auth.currentUser;
                  if (currentUser != null && !currentUser.isAnonymous) {
                    if (mounted) {
                      try {
                        await Provider.of<DatabaseProvider>(context,
                                listen: false)
                            .syncUserRecipes(currentUser.id);
                        print("DEBUG: Immediate sync triggered successfully.");
                      } catch (syncError) {
                        print("DEBUG: Error during immediate sync: $syncError");
                      }
                    } else {
                      print(
                          "DEBUG: Context not mounted, skipping immediate sync.");
                    }
                  } else {
                    print(
                        "DEBUG: User not logged in or anonymous, skipping immediate sync.");
                  }
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
              print("DEBUG: User declined to import recipe");
              setState(() => _errorMessage = l10n.recipeNotImported);
            }
          } else {
            print("DEBUG: Recipe not found in Supabase or not public");
            setState(() => _errorMessage = l10n.recipeNotFoundCloud);
          }
        }
      } else {
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

  Future<bool?> _showImportDialog(String recipeName) async {
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

  Future<bool?> _showUpdateDialog(String recipeName) async {
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

  // Modified to accept recipeId
  Future<void> _loadRecipeDetails(String recipeIdToLoad) async {
    if (!mounted) return;
    try {
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Retry loop to tolerate momentary visibility lag after import/transactions
      const int maxAttempts = 5;
      const Duration backoff = Duration(milliseconds: 120);
      RecipeModel? recipeModel;
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        if (!mounted) return;
        recipeModel = await recipeProvider.getRecipeById(recipeIdToLoad);
        if (recipeModel != null) {
          break;
        }
        // Debug diagnostics to help identify timing/visibility issues
        // ignore: avoid_print
        print(
            "DEBUG: _loadRecipeDetails attempt $attempt/$maxAttempts for id=$recipeIdToLoad returned null. Retrying after ${backoff.inMilliseconds}ms");
        await Future.delayed(backoff);
      }

      if (!mounted) return;

      if (recipeModel == null) {
        setState(() {
          _errorMessage = l10n.recipeLoadErrorGeneric;
          _updatedRecipe = null;
        });
        return;
      }

      String brewingMethodName = l10n.unknownBrewingMethod;
      brewingMethodName = await recipeProvider
          .fetchBrewingMethodName(recipeModel.brewingMethodId);

      if (!mounted) return;

      setState(() {
        _brewingMethodName = brewingMethodName;
        _updatedRecipe = recipeModel;

        final double customCoffee = (recipeModel?.customCoffeeAmount) ??
            (recipeModel?.coffeeAmount ?? 0);
        final double customWater =
            (recipeModel?.customWaterAmount) ?? (recipeModel?.waterAmount ?? 0);

        _controller.setInitialAmounts(
          coffeeAmount: customCoffee,
          waterAmount: customWater,
        );

        _controller.sweetnessSliderPosition =
            recipeModel?.sweetnessSliderPosition ?? 1;
        _controller.strengthSliderPosition =
            recipeModel?.strengthSliderPosition ?? 2;
        _controller.coffeeChroniclerSliderPosition =
            recipeModel?.coffeeChroniclerSliderPosition ?? 0;

        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context)?.recipeLoadErrorGeneric ??
                  "Error loading recipe";
          _updatedRecipe = null;
        });
      }
    }
  }

  Future<void> _loadSelectedBean() async {
    if (!mounted) return;
    final service = const BeanSelectionService();
    final result = await service.loadSelectedBean(context);
    if (!mounted) return;
    if (result == null) {
      _controller.clearBeanSelection();
    } else {
      _controller.setBeanSelection(
        uuid: result.uuid,
        name: result.name,
        originalUrl: result.originalLogoUrl,
        mirrorUrl: result.mirrorLogoUrl,
      );
    }
    // No explicit setState needed; AnimatedBuilder listens to controller
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
    if (!mounted) return;
    final service = const BeanSelectionService();
    if (uuid != null) {
      final result = await service.updateSelectedBean(context, uuid);
      if (!mounted) return;
      if (result != null) {
        _controller.setBeanSelection(
          uuid: result.uuid,
          name: result.name,
          originalUrl: result.originalLogoUrl,
          mirrorUrl: result.mirrorLogoUrl,
        );
      }
    } else {
      await service.clearSelectedBean(context);
      if (!mounted) return;
      _controller.clearBeanSelection();
    }
    // No explicit setState needed; AnimatedBuilder listens to controller
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Share flow (restored, no ShareService) ---
  void _onShare(BuildContext context) async {
    if (_isSharing) return; // Prevent double taps

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String shareRecipeId = _effectiveRecipeId ?? widget.initialRecipeId;

    if (_updatedRecipe == null) {
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text(l10n.recipeLoadErrorGeneric)));
      return;
    }
    if (!mounted) return;

    setState(() => _isSharing = true);

    try {
      // --- User Recipe Sharing Logic ---
      if (shareRecipeId.startsWith('usr-')) {
        // 1. Check Authentication
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null || currentUser.isAnonymous) {
          final signedIn = await _promptSignIn(context);
          if (!signedIn) {
            setState(() => _isSharing = false);
            return;
          }
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
          final currentLocale = window.locale.languageCode;
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
        setState(() => _isSharing = false);
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
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, fabHeight),
                  child: SingleChildScrollView(
                    child: _buildRecipeContent(context, recipe),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: _buildFloatingActionButton(context, recipe),
                ),
              ],
            );
          },
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
      title: RecipeDetailTitle(
        brewingMethodIcon: getIconByBrewingMethod(recipe.brewingMethodId),
        brewingMethodName: _brewingMethodName,
      ),
      actions: [
        RecipeDetailAppBarActions(
          isUserRecipe: isUserRecipe,
          isSharing: _isSharing,
          idForActions: idForActions,
          onEdit: () => _navigateToEditRecipe(context, recipe),
          onCopy: () => _navigateToCopyRecipe(context, recipe),
          onShare: () => _onShare(context),
          favoriteButton: FavoriteButton(recipeId: idForActions),
        ),
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
        // Rich text with markdown-like links; disable for user recipes (same behavior)
        if (!((_effectiveRecipeId?.startsWith('usr-')) ?? false))
          RichTextLinks(
            text: recipe.shortDescription,
            onTapUrl: (uri) async {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          )
        else
          Text(
            recipe.shortDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: 16),
        BeanSelectionRow(
          selectedBeanUuid: _controller.selectedBeanUuid,
          selectedBeanName: _controller.selectedBeanName,
          originalRoasterLogoUrl: _controller.originalRoasterLogoUrl,
          mirrorRoasterLogoUrl: _controller.mirrorRoasterLogoUrl,
          onSelectBeans: () => _openAddBeansPopup(context),
          onClearSelection: () => _updateSelectedBean(null),
        ),
        const SizedBox(height: 16),
        AmountFields(
          coffeeController: _controller.coffeeController,
          waterController: _controller.waterController,
          onCoffeeChanged: () {
            final id = _effectiveRecipeId;
            if (id != null) {
              _controller.updateAmounts(id);
            }
          },
          onWaterChanged: () {
            final id = _effectiveRecipeId;
            if (id != null) {
              _controller.updateAmounts(id);
            }
          },
          onCoffeeFocus: () => _controller.setEditingCoffee(true),
          onWaterFocus: () => _controller.setEditingCoffee(false),
        ),
        const SizedBox(height: 16),
        MetaInfoSection(
          waterTempCelsius: recipe.waterTemp,
          grindSize: recipe.grindSize,
          brewTime: recipe.brewTime,
        ),
        const SizedBox(height: 16),
        // Use effective ID for slider logic
        if (_effectiveRecipeId == '1002')
          CoffeeChroniclerSizeSlider(
            position: _controller.coffeeChroniclerSliderPosition,
            onChanged: (int value) {
              final mapped =
                  _controller.setChroniclerPositionAndMapAmounts(value);
              if (_updatedRecipe?.id == '1002' && mapped != null) {
                _controller.applyAmounts(mapped['coffee']!, mapped['water']!);
              } else {
                _controller.notifyListeners();
              }
            },
          ),
        if (_effectiveRecipeId == '106')
          SweetnessStrengthSliders(
            sweetnessPosition: _controller.sweetnessSliderPosition,
            strengthPosition: _controller.strengthSliderPosition,
            onSweetnessChanged: (v) {
              _controller.setSweetnessPosition(v);
            },
            onStrengthChanged: (v) {
              _controller.setStrengthPosition(v);
            },
          ),
        if (_effectiveRecipeId != '106' && _effectiveRecipeId != '1002')
          RecipeSummaryTile(recipe: recipe),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, RecipeModel recipe) {
    return FloatingNavButton(
      onPressed: () => _saveCustomAmountsAndNavigate(context, recipe),
    );
  }

  Future<void> _saveCustomAmountsAndNavigate(
      BuildContext context, RecipeModel recipe) async {
    // Use _effectiveRecipeId when saving
    final String idToSave = _effectiveRecipeId ?? widget.initialRecipeId;
    // Ensure context is valid before accessing Providers
    if (!mounted) return;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    double customCoffeeAmount = double.tryParse(
            _controller.coffeeController.text.replaceAll(',', '.')) ??
        recipe.coffeeAmount;
    double customWaterAmount = double.tryParse(
            _controller.waterController.text.replaceAll(',', '.')) ??
        recipe.waterAmount;

    await recipeProvider.saveCustomAmounts(
        idToSave, customCoffeeAmount, customWaterAmount);

    // Use effective ID for slider logic check
    if (idToSave == '106' || idToSave == '1002') {
      await recipeProvider.saveSliderPositions(
        idToSave,
        sweetnessSliderPosition:
            idToSave == '106' ? _controller.sweetnessSliderPosition : null,
        strengthSliderPosition:
            idToSave == '106' ? _controller.strengthSliderPosition : null,
        coffeeChroniclerSliderPosition: idToSave == '1002'
            ? _controller.coffeeChroniclerSliderPosition
            : null,
      );
    }

    RecipeModel updatedRecipeForNav = recipe.copyWith(
      id: idToSave, // Ensure the ID passed to next screen is the effective one
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
      sweetnessSliderPosition:
          idToSave == '106' ? _controller.sweetnessSliderPosition : null,
      strengthSliderPosition:
          idToSave == '106' ? _controller.strengthSliderPosition : null,
      coffeeChroniclerSliderPosition: idToSave == '1002'
          ? _controller.coffeeChroniclerSliderPosition
          : null,
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
}
