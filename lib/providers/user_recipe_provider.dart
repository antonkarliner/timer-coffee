import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRecipeProvider with ChangeNotifier {
  List<RecipeModel> _userRecipes = [];
  final AppDatabase _database;
  final Uuid uuid = const Uuid();

  UserRecipeProvider(this._database);

  List<RecipeModel> get userRecipes => [..._userRecipes];

  Future<void> createUserRecipe(RecipeModel recipe) async {
    // Get current user from Supabase
    final user = Supabase.instance.client.auth.currentUser;
    // Always use the current locale for steps and localization.
    final effectiveLocale = Intl.getCurrentLocale().split('_')[0];

    // Create a recipe with vendor ID
    final recipeWithVendorId = recipe.copyWith(
      // Use "usr-<user_id>" as vendor ID, but only if user is not null
      // Make sure to use the full user ID to match the RLS policy
      vendorId: user != null ? 'usr-${user.id}' : null,
    );

    // Add debug logging
    print(
        'Creating user recipe with vendor_id: ${recipeWithVendorId.vendorId}');

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
      );
      await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

      // Insert steps using effective locale (empty string for user recipes)
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

      // Insert localization using effective locale
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
    // Always use the current locale for steps and localization.
    final effectiveLocale = Intl.getCurrentLocale().split('_')[0];
    print(
        "UserRecipeProvider.updateUserRecipe: effectiveLocale = '$effectiveLocale'"); // Add logging

    // Add explicit check for empty or invalid locale before proceeding
    if (effectiveLocale.isEmpty || effectiveLocale.length < 2) {
      print(
          "UserRecipeProvider.updateUserRecipe: ERROR - Determined locale ('$effectiveLocale') is invalid.");
      // Throw a specific error instead of letting Drift catch the constraint violation
      throw Exception(
          "Invalid locale determined: '$effectiveLocale'. Cannot update recipe steps/localization.");
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
    );

    // Wrap database operations in a transaction
    await _database.transaction(() async {
      await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

      // Update steps: delete existing steps for this recipe with the effective locale, then recreate.
      final steps = await _database.stepsDao
          .getLocalizedBrewStepsForRecipe(recipe.id, effectiveLocale);
      for (final step in steps) {
        await _database.stepsDao
            .deleteStep(step.order, recipe.id, effectiveLocale);
      }
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

      // Update localization: first delete existing localization for this recipe with the effective locale.
      try {
        await _database.recipeLocalizationsDao
            .deleteLocalization(recipe.id, effectiveLocale);
      } catch (e) {
        print("Error deleting localization: $e");
      }

      // Then create a new localization entry using the effective locale.
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
    final effectiveLocale = recipeId.startsWith('usr-')
        ? ''
        : Intl.getCurrentLocale().split('_')[0];
    // Delete from local database
    try {
      await _database.recipesDao.deleteRecipe(recipeId);
    } catch (e) {
      print("Error deleting recipe: $e");
    }
    try {
      await _database.recipeLocalizationsDao
          .deleteLocalization(recipeId, effectiveLocale);
    } catch (e) {
      print("Error deleting localization: $e");
    }
    try {
      final steps = await _database.stepsDao
          .getLocalizedBrewStepsForRecipe(recipeId, effectiveLocale);
      for (final step in steps) {
        try {
          await _database.stepsDao
              .deleteStep(step.order, recipeId, effectiveLocale);
        } catch (e) {
          print("Error deleting step: $e");
        }
      }
    } catch (e) {
      print("Error retrieving steps: $e");
    }

    // Mark as deleted in Supabase if it's a user recipe and the user is not anonymous
    if (recipeId.startsWith('usr-')) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        // Only perform remote cleanup if user is logged in and not anonymous
        if (user != null && !user.isAnonymous) {
          final userId = user.id;
          print(
              'Performing remote cleanup for recipe $recipeId for user $userId...');

          // 1. Clean up user_stats (mark as deleted)
          try {
            await Supabase.instance.client.from('user_stats').update({
              'is_deleted': true,
              // Optionally update a 'last_modified' timestamp if the table has one
            }).match({
              'user_id': userId,
              'recipe_id': recipeId,
            });
            print('Marked related user_stats as deleted for recipe $recipeId.');
          } catch (e) {
            print(
                "Error marking related user_stats as deleted for recipe $recipeId: $e");
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
            print(
                'Deleted related user_recipe_preferences for recipe $recipeId.');
          } catch (e) {
            print(
                "Error deleting related user_recipe_preferences for recipe $recipeId: $e");
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
            print(
                'Marked recipe $recipeId as deleted and private in Supabase.');
          } catch (e) {
            // This was the original catch block, keep it for the main recipe deletion error
            print("Error marking recipe $recipeId as deleted in Supabase: $e");
          }
        } else {
          print(
              'Skipping Supabase remote cleanup/delete for anonymous user or no user.');
        }
      } catch (e) {
        print("Error marking recipe as deleted in Supabase: $e");
      }
    }

    _userRecipes.removeWhere((element) => element.id == recipeId);
    notifyListeners();
  }

  // Returns the ID of the newly created recipe, or null on failure.
  Future<String?> copyUserRecipe(RecipeModel originalRecipe) async {
    // Get current user and locale
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in, cannot copy recipe.");
    }
    // Use the current app locale for the initial steps and localization of the copied recipe.
    final effectiveLocale = Intl.getCurrentLocale().split('_')[0];

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
        );
        // Use insertOrUpdate, which handles potential (though unlikely) conflicts
        await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

        // 2. Insert new Steps entries
        for (final step in originalRecipe.steps) {
          final stepCompanion = StepsCompanion(
            id: drift.Value(uuid.v4()), // New unique ID for the step
            recipeId: drift.Value(newRecipeId), // Link to the new recipe
            stepOrder: drift.Value(step.order),
            description: drift.Value(step.description),
            time: drift.Value(step.time.inSeconds.toString()),
            locale: drift.Value(effectiveLocale), // Use current locale
          );
          // Use insertOrUpdate
          await _database.stepsDao.insertOrUpdateStep(stepCompanion);
        }

        // 3. Insert new RecipeLocalizations entry
        final localizationCompanion = RecipeLocalizationsCompanion(
          id: drift.Value(uuid.v4()), // New unique ID for localization
          recipeId: drift.Value(newRecipeId), // Link to the new recipe
          name: drift.Value('${originalRecipe.name} (Copy)'), // Add suffix
          grindSize: drift.Value(originalRecipe.grindSize),
          shortDescription: drift.Value(originalRecipe.shortDescription),
          locale: drift.Value(effectiveLocale), // Use current locale
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
      print("Error copying recipe: $e");
      // rethrow; // Don't rethrow, return null to indicate failure
      return null;
    }
  }

  // Import a recipe fetched from Supabase
  Future<String?> importSupabaseRecipe(
      Map<String, dynamic> supabaseRecipeData) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print("User not logged in, cannot import recipe.");
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
        );
        await _database.recipesDao.insertOrUpdateRecipe(recipeCompanion);

        // 2. Insert Localizations
        final localizationsData =
            supabaseRecipeData['user_recipe_localizations'] as List<dynamic>? ??
                [];
        for (final locData in localizationsData) {
          final localizationCompanion = RecipeLocalizationsCompanion(
            id: drift.Value(uuid.v4()), // New unique ID
            recipeId: drift.Value(newLocalRecipeId), // Link to new local recipe
            locale: drift.Value(locData['locale']),
            name: drift.Value(locData['name']),
            grindSize: drift.Value(locData['grind_size']),
            shortDescription: drift.Value(locData['short_description']),
          );
          await _database.recipeLocalizationsDao
              .insertOrUpdateLocalization(localizationCompanion);
        }

        // 3. Insert Steps
        final stepsData =
            supabaseRecipeData['user_steps'] as List<dynamic>? ?? [];
        for (final stepData in stepsData) {
          final stepCompanion = StepsCompanion(
            id: drift.Value(uuid.v4()), // New unique ID
            recipeId: drift.Value(newLocalRecipeId), // Link to new local recipe
            stepOrder: drift.Value(stepData['step_order']),
            description: drift.Value(stepData['description']),
            time: drift.Value(stepData['time']),
            locale: drift.Value(stepData['locale']),
          );
          await _database.stepsDao.insertOrUpdateStep(stepCompanion);
        }

        // 4. Insert default UserRecipePreferences
        await _database.userRecipePreferencesDao.updatePreferences(
          newLocalRecipeId,
          isFavorite: false, // Default value
        );
      });

      print("Recipe imported successfully with new ID: $newLocalRecipeId");
      notifyListeners(); // Notify UI about potential changes
      return newLocalRecipeId;
    } catch (e) {
      print("Error importing recipe $originalSupabaseId: $e");
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
    print(
        'Attempting to update recipe IDs from anonymous user $oldUserId to $newUserId');
    final oldVendorId = 'usr-$oldUserId';
    // Make sure to use the full user ID to match the RLS policy
    final newVendorId = 'usr-$newUserId';

    try {
      await _database.transaction(() async {
        // Find recipes belonging to the old anonymous user
        final userRecipesToUpdate = await (_database.select(_database.recipes)
              ..where((tbl) => tbl.vendorId.equals(oldVendorId)))
            .get();

        print('Found ${userRecipesToUpdate.length} recipes to update.');

        for (final recipe in userRecipesToUpdate) {
          final oldRecipeId = recipe.id;
          print('Processing recipe with old ID: $oldRecipeId');

          // Extract timestamp part from the old ID
          final idParts = oldRecipeId.split('-');
          if (idParts.length != 3 || idParts[0] != 'usr') {
            print('Skipping invalid recipe ID format: $oldRecipeId');
            continue; // Skip if the ID format is unexpected
          }
          final timestampPart = idParts[2];
          final newRecipeId = 'usr-$newUserId-$timestampPart';

          print('  New Recipe ID: $newRecipeId');
          print('  New Vendor ID: $newVendorId');

          // 1. Update RecipeLocalizations table
          final updatedLocalizationsCount =
              await (_database.update(_database.recipeLocalizations)
                    ..where((tbl) => tbl.recipeId.equals(oldRecipeId)))
                  .write(RecipeLocalizationsCompanion(
            recipeId: drift.Value(newRecipeId),
          ));
          print(
              '  Updated $updatedLocalizationsCount localizations for recipe $oldRecipeId');

          // 2. Update Steps table
          final updatedStepsCount = await (_database.update(_database.steps)
                ..where((tbl) => tbl.recipeId.equals(oldRecipeId)))
              .write(StepsCompanion(
            recipeId: drift.Value(newRecipeId),
          ));
          print('  Updated $updatedStepsCount steps for recipe $oldRecipeId');

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
          print(
              '  Updated $updatedRecipesCount recipe entry from $oldRecipeId to $newRecipeId');

          if (updatedRecipesCount == 0) {
            print(
                'Warning: Recipe with ID $oldRecipeId not found for final update step.');
          }
        }
      });
      print(
          'Completed updating recipe IDs from anonymous user $oldUserId to $newUserId');
      // Optionally reload recipes if needed, though sync might handle this
      // await loadUserRecipes();
    } catch (e) {
      print('Error updating user recipe IDs after login: $e');
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
      print('Cleared import status for recipe $recipeId');
      // Optionally, update local state if needed, though a full refresh might be better
      // notifyListeners();
    } catch (e) {
      print('Error clearing import status for recipe $recipeId: $e');
      // Rethrow or handle as needed
      rethrow;
    }
  }

  // Get the name of a user recipe from its single localization entry
  Future<String?> getUserRecipeName(String recipeId) async {
    if (!recipeId.startsWith('usr-')) {
      // This method is only intended for user recipes
      print("Warning: getUserRecipeName called for non-user recipe: $recipeId");
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
      print("Error fetching name for user recipe $recipeId: $e");
      return null; // Return null on error
    }
  }
}
