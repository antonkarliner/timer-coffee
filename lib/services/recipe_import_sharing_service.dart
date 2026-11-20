import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../models/brew_step_model.dart';
import '../models/recipe_model.dart';
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_recipe_provider.dart';
import '../utils/app_logger.dart';
import '../utils/input_validator.dart';
import '../utils/recipe_schedule_limits.dart';
import 'authentication_service.dart';
import 'recipe_publication.dart';

class RecipeImportResult {
  final String? newRecipeId;
  final RecipeModel? preview;
  final String? errorMessage;

  bool get success => newRecipeId != null || preview != null;

  const RecipeImportResult({this.newRecipeId, this.preview, this.errorMessage});
}

class RecipeSharingResult {
  final bool success;
  final String? errorMessage;

  const RecipeSharingResult.success() : success = true, errorMessage = null;
  const RecipeSharingResult.error(this.errorMessage) : success = false;
}

class RecipeImportSharingService {
  RecipeImportSharingService._();

  /// A link is a read. Library writes happen only in [importSharedRecipe].
  static Future<RecipeImportResult> performInitialRecipeCheck({
    required BuildContext context,
    required String potentialImportId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final recipeProvider = context.read<RecipeProvider>();
    final database = context.read<AppDatabase?>();
    final dbProvider = context.read<DatabaseProvider>();
    final validatedId = InputValidator.validateAndSanitizeRecipeId(
      potentialImportId,
    );
    if (validatedId == null) {
      return RecipeImportResult(errorMessage: l10n.recipeLoadErrorGeneric);
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    try {
      final localRecipe = await recipeProvider.getRecipeById(validatedId);
      if (client.auth.currentUser?.id != userId) {
        return RecipeImportResult(errorMessage: l10n.recipeLoadErrorGeneric);
      }
      if (localRecipe != null &&
          (!validatedId.startsWith('usr-') ||
              ownsUserRecipe(
                validatedId,
                localRecipe.vendorId,
                localRecipeOwner(database, userId),
              ))) {
        return RecipeImportResult(newRecipeId: validatedId);
      }
      if (!validatedId.startsWith('usr-')) {
        return RecipeImportResult(errorMessage: l10n.recipeLoadErrorGeneric);
      }

      final snapshot = await dbProvider.fetchFullPublicUserRecipeData(
        validatedId,
      );
      if (snapshot == null) {
        return RecipeImportResult(errorMessage: l10n.recipeNotFoundCloud);
      }
      return RecipeImportResult(
        preview: recipePreviewFromSnapshot(
          snapshot,
          recipeProvider.currentLocale.languageCode,
        ),
      );
    } catch (error) {
      AppLogger.error('Failed to open shared recipe', errorObject: error);
      return RecipeImportResult(errorMessage: l10n.recipeLoadErrorGeneric);
    }
  }

  @visibleForTesting
  static RecipeModel recipePreviewFromSnapshot(
    Map<String, dynamic> snapshot,
    String locale,
  ) {
    validateImportedRecipeSchedule(snapshot);
    final localizations = (snapshot['user_recipe_localizations'] as List)
        .cast<Map<String, dynamic>>();
    final localization = localizations.firstWhere(
      (row) => row['locale'] == locale,
      orElse: () => localizations.first,
    );
    final allSteps = (snapshot['user_steps'] as List)
        .cast<Map<String, dynamic>>();
    final localizedSteps = allSteps
        .where((row) => row['locale'] == localization['locale'])
        .toList();
    final steps = localizedSteps.isEmpty ? allSteps.toList() : localizedSteps;
    steps.sort(
      (a, b) => (a['step_order'] as int).compareTo(b['step_order'] as int),
    );
    return RecipeModel(
      id: snapshot['id'] as String,
      name: localization['name'] as String,
      vendorId: snapshot['vendor_id'] as String?,
      originalAuthorId: snapshot['original_author_id'] as String?,
      importId: snapshot['import_id'] as String?,
      brewingMethodId: snapshot['brewing_method_id'] as String,
      coffeeAmount: (snapshot['coffee_amount'] as num).toDouble(),
      waterAmount: (snapshot['water_amount'] as num).toDouble(),
      waterTemp: (snapshot['water_temp'] as num?)?.toDouble(),
      grindSize: localization['grind_size'] as String? ?? '',
      shortDescription: localization['short_description'] as String? ?? '',
      brewTime: Duration(seconds: snapshot['brew_time'] as int),
      steps: steps
          .map(
            (row) => BrewStepModel(
              id: row['id'] as String,
              order: row['step_order'] as int,
              description: row['description'] as String,
              time: Duration(
                seconds: int.tryParse(row['time'].toString()) ?? 0,
              ),
            ),
          )
          .toList(),
      isPublic: true,
    );
  }

  static Future<RecipeImportResult> importSharedRecipe(
    BuildContext context,
    String sourceRecipeId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final dbProvider = context.read<DatabaseProvider>();
    final userRecipeProvider = context.read<UserRecipeProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return RecipeImportResult(errorMessage: l10n.recipeImportFailedSave);
    }

    try {
      // Recheck visibility after the user confirms, in case it was withdrawn
      // while they were viewing the preview.
      final snapshot = await dbProvider.fetchFullPublicUserRecipeData(
        sourceRecipeId,
      );
      if (!context.mounted ||
          client.auth.currentUser?.id != user.id ||
          snapshot == null) {
        return RecipeImportResult(errorMessage: l10n.recipeImportFailedFetch);
      }
      final newLocalId = await userRecipeProvider.importSupabaseRecipe(
        snapshot,
      );
      if (newLocalId == null) {
        return RecipeImportResult(errorMessage: l10n.recipeImportFailedSave);
      }
      if (client.auth.currentUser?.id == user.id) {
        await recipeProvider.fetchAllRecipes();
        if (!user.isAnonymous) await dbProvider.syncUserRecipes(user.id);
      }
      return RecipeImportResult(newRecipeId: newLocalId);
    } catch (error) {
      AppLogger.error('Failed to import shared recipe', errorObject: error);
      return RecipeImportResult(errorMessage: l10n.recipeImportFailedSave);
    }
  }

  static Future<RecipeSharingResult> shareRecipe({
    required BuildContext context,
    required RecipeModel recipe,
    required String shareRecipeId,
  }) async {
    if (!context.mounted) {
      return const RecipeSharingResult.error('Context not mounted');
    }
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (shareRecipeId.startsWith('usr-')) {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null || user.isAnonymous) {
          if (user != null &&
              !ownsUserRecipe(shareRecipeId, recipe.vendorId, user.id)) {
            return RecipeSharingResult.error(l10n.recipeNotFoundCloud);
          }
          await AuthenticationService.promptSignIn(
            context,
            source: 'recipe_share',
            bodyText: l10n.signInRequiredBodyShare,
          );
          // A real account switch rebuilds the account-scoped recipe library.
          // The owner can share the migrated recipe from the signed-in library.
          return const RecipeSharingResult.error('Authentication required');
        }
        if (!ownsUserRecipe(shareRecipeId, recipe.vendorId, user.id)) {
          return RecipeSharingResult.error(l10n.recipeNotFoundCloud);
        }

        final dbProvider = context.read<DatabaseProvider>();
        final prefs = await SharedPreferences.getInstance();
        if (!context.mounted) {
          return const RecipeSharingResult.error('Context not mounted');
        }
        if (prefs.getBool(pendingRecipeWithdrawalKey(user.id, shareRecipeId)) ==
            true) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.recipeUnpublishPending)),
          );
          return RecipeSharingResult.error(l10n.recipeUnpublishPending);
        }
        final response = await dbProvider.publishRecipeRevision(
          shareRecipeId,
          user.id,
        );
        if (!context.mounted || client.auth.currentUser?.id != user.id) {
          return const RecipeSharingResult.error('Authentication required');
        }
        if (!response.published) {
          final message = response.reason == null
              ? l10n.moderationErrorFunction
              : l10n.moderationFailedBody(response.reason!);
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
          return RecipeSharingResult.error(message);
        }
      }

      // --- Actual Sharing ---
      if (!context.mounted) {
        return RecipeSharingResult.error('Context not mounted');
      }
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
        final Offset center = Offset(
          screenSize.width / 2,
          screenSize.height / 2,
        );
        shareOrigin = Rect.fromCenter(center: center, width: 1, height: 1);
      } else {
        // Default behavior using widget's bounding box
        shareOrigin = box.localToGlobal(Offset.zero) & box.size;
      }

      final String textToShare =
          'https://app.timer.coffee/recipes/${recipe.brewingMethodId}/$shareRecipeId';

      await SharePlus.instance.share(
        ShareParams(text: textToShare, sharePositionOrigin: shareOrigin),
      );

      return RecipeSharingResult.success();
    } catch (e, stacktrace) {
      AppLogger.error(
        "Error during sharing process",
        errorObject: e,
        stackTrace: stacktrace,
      );
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.shareErrorGeneric(e.toString()))),
        );
      }
      return RecipeSharingResult.error(e.toString());
    }
  }
}
