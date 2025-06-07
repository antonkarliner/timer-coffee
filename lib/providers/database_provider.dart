import 'dart:async';
import 'dart:math' as math;

import 'package:coffee_timer/database/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/extensions.dart';
import 'package:diacritic/diacritic.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart'; // Added for sync timestamps
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Ensure Intl is imported if needed for locale logic

class DatabaseProvider {
  final AppDatabase _db;
  // Constants for SharedPreferences keys
  static const String _lastSyncTimestampKey = 'lastUserRecipeSyncTimestamp';
  static const String _lastDeferredModerationCheckKey =
      'lastDeferredModerationCheckTimestamp';

  DatabaseProvider(this._db);

  // --- SharedPreferences Helpers ---

  Future<DateTime?> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString(_lastSyncTimestampKey);
    return timestampString != null ? DateTime.parse(timestampString) : null;
  }

  Future<void> _setLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimestampKey, timestamp.toIso8601String());
  }

  Future<DateTime?> _getLastDeferredModerationCheckTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString(_lastDeferredModerationCheckKey);
    return timestampString != null ? DateTime.parse(timestampString) : null;
  }

  Future<void> _setLastDeferredModerationCheckTimestamp(
      DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastDeferredModerationCheckKey, timestamp.toIso8601String());
  }

  // --- End SharedPreferences Helpers ---

  Future<void> initializeDatabase({required bool isFirstLaunch}) async {
    if (isFirstLaunch) {
      // No timeout on the first launch to ensure all essential data is loaded
      try {
        await _initializeDatabaseInternal(isFirstLaunch: isFirstLaunch);
      } catch (error) {
        print('Error initializing database on first launch: $error');
        // Optionally, handle the error appropriately
      }
    } else {
      // Apply a 10-second timeout to the entire initialization process
      try {
        await _initializeDatabaseInternal(isFirstLaunch: isFirstLaunch).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('initializeDatabase timed out');
            // Proceed with partial data or notify the user
            return;
          },
        );
      } catch (error) {
        print('Error initializing database: $error');
        // Optionally, handle other errors
      }
    }
  }

  Future<void> _initializeDatabaseInternal(
      {required bool isFirstLaunch}) async {
    await _fetchAndStoreReferenceData(isFirstLaunch: isFirstLaunch);
    await Future.wait([
      _fetchAndStoreRecipes(isFirstLaunch: isFirstLaunch),
      _fetchAndStoreExtraData(isFirstLaunch: isFirstLaunch),
      // Perform deferred moderation checks after main sync, but don't block forever if offline
      _performDeferredModerationChecks().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Deferred moderation checks timed out');
          return;
        },
      ),
    ]);
  }

  Future<void> _fetchAndStoreReferenceData(
      {required bool isFirstLaunch}) async {
    try {
      // Define individual futures
      final brewingMethodsFuture = Supabase.instance.client
          .from('brewing_methods')
          .select(
              'brewing_method_id,brewing_method'); // Removed show_on_main from select
      final supportedLocalesFuture =
          Supabase.instance.client.from('supported_locales').select();

      // Apply timeouts if it's not the first launch
      final brewingMethodsRequest = isFirstLaunch
          ? brewingMethodsFuture
          : brewingMethodsFuture.timeout(const Duration(seconds: 5));
      final supportedLocalesRequest = isFirstLaunch
          ? supportedLocalesFuture
          : supportedLocalesFuture.timeout(const Duration(seconds: 5));

      // Run all requests in parallel
      final responses = await Future.wait([
        brewingMethodsRequest,
        supportedLocalesRequest,
      ]);

      // Process the responses
      final brewingMethodsResponse = responses[0] as List<dynamic>;
      final supportedLocalesResponse = responses[1] as List<dynamic>;

      final brewingMethods = brewingMethodsResponse
          .map((json) => BrewingMethodsCompanionExtension.fromJson(json))
          .toList();
      final supportedLocales = supportedLocalesResponse
          .map((json) => SupportedLocalesCompanionExtension.fromJson(json))
          .toList();

      await _db.transaction(() async {
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.brewingMethods, brewingMethods);
          batch.insertAllOnConflictUpdate(
              _db.supportedLocales, supportedLocales);
        });
      });
    } catch (error) {
      print('Error fetching and storing reference data: $error');
      // Optionally, handle the error (e.g., provide default data)
    }
  }

  Future<void> _fetchAndStoreRecipes({required bool isFirstLaunch}) async {
    try {
      // Get all recipe IDs from local database
      final localRecipeIds =
          await _db.recipesDao.fetchIdsAndLastModifiedDates();

      // Fetch all recipes from Supabase
      var request = Supabase.instance.client
          .from('recipes')
          .select('*, recipe_localization(*), steps(*)');

      DateTime? lastModified = await _db.recipesDao.fetchLastModified();
      if (lastModified != null && !isFirstLaunch) {
        final lastModifiedUtc = lastModified.toUtc();
        request =
            request.gt('last_modified', lastModifiedUtc.toIso8601String());
      }

      // Apply timeout if it's not the first launch
      final response = isFirstLaunch
          ? await request
          : await request.timeout(const Duration(seconds: 5));

      final recipes = (response as List<dynamic>)
          .map((json) => RecipesCompanionExtension.fromJson(json))
          .toList();

      // Extract and store localizations
      final localizationsJson = response
          .expand((json) => (json['recipe_localization'] as List<dynamic>))
          .toList();
      final localizations = localizationsJson
          .map((json) => RecipeLocalizationsCompanionExtension.fromJson(json))
          .toList();

      // Extract and store steps
      final stepsJson =
          response.expand((json) => (json['steps'] as List<dynamic>)).toList();
      final steps = stepsJson
          .map((json) => StepsCompanionExtension.fromJson(json))
          .toList();

      // Get all recipe IDs from Supabase
      // If we're not fetching all recipes (i.e., we're only fetching updated recipes),
      // we need to fetch all recipe IDs from Supabase to check for deleted recipes
      Set<String> supabaseRecipeIds;
      if (!isFirstLaunch && lastModified != null) {
        // We're only fetching updated recipes, so we need to fetch all recipe IDs separately
        final allRecipesResponse = await Supabase.instance.client
            .from('recipes')
            .select('id')
            .timeout(const Duration(seconds: 5));
        supabaseRecipeIds = (allRecipesResponse as List<dynamic>)
            .map((json) => json['id'] as String)
            .toSet();
      } else {
        // We're fetching all recipes, so we can use the IDs from the recipes we've already fetched
        supabaseRecipeIds = recipes.map((recipe) => recipe.id.value).toSet();
      }

      // Find recipes that exist in local DB but not in Supabase (deleted recipes)
      // Exclude user-created recipes (those with 'usr-' prefix) from deletion
      final deletedRecipeIds = localRecipeIds.keys
          .where(
              (id) => !supabaseRecipeIds.contains(id) && !id.startsWith('usr-'))
          .toList();

      // Delete these recipes from local DB
      for (final recipeId in deletedRecipeIds) {
        await _deleteRecipeFromLocalDb(recipeId);
      }

      await _db.transaction(() async {
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.recipes, recipes);
          batch.insertAllOnConflictUpdate(
              _db.recipeLocalizations, localizations);
          batch.insertAllOnConflictUpdate(_db.steps, steps);
        });
      });

      // Sync user recipes and imported recipes only for non-anonymous users
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && !user.isAnonymous) {
        await _syncUserRecipes(user.id, localRecipeIds);
        await _syncImportedRecipes(user.id);
      }
    } catch (error) {
      print('Error fetching and storing recipes: $error');
      // Optionally, handle the error
    }
  }

  // Sync user-created recipes with Supabase (Optimized with Timestamps)
  Future<void> _syncUserRecipes(
      String userId, Map<String, DateTime> localRecipeIds) async {
    final DateTime syncStartTime = DateTime.now().toUtc();
    final DateTime? lastSyncTime = await _getLastSyncTimestamp();
    print(
        'Starting user recipe sync for user $userId. Last sync: ${lastSyncTime?.toIso8601String() ?? 'Never'}');

    try {
      // --- UPLOAD ---
      print('Checking for local recipes to upload...');
      // Get local user recipes modified since last sync AND not flagged for moderation
      // AND recipes that were newly imported but not yet uploaded.
      final recipesToUpload = await _db.recipesDao
          .getUserRecipesModifiedAfter(lastSyncTime, userId);
      final newlyImportedRecipes = await _db.recipesDao
          .getImportedRecipesForUserNotYetUploaded(
              userId); // New DAO method needed

      // Combine the lists, ensuring uniqueness based on recipe ID
      final allRecipesToPotentiallyUpload = {
        for (var r in recipesToUpload) r.id: r
      };
      for (var r in newlyImportedRecipes) {
        allRecipesToPotentiallyUpload.putIfAbsent(r.id, () => r);
      }

      print(
          'Found ${allRecipesToPotentiallyUpload.length} local recipes to potentially upload (modified or newly imported).');

      for (final recipe in allRecipesToPotentiallyUpload.values) {
        // Double-check ownership (already filtered in DAO, but good practice)
        if (recipe.vendorId != 'usr-$userId') {
          print(
              'Skipping upload for recipe ${recipe.id} due to vendor ID mismatch: ${recipe.vendorId}');
          continue;
        }

        // Fetch current remote status (needed for ispublic check AND to see if it exists)
        final remoteData = await Supabase.instance.client
            .from('user_recipes')
            .select('id, last_modified, is_deleted, ispublic')
            .eq('id', recipe.id)
            .maybeSingle();

        // Skip if marked deleted remotely
        if (remoteData != null && remoteData['is_deleted'] == true) {
          print('Skipping upload for recipe ${recipe.id}, deleted remotely.');
          continue;
        }

        // Determine if this is a newly imported recipe needing its first upload
        final bool isFirstUploadForImport =
            recipe.isImported == true && remoteData == null;

        // Upload the recipe if:
        // 1. It's modified locally and newer than remote (handled by getUserRecipesModifiedAfter)
        // 2. It's a newly imported recipe that doesn't exist remotely yet (isFirstUploadForImport)
        if (isFirstUploadForImport ||
            recipesToUpload.any((r) => r.id == recipe.id)) {
          print(
              'Uploading recipe ${recipe.id}. Reason: ${isFirstUploadForImport ? "Newly imported" : "Modified locally"}');
          await _uploadRecipeToSupabase(recipe, userId,
              currentIsPublic: remoteData?['ispublic']);

          // // If it was the first upload for an imported recipe, mark isImported as false locally
          // // REMOVED: Keep isImported = true to allow future updates from parent
          // if (isFirstUploadForImport) {
          //   print('Marking recipe ${recipe.id} as no longer imported locally.');
          //   await _db.recipesDao.updateRecipe(
          //     recipe.id,
          //     RecipesCompanion(
          //       isImported: const drift.Value(false),
          //       lastModified:
          //           drift.Value(DateTime.now().toUtc()), // Update timestamp
          //     ),
          //   );
          // }
        } else if (recipe.isImported == true && remoteData != null) {
          // Exists remotely but wasn't in the 'modified' list - likely already synced or only needs download sync
          print(
              'Skipping upload for imported recipe ${recipe.id} - already exists remotely and not modified locally.');
        } else {
          // Wasn't modified locally and wasn't a new import needing upload
          print(
              'Skipping upload for recipe ${recipe.id} - not modified locally.');
        }
      }
      print('Finished processing potential uploads.');

      // --- HANDLE DELETIONS ---
      print('Checking for remotely deleted recipes...');
      // Fetch IDs of all remotely deleted recipes for this user, regardless of timestamp
      final deletedResponse = await Supabase.instance.client
          .from('user_recipes')
          .select('id')
          .eq('vendor_id', 'usr-$userId')
          .eq('is_deleted', true);

      final remotelyDeletedIds = (deletedResponse as List<dynamic>? ?? [])
          .map((e) => e['id'] as String)
          .toSet();

      // Find which of the remotely deleted IDs exist locally
      final List<String> idsToDeleteLocally = localRecipeIds.keys
          .where((localId) => remotelyDeletedIds.contains(localId))
          .toList();

      // Perform local deletions if necessary
      if (idsToDeleteLocally.isNotEmpty) {
        print(
            'Found ${idsToDeleteLocally.length} recipes to delete locally based on remote status.');
        await _db.transaction(() async {
          print('Deleting ${idsToDeleteLocally.length} recipes locally...');
          for (final id in idsToDeleteLocally) {
            // Pass false for markDeletedInSupabase as the deletion originated from Supabase.
            await _deleteRecipeFromLocalDb(id, markDeletedInSupabase: false);
          }
          print('Finished deleting recipes locally.');
        });
      } else {
        print('No remotely deleted recipes found that need local deletion.');
      }

      // --- DOWNLOAD UPDATES/INSERTS ---
      print('Checking for remote recipe updates/inserts...');
      // Build query to get NON-DELETED remote recipes modified since last sync
      var downloadQuery = Supabase.instance.client
          .from('user_recipes')
          .select('*, user_recipe_localizations(*), user_steps(*)')
          .eq('vendor_id', 'usr-$userId')
          .eq('is_deleted',
              false); // Only fetch non-deleted for updates/inserts

      if (lastSyncTime != null) {
        downloadQuery =
            downloadQuery.gt('last_modified', lastSyncTime.toIso8601String());
      }

      final downloadResponse = await downloadQuery;

      if (downloadResponse == null || (downloadResponse as List).isEmpty) {
        print('No new or updated remote recipes to download/insert.');
      } else {
        final remoteRecipesData = downloadResponse as List<dynamic>;
        print(
            'Found ${remoteRecipesData.length} remote recipes to download/insert.');

        final List<RecipesCompanion> recipesToInsertOrUpdate = [];
        final List<RecipeLocalizationsCompanion> localizationsToInsertOrUpdate =
            [];
        final List<StepsCompanion> stepsToInsertOrUpdate = [];

        for (final recipeJson in remoteRecipesData) {
          final recipeId = recipeJson['id'] as String;
          // We already filtered is_deleted=false in the query, but double-check just in case
          final isDeletedRemotely = recipeJson['is_deleted'] as bool? ?? false;
          if (isDeletedRemotely) {
            print(
                'Skipping unexpectedly deleted recipe in update/insert phase: $recipeId');
            continue;
          }

          final remoteLastModifiedStr = recipeJson['last_modified'] as String?;
          final remoteLastModified = remoteLastModifiedStr != null
              ? DateTime.parse(remoteLastModifiedStr).toUtc()
              : null;

          final localLastModified = localRecipeIds[recipeId];

          // Check if remote is newer (or local doesn't exist)
          // Note: The gt filter in the query already handles the timestamp comparison,
          // but this check adds robustness and handles the case where localLastModified is null.
          if (localLastModified == null ||
              (remoteLastModified != null &&
                  !remoteLastModified.isAtSameMomentAs(localLastModified) &&
                  remoteLastModified.isAfter(localLastModified))) {
            print('Processing download/update for recipe: $recipeId');
            final recipeCompanion =
                RecipesCompanionExtension.fromUserRecipeJson(recipeJson);
            // Ensure needs_moderation_review is false as we trust the cloud version
            recipesToInsertOrUpdate.add(recipeCompanion.copyWith(
                needsModerationReview: const drift.Value(false)));

            // Extract and add localizations
            final localizationsJson =
                recipeJson['user_recipe_localizations'] as List<dynamic>? ?? [];
            localizationsToInsertOrUpdate.addAll(localizationsJson.map((json) =>
                RecipeLocalizationsCompanionExtension
                    .fromUserRecipeLocalizationJson(json)));

            // Extract and add steps
            final stepsJson = recipeJson['user_steps'] as List<dynamic>? ?? [];
            stepsToInsertOrUpdate.addAll(stepsJson
                .map((json) => StepsCompanionExtension.fromUserStepJson(json)));
          } else {
            // This case should ideally not happen often due to the query filter,
            // but log it if it does.
            print(
                'Skipping download for recipe $recipeId (local is same or newer, or timestamp issue).');
          }
        }

        // Perform batch insert/update in a transaction
        if (recipesToInsertOrUpdate.isNotEmpty) {
          print(
              'Inserting/Updating ${recipesToInsertOrUpdate.length} downloaded recipes locally...');
          await _db.transaction(() async {
            await _db.batch((batch) {
              batch.insertAllOnConflictUpdate(
                  _db.recipes, recipesToInsertOrUpdate);
              // See previous comment about potential issues with orphaned related data if IDs change.
              batch.insertAllOnConflictUpdate(
                  _db.recipeLocalizations, localizationsToInsertOrUpdate);
              batch.insertAllOnConflictUpdate(_db.steps, stepsToInsertOrUpdate);
            });
          });
          print('Finished inserting/updating downloaded recipes.');
        } else {
          print(
              'No recipes needed inserting/updating from the downloaded batch.');
        }
      }

      // --- Update Last Sync Timestamp ---
      await _setLastSyncTimestamp(syncStartTime);
      print(
          'User recipe sync completed. Updated last sync time to: ${syncStartTime.toIso8601String()}');
    } catch (e, stacktrace) {
      print('Error during user recipe sync: $e');
      print(stacktrace);
      // Consider not updating the timestamp on error to retry next time
    }
  }

  // Upload a recipe to Supabase (minor adjustments for clarity)
  Future<void> _uploadRecipeToSupabase(Recipe recipe, String userId,
      {bool? currentIsPublic}) async {
    try {
      // Add debug logging
      print('Uploading recipe to Supabase: ${recipe.id}');
      print('User ID: $userId');
      print('Vendor ID from recipe: ${recipe.vendorId}');

      // Ensure vendor_id uses the full user ID for RLS
      final String effectiveVendorId = 'usr-$userId';

      // Convert recipe to Supabase format
      final recipeJson = {
        'id': recipe.id,
        'brewing_method_id': recipe.brewingMethodId,
        'coffee_amount': recipe.coffeeAmount,
        'water_amount': recipe.waterAmount,
        'water_temp': recipe.waterTemp,
        'brew_time': recipe.brewTime,
        'vendor_id':
            effectiveVendorId, // Use the effective vendor ID instead of just userId
        'last_modified': recipe.lastModified?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(), // Ensure UTC
        'import_id': recipe.importId,
        'is_imported': recipe.isImported,
        'ispublic': currentIsPublic ??
            false, // Preserve current public status if known, else false
        'is_deleted': false,
      };

      // --- Explicit Insert/Update Logic ---
      // Check if the recipe already exists remotely
      final existingRecipe = await Supabase.instance.client
          .from('user_recipes')
          .select('id')
          .eq('id', recipe.id)
          .maybeSingle();

      if (existingRecipe == null) {
        // Recipe doesn't exist, perform INSERT
        print('  Recipe ${recipe.id} not found remotely, performing INSERT.');
        await Supabase.instance.client.from('user_recipes').insert(recipeJson);
      } else {
        // Recipe exists, perform UPDATE
        print('  Recipe ${recipe.id} found remotely, performing UPDATE.');
        await Supabase.instance.client
            .from('user_recipes')
            .update(recipeJson)
            .eq('id', recipe.id);
      }
      // --- End Explicit Insert/Update Logic ---

      // Get localizations and steps for this recipe
      final localizations =
          await _db.recipeLocalizationsDao.getLocalizationsForRecipe(recipe.id);
      final steps = await _db.stepsDao.getStepsForRecipe(recipe.id);

      // Upload localizations (Batch Upsert)
      final localizationsJsonList = localizations
          .map((loc) => {
                'id':
                    loc.id, // Assuming local ID is stable or handled by upsert
                'recipe_id': loc.recipeId,
                'locale': loc.locale,
                'name': loc.name,
                'grind_size': loc.grindSize,
                'short_description': loc.shortDescription,
              })
          .toList();
      if (localizationsJsonList.isNotEmpty) {
        await Supabase.instance.client
            .from('user_recipe_localizations')
            .upsert(localizationsJsonList);
      }

      // Upload steps (Batch Upsert)
      final stepsJsonList = steps
          .map((step) => {
                'id':
                    step.id, // Assuming local ID is stable or handled by upsert
                'recipe_id': step.recipeId,
                'step_order': step.stepOrder,
                'description': step.description,
                'time': step.time,
                'locale': step.locale,
              })
          .toList();
      if (stepsJsonList.isNotEmpty) {
        await Supabase.instance.client.from('user_steps').upsert(stepsJsonList);
      }
      print('Successfully uploaded recipe ${recipe.id} and related data.');
    } catch (e, stacktrace) {
      print('Error uploading recipe ${recipe.id} to Supabase: $e');
      print(stacktrace);
      // Consider how to handle upload errors (e.g., retry later?)
    }
  }

  // Sync imported recipes with their originals (Minor adjustments for consistency)
  Future<void> _syncImportedRecipes(String userId) async {
    try {
      // Get all local imported recipes
      final importedRecipes = await _db.recipesDao.getImportedRecipes();

      for (final recipe in importedRecipes) {
        // Skip recipes without importId
        if (recipe.importId == null) continue;

        // Check if original recipe exists and is public
        final String importId =
            recipe.importId!; // Non-null assertion is safe here

        final response = await Supabase.instance.client
            .from('user_recipes')
            .select('*, user_recipe_localizations(*), user_steps(*)')
            .eq('id', importId)
            .eq('ispublic', true)
            .eq('is_deleted', false) // Only get non-deleted recipes
            .maybeSingle();

        if (response == null) {
          // Original recipe not found, not public, or deleted
          continue;
        }

        final DateTime? originalLastModified = response['last_modified'] != null
            ? DateTime.parse(response['last_modified']).toUtc()
            : null;
        final DateTime localLastModified =
            recipe.lastModified?.toUtc() ?? DateTime(0);

        // If original is newer than local copy
        if (originalLastModified != null &&
            originalLastModified.isAfter(localLastModified)) {
          print('Updating local imported recipe ${recipe.id} from $importId');
          // Update local copy with original's data
          final updatedRecipe = RecipesCompanion(
            id: drift.Value(recipe.id), // Keep local ID
            brewingMethodId: drift.Value(response['brewing_method_id']),
            coffeeAmount:
                drift.Value((response['coffee_amount'] as num).toDouble()),
            waterAmount:
                drift.Value((response['water_amount'] as num).toDouble()),
            waterTemp: response['water_temp'] != null
                ? drift.Value((response['water_temp'] as num).toDouble())
                : const drift.Value.absent(),
            brewTime: drift.Value(response['brew_time']),
            vendorId: drift.Value(recipe.vendorId), // Keep local vendor
            lastModified:
                drift.Value(DateTime.now().toUtc()), // Update local time
            importId: drift.Value(recipe.importId), // Keep import ID
            isImported: drift.Value(true),
            // Ensure needs_moderation_review is false when updating from cloud
            needsModerationReview: const drift.Value(false),
          );

          // Extract and update localizations
          final localizationsJson =
              response['user_recipe_localizations'] as List<dynamic>;
          final localizations = localizationsJson.map((json) {
            return RecipeLocalizationsCompanion(
              id: drift.Value(const Uuid().v4()), // Generate new ID
              recipeId: drift.Value(recipe.id), // Use local recipe ID
              locale: drift.Value(json['locale']),
              name: drift.Value(json['name']),
              grindSize: drift.Value(json['grind_size']),
              shortDescription: drift.Value(json['short_description']),
            );
          }).toList();

          // Extract and update steps
          final stepsJson = response['user_steps'] as List<dynamic>;
          final steps = stepsJson.map((json) {
            return StepsCompanion(
              id: drift.Value(const Uuid().v4()), // Generate new ID
              recipeId: drift.Value(recipe.id), // Use local recipe ID
              stepOrder: drift.Value(json['step_order']),
              description: drift.Value(json['description']),
              time: drift.Value(json['time']),
              locale: drift.Value(json['locale']),
            );
          }).toList();

          // Update in local DB
          await _db.transaction(() async {
            // Update recipe
            await _db.recipesDao.insertOrUpdateRecipe(updatedRecipe);

            // Delete existing localizations and steps
            await _db.recipeLocalizationsDao
                .deleteLocalizationsForRecipe(recipe.id);
            await _db.stepsDao.deleteStepsForRecipe(recipe.id);

            // Insert new localizations and steps
            for (final localization in localizations) {
              await _db.recipeLocalizationsDao
                  .insertOrUpdateLocalization(localization);
            }

            for (final step in steps) {
              await _db.stepsDao.insertOrUpdateStep(step);
            }
          });
        }
      }
    } catch (e) {
      print('Error syncing imported recipes: $e');
    }
  }

  // Public wrapper for syncing user recipes
  Future<void> syncUserRecipes(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('Skipping user recipe sync for anonymous user.');
      return;
    }
    try {
      final localRecipeIds =
          await _db.recipesDao.fetchIdsAndLastModifiedDates();
      await _syncUserRecipes(userId, localRecipeIds);
    } catch (e) {
      print('Error in public syncUserRecipes: $e');
      // Rethrow or handle as needed
      rethrow;
    }
  }

  // Public wrapper for syncing imported recipes
  Future<void> syncImportedRecipes(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('Skipping imported recipe sync for anonymous user.');
      return;
    }
    try {
      await _syncImportedRecipes(userId);
    } catch (e) {
      print('Error in public syncImportedRecipes: $e');
      // Rethrow or handle as needed
      rethrow;
    }
  }

  Future<void> _fetchAndStoreExtraData({required bool isFirstLaunch}) async {
    try {
      // Define individual futures
      final coffeeFactsFuture =
          Supabase.instance.client.from('coffee_facts').select();
      final launchPopupFuture =
          Supabase.instance.client.from('launch_popup').select();
      final coffeeFactsRequest = isFirstLaunch
          ? coffeeFactsFuture
          : coffeeFactsFuture.timeout(const Duration(seconds: 5));
      final launchPopupRequest = isFirstLaunch
          ? launchPopupFuture
          : launchPopupFuture.timeout(const Duration(seconds: 5));

      // Run all requests in parallel
      final responses = await Future.wait([
        coffeeFactsRequest,
        launchPopupRequest,
      ]);

      // Process the responses
      final coffeeFactsResponse = responses[0] as List<dynamic>;
      final launchPopupResponse = responses[1] as List<dynamic>;

      final coffeeFacts = coffeeFactsResponse
          .map((json) => CoffeeFactsCompanionExtension.fromJson(json))
          .toList();
      final launchPopups = launchPopupResponse
          .map((json) => LaunchPopupsCompanionExtension.fromJson(json))
          .toList();

      await _db.transaction(() async {
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.coffeeFacts, coffeeFacts);
          batch.insertAllOnConflictUpdate(_db.launchPopups, launchPopups);
        });
      });
    } catch (error) {
      print('Error fetching and storing extra data: $error');
      // Optionally, handle the error
    }
  }

  // Inside DatabaseProvider
  Future<double> fetchGlobalBrewedCoffeeAmount(
      DateTime start, DateTime end) async {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final response = await Supabase.instance.client
        .from('global_stats')
        .select('water_amount')
        .gte('created_at', startUtc.toIso8601String())
        .lte('created_at', endUtc.toIso8601String());
    final data = response as List<dynamic>;
    return data.fold<double>(
        0.0, (sum, element) => sum + element['water_amount'] / 1000);
  }

  Future<List<String>> fetchGlobalTopRecipes(
      DateTime start, DateTime end) async {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final response = await Supabase.instance.client
        .from('global_stats')
        .select('recipe_id')
        .gte('created_at', startUtc.toIso8601String())
        .lte('created_at', endUtc.toIso8601String());

    // Aggregate counts of recipe_id
    final Map<String, int> recipeCounts = {};
    for (var entry in response) {
      final recipeId = entry['recipe_id'] as String;
      recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
    }

    // Sort and get top 3 recipe_ids based on usage count
    final sortedRecipes = recipeCounts.keys.toList()
      ..sort((a, b) => recipeCounts[b]!.compareTo(recipeCounts[a]!));
    return sortedRecipes.take(3).toList();
  }

  Future<List<String>> fetchCountriesForLocale(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_countries')
          .select('country_name')
          .eq('locale', locale)
          .timeout(const Duration(seconds: 2));

      final data = response as List<dynamic>;
      return data.map((e) => e['country_name'] as String).toList();
    } on TimeoutException catch (e) {
      print('Supabase request timed out: $e');
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      print('Error fetching countries: $error');
      return [];
    }
  }

  Future<List<String>> fetchTastingNotesForLocale(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_descriptors')
          .select('descriptor_name')
          .eq('locale', locale)
          .timeout(const Duration(seconds: 2));

      final data = response as List<dynamic>;
      return data.map((e) => e['descriptor_name'] as String).toList();
    } on TimeoutException catch (e) {
      print('Supabase request timed out: $e');
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      print('Error fetching tasting notes: $error');
      return [];
    }
  }

  Future<List<String>> fetchProcessingMethodsForLocale(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_processing_methods')
          .select('method_name')
          .eq('locale', locale)
          .timeout(const Duration(seconds: 2));

      final data = response as List<dynamic>;
      return data.map((e) => e['method_name'] as String).toList();
    } on TimeoutException catch (e) {
      print('Supabase request timed out: $e');
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      print('Error fetching processing methods: $error');
      return [];
    }
  }

  Future<List<String>> fetchRoasters() async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_roasters')
          .select('roaster_name')
          .timeout(const Duration(seconds: 2));

      final data = response as List<dynamic>;
      return data.map((e) => e['roaster_name'] as String).toList();
    } on TimeoutException catch (e) {
      print('Supabase request timed out: $e');
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      print('Error fetching roasters: $error');
      return [];
    }
  }

  // 1) Add a private field to store cached logo URLs in memory:
  final Map<String, Map<String, String?>> _roasterLogoCache = {};

  // 2) Optionally, expose a method that uses the cache:
  Future<Map<String, String?>> fetchCachedRoasterLogoUrls(
      String roasterName) async {
    // Normalize the roaster name the same way you do in fetchRoasterLogoUrls
    final normalizedRoasterName = removeDiacritics(roasterName).toLowerCase();

    // If we’ve already fetched logos for this roaster, return immediately:
    if (_roasterLogoCache.containsKey(normalizedRoasterName)) {
      return _roasterLogoCache[normalizedRoasterName]!;
    }

    // Otherwise, call your existing fetchRoasterLogoUrls or the RPC
    final logoUrls = await fetchRoasterLogoUrls(roasterName);

    // Store the result in the cache, so next time we skip the network call
    _roasterLogoCache[normalizedRoasterName] = logoUrls;

    // Return it
    return logoUrls;
  }

  Future<Map<String, String?>> fetchRoasterLogoUrls(String roasterName) async {
    try {
      // We no longer remove diacritics here because unaccent handles it on the DB side.
      // But we do convert to lower if desired. Example:
      final searchTerm = roasterName.trim();

      final response = await Supabase.instance.client.rpc(
          'search_roaster_unaccent',
          params: {'search_name': searchTerm}).maybeSingle();
      // maybeSingle() means: if multiple rows are returned, pick the first, else null.

      if (response != null) {
        return {
          'original': response['roaster_logo_url'] as String?,
          'mirror': response['roaster_logo_mirror_url'] as String?,
        };
      }

      print('No matching data found for roaster: $roasterName');
      return {'original': null, 'mirror': null};
    } catch (error) {
      print('Exception fetching roaster logo URLs: $error');
      return {'original': null, 'mirror': null};
    }
  }

  Future<void> uploadUserPreferencesToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    final localPreferences =
        await _db.userRecipePreferencesDao.getAllPreferences();

    final preferencesData = localPreferences
        .map((pref) => {
              'user_id': user.id,
              'recipe_id': pref.recipeId,
              'last_used': pref.lastUsed?.toUtc().toIso8601String(),
              'is_favorite': pref.isFavorite,
              'sweetness_slider_position': pref.sweetnessSliderPosition,
              'strength_slider_position': pref.strengthSliderPosition,
              'custom_coffee_amount': pref.customCoffeeAmount,
              'custom_water_amount': pref.customWaterAmount,
            })
        .toList();

    try {
      await Supabase.instance.client
          .from('user_recipe_preferences')
          .upsert(preferencesData);

      print('Successfully uploaded ${preferencesData.length} preferences');
    } catch (e) {
      print('Error uploading preferences: $e');
      // You might want to handle this error more gracefully,
      // perhaps by showing a message to the user or implementing a retry mechanism
    }
  }

  Future<void> updateUserPreferenceInSupabase(
    String recipeId, {
    bool? isFavorite,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    int? coffeeChroniclerSliderPosition, // Add this parameter
    double? customCoffeeAmount,
    double? customWaterAmount,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    final data = {
      'user_id': user.id,
      'recipe_id': recipeId,
      'last_used': DateTime.now().toUtc().toIso8601String(),
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (sweetnessSliderPosition != null)
        'sweetness_slider_position': sweetnessSliderPosition,
      if (strengthSliderPosition != null)
        'strength_slider_position': strengthSliderPosition,
      if (coffeeChroniclerSliderPosition != null)
        'coffee_chronicler_slider_position':
            coffeeChroniclerSliderPosition, // Add this line
      if (customCoffeeAmount != null)
        'custom_coffee_amount': customCoffeeAmount,
      if (customWaterAmount != null) 'custom_water_amount': customWaterAmount,
    };

    try {
      await Supabase.instance.client
          .from('user_recipe_preferences')
          .upsert(data)
          .timeout(const Duration(seconds: 2));
      print('Preference updated successfully');
    } on TimeoutException catch (e) {
      print('Supabase request timed out: $e');
      // Optionally, handle the timeout, e.g., by retrying or queuing the request
    } catch (e) {
      print('Error updating preference: $e');
      // Handle other exceptions as needed
    }
  }

  // Fetch minimal metadata for a public user recipe
  Future<Map<String, dynamic>?> getPublicUserRecipeMetadata(
      String recipeId) async {
    print('DEBUG: getPublicUserRecipeMetadata called for recipeId: $recipeId');
    print(
        'DEBUG: Current user: ${Supabase.instance.client.auth.currentUser?.id ?? "Not logged in"}');

    try {
      // Step 1: Fetch basic recipe data (without name)
      print('DEBUG: Executing Supabase query (Step 1 - Recipe):');
      print('DEBUG: FROM: user_recipes');
      print('DEBUG: SELECT: id, last_modified'); // Select only existing columns
      print(
          'DEBUG: WHERE: id = $recipeId AND ispublic = true AND is_deleted = false');

      final recipeResponse = await Supabase.instance.client
          .from('user_recipes')
          .select('id, last_modified') // Fetch only existing columns
          .eq('id', recipeId)
          .eq('ispublic', true)
          .eq('is_deleted', false)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      if (recipeResponse == null) {
        print('DEBUG: No public, non-deleted recipe found for id: $recipeId');
        // Optional: Check if it exists but isn't public/deleted
        print(
            'DEBUG: Checking if recipe exists at all (ignoring public/deleted flags)...');
        final checkResponse = await Supabase.instance.client
            .from('user_recipes')
            .select('id, ispublic, is_deleted')
            .eq('id', recipeId)
            .maybeSingle()
            .timeout(const Duration(seconds: 2));
        if (checkResponse != null) {
          print(
              'DEBUG: Recipe exists but with flags: ispublic=${checkResponse['ispublic']}, is_deleted=${checkResponse['is_deleted']}');
        } else {
          print('DEBUG: Recipe does not exist at all');
        }
        return null; // Recipe not found or not accessible
      }

      print('DEBUG: Basic recipe metadata found: ${recipeResponse.toString()}');

      // Step 2: Fetch the name from localizations
      print('DEBUG: Executing Supabase query (Step 2 - Localization Name):');
      print('DEBUG: FROM: user_recipe_localizations');
      print('DEBUG: SELECT: name');
      print('DEBUG: WHERE: recipe_id = $recipeId');
      print('DEBUG: LIMIT: 1');

      final localizationResponse = await Supabase.instance.client
          .from('user_recipe_localizations')
          .select('name')
          .eq('recipe_id', recipeId)
          .limit(1) // Get just one name
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      String recipeName = "Unnamed Recipe"; // Default name
      if (localizationResponse != null &&
          localizationResponse['name'] != null) {
        recipeName = localizationResponse['name'];
        print('DEBUG: Found recipe name: $recipeName');
      } else {
        print(
            'DEBUG: No localization found for recipe $recipeId, using default name.');
      }

      // Step 3: Combine results
      final Map<String, dynamic> combinedMetadata = {
        ...recipeResponse, // Spread the basic recipe data (id, last_modified)
        'name': recipeName, // Add the fetched or default name
      };

      print('DEBUG: Combined metadata: ${combinedMetadata.toString()}');
      return combinedMetadata;
    } on TimeoutException {
      print('DEBUG: TIMEOUT fetching metadata for recipe $recipeId');
      return null;
    } catch (e) {
      print('DEBUG: ERROR fetching metadata for recipe $recipeId: $e');
      if (e is PostgrestException) {
        print("DEBUG: Postgrest error code: ${e.code}");
        print("DEBUG: Postgrest error message: ${e.message}");
        print("DEBUG: Postgrest error details: ${e.details}");
      }
      return null;
    }
  }

  // Fetch full data for a public user recipe
  Future<Map<String, dynamic>?> fetchFullPublicUserRecipeData(
      String recipeId) async {
    print(
        'DEBUG: fetchFullPublicUserRecipeData called for recipeId: $recipeId');
    print(
        'DEBUG: Current user: ${Supabase.instance.client.auth.currentUser?.id ?? "Not logged in"}');

    try {
      print('DEBUG: Executing Supabase query:');
      print('DEBUG: FROM: user_recipes');
      print('DEBUG: SELECT: *, user_recipe_localizations(*), user_steps(*)');
      print(
          'DEBUG: WHERE: id = $recipeId AND ispublic = true AND is_deleted = false');

      final response = await Supabase.instance.client
          .from('user_recipes')
          .select('*, user_recipe_localizations(*), user_steps(*)')
          .eq('id', recipeId)
          .eq('ispublic', true)
          .eq('is_deleted', false)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      if (response != null) {
        print('DEBUG: Recipe found with id: $recipeId');
        print(
            'DEBUG: Recipe data: ${response.toString().substring(0, math.min(200, response.toString().length))}...');
        print(
            'DEBUG: Localizations count: ${(response['user_recipe_localizations'] as List?)?.length ?? 0}');
        print(
            'DEBUG: Steps count: ${(response['user_steps'] as List?)?.length ?? 0}');

        // Check if localizations and steps are empty
        if ((response['user_recipe_localizations'] as List?)?.isEmpty ?? true) {
          print('DEBUG: WARNING - No localizations found for recipe $recipeId');
        }
        if ((response['user_steps'] as List?)?.isEmpty ?? true) {
          print('DEBUG: WARNING - No steps found for recipe $recipeId');
        }
      } else {
        print('DEBUG: No recipe found for id: $recipeId');

        // Check if recipe exists but isn't public
        final checkResponse = await Supabase.instance.client
            .from('user_recipes')
            .select('id, ispublic, is_deleted')
            .eq('id', recipeId)
            .maybeSingle()
            .timeout(const Duration(seconds: 2));

        if (checkResponse != null) {
          print(
              'DEBUG: Recipe exists but with flags: ispublic=${checkResponse['ispublic']}, is_deleted=${checkResponse['is_deleted']}');

          // Check if related data exists
          print('DEBUG: Checking if localizations exist...');
          final localizationsResponse = await Supabase.instance.client
              .from('user_recipe_localizations')
              .select('id, recipe_id')
              .eq('recipe_id', recipeId)
              .limit(1)
              .maybeSingle()
              .timeout(const Duration(seconds: 2));

          print('DEBUG: Localizations exist: ${localizationsResponse != null}');

          print('DEBUG: Checking if steps exist...');
          final stepsResponse = await Supabase.instance.client
              .from('user_steps')
              .select('id, recipe_id')
              .eq('recipe_id', recipeId)
              .limit(1)
              .maybeSingle()
              .timeout(const Duration(seconds: 2));

          print('DEBUG: Steps exist: ${stepsResponse != null}');
        } else {
          print('DEBUG: Recipe does not exist at all');
        }
      }

      return response;
    } on TimeoutException {
      print('DEBUG: TIMEOUT fetching full data for recipe $recipeId');
      return null;
    } catch (e) {
      print('DEBUG: ERROR fetching full data for recipe $recipeId: $e');
      print('DEBUG: Error details: ${e.toString()}');
      return null;
    }
  }

  // Updated to optionally skip marking deleted in Supabase if the deletion originated from there
  Future<void> _deleteRecipeFromLocalDb(String recipeId,
      {bool markDeletedInSupabase = true}) async {
    try {
      // If requested, mark as deleted in Supabase (only for user recipes)
      if (markDeletedInSupabase && recipeId.startsWith('usr-')) {
        final user = Supabase.instance.client.auth.currentUser;
        // Only mark as deleted if user is logged in and not anonymous
        if (user != null && !user.isAnonymous) {
          try {
            await Supabase.instance.client.from('user_recipes').update({
              'is_deleted': true,
              'last_modified': DateTime.now().toUtc().toIso8601String()
            }) // Also update timestamp
                .eq('id', recipeId);
            print('Marked recipe $recipeId as deleted in Supabase');
          } catch (e) {
            print('Error marking recipe $recipeId as deleted in Supabase: $e');
            // Decide if we should proceed with local deletion despite Supabase error
          }
        }
      }

      // Delete from local database (this should handle related data via cascades or DAO logic)
      await _db.recipesDao.deleteRecipe(recipeId);
      print('Deleted recipe $recipeId from local database');
    } catch (error) {
      print('Error deleting recipe $recipeId from local database: $error');
    }
  }

  Future<void> fetchAndInsertUserPreferencesFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('user_recipe_preferences')
          .select()
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 3));

      final preferences = (response as List<dynamic>)
          .map((json) {
            try {
              return UserRecipePreferencesCompanionExtension.fromJson(json);
            } catch (e) {
              print('Error parsing preference: $e');
              return null;
            }
          })
          .whereType<UserRecipePreferencesCompanion>()
          .toList();

      await _db.userRecipePreferencesDao
          .insertOrUpdateMultiplePreferences(preferences);

      print(
          'Successfully fetched and inserted ${preferences.length} preferences');
    } on TimeoutException catch (e) {
      print('Supabase request timed out: $e');
      // Optionally, handle the timeout here
    } catch (e) {
      print('Error fetching and inserting preferences: $e');
    }
  }

  // --- Deferred Moderation Check ---
  Future<void> _performDeferredModerationChecks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('Skipping deferred moderation check for anonymous user.');
      return;
    }

    final lastCheckTime = await _getLastDeferredModerationCheckTimestamp();
    final now = DateTime.now().toUtc();
    // Check only once per day (adjust duration as needed)
    if (lastCheckTime != null &&
        now.difference(lastCheckTime) < const Duration(hours: 24)) {
      print(
          'Skipping deferred moderation check, last check was at ${lastCheckTime.toIso8601String()}');
      return;
    }

    print('Performing deferred moderation checks...');
    final recipesToCheck = await _db.recipesDao.getRecipesNeedingModeration();
    if (recipesToCheck.isEmpty) {
      print('No recipes found needing deferred moderation check.');
      await _setLastDeferredModerationCheckTimestamp(
          now); // Update check time even if none found
      return;
    }

    print('Found ${recipesToCheck.length} recipes needing moderation check.');
    int passedCount = 0;
    int failedCount = 0;

    for (final recipe in recipesToCheck) {
      // Verify ownership again just in case
      if (recipe.vendorId != 'usr-${user.id}') continue;

      print('Checking recipe: ${recipe.id}');
      // Fetch full local data (steps, localizations) needed for combinedText
      final localizations =
          await _db.recipeLocalizationsDao.getLocalizationsForRecipe(recipe.id);
      final steps = await _db.stepsDao.getStepsForRecipe(recipe.id);

      // Prepare combinedText
      final firstLoc = localizations.isNotEmpty ? localizations.first : null;
      String combinedText = "";
      combinedText += "${firstLoc?.name ?? recipe.id}\n";
      combinedText += "${firstLoc?.shortDescription ?? ''}\n";
      combinedText += "${firstLoc?.grindSize ?? ''}\n";
      for (var step in steps) {
        combinedText += "${step.description}\n";
      }
      combinedText = combinedText.trim();

      bool moderationPassed = true; // Assume pass initially
      if (combinedText.isNotEmpty) {
        try {
          final moderationResponse =
              await Supabase.instance.client.functions.invoke(
            'content-moderation-gemini',
            body: {'text': combinedText},
          ).timeout(const Duration(seconds: 10)); // Timeout for moderation call

          if (moderationResponse.status != 200 ||
              moderationResponse.data == null) {
            print(
                "Deferred Moderation Error (Function Call): Recipe ${recipe.id}");
            moderationPassed = false; // Treat function error as failure
          } else {
            final moderationResult =
                moderationResponse.data as Map<String, dynamic>;
            if (moderationResult['safe'] != true) {
              print(
                  "Deferred Moderation Failed (Content Flagged): Recipe ${recipe.id}. Reason: ${moderationResult['reason']}");
              moderationPassed = false;
            } else {
              print("Deferred Moderation Passed: Recipe ${recipe.id}");
              moderationPassed = true;
            }
          }
        } catch (e) {
          print(
              "Deferred Moderation Error (Exception): Recipe ${recipe.id}. Error: $e");
          moderationPassed = false; // Treat exceptions as failure
        }
      } else {
        print(
            "Deferred Moderation Skipped (No Text): Recipe ${recipe.id}, assuming pass.");
        moderationPassed = true; // No text, allow it
      }

      // Update local flag based on result
      await _db.recipesDao
          .setNeedsModerationReview(recipe.id, !moderationPassed);
      if (moderationPassed) {
        passedCount++;
      } else {
        failedCount++;
      }
    }

    // Update the last check timestamp after processing all recipes
    await _setLastDeferredModerationCheckTimestamp(now);
    print(
        'Deferred moderation checks complete. Passed: $passedCount, Failed: $failedCount. Updated last check time.');
  }
  // --- End Deferred Moderation Check ---

  // Public method to get recipes needing moderation
  Future<List<Recipe>> getRecipesNeedingModeration() async {
    return await _db.recipesDao.getRecipesNeedingModeration();
  }

  // Public method to clear the needs_moderation_review flag for a recipe
  Future<void> clearNeedsModerationReview(String recipeId) async {
    await _db.recipesDao.setNeedsModerationReview(recipeId, false);
  }

  // --- User Profile Management ---

  /// Ensures a profile exists for the given user ID in the public profiles table.
  /// If not, creates a default profile.
  Future<void> ensureUserProfileExists(String userId) async {
    final supabase = Supabase.instance.client;
    try {
      // Check if a profile already exists
      final existingProfile = await supabase
          .from('user_public_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      // If no profile exists, create a default one
      if (existingProfile == null) {
        print('No profile found for user $userId. Creating default profile.');
        const defaultAvatarUrl =
            'https://mprokbemdullwezwwscn.supabase.co/storage/v1/object/public/user-profile-pictures//avatar_default.webp';
        // Format default display name as User-<first 5 chars of ID>
        final defaultDisplayName = 'User-${userId.substring(0, 5)}';
        await supabase.from('user_public_profiles').insert({
          'user_id': userId,
          'display_name': defaultDisplayName,
          'profile_picture_url': defaultAvatarUrl,
        });
        print(
            'Default profile created for user $userId with name $defaultDisplayName.');
      } else {
        print('Profile already exists for user $userId.');
      }
    } catch (e) {
      print('Error ensuring user profile exists for $userId: $e');
      // Handle error appropriately, maybe rethrow or log
    }
  }
  // --- End User Profile Management ---
}
