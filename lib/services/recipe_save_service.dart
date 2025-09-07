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
      print("Checking if recipe $recipeId is public...");
      try {
        final response = await Supabase.instance.client
            .from('user_recipes')
            .select('ispublic')
            .eq('id', recipeId)
            .maybeSingle()
            .timeout(const Duration(seconds: 2));

        if (response != null && response['ispublic'] == true) {
          print("Recipe $recipeId is public. Moderation check required.");
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
            print("Warning: No text content found for moderation.");
            moderationPassed = true;
          } else {
            print("Calling content moderation for recipe $recipeId update...");
            try {
              final moderationResponse =
                  await Supabase.instance.client.functions.invoke(
                'content-moderation-gemini',
                body: {'text': combinedText},
              ).timeout(const Duration(seconds: 5));

              if (moderationResponse.status != 200 ||
                  moderationResponse.data == null) {
                print(
                    "Moderation Error (Function Call): Recipe $recipeId. Status: ${moderationResponse.status}");
                moderationPassed = false;
              } else {
                final moderationResult =
                    moderationResponse.data as Map<String, dynamic>;
                if (moderationResult['safe'] != true) {
                  moderationFailureReason = moderationResult['reason'] ??
                      "Content flagged for review.";
                  print(
                      "Moderation Failed (Content Flagged): Recipe $recipeId. Reason: $moderationFailureReason");
                  moderationPassed = false;
                } else {
                  print("Moderation Passed: Recipe $recipeId");
                  moderationPassed = true;
                }
              }
            } on TimeoutException {
              print("Moderation check timed out for recipe $recipeId.");
              supabaseCheckFailed = true;
              moderationPassed = false;
            } catch (e) {
              print("Moderation check failed with error: $e");
              supabaseCheckFailed = true;
              moderationPassed = false;
            }
          }
        } else {
          print(
              "Recipe $recipeId is not public or not found. No moderation needed.");
          moderationPassed = true;
        }
      } on TimeoutException {
        print("Checking public status timed out for recipe $recipeId.");
        supabaseCheckFailed = true;
        moderationPassed = false;
        requiresModeration = true;
      } catch (e) {
        print("Error checking public status for recipe $recipeId: $e");
        supabaseCheckFailed = true;
        moderationPassed = false;
        requiresModeration = true;
      }
    }

    print("Saving recipe locally: $recipeId");
    if (isUpdate) {
      await userRecipeProvider.updateUserRecipe(recipeData);
    } else {
      await userRecipeProvider.createUserRecipe(recipeData);
    }
    print("Local save complete for recipe: $recipeId");

    if (requiresModeration && moderationPassed && !supabaseCheckFailed) {
      print("Clearing needs_moderation_review flag for $recipeId");
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
      print("Syncing recipe to Supabase immediately: $recipeId");
      try {
        await dbProvider
            .syncUserRecipes(currentUser.id)
            .timeout(const Duration(seconds: 2), onTimeout: () {
          print("Immediate sync timed out, will sync on next app start");
          return;
        });
        print("Immediate sync completed for recipe: $recipeId");
      } catch (e) {
        print("Error during immediate sync: $e");
      }
    }

    if (context.mounted) {
      print("Navigating after save for recipe: $recipeId");

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
