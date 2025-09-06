import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_recipe_provider.dart';
import 'authentication_service.dart';

/// Result class for recipe import operations
class RecipeImportResult {
  final bool success;
  final String? newRecipeId;
  final String? errorMessage;

  const RecipeImportResult({
    required this.success,
    this.newRecipeId,
    this.errorMessage,
  });

  factory RecipeImportResult.success(String newRecipeId) {
    return RecipeImportResult(success: true, newRecipeId: newRecipeId);
  }

  factory RecipeImportResult.error(String errorMessage) {
    return RecipeImportResult(success: false, errorMessage: errorMessage);
  }
}

/// Result class for recipe sharing operations
class RecipeSharingResult {
  final bool success;
  final String? errorMessage;
  // New: when share flow remaps/derives a stable cloud id, surface it to caller
  final String? resolvedRecipeId;

  const RecipeSharingResult({
    required this.success,
    this.errorMessage,
    this.resolvedRecipeId,
  });

  factory RecipeSharingResult.success({String? resolvedRecipeId}) {
    return RecipeSharingResult(
        success: true, resolvedRecipeId: resolvedRecipeId);
  }

  factory RecipeSharingResult.error(String errorMessage) {
    return RecipeSharingResult(success: false, errorMessage: errorMessage);
  }
}

/// Service class for handling recipe import and sharing operations
class RecipeImportSharingService {
  RecipeImportSharingService._();

  /// Performs the initial recipe check and import workflow
  ///
  /// This method handles the complex workflow of:
  /// 1. Checking if recipe exists locally by ID
  /// 2. Checking if recipe exists locally by import_id
  /// 3. Fetching recipe metadata from Supabase
  /// 4. Showing import dialog and handling user choice
  /// 5. Importing recipe from cloud if user agrees
  /// 6. Managing import status and error handling
  static Future<RecipeImportResult> performInitialRecipeCheck({
    required BuildContext context,
    required String potentialImportId,
  }) async {
    print("DEBUG: performInitialRecipeCheck started");

    final l10n = AppLocalizations.of(context)!;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    final appDb = Provider.of<AppDatabase>(context, listen: false);

    print("DEBUG: Checking recipe with ID: $potentialImportId");
    print(
        "DEBUG: Current user: ${Supabase.instance.client.auth.currentUser?.id ?? "Not logged in"}");

    try {
      // 1. First check if recipe exists directly by ID in local database
      print("DEBUG: Step 1 - Checking if recipe exists locally by ID");
      RecipeModel? localRecipe =
          await recipeProvider.getRecipeById(potentialImportId);

      if (localRecipe != null) {
        print("DEBUG: Recipe found locally with ID: $potentialImportId");
        return RecipeImportResult.success(potentialImportId);
      } else if (potentialImportId.startsWith('usr-')) {
        print(
            "DEBUG: Step 2 - Recipe not found locally. Checking if it exists as an import_id");
        final localRecipeByImportId =
            await appDb.recipesDao.getRecipeByImportId(potentialImportId);

        if (localRecipeByImportId != null) {
          print(
              "DEBUG: Recipe found locally as import with ID: ${localRecipeByImportId.id} (Import ID: $potentialImportId)");
          return RecipeImportResult.success(localRecipeByImportId.id);
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

          if (metadata != null) {
            print("DEBUG: Recipe exists in Supabase, showing import dialog");
            final bool? wantsImport = await _showImportDialog(
              context: context,
              recipeName: metadata['name'] ?? potentialImportId,
            );

            if (wantsImport == true) {
              print("DEBUG: User wants to import recipe");
              final fullData = await dbProvider
                  .fetchFullPublicUserRecipeData(potentialImportId);
              print(
                  "DEBUG: Full recipe data: ${fullData != null ? "Found" : "Not found"}");

              if (!context.mounted)
                return RecipeImportResult.error('Context not mounted');

              if (fullData != null) {
                print("DEBUG: Recipe data keys: ${fullData.keys.join(', ')}");
                print(
                    "DEBUG: Recipe has localizations: ${(fullData['user_recipe_localizations'] as List?)?.isNotEmpty ?? false}");
                print(
                    "DEBUG: Recipe has steps: ${(fullData['user_steps'] as List?)?.isNotEmpty ?? false}");

                print("DEBUG: Importing recipe into local database");
                final String? newLocalId =
                    await userRecipeProvider.importSupabaseRecipe(fullData);
                print("DEBUG: Import result - new local ID: $newLocalId");

                if (newLocalId != null) {
                  print("DEBUG: Recipe imported successfully");

                  // Additional diagnostics to ensure local visibility after import
                  try {
                    final byImport = await appDb.recipesDao
                        .getRecipeByImportId(potentialImportId);
                    print(
                        "DEBUG: Post-import local lookup by import_id present: ${byImport != null} (id: ${byImport?.id})");
                  } catch (e) {
                    print("DEBUG: Post-import diagnostic lookup error: $e");
                  }

                  // Ensure provider state is refreshed before loading
                  await recipeProvider.fetchAllRecipes();

                  // Small delay to tolerate any pending SQLite commit scheduling
                  await Future.delayed(const Duration(milliseconds: 20));

                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.recipeImportSuccess)));
                  }

                  print("DEBUG: Triggering immediate sync after import...");
                  final currentUser = Supabase.instance.client.auth.currentUser;
                  if (currentUser != null && !currentUser.isAnonymous) {
                    if (context.mounted) {
                      try {
                        await dbProvider.syncUserRecipes(currentUser.id);
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

                  return RecipeImportResult.success(newLocalId);
                } else {
                  print("DEBUG: Failed to save imported recipe");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.recipeImportFailedSave)));
                  }
                  return RecipeImportResult.error(l10n.recipeImportFailedSave);
                }
              } else {
                print("DEBUG: Failed to fetch full recipe data");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.recipeImportFailedFetch)));
                }
                return RecipeImportResult.error(l10n.recipeImportFailedFetch);
              }
            } else {
              print("DEBUG: User declined to import recipe");
              return RecipeImportResult.error(l10n.recipeNotImported);
            }
          } else {
            print("DEBUG: Recipe not found in Supabase or not public");
            return RecipeImportResult.error(l10n.recipeNotFoundCloud);
          }
        }
      } else {
        print("DEBUG: Not a user recipe ID and not found locally");
        return RecipeImportResult.error(l10n.recipeLoadErrorGeneric);
      }
    } catch (e) {
      print("DEBUG: Error during initial recipe check: $e");
      if (e is PostgrestException) {
        print("DEBUG: Postgrest error code: ${e.code}");
        print("DEBUG: Postgrest error message: ${e.message}");
        print("DEBUG: Postgrest error details: ${e.details}");
      }
      return RecipeImportResult.error(l10n.recipeLoadErrorGeneric);
    }
  }

  /// Shows the import dialog to ask user if they want to import a recipe
  static Future<bool?> _showImportDialog({
    required BuildContext context,
    required String recipeName,
  }) async {
    if (!context.mounted) return false;
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

  /// Shows the update dialog to ask user if they want to update a recipe
  static Future<bool?> showUpdateDialog({
    required BuildContext context,
    required String recipeName,
  }) async {
    if (!context.mounted) return false;
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

  /// Determines if a recipe needs moderation check based on public status,
  /// timestamp comparison, and local moderation flags
  static Future<bool> _needsModerationCheck({
    required BuildContext context,
    required String recipeId,
    required bool isAlreadyPublic,
    required Map<String, dynamic> remoteData,
  }) async {
    // If already public, no moderation needed
    if (isAlreadyPublic) {
      print("Recipe $recipeId is already public. Skipping moderation.");
      return false;
    }

    try {
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final appDb = Provider.of<AppDatabase>(context, listen: false);

      // Get local recipe model to verify it exists
      final localRecipeModel = await recipeProvider.getRecipeById(recipeId);
      if (localRecipeModel == null) {
        print("Local recipe $recipeId not found. Performing moderation.");
        return true;
      }

      // Get the database entity to access moderation flag and timestamp
      final localRecipeEntity = await (appDb.select(appDb.recipes)
            ..where((tbl) => tbl.id.equals(recipeId)))
          .getSingleOrNull();

      if (localRecipeEntity == null) {
        print(
            "Local recipe entity $recipeId not found. Performing moderation.");
        return true;
      }

      // If local recipe is flagged for moderation review, perform moderation
      if (localRecipeEntity.needsModerationReview == true) {
        print(
            "Recipe $recipeId flagged for moderation review. Performing moderation.");
        return true;
      }

      // Compare timestamps using existing proven logic from DatabaseProvider._syncUserRecipes
      final remoteLastModifiedStr = remoteData['last_modified'] as String?;
      final remoteLastModified = remoteLastModifiedStr != null
          ? DateTime.parse(remoteLastModifiedStr).toUtc()
          : null;

      final localLastModified = localRecipeEntity.lastModified?.toUtc();

      // If local is newer than remote, perform moderation (recipe was modified locally)
      if (localLastModified != null && remoteLastModified != null) {
        if (localLastModified.isAfter(remoteLastModified)) {
          print(
              "Recipe $recipeId was modified locally (local: ${localLastModified.toIso8601String()}, remote: ${remoteLastModified.toIso8601String()}). Performing moderation.");
          return true;
        } else {
          print(
              "Recipe $recipeId is up-to-date with remote. Skipping moderation.");
          return false;
        }
      }

      // If we can't compare timestamps reliably, err on the side of caution
      print(
          "Recipe $recipeId timestamp comparison inconclusive. Performing moderation.");
      return true;
    } catch (e) {
      print(
          "Error checking moderation status for recipe $recipeId: $e. Performing moderation.");
      return true; // Err on the side of caution
    }
  }

  /// Handles the complete recipe sharing workflow
  ///
  /// This method handles:
  /// 1. Authentication checks using AuthenticationService
  /// 2. Content moderation via Supabase functions
  /// 3. Making recipes public
  /// 4. Share dialog positioning for different platforms
  /// 5. Error handling and user feedback
  static Future<RecipeSharingResult> shareRecipe({
    required BuildContext context,
    required RecipeModel recipe,
    required String shareRecipeId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // Track a potentially remapped id to propagate back to caller
    String? resolvedIdFromRemediation;

    try {
      // --- User Recipe Sharing Logic ---
      if (shareRecipeId.startsWith('usr-')) {
        // 1. Check Authentication using AuthenticationService
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null || currentUser.isAnonymous) {
          print(
              'DEBUG: User not authenticated at start of share. Prompting sign-in...');
          // Show prompt; may return before user completes email/OTP
          await AuthenticationService.promptSignIn(context);
          print('DEBUG: Entering auth wait loop after promptSignIn');

          // Wait until user becomes authenticated (non-anonymous) or timeout
          const totalTimeout = Duration(minutes: 3);
          const pollInterval = Duration(milliseconds: 300);
          final start = DateTime.now();
          bool authenticated = false;

          while (DateTime.now().difference(start) < totalTimeout) {
            final u = Supabase.instance.client.auth.currentUser;
            if (u != null && !u.isAnonymous) {
              print('DEBUG: Auth check shows authenticated user: ${u.id}');
              authenticated = true;
              break;
            }
            // Try a quick peek at the stream for immediate events
            try {
              final evt = await Supabase
                  .instance.client.auth.onAuthStateChange.first
                  .timeout(const Duration(milliseconds: 1));
              final streamUser = evt.session?.user;
              if (streamUser != null && !streamUser.isAnonymous) {
                print(
                    'DEBUG: Auth stream indicates authenticated user: ${streamUser.id}');
                authenticated = true;
                break;
              }
            } catch (_) {
              // No immediate event; continue polling
            }
            await Future.delayed(pollInterval);
          }

          if (!authenticated) {
            print(
                'DEBUG: Sign-in not completed within waiting window. Aborting share.');
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(l10n.shareErrorGeneric('Authentication required'))));
            return RecipeSharingResult.error('Authentication required');
          }
        }

        // Ensure we have the latest user ID after potential sign-in/sync
        final userId = Supabase.instance.client.auth.currentUser!.id;
        print('DEBUG: Proceeding with share as authenticated user: $userId');

        // 2. Fetch Recipe Data from Supabase
        print(
            "Fetching recipe $shareRecipeId for user $userId from Supabase...");
        Map<String, dynamic>? response = await Supabase.instance.client
            .from('user_recipes')
            .select('*, user_recipe_localizations(*), user_steps(*)')
            .eq('id', shareRecipeId)
            .maybeSingle();

        // If not found, attempt anonymous-to-signed-in remediation:
        // derive usr-<currentUserId>-<timestamp> and create remote rows from local recipe data.
        if (response == null && shareRecipeId.startsWith('usr-')) {
          try {
            print(
                "DEBUG: Supabase lookup returned null for $shareRecipeId. Attempting remediation for anonymous-to-signed-in sharing.");
            // Prefer server-driven sync path first
            try {
              final dbProvider =
                  Provider.of<DatabaseProvider>(context, listen: false);
              print(
                  'DEBUG: Attempting pre-remediation syncUserRecipes($userId)');
              await dbProvider.syncUserRecipes(userId);
              // Re-check original id after sync
              response = await Supabase.instance.client
                  .from('user_recipes')
                  .select('*, user_recipe_localizations(*), user_steps(*)')
                  .eq('id', shareRecipeId)
                  .maybeSingle();
            } catch (e) {
              print('DEBUG: syncUserRecipes failed or not applicable: $e');
            }

            // Extract timestamp from the original id (last hyphen-separated token)
            final parts = shareRecipeId.split('-');
            if (parts.length < 3) {
              print("DEBUG: Invalid usr-* id format, skip remediation.");
            } else {
              final timestamp = parts.last;
              final derivedNewId = 'usr-$userId-$timestamp';
              print(
                  'DEBUG: Derived new cloud id for current user: $derivedNewId');

              // Try to fetch local recipe for either original or derived id.
              final recipeProvider =
                  Provider.of<RecipeProvider>(context, listen: false);

              RecipeModel? localRecipe =
                  await recipeProvider.getRecipeById(derivedNewId);
              if (localRecipe == null) {
                localRecipe = await recipeProvider.getRecipeById(shareRecipeId);
                if (localRecipe != null) {
                  print(
                      'DEBUG: Found local recipe under old id=$shareRecipeId; will push to cloud as $derivedNewId');
                }
              } else {
                print(
                    'DEBUG: Found local recipe already remapped to $derivedNewId');
              }

              if (localRecipe != null) {
                // Build payloads from local model. Use at least one localization for current locale.
                final currentLocale =
                    View.of(context).platformDispatcher.locale.languageCode;

                // Minimal user_recipes row payload
                final userRecipePayload = {
                  'id': derivedNewId,
                  'brewing_method_id': localRecipe.brewingMethodId,
                  'coffee_amount': localRecipe.coffeeAmount,
                  'water_amount': localRecipe.waterAmount,
                  'water_temp': localRecipe.waterTemp ?? 0.0,
                  'brew_time': localRecipe.brewTime.inSeconds,
                  'vendor_id': 'usr-$userId',
                  'ispublic': false,
                  'is_deleted': false,
                  'import_id': localRecipe.importId,
                  'is_imported': localRecipe.isImported,
                  'last_modified': DateTime.now().toUtc().toIso8601String(),
                };

                print('DEBUG: Ensuring user_recipes row for $derivedNewId');
                final exists = await Supabase.instance.client
                    .from('user_recipes')
                    .select('id')
                    .eq('id', derivedNewId)
                    .maybeSingle();
                if (exists == null) {
                  await Supabase.instance.client
                      .from('user_recipes')
                      .insert(userRecipePayload);
                } else {
                  await Supabase.instance.client
                      .from('user_recipes')
                      .update(userRecipePayload)
                      .eq('id', derivedNewId);
                }

                // Insert a single localization from the RecipeModel fields (generate id)
                final locId = const Uuid().v4();
                final locPayload = {
                  'id': locId,
                  'recipe_id': derivedNewId,
                  'locale': currentLocale,
                  'name': localRecipe.name,
                  'grind_size': localRecipe.grindSize,
                  'short_description': localRecipe.shortDescription,
                };
                print(
                    'DEBUG: Inserting user_recipe_localizations for $derivedNewId locale=$currentLocale');
                await Supabase.instance.client
                    .from('user_recipe_localizations')
                    .insert(locPayload);

                // Insert steps for this locale using the steps in the model (generate ids)
                if (localRecipe.steps.isNotEmpty) {
                  final stepsPayload = localRecipe.steps
                      .map((s) => {
                            'id': const Uuid().v4(),
                            'recipe_id': derivedNewId,
                            'step_order': s.order,
                            'description': s.description,
                            'time': s.time.inSeconds.toString(),
                            'locale': currentLocale,
                          })
                      .toList();
                  print(
                      'DEBUG: Inserting user_steps for $derivedNewId count=${stepsPayload.length} locale=$currentLocale');
                  await Supabase.instance.client
                      .from('user_steps')
                      .insert(stepsPayload);
                } else {
                  print(
                      'DEBUG: Local recipe has zero steps, skipping steps upsert');
                }

                // Re-fetch from Supabase under the new id
                print('DEBUG: Re-fetching created cloud recipe $derivedNewId');
                response = await Supabase.instance.client
                    .from('user_recipes')
                    .select('*, user_recipe_localizations(*), user_steps(*)')
                    .eq('id', derivedNewId)
                    .maybeSingle();

                if (response != null) {
                  print(
                      'DEBUG: Remediation succeeded, continuing share with id=$derivedNewId');
                  // Also update shareRecipeId variable to new id so share URL is correct
                  shareRecipeId = derivedNewId;
                  // Capture resolved id to inform caller
                  resolvedIdFromRemediation = derivedNewId;
                } else {
                  print(
                      'DEBUG: Remediation failed to verify created record for $derivedNewId');
                }
              } else {
                print(
                    'DEBUG: No local recipe found for either $derivedNewId or $shareRecipeId. Cannot remediate.');
              }
            }
          } catch (remapError, remapStack) {
            print('DEBUG: Error during remediation: $remapError');
            print(remapStack);
          }
        }

        if (response == null) {
          print(
              "Recipe $shareRecipeId not found in Supabase or not owned by user $userId.");
          scaffoldMessenger
              .showSnackBar(SnackBar(content: Text(l10n.recipeNotFoundCloud)));
          return RecipeSharingResult.error(l10n.recipeNotFoundCloud);
        }

        final recipeData = response;
        final bool isAlreadyPublic = recipeData['ispublic'] == true;

        // Check if moderation is needed (combines public status, timestamp comparison, and local flag)
        final bool needsModeration = await _needsModerationCheck(
          context: context,
          recipeId: shareRecipeId,
          isAlreadyPublic: isAlreadyPublic,
          remoteData: recipeData,
        );

        // Only perform moderation and update if needed
        if (needsModeration) {
          print(
              "Recipe $shareRecipeId is not public yet. Performing moderation and update...");
          final localizations =
              recipeData['user_recipe_localizations'] as List<dynamic>? ?? [];
          final steps = recipeData['user_steps'] as List<dynamic>? ?? [];

          // 3. Prepare Moderation Text
          final currentLocale =
              View.of(context).platformDispatcher.locale.languageCode;
          String combinedText = "";

          final currentLocalization = localizations.firstWhere(
            (loc) => loc['locale'] == currentLocale,
            orElse: () => localizations.isNotEmpty ? localizations.first : null,
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
              return RecipeSharingResult.error(l10n.moderationErrorFunction);
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
              return RecipeSharingResult.error(
                  'Content moderation failed: $reason');
            }
            print("Moderation passed for recipe $shareRecipeId.");
          }

          // Clear the moderation flag since moderation passed
          final dbProvider =
              Provider.of<DatabaseProvider>(context, listen: false);
          await dbProvider.clearNeedsModerationReview(shareRecipeId);
          print("Cleared moderation flag for recipe $shareRecipeId.");
          print(
              "SAFETY_LOG: Moderation passed for $shareRecipeId - flag cleared before setting isPublic=true");

          // 5. Make Public (only if moderation passed and it wasn't already public)
          print("Setting recipe $shareRecipeId to public...");
          await Supabase.instance.client.from('user_recipes').update({
            'ispublic': true,
            'needs_moderation_review': false, // Explicitly clear the flag
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
          'https://app.timer.coffee/recipes/${recipe.brewingMethodId}/$shareRecipeId';

      await SharePlus.instance.share(
        ShareParams(
          text: textToShare,
          sharePositionOrigin: shareOrigin,
        ),
      );

      return RecipeSharingResult.success(
          resolvedRecipeId: resolvedIdFromRemediation);
    } catch (e, stacktrace) {
      print("Error during sharing process: $e");
      print(stacktrace);
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.shareErrorGeneric(e.toString()))));
      return RecipeSharingResult.error(e.toString());
    }
  }
}
