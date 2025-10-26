import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class UserRecipeProvider with ChangeNotifier {
  List<RecipeModel> _userRecipes = [];
  final AppDatabase _database;
  final Uuid uuid = const Uuid();

  UserRecipeProvider(this._database);

  List<RecipeModel> get userRecipes => [..._userRecipes];

  Future<void> createUserRecipe(RecipeModel recipe) async {
    // Get current user from Supabase
    final user = Supabase.instance.client.auth.currentUser;
    // Locale-agnostic policy for user recipes: canonicalize to 'en' on write
    const String effectiveLocale = 'en';

    // Create a recipe with vendor ID
    final recipeWithVendorId = recipe.copyWith(
      // Use "usr-<user_id>" as vendor ID, but only if user is not null
      // Make sure to use the full user ID to match the RLS policy
      vendorId: user != null ? 'usr-${user.id}' : null,
    );

    // Add debug logging
    AppLogger.debug(
        'Creating user recipe with vendor_id: ${AppLogger.sanitize(recipeWithVendorId.vendorId)}');

    // Wrap database operations in a transaction
    await _database.transaction(() async {
      final recipeCompanion = RecipesCompanion(
        id: drift.Value(recipeWithVendorId.id),
        brewingMethodId: drift.Value(recipeWithVendorId.brewingMethodId),
        coffeeAmount: drift.Value(recipeWithVendorId.coffeeAmount),
        waterAmount: drift.Value(recipeWithVendorId.waterAmount),
        waterTemp: recipeWithVendorId.waterTemp != null
            ? drift.Value(recipeWithVendorId.waterTemp!)
            : const drift.Value.absent(),
        brewTime: drift.Value(recipeWithVendorId.brewTime.inSeconds),
        vendorId: drift.Value(recipeWithVendorId.vendorId),
        lastModified: drift.Value(DateTime.now().toUtc()), // Use UTC time
        isPublic:
            drift.Value(recipeWithVendorId.isPublic), // Include isPublic field
      );
      await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

      // Clean any existing steps for this recipe across all locales before inserting (defensive)
      await _database.stepsDao.deleteStepsForRecipe(recipeWithVendorId.id);

      // Insert steps using canonical locale 'en'
      for (final step in recipeWithVendorId.steps) {
        final stepCompanion = StepsCompanion(
          id: drift.Value(uuid.v4()),
          recipeId: drift.Value(recipeWithVendorId.id),
          stepOrder: drift.Value(step.order),
          description: drift.Value(step.description),
          time: drift.Value(step.time.inSeconds.toString()),
          locale: drift.Value(effectiveLocale),
        );
        await _database.stepsDao.insertOrUpdateStep(stepCompanion);
      }

      // Insert localization using canonical locale 'en'
      final localizationCompanion = RecipeLocalizationsCompanion(
        id: drift.Value(uuid.v4()),
        recipeId: drift.Value(recipeWithVendorId.id),
        name: drift.Value(recipeWithVendorId.name),
        grindSize: drift.Value(recipeWithVendorId.grindSize),
        shortDescription: drift.Value(recipeWithVendorId.shortDescription),
        locale: drift.Value(effectiveLocale),
      );
      await _database.recipeLocalizationsDao
          .insertOrUpdateLocalization(localizationCompanion);
    });

    // Removed duplicate call here

    _userRecipes.add(recipeWithVendorId);
    notifyListeners();
  }

  Future<void> updateUserRecipe(RecipeModel recipe) async {
    // Locale-agnostic policy for user recipes: canonicalize to 'en' on write
    const String effectiveLocale = 'en';
    AppLogger.debug(
        "UserRecipeProvider.updateUserRecipe: using canonical effectiveLocale = '$effectiveLocale'");

    // Get current user from Supabase for authentication check
    final user = Supabase.instance.client.auth.currentUser;

    // Check if the recipe is being made public for the first time
    final existingRecipe = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.id.equals(recipe.id)))
        .getSingleOrNull();
    final bool isBecomingPublic = existingRecipe != null &&
        existingRecipe.isPublic == false &&
        recipe.isPublic == true;
    AppLogger.debug(
        'DEBUG: Recipe ${AppLogger.sanitize(recipe.id)} is becoming public: $isBecomingPublic (existing: ${existingRecipe?.isPublic}, new: ${recipe.isPublic})');

    // Safety log: moderation flag transition
    if (isBecomingPublic && existingRecipe != null) {
      AppLogger.security(
          'Recipe ${AppLogger.sanitize(recipe.id)} becoming public (first time) - setting moderation flag to false');
    }

    final recipeCompanion = RecipesCompanion(
      id: drift.Value(recipe.id),
      brewingMethodId: drift.Value(recipe.brewingMethodId),
      coffeeAmount: drift.Value(recipe.coffeeAmount),
      waterAmount: drift.Value(recipe.waterAmount),
      waterTemp: recipe.waterTemp != null
          ? drift.Value(recipe.waterTemp!)
          : const drift.Value.absent(),
      brewTime: drift.Value(recipe.brewTime.inSeconds),
      vendorId: drift.Value(recipe.vendorId),
      lastModified: drift.Value(DateTime.now().toUtc()), // Use UTC time
      importId: recipe.importId != null
          ? drift.Value(recipe.importId!)
          : const drift.Value.absent(),
      isImported: recipe.isImported != null
          ? drift.Value(recipe.isImported!)
          : const drift.Value.absent(),
      isPublic: recipe.isPublic != null
          ? drift.Value(recipe.isPublic!)
          : const drift.Value.absent(),
      // Moderation policy:
      // - Do NOT set needsModerationReview when first becoming public.
      // - The share flow performs moderation immediately before toggling public
      //   and explicitly clears the flag. Setting it here would re-flag on restart.
      // - Future edits to already-public recipes are moderated in the save flow.
      needsModerationReview: const drift.Value(false),
    );

    // Wrap database operations in a transaction
    await _database.transaction(() async {
      await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

      // Update steps for user recipes: delete ALL existing steps across locales, then recreate under canonical 'en'
      await _database.stepsDao.deleteStepsForRecipe(recipe.id);

      for (final step in recipe.steps) {
        final stepCompanion = StepsCompanion(
          id: drift.Value(uuid.v4()),
          recipeId: drift.Value(recipe.id),
          stepOrder: drift.Value(step.order),
          description: drift.Value(step.description),
          time: drift.Value(step.time.inSeconds.toString()),
          locale: drift.Value(effectiveLocale),
        );
        await _database.stepsDao.insertOrUpdateStep(stepCompanion);
      }

      // Update localization: remove all localizations for this recipe, then insert canonical 'en'
      try {
        await _database.recipeLocalizationsDao
            .deleteLocalizationsForRecipe(recipe.id);
      } catch (e) {
        AppLogger.error("Error deleting localizations", errorObject: e);
      }

      // Then create a new localization entry using the canonical locale 'en'.
      final localizationCompanion = RecipeLocalizationsCompanion(
        id: drift.Value(uuid.v4()),
        recipeId: drift.Value(recipe.id),
        name: drift.Value(recipe.name),
        grindSize: drift.Value(recipe.grindSize),
        shortDescription: drift.Value(recipe.shortDescription),
        locale: drift.Value(effectiveLocale),
      );
      await _database.recipeLocalizationsDao
          .insertOrUpdateLocalization(localizationCompanion);
    });

    final index = _userRecipes.indexWhere((element) => element.id == recipe.id);
    if (index >= 0) {
      _userRecipes[index] = recipe;
      notifyListeners();
    }
  }

  Future<void> deleteUserRecipe(String recipeId) async {
    // On delete, remove all localizations and steps regardless of locale for usr- recipes
    // Delete from local database
    try {
      await _database.recipesDao.deleteRecipe(recipeId);
    } catch (e) {
      AppLogger.error("Error deleting recipe", errorObject: e);
    }
    try {
      await _database.recipeLocalizationsDao
          .deleteLocalizationsForRecipe(recipeId);
    } catch (e) {
      AppLogger.error("Error deleting localizations", errorObject: e);
    }
    try {
      await _database.stepsDao.deleteStepsForRecipe(recipeId);
    } catch (e) {
      AppLogger.error("Error deleting steps", errorObject: e);
    }

    // Mark as deleted in Supabase if it's a user recipe and the user is not anonymous
    if (recipeId.startsWith('usr-')) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        // Only perform remote cleanup if user is logged in and not anonymous
        if (user != null && !user.isAnonymous) {
          final userId = user.id;
          AppLogger.debug(
              'Performing remote cleanup for recipe ${AppLogger.sanitize(recipeId)} for user ${AppLogger.sanitize(userId)}...');

          // 1. Clean up user_stats (mark as deleted)
          try {
            await Supabase.instance.client.from('user_stats').update({
              'is_deleted': true,
              // Optionally update a 'last_modified' timestamp if the table has one
            }).match({
              'user_id': userId,
              'recipe_id': recipeId,
            });
            AppLogger.debug(
                'Marked related user_stats as deleted for recipe ${AppLogger.sanitize(recipeId)}.');
          } catch (e) {
            AppLogger.error(
                "Error marking related user_stats as deleted for recipe ${AppLogger.sanitize(recipeId)}",
                errorObject: e);
            // Decide if we should continue or abort
          }

          // 2. Clean up user_recipe_preferences (delete)
          try {
            await Supabase.instance.client
                .from('user_recipe_preferences')
                .delete()
                .match({
              'user_id': userId,
              'recipe_id': recipeId,
            });
            AppLogger.debug(
                'Deleted related user_recipe_preferences for recipe ${AppLogger.sanitize(recipeId)}.');
          } catch (e) {
            AppLogger.error(
                "Error deleting related user_recipe_preferences for recipe ${AppLogger.sanitize(recipeId)}",
                errorObject: e);
            // Decide if we should continue or abort
          }

          // 3. Mark the recipe itself as deleted and make it private
          try {
            await Supabase.instance.client.from('user_recipes').update({
              'is_deleted': true,
              'ispublic': false, // Set ispublic to false on deletion
              'last_modified': DateTime.now()
                  .toUtc()
                  .toIso8601String() // Also update timestamp
            }).eq('id', recipeId);
            AppLogger.debug(
                'Marked recipe ${AppLogger.sanitize(recipeId)} as deleted and private in Supabase.');
          } catch (e) {
            // This was the original catch block, keep it for the main recipe deletion error
            AppLogger.error(
                "Error marking recipe ${AppLogger.sanitize(recipeId)} as deleted in Supabase",
                errorObject: e);
          }
        } else {
          AppLogger.debug(
              'Skipping Supabase remote cleanup/delete for anonymous user or no user.');
        }
      } catch (e) {
        AppLogger.error("Error marking recipe as deleted in Supabase",
            errorObject: e);
      }
    }

    _userRecipes.removeWhere((element) => element.id == recipeId);
    notifyListeners();
  }

  Future<void> unpublishRecipe(String recipeId) async {
    // Check if this is a user-created recipe
    if (!recipeId.startsWith('usr-')) {
      throw Exception("Cannot unpublish non-user created recipe: $recipeId");
    }

    // Get current user for authentication check
    final user = Supabase.instance.client.auth.currentUser;

    // Update local database in a transaction
    await _database.transaction(() async {
      final recipeCompanion = RecipesCompanion(
        isPublic: drift.Value(false),
        needsModerationReview: drift.Value(false),
        lastModified: drift.Value(DateTime.now().toUtc()),
      );

      await (_database.update(_database.recipes)
            ..where((tbl) => tbl.id.equals(recipeId)))
          .write(recipeCompanion);
    });

    // Update Supabase if user is authenticated and not anonymous
    if (user != null && !user.isAnonymous) {
      try {
        await Supabase.instance.client.from('user_recipes').update({
          'ispublic': false,
          'last_modified': DateTime.now().toUtc().toIso8601String()
        }).eq('id', recipeId);
        AppLogger.debug(
            'Successfully unpublished recipe ${AppLogger.sanitize(recipeId)} in Supabase.');
      } catch (e) {
        AppLogger.error(
            "Error unpublishing recipe ${AppLogger.sanitize(recipeId)} in Supabase",
            errorObject: e);
        // Local update still succeeded, so don't rethrow
      }
    } else {
      AppLogger.debug(
          'Skipping Supabase update for unpublish - user not authenticated');
    }

    // Update local state
    final index = _userRecipes.indexWhere((element) => element.id == recipeId);
    if (index >= 0) {
      _userRecipes[index] = _userRecipes[index].copyWith(isPublic: false);
    }

    notifyListeners();
  }

  // Returns the ID of the newly created recipe, or null on failure.
  Future<String?> copyUserRecipe(RecipeModel originalRecipe) async {
    // Get current user and locale
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in, cannot copy recipe.");
    }
    // Locale-agnostic policy for user recipes: canonicalize to 'en' on write
    const String effectiveLocale = 'en';

    // Generate new ID and vendor ID
    final now = DateTime.now(); // Keep local 'now' for timestamp generation
    final nowUtc = now.toUtc(); // Get UTC time for database storage
    final timestamp =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final newRecipeId = 'usr-${user.id}-$timestamp';
    // Make sure to use the full user ID to match the RLS policy
    final newVendorId = 'usr-${user.id}';

    try {
      await _database.transaction(() async {
        // 1. Insert new Recipe entry
        final recipeCompanion = RecipesCompanion(
          id: drift.Value(newRecipeId),
          brewingMethodId: drift.Value(originalRecipe.brewingMethodId),
          coffeeAmount: drift.Value(originalRecipe.coffeeAmount),
          waterAmount: drift.Value(originalRecipe.waterAmount),
          waterTemp: originalRecipe.waterTemp != null
              ? drift.Value(originalRecipe.waterTemp!)
              : const drift.Value.absent(),
          brewTime: drift.Value(originalRecipe.brewTime.inSeconds),
          vendorId: drift.Value(newVendorId),
          lastModified: drift.Value(nowUtc), // Use UTC time
          // Copy import status if applicable, though unlikely for non-user recipes
          importId: originalRecipe.importId != null
              ? drift.Value(originalRecipe.importId!)
              : const drift.Value.absent(),
          isImported: originalRecipe.isImported != null
              ? drift.Value(originalRecipe.isImported!)
              : const drift.Value.absent(),
          isPublic: drift.Value(originalRecipe.isPublic), // Copy isPublic field
        );
        // Use insertOrUpdate, which handles potential (though unlikely) conflicts
        await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

        // 2. Insert new Steps entries (canonical 'en')
        for (final step in originalRecipe.steps) {
          final stepCompanion = StepsCompanion(
            id: drift.Value(uuid.v4()), // New unique ID for the step
            recipeId: drift.Value(newRecipeId), // Link to the new recipe
            stepOrder: drift.Value(step.order),
            description: drift.Value(step.description),
            time: drift.Value(step.time.inSeconds.toString()),
            locale: drift.Value(effectiveLocale), // Canonical 'en'
          );
          // Use insertOrUpdate
          await _database.stepsDao.insertOrUpdateStep(stepCompanion);
        }

        // 3. Insert new RecipeLocalizations entry (canonical 'en')
        final localizationCompanion = RecipeLocalizationsCompanion(
          id: drift.Value(uuid.v4()), // New unique ID for localization
          recipeId: drift.Value(newRecipeId), // Link to the new recipe
          name: drift.Value('${originalRecipe.name} (Copy)'), // Add suffix
          grindSize: drift.Value(originalRecipe.grindSize),
          shortDescription: drift.Value(originalRecipe.shortDescription),
          locale: drift.Value(effectiveLocale), // Canonical 'en'
        );
        // Use insertOrUpdate
        await _database.recipeLocalizationsDao
            .insertOrUpdateLocalization(localizationCompanion);

        // 4. Insert default UserRecipePreferences using the existing update method
        // which handles insertion if the record doesn't exist.
        await _database.userRecipePreferencesDao.updatePreferences(
          newRecipeId,
          isFavorite: false, // Explicitly set default
          // Ensure other fields are handled by updatePreferences defaults or are absent
        );
      });

      // Add to local state (optional, as refresh should handle it)
      // final copiedRecipeModel = await _database.recipesDao.getRecipeModelById(newRecipeId, effectiveLocale);
      // if (copiedRecipeModel != null) {
      //   _userRecipes.add(copiedRecipeModel);
      // }
      notifyListeners(); // Notify that user recipes might have changed
      return newRecipeId; // Return the ID of the created recipe
    } catch (e) {
      AppLogger.error("Error copying recipe", errorObject: e);
      // rethrow; // Don't rethrow, return null to indicate failure
      return null;
    }
  }

  // Import a recipe fetched from Supabase
  Future<String?> importSupabaseRecipe(
      Map<String, dynamic> supabaseRecipeData) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      AppLogger.warning("User not logged in, cannot import recipe.");
      return null; // Or throw an exception
    }

    final String originalSupabaseId = supabaseRecipeData['id'];
    final String userId = user.id;

    // Generate new local ID
    final now = DateTime.now(); // Keep local 'now' for timestamp generation
    final nowUtc = now.toUtc(); // Get UTC time for database storage
    final timestamp =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final newLocalRecipeId = 'usr-$userId-$timestamp';
    // Make sure to use the full user ID to match the RLS policy
    final newVendorId = 'usr-$userId';

    try {
      await _database.transaction(() async {
        // 1. Insert Recipe
        final recipeCompanion = RecipesCompanion(
          // --- MODIFICATION START ---
          // Check if the recipe being imported already has an import_id.
          // If yes, preserve it. Otherwise, use the original recipe's ID.
          importId: drift.Value(supabaseRecipeData['import_id'] ??
              originalSupabaseId), // Preserve existing or use original ID
          // --- MODIFICATION END ---
          id: drift.Value(newLocalRecipeId),
          brewingMethodId: drift.Value(supabaseRecipeData['brewing_method_id']),
          coffeeAmount: drift.Value(
              (supabaseRecipeData['coffee_amount'] as num).toDouble()),
          waterAmount: drift.Value(
              (supabaseRecipeData['water_amount'] as num).toDouble()),
          waterTemp: supabaseRecipeData['water_temp'] != null
              ? drift.Value(
                  (supabaseRecipeData['water_temp'] as num).toDouble())
              : const drift.Value.absent(),
          brewTime: drift.Value(supabaseRecipeData['brew_time']),
          vendorId: drift.Value(newVendorId),
          lastModified: drift.Value(nowUtc), // Use UTC time
          isImported: drift.Value(true), // Mark as imported
          isPublic: drift.Value(supabaseRecipeData['ispublic'] ??
              false), // Include isPublic field from Supabase
        );
        await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

        // 2. Insert Localizations (import as-is, then normalize to canonical 'en')
        final localizationsData =
            supabaseRecipeData['user_recipe_localizations'] as List<dynamic>? ??
                [];
        // Delete any pre-existing localizations for safety
        await _database.recipeLocalizationsDao
            .deleteLocalizationsForRecipe(newLocalRecipeId);
        for (final locData in localizationsData) {
          final localizationCompanion = RecipeLocalizationsCompanion(
            id: drift.Value(uuid.v4()), // New unique ID
            recipeId: drift.Value(newLocalRecipeId), // Link to new local recipe
            // Canonicalize to 'en'
            locale: const drift.Value('en'),
            name: drift.Value(locData['name']),
            grindSize: drift.Value(locData['grind_size']),
            shortDescription: drift.Value(locData['short_description']),
          );
          await _database.recipeLocalizationsDao
              .insertOrUpdateLocalization(localizationCompanion);
        }

        // 3. Insert Steps (import as-is, then normalize to canonical 'en' to avoid duplicates)
        final stepsData =
            supabaseRecipeData['user_steps'] as List<dynamic>? ?? [];
        // Delete any pre-existing steps for safety
        await _database.stepsDao.deleteStepsForRecipe(newLocalRecipeId);
        for (final stepData in stepsData) {
          final stepCompanion = StepsCompanion(
            id: drift.Value(uuid.v4()), // New unique ID
            recipeId: drift.Value(newLocalRecipeId), // Link to new local recipe
            stepOrder: drift.Value(stepData['step_order']),
            description: drift.Value(stepData['description']),
            time: drift.Value(stepData['time']),
            // Canonicalize to 'en' to keep locale-agnostic behavior
            locale: const drift.Value('en'),
          );
          await _database.stepsDao.insertOrUpdateStep(stepCompanion);
        }

        // 4. Insert default UserRecipePreferences
        await _database.userRecipePreferencesDao.updatePreferences(
          newLocalRecipeId,
          isFavorite: false, // Default value
        );
      });

      AppLogger.debug(
          "Recipe imported successfully with new ID: ${AppLogger.sanitize(newLocalRecipeId)}");
      notifyListeners(); // Notify UI about potential changes
      return newLocalRecipeId;
    } catch (e) {
      AppLogger.error(
          "Error importing recipe ${AppLogger.sanitize(originalSupabaseId)}",
          errorObject: e);
      return null;
    }
  }

  Future<void> loadUserRecipes() async {
    // Load all user recipes without applying a locale filter.
    final recipes = await _database.recipesDao.getAllRecipes('');
    _userRecipes = recipes;
    notifyListeners();
  }

  Future<void> updateUserRecipeIdsAfterLogin(
      String oldUserId, String newUserId) async {
    AppLogger.debug(
        'Attempting to update recipe IDs from anonymous user ${AppLogger.sanitize(oldUserId)} to ${AppLogger.sanitize(newUserId)}');
    final oldVendorId = 'usr-$oldUserId';
    // Make sure to use the full user ID to match the RLS policy
    final newVendorId = 'usr-$newUserId';

    try {
      await _database.transaction(() async {
        // Find recipes belonging to the old anonymous user
        final userRecipesToUpdate = await (_database.select(_database.recipes)
              ..where((tbl) => tbl.vendorId.equals(oldVendorId)))
            .get();

        AppLogger.debug(
            'Found ${userRecipesToUpdate.length} recipes to update.');

        for (final recipe in userRecipesToUpdate) {
          final oldRecipeId = recipe.id;
          AppLogger.debug(
              'Processing recipe with old ID: ${AppLogger.sanitize(oldRecipeId)}');

          // Extract timestamp part from the old ID
          final idParts = oldRecipeId.split('-');
          if (idParts.length != 3 || idParts[0] != 'usr') {
            AppLogger.warning(
                'Skipping invalid recipe ID format: ${AppLogger.sanitize(oldRecipeId)}');
            continue; // Skip if the ID format is unexpected
          }
          final timestampPart = idParts[2];
          final newRecipeId = 'usr-$newUserId-$timestampPart';

          AppLogger.debug(
              '  New Recipe ID: ${AppLogger.sanitize(newRecipeId)}');
          AppLogger.debug(
              '  New Vendor ID: ${AppLogger.sanitize(newVendorId)}');

          // 1. Update RecipeLocalizations table
          final updatedLocalizationsCount =
              await (_database.update(_database.recipeLocalizations)
                    ..where((tbl) => tbl.recipeId.equals(oldRecipeId)))
                  .write(RecipeLocalizationsCompanion(
            recipeId: drift.Value(newRecipeId),
          ));
          AppLogger.debug(
              '  Updated $updatedLocalizationsCount localizations for recipe ${AppLogger.sanitize(oldRecipeId)}');

          // 2. Update Steps table
          final updatedStepsCount = await (_database.update(_database.steps)
                ..where((tbl) => tbl.recipeId.equals(oldRecipeId)))
              .write(StepsCompanion(
            recipeId: drift.Value(newRecipeId),
          ));
          AppLogger.debug(
              '  Updated $updatedStepsCount steps for recipe ${AppLogger.sanitize(oldRecipeId)}');

          // 3. Update Recipes table (update ID and vendorId)
          // IMPORTANT: Update the recipe ID *last* to avoid foreign key constraint issues
          // if RecipeLocalizations or Steps were updated first referencing the old ID.
          // The transaction ensures this is safe.
          final updatedRecipesCount = await (_database.update(_database.recipes)
                ..where((tbl) => tbl.id.equals(oldRecipeId)))
              .write(RecipesCompanion(
            id: drift.Value(newRecipeId),
            vendorId: drift.Value(newVendorId),
            lastModified: drift.Value(DateTime.now().toUtc()), // Use UTC time
          ));
          AppLogger.debug(
              '  Updated $updatedRecipesCount recipe entry from ${AppLogger.sanitize(oldRecipeId)} to ${AppLogger.sanitize(newRecipeId)}');

          if (updatedRecipesCount == 0) {
            AppLogger.warning(
                'Warning: Recipe with ID ${AppLogger.sanitize(oldRecipeId)} not found for final update step.');
          }
        }
      });
      AppLogger.debug(
          'Completed updating recipe IDs from anonymous user ${AppLogger.sanitize(oldUserId)} to ${AppLogger.sanitize(newUserId)}');
      // Optionally reload recipes if needed, though sync might handle this
      // await loadUserRecipes();
    } catch (e) {
      AppLogger.error('Error updating user recipe IDs after login',
          errorObject: e);
      // Consider re-throwing or handling the error more gracefully
    }
  }

  // Method to clear import status for a given recipe ID
  Future<void> clearImportStatus(String recipeId) async {
    try {
      await _database.transaction(() async {
        final updateCompanion = RecipesCompanion(
          importId: const drift.Value(null), // Set importId to null
          isImported: const drift.Value(false), // Set isImported to false
          lastModified: drift.Value(DateTime.now().toUtc()), // Update timestamp
        );
        await (_database.update(_database.recipes)
              ..where((tbl) => tbl.id.equals(recipeId)))
            .write(updateCompanion);
      });
      AppLogger.debug(
          'Cleared import status for recipe ${AppLogger.sanitize(recipeId)}');
      // Optionally, update local state if needed, though a full refresh might be better
      // notifyListeners();
    } catch (e) {
      AppLogger.error(
          'Error clearing import status for recipe ${AppLogger.sanitize(recipeId)}',
          errorObject: e);
      // Rethrow or handle as needed
      rethrow;
    }
  }

  // Get the name of a user recipe from its single localization entry
  Future<String?> getUserRecipeName(String recipeId) async {
    if (!recipeId.startsWith('usr-')) {
      // This method is only intended for user recipes
      AppLogger.warning(
          "Warning: getUserRecipeName called for non-user recipe: ${AppLogger.sanitize(recipeId)}");
      return null; // Or throw an error
    }
    try {
      // Fetch the first (and only) localization for this user recipe ID
      final localization =
          await (_database.select(_database.recipeLocalizations)
                ..where((tbl) => tbl.recipeId.equals(recipeId))
                ..limit(1))
              .getSingleOrNull();

      return localization?.name;
    } catch (e) {
      AppLogger.error(
          "Error fetching name for user recipe ${AppLogger.sanitize(recipeId)}",
          errorObject: e);
      return null; // Return null on error
    }
  }

  // Method to handle moderation checks after user authentication
  Future<void> checkModerationAfterLogin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug(
          'DEBUG: Skipping post-login moderation check - user not authenticated or anonymous');
      return;
    }

    try {
      AppLogger.debug(
          'DEBUG: Performing post-login moderation check for user: ${AppLogger.sanitize(user.id)}');

      // Clean up any existing incorrect moderation flags for unpublished recipes
      await clearModerationFlagsForUnpublishedRecipes();

      // Check for recipes that need moderation
      final recipesNeedingModeration =
          await _database.recipesDao.getRecipesNeedingModeration();
      AppLogger.debug(
          'DEBUG: Found ${recipesNeedingModeration.length} recipes needing moderation after login');

      // The actual popup display will be handled by the UI layer (HomeScreen)
      // This method just ensures the data is clean and up-to-date
    } catch (e) {
      AppLogger.error('ERROR: Failed to perform post-login moderation check',
          errorObject: e);
      // Don't throw - this is a background operation
    }
  }

  // Method to clear moderation flags for unpublished recipes owned by the current user
  Future<int> clearModerationFlagsForUnpublishedRecipes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug(
          'DEBUG: Skipping moderation cleanup - user not authenticated or anonymous');
      return 0;
    }

    try {
      final userVendorId = 'usr-${user.id}';

      // Find unpublished recipes owned by this user that have moderation flags
      final unpublishedRecipes = await (_database.select(_database.recipes)
            ..where((tbl) =>
                tbl.vendorId.equals(userVendorId) &
                tbl.isPublic.equals(false) &
                tbl.needsModerationReview.equals(true)))
          .get();

      if (unpublishedRecipes.isEmpty) {
        AppLogger.debug(
            'DEBUG: No unpublished recipes with moderation flags found for user ${AppLogger.sanitize(user.id)}');
        return 0;
      }

      final recipeIds = unpublishedRecipes.map((r) => r.id).toList();
      AppLogger.debug(
          'DEBUG: Clearing moderation flags for ${recipeIds.length} unpublished recipes: ${AppLogger.sanitize(recipeIds.toString())}');

      int clearedCount = 0;
      for (final recipeId in recipeIds) {
        await _database.recipesDao.setNeedsModerationReview(recipeId, false);
        clearedCount++;
      }

      AppLogger.debug(
          'DEBUG: Successfully cleared moderation flags for $clearedCount unpublished recipes');
      return clearedCount;
    } catch (e) {
      AppLogger.error(
          'ERROR: Failed to clear moderation flags for unpublished recipes',
          errorObject: e);
      return 0;
    }
  }
}
