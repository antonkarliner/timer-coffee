import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/database_provider.dart';
import '../app_router.gr.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../widgets/base_buttons.dart';

class RecipeSaveService {
  static Future<void> save(
    RecipeModel recipeData,
    BuildContext context, {
    required bool isUpdate,
    required bool redirectToNewDetailOnSave,
    bool popWithResultOnSave = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userRecipeProvider = Provider.of<UserRecipeProvider>(
      context,
      listen: false,
    );
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final currentUser = Supabase.instance.client.auth.currentUser;

    final recipeId = recipeData.id;
    String? moderationFailureReason;
    bool reviewPending = false;

    AppLogger.debug("Saving recipe locally: ${AppLogger.sanitize(recipeId)}");
    if (isUpdate) {
      await userRecipeProvider.updateUserRecipe(recipeData);
    } else {
      await userRecipeProvider.createUserRecipe(recipeData);
    }
    AppLogger.debug(
      "Local save complete for recipe: ${AppLogger.sanitize(recipeId)}",
    );

    if (isUpdate &&
        recipeData.isPublic &&
        currentUser != null &&
        !currentUser.isAnonymous) {
      try {
        final result = await dbProvider.publishRecipeRevision(
          recipeId,
          currentUser.id,
          requirePublic: true,
        );
        moderationFailureReason = result.reason;
        reviewPending = !result.published && result.reason == null;
      } catch (error) {
        AppLogger.warning('Recipe review is pending', errorObject: error);
        reviewPending = true;
      }
    }

    final failureReason = moderationFailureReason;
    if (failureReason != null) {
      if (context.mounted) {
        final outerContext = context;
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            title: Text(l10n.saveLocallyModerationFailedTitle),
            content: Text(l10n.saveLocallyModerationFailedBody(failureReason)),
            actions: [
              AppTextButton(
                label: l10n.moderationRulesLearnMore,
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (outerContext.mounted) {
                    outerContext.router.push(InfoRoute(section: 'moderation'));
                  }
                },
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: AppButton.paddingSmall,
              ),
              AppTextButton(
                label: l10n.ok,
                onPressed: () => Navigator.pop(dialogContext),
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: AppButton.paddingSmall,
              ),
            ],
          ),
        );
      }
    } else if (reviewPending) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.saveLocallyCheckLater)),
        );
      }
    }

    if (currentUser != null && !currentUser.isAnonymous) {
      AppLogger.debug(
        "Syncing recipe to Supabase immediately: ${AppLogger.sanitize(recipeId)}",
      );
      try {
        await dbProvider
            .syncUserRecipes(currentUser.id)
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                AppLogger.warning(
                  "Immediate sync timed out, will sync on next app start",
                );
                return;
              },
            );
        AppLogger.debug(
          "Immediate sync completed for recipe: ${AppLogger.sanitize(recipeId)}",
        );
      } catch (e) {
        AppLogger.error(
          "Error during immediate sync: ${AppLogger.sanitize(e)}",
        );
      }
    }

    if (context.mounted) {
      AppLogger.debug(
        "Navigating after save for recipe: ${AppLogger.sanitize(recipeId)}",
      );

      if (popWithResultOnSave) {
        // Pop back to the caller with the saved recipe data.
        // Used when recipe creation is invoked from manual brew entry.
        // The caller is responsible for refreshing recipes and showing feedback.
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.recipeCreationScreenSaveSuccess)),
        );
        context.router.pop(recipeData);
        return;
      } else if (redirectToNewDetailOnSave) {
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
          context.router.push(
            RecipeDetailRoute(
              brewingMethodId: recipeData.brewingMethodId,
              recipeId: recipeData.id,
            ),
          );
        });
      } else if (isUpdate) {
        if (context.router.canPop()) {
          context.router.pop();
        } else {
          context.router.replace(
            RecipeDetailRoute(
              brewingMethodId: recipeData.brewingMethodId,
              recipeId: recipeData.id,
            ),
          );
        }
      } else {
        context.router.replace(
          RecipeDetailRoute(
            brewingMethodId: recipeData.brewingMethodId,
            recipeId: recipeData.id,
          ),
        );
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? l10n.recipeCreationScreenUpdateSuccess
                : l10n.recipeCreationScreenSaveSuccess,
          ),
        ),
      );

      await recipeProvider.fetchAllRecipes();
    }
  }
}
