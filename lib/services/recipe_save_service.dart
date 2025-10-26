import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/database_provider.dart';
import '../database/database.dart';
import '../app_router.gr.dart';
import '../utils/app_logger.dart';

class RecipeSaveService {
  static Future<void> save(
    RecipeModel recipeData,
    BuildContext context, {
    required bool isUpdate,
    required bool redirectToNewDetailOnSave,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final currentUser = Supabase.instance.client.auth.currentUser;

    bool requiresModeration = false;
    bool moderationPassed = true;
    bool supabaseCheckFailed = false;
    String moderationFailureReason = "Content flagged for review.";

    final recipeId = recipeData.id;

    if (isUpdate &&
        recipeId.startsWith('usr-') &&
        currentUser != null &&
        !currentUser.isAnonymous) {
      AppLogger.debug(
          "Checking if recipe ${AppLogger.sanitize(recipeId)} is public...");
      try {
        final response = await Supabase.instance.client
            .from('user_recipes')
            .select('ispublic')
            .eq('id', recipeId)
            .maybeSingle()
            .timeout(const Duration(seconds: 2));

        if (response != null && response['ispublic'] == true) {
          AppLogger.debug(
              "Recipe ${AppLogger.sanitize(recipeId)} is public. Moderation check required.");
          requiresModeration = true;

          String combinedText = "";
          combinedText += "${recipeData.name}\n";
          combinedText += "${recipeData.shortDescription}\n";
          combinedText += "${recipeData.grindSize}\n";
          for (var step in recipeData.steps) {
            combinedText += "${step.description}\n";
          }
          combinedText = combinedText.trim();

          if (combinedText.isEmpty) {
            AppLogger.warning("Warning: No text content found for moderation.");
            moderationPassed = true;
          } else {
            AppLogger.debug(
                "Calling content moderation for recipe ${AppLogger.sanitize(recipeId)} update...");
            try {
              final moderationResponse =
                  await Supabase.instance.client.functions.invoke(
                'content-moderation-gemini',
                body: {'text': combinedText},
              ).timeout(const Duration(seconds: 5));

              if (moderationResponse.status != 200 ||
                  moderationResponse.data == null) {
                AppLogger.error(
                    "Moderation Error (Function Call): Recipe ${AppLogger.sanitize(recipeId)}. Status: ${moderationResponse.status}");
                moderationPassed = false;
              } else {
                final moderationResult =
                    moderationResponse.data as Map<String, dynamic>;
                if (moderationResult['safe'] != true) {
                  moderationFailureReason = moderationResult['reason'] ??
                      "Content flagged for review.";
                  AppLogger.warning(
                      "Moderation Failed (Content Flagged): Recipe ${AppLogger.sanitize(recipeId)}. Reason: ${AppLogger.sanitize(moderationFailureReason)}");
                  moderationPassed = false;
                } else {
                  AppLogger.debug(
                      "Moderation Passed: Recipe ${AppLogger.sanitize(recipeId)}");
                  moderationPassed = true;
                }
              }
            } on TimeoutException {
              AppLogger.warning(
                  "Moderation check timed out for recipe ${AppLogger.sanitize(recipeId)}.");
              supabaseCheckFailed = true;
              moderationPassed = false;
            } catch (e) {
              AppLogger.error(
                  "Moderation check failed with error: ${AppLogger.sanitize(e)}");
              supabaseCheckFailed = true;
              moderationPassed = false;
            }
          }
        } else {
          AppLogger.debug(
              "Recipe ${AppLogger.sanitize(recipeId)} is not public or not found. No moderation needed.");
          moderationPassed = true;
        }
      } on TimeoutException {
        AppLogger.warning(
            "Checking public status timed out for recipe ${AppLogger.sanitize(recipeId)}.");
        supabaseCheckFailed = true;
        moderationPassed = false;
        requiresModeration = true;
      } catch (e) {
        AppLogger.error(
            "Error checking public status for recipe ${AppLogger.sanitize(recipeId)}: ${AppLogger.sanitize(e)}");
        supabaseCheckFailed = true;
        moderationPassed = false;
        requiresModeration = true;
      }
    }

    AppLogger.debug("Saving recipe locally: ${AppLogger.sanitize(recipeId)}");
    if (isUpdate) {
      await userRecipeProvider.updateUserRecipe(recipeData);
    } else {
      await userRecipeProvider.createUserRecipe(recipeData);
    }
    AppLogger.debug(
        "Local save complete for recipe: ${AppLogger.sanitize(recipeId)}");

    if (requiresModeration && moderationPassed && !supabaseCheckFailed) {
      AppLogger.debug(
          "Clearing needs_moderation_review flag for ${AppLogger.sanitize(recipeId)}");
      await dbProvider.clearNeedsModerationReview(recipeId);
    }

    if (requiresModeration && !moderationPassed && !supabaseCheckFailed) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.saveLocallyModerationFailedTitle),
            content: Text(
                l10n.saveLocallyModerationFailedBody(moderationFailureReason)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text(l10n.ok))
            ],
          ),
        );
      }
    } else if (supabaseCheckFailed) {
      if (context.mounted) {
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text(l10n.saveLocallyCheckLater)));
      }
    }

    if (currentUser != null && !currentUser.isAnonymous) {
      AppLogger.debug(
          "Syncing recipe to Supabase immediately: ${AppLogger.sanitize(recipeId)}");
      try {
        await dbProvider
            .syncUserRecipes(currentUser.id)
            .timeout(const Duration(seconds: 2), onTimeout: () {
          AppLogger.warning(
              "Immediate sync timed out, will sync on next app start");
          return;
        });
        AppLogger.debug(
            "Immediate sync completed for recipe: ${AppLogger.sanitize(recipeId)}");
      } catch (e) {
        AppLogger.error(
            "Error during immediate sync: ${AppLogger.sanitize(e)}");
      }
    }

    if (context.mounted) {
      AppLogger.debug(
          "Navigating after save for recipe: ${AppLogger.sanitize(recipeId)}");

      if (redirectToNewDetailOnSave) {
        // This screen may have been pushed using MaterialPageRoute.
        // To ensure navigation works in that case, pop this route first,
        // then push the detail via AutoRoute.
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
        // Schedule push on next microtask/frame to avoid operating during pop.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.router.push(RecipeDetailRoute(
            brewingMethodId: recipeData.brewingMethodId,
            recipeId: recipeData.id!,
          ));
        });
      } else if (isUpdate) {
        if (context.router.canPop()) {
          context.router.pop();
        } else {
          context.router.replace(RecipeDetailRoute(
              brewingMethodId: recipeData.brewingMethodId,
              recipeId: recipeData.id!));
        }
      } else {
        context.router.replace(RecipeDetailRoute(
            brewingMethodId: recipeData.brewingMethodId,
            recipeId: recipeData.id!));
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(isUpdate
                ? l10n.recipeCreationScreenUpdateSuccess
                : l10n.recipeCreationScreenSaveSuccess)),
      );

      await recipeProvider.fetchAllRecipes();
    }
  }
}
