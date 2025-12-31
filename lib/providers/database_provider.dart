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
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/models/gift_offer_model.dart';
import 'package:flutter/material.dart';

class YearlyPercentileResult {
  final double? percentile;
  final int? topPct;
  final double? liters;
  final int? activeUsers;

  const YearlyPercentileResult({
    required this.percentile,
    required this.topPct,
    required this.liters,
    required this.activeUsers,
  });
}

class DatabaseProvider {
  final AppDatabase _db;
  LaunchPopupModel? _launchPopupModel; // Field to store fetched launch popup
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

  Future<void> initializeDatabase(
      {required bool isFirstLaunch, String? locale}) async {
    if (isFirstLaunch) {
      // No timeout on the first launch to ensure all essential data is loaded
      try {
        await _initializeDatabaseInternal(
            isFirstLaunch: isFirstLaunch, locale: locale);
      } catch (error) {
        AppLogger.error(
            'Error initializing database on first launch: ${AppLogger.sanitize(error)}');
        // Optionally, handle the error appropriately
      }
    } else {
      // Apply a 10-second timeout to the entire initialization process
      try {
        await _initializeDatabaseInternal(
                isFirstLaunch: isFirstLaunch, locale: locale)
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            AppLogger.warning('initializeDatabase timed out');
            // Proceed with partial data or notify the user
            return;
          },
        );
      } catch (error) {
        AppLogger.error(
            'Error initializing database: ${AppLogger.sanitize(error)}');
        // Optionally, handle other errors
      }
    }
  }

  Future<void> _initializeDatabaseInternal(
      {required bool isFirstLaunch, String? locale}) async {
    // Added locale parameter
    await _fetchAndStoreReferenceData(isFirstLaunch: isFirstLaunch);
    await Future.wait([
      _fetchAndStoreRecipes(isFirstLaunch: isFirstLaunch),
      _fetchAndStoreExtraData(isFirstLaunch: isFirstLaunch),
      if (locale != null)
        _fetchAndStoreLaunchPopup(locale), // Pass locale to fetch popup
      // Perform deferred moderation checks after main sync, but don't block forever if offline
      _performDeferredModerationChecks().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('Deferred moderation checks timed out');
          return;
        },
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Gift Box (online-only, no Drift tables)
  // ---------------------------------------------------------------------------

  /// Fetches active Gift Box offers from Supabase and applies client-side
  /// validity + region ordering. Returns an empty list on failure.
  Future<List<GiftOffer>> fetchGiftBoxOffers({
    required Locale locale,
    String? regionCode,
  }) async {
    final now = DateTime.now().toUtc();
    try {
      final response = await Supabase.instance.client
          .from('giftbox_offers')
          .select()
          .eq('is_active', true)
          // Higher priority value should float to the top; fetch in that order.
          .order('priority', ascending: false)
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      final rawList = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final offers = rawList
          .map((row) => GiftOffer.fromMap(row, locale))
          .where((offer) {
        final vt = offer.validTo;
        if (vt != null && vt.isBefore(now)) return false;
        return true;
      }).toList();

      _sortOffers(offers, regionCode);
      return offers;
    } catch (e) {
      AppLogger.error('Failed to fetch giftbox offers', errorObject: e);
      return [];
    }
  }

  /// Fetch a single offer by id. Returns null on not found / error.
  Future<GiftOffer?> fetchGiftOfferById(
      String id, {
      required Locale locale,
      String? regionCode,
    }) async {
    try {
      final response = await Supabase.instance.client
          .from('giftbox_offers')
          .select()
          .eq('id', id)
          .limit(1)
          .single()
          .timeout(const Duration(seconds: 6));

      final offer = GiftOffer.fromMap(
          (response as Map<String, dynamic>), locale);

      if (_isOfferExpired(offer)) return null;
      return offer;
    } catch (e) {
      AppLogger.error('Failed to fetch giftbox offer $id', errorObject: e);
      return null;
    }
  }

  /// Fetch a single active offer by slug. Returns null on not found / inactive / error.
  Future<GiftOffer?> fetchGiftOfferBySlug(
    String slug, {
    required Locale locale,
    String? regionCode,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('giftbox_offers')
          .select()
          .eq('slug', slug)
          .eq('is_active', true)
          .limit(1)
          .single()
          .timeout(const Duration(seconds: 6));

      final offer = GiftOffer.fromMap((response as Map<String, dynamic>), locale);

      if (_isOfferExpired(offer)) return null;
      return offer;
    } catch (e) {
      AppLogger.error('Failed to fetch active giftbox offer $slug',
          errorObject: e);
      return null;
    }
  }

  bool _isOfferExpired(GiftOffer offer) {
    final now = DateTime.now().toUtc();
    if (offer.validTo != null && offer.validTo!.isBefore(now)) return true;
    return false;
  }

  void _sortOffers(List<GiftOffer> offers, String? regionCode) {
    if (offers.isEmpty) return;
    final region = regionCode?.toUpperCase();

    int score(GiftOffer o) {
      final regions = o.regions.map((e) => e.toUpperCase()).toList();
      if (region != null && regions.contains(region)) return 0;
      if (regions.contains('WORLDWIDE') || regions.contains('WW')) return 1;
      return 2;
    }

    offers.sort((a, b) {
      final s = score(a).compareTo(score(b));
      if (s != 0) return s;
      // Higher numeric priority should appear first.
      final prio = (b.priority ?? 0).compareTo(a.priority ?? 0);
      if (prio != 0) return prio;
      final aValid = a.validTo ?? DateTime.utc(2100);
      final bValid = b.validTo ?? DateTime.utc(2100);
      return aValid.compareTo(bValid);
    });
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
      AppLogger.error(
          'Error fetching and storing reference data: ${AppLogger.sanitize(error)}');
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
      AppLogger.error(
          'Error fetching and storing recipes: ${AppLogger.sanitize(error)}');
      // Optionally, handle the error
    }
  }

  // Sync user-created recipes with Supabase (Optimized with Timestamps)
  Future<void> _syncUserRecipes(
      String userId, Map<String, DateTime> localRecipeIds) async {
    final DateTime syncStartTime = DateTime.now().toUtc();
    final DateTime? lastSyncTime = await _getLastSyncTimestamp();
    AppLogger.debug(
        'Starting user recipe sync. Last sync: ${lastSyncTime?.toIso8601String() ?? 'Never'}',
        errorObject: {'userId': AppLogger.sanitize(userId)});

    try {
      // --- UPLOAD ---
      AppLogger.debug('Checking for local recipes to upload...');
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

      AppLogger.debug(
          'Found ${allRecipesToPotentiallyUpload.length} local recipes to potentially upload (modified or newly imported).');

      for (final recipe in allRecipesToPotentiallyUpload.values) {
        // Double-check ownership (already filtered in DAO, but good practice)
        if (recipe.vendorId != 'usr-$userId') {
          AppLogger.warning(
              'Skipping upload for recipe due to vendor ID mismatch',
              errorObject: {
                'recipeId': AppLogger.sanitize(recipe.id),
                'vendorId': AppLogger.sanitize(recipe.vendorId)
              });
          continue;
        }

        // Fetch current remote status (needed for ispublic check AND to see if it exists)
        final remoteData = await Supabase.instance.client
            .from('user_recipes')
            .select(
                'id, last_modified, is_deleted, ispublic, needs_moderation_review')
            .eq('id', recipe.id)
            .maybeSingle();

        // Skip if marked deleted remotely
        if (remoteData != null && remoteData['is_deleted'] == true) {
          AppLogger.debug('Skipping upload for recipe, deleted remotely.',
              errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
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
          AppLogger.debug(
              'Uploading recipe. Reason: ${isFirstUploadForImport ? "Newly imported" : "Modified locally"}',
              errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
          await _uploadRecipeToSupabase(recipe, userId,
              currentIsPublic: remoteData?['ispublic']);

          // // If it was the first upload for an imported recipe, mark isImported as false locally
          // // REMOVED: Keep isImported = true to allow future updates from parent
          // if (isFirstUploadForImport) {
          //   AppLogger.debug('Marking recipe as no longer imported locally.',
          //       errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
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
          AppLogger.debug(
              'Skipping upload for imported recipe - already exists remotely and not modified locally.',
              errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
        } else {
          // Wasn't modified locally and wasn't a new import needing upload
          AppLogger.debug('Skipping upload for recipe - not modified locally.',
              errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
        }
      }
      AppLogger.debug('Finished processing potential uploads.');

      // --- HANDLE DELETIONS ---
      AppLogger.debug('Checking for remotely deleted recipes...');
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
        AppLogger.debug(
            'Found ${idsToDeleteLocally.length} recipes to delete locally based on remote status.');
        await _db.transaction(() async {
          AppLogger.debug(
              'Deleting ${idsToDeleteLocally.length} recipes locally...');
          for (final id in idsToDeleteLocally) {
            // Pass false for markDeletedInSupabase as the deletion originated from Supabase.
            await _deleteRecipeFromLocalDb(id, markDeletedInSupabase: false);
          }
          AppLogger.debug('Finished deleting recipes locally.');
        });
      } else {
        AppLogger.debug(
            'No remotely deleted recipes found that need local deletion.');
      }

      // --- DOWNLOAD UPDATES/INSERTS ---
      AppLogger.debug('Checking for remote recipe updates/inserts...');
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

      final downloadResponse =
          await downloadQuery.timeout(const Duration(seconds: 3));

      if (downloadResponse == null || (downloadResponse as List).isEmpty) {
        AppLogger.debug('No new or updated remote recipes to download/insert.');
      } else {
        final remoteRecipesData = downloadResponse as List<dynamic>;
        AppLogger.debug(
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
            AppLogger.warning(
                'Skipping unexpectedly deleted recipe in update/insert phase',
                errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
            continue;
          }

          final remoteLastModifiedStr = recipeJson['last_modified'] as String?;
          final remoteLastModified = remoteLastModifiedStr != null
              ? DateTime.parse(remoteLastModifiedStr).toUtc()
              : null;
          final remoteNeedsModerationReview =
              recipeJson['needs_moderation_review'] as bool? ?? false;

          final localLastModified = localRecipeIds[recipeId];

          // Check if remote is newer (or local doesn't exist)
          // Note: The gt filter in the query already handles the timestamp comparison,
          // but this check adds robustness and handles the case where localLastModified is null.
          if (localLastModified == null ||
              (remoteLastModified != null &&
                  !remoteLastModified.isAtSameMomentAs(localLastModified) &&
                  remoteLastModified.isAfter(localLastModified))) {
            AppLogger.debug('Processing download/update for recipe',
                errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
            final recipeCompanion =
                RecipesCompanionExtension.fromUserRecipeJson(recipeJson);
            // Use remote moderation status if available, default to false
            recipesToInsertOrUpdate.add(recipeCompanion.copyWith(
                needsModerationReview:
                    drift.Value(remoteNeedsModerationReview)));

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
            AppLogger.debug(
                'Skipping download for recipe (local is same or newer, or timestamp issue)',
                errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
          }
        }

        // Perform batch insert/update in a transaction
        if (recipesToInsertOrUpdate.isNotEmpty) {
          AppLogger.debug(
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
          AppLogger.debug('Finished inserting/updating downloaded recipes.');
        } else {
          AppLogger.debug(
              'No recipes needed inserting/updating from the downloaded batch.');
        }
      }

      // --- Update Last Sync Timestamp ---
      await _setLastSyncTimestamp(syncStartTime);
      AppLogger.debug(
          'User recipe sync completed. Updated last sync time to: ${syncStartTime.toIso8601String()}');
    } catch (e, stacktrace) {
      AppLogger.error('Error during user recipe sync',
          errorObject: e, stackTrace: stacktrace);
      // Consider not updating the timestamp on error to retry next time
    }
  }

  // Upload a recipe to Supabase (minor adjustments for clarity)
  Future<void> _uploadRecipeToSupabase(Recipe recipe, String userId,
      {bool? currentIsPublic}) async {
    try {
      // Add debug logging
      AppLogger.debug('UPLOADING RECIPE TO SUPABASE', errorObject: {
        'timestamp': DateTime.now().toIso8601String(),
        'recipeId': AppLogger.sanitize(recipe.id),
        'userId': AppLogger.sanitize(userId),
        'vendorId': AppLogger.sanitize(recipe.vendorId),
        'needsModerationReview': recipe.needsModerationReview
      });
      // recipeJson will be logged after it's declared below

      // Ensure vendor_id uses the full user ID for RLS
      final String effectiveVendorId = 'usr-$userId';

      // Determine effective flags with moderation policy guard:
      // - If the recipe is (or is known to be) public, we must not upload a moderation flag.
      // - Moderation is handled during share and edits; uploads of already-public recipes
      //   should carry needs_moderation_review = false.
      final bool effectiveIsPublic = currentIsPublic ?? false;
      final bool effectiveNeedsModeration =
          effectiveIsPublic ? false : (recipe.needsModerationReview == true);

      if (recipe.needsModerationReview == true && effectiveIsPublic) {
        AppLogger.debug(
            'Guard: Coercing needs_moderation_review=false for already-public recipe',
            errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
      }

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
        'ispublic': effectiveIsPublic, // Preserve/reflect known public status
        'needs_moderation_review':
            effectiveNeedsModeration, // Guarded by effectiveIsPublic
        'is_deleted': false,
      };

      // Log the full recipe JSON after it's been created
      AppLogger.debug('Full recipe JSON',
          errorObject: AppLogger.sanitize(recipeJson));

      // --- Explicit Insert/Update Logic ---
      // Check if the recipe already exists remotely
      final existingRecipe = await Supabase.instance.client
          .from('user_recipes')
          .select('id')
          .eq('id', recipe.id)
          .maybeSingle();

      if (existingRecipe == null) {
        // Recipe doesn't exist, perform INSERT
        AppLogger.debug('Recipe not found remotely, performing INSERT',
            errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
        await Supabase.instance.client.from('user_recipes').insert(recipeJson);
      } else {
        // Recipe exists, perform UPDATE
        AppLogger.debug('Recipe found remotely, performing UPDATE',
            errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
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

      // Delete existing localizations before upload to prevent accumulation
      await Supabase.instance.client
          .from('user_recipe_localizations')
          .delete()
          .eq('recipe_id', recipe.id);

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

      // Delete existing steps before upload to prevent accumulation
      final deletedStepsCount = await Supabase.instance.client
          .from('user_steps')
          .delete()
          .eq('recipe_id', recipe.id);
      AppLogger.debug('Deleted existing steps for recipe before upload',
          errorObject: {
            'deletedStepsCount': deletedStepsCount,
            'recipeId': AppLogger.sanitize(recipe.id)
          });

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
        AppLogger.debug('Uploaded steps for recipe', errorObject: {
          'stepsCount': stepsJsonList.length,
          'recipeId': AppLogger.sanitize(recipe.id)
        });
      }

      AppLogger.debug('Successfully uploaded recipe and related data',
          errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
    } catch (e, stacktrace) {
      AppLogger.error('Error uploading recipe to Supabase',
          errorObject: e, stackTrace: stacktrace);
      AppLogger.debug('Recipe ID that failed to upload',
          errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
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
            .maybeSingle()
            .timeout(const Duration(seconds: 3));

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
          AppLogger.debug('Updating local imported recipe', errorObject: {
            'recipeId': AppLogger.sanitize(recipe.id),
            'importId': AppLogger.sanitize(importId)
          });
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
      AppLogger.error('Error syncing imported recipes', errorObject: e);
    }
  }

  // Public wrapper for syncing user recipes
  Future<void> syncUserRecipes(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('Skipping user recipe sync for anonymous user.');
      return;
    }
    try {
      final localRecipeIds =
          await _db.recipesDao.fetchIdsAndLastModifiedDates();
      await _syncUserRecipes(userId, localRecipeIds);
    } catch (e) {
      AppLogger.error('Error in public syncUserRecipes', errorObject: e);
      // Rethrow or handle as needed
      rethrow;
    }
  }

  // Public wrapper for syncing imported recipes
  Future<void> syncImportedRecipes(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('Skipping imported recipe sync for anonymous user.');
      return;
    }
    try {
      await _syncImportedRecipes(userId);
    } catch (e) {
      AppLogger.error('Error in public syncImportedRecipes', errorObject: e);
      // Rethrow or handle as needed
      rethrow;
    }
  }

  Future<void> _fetchAndStoreLaunchPopup(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('launch_popup')
          .select('id, content, locale, created_at, platform')
          .eq('locale', locale)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      if (response != null) {
        _launchPopupModel =
            LaunchPopupModel.fromMap(response as Map<String, dynamic>);
      } else {
        _launchPopupModel = null;
      }
    } on TimeoutException {
      AppLogger.warning('Launch popup fetch timed out. Proceeding without it.');
      _launchPopupModel = null; // Ensure it's null on timeout
    } catch (e) {
      AppLogger.error('Error fetching and storing remote launch popup',
          errorObject: e);
      _launchPopupModel = null; // Ensure it's null on error
    }
  }

  // Public getter for the cached launch popup model
  LaunchPopupModel? get launchPopupModel => _launchPopupModel;

  Future<void> _fetchAndStoreExtraData({required bool isFirstLaunch}) async {
    try {
      // Define individual futures
      final coffeeFactsFuture =
          Supabase.instance.client.from('coffee_facts').select();
      final coffeeFactsRequest = isFirstLaunch
          ? coffeeFactsFuture
          : coffeeFactsFuture.timeout(const Duration(seconds: 5));

      // Run all requests in parallel
      final responses = await Future.wait([
        coffeeFactsRequest,
      ]);

      // Process the responses
      final coffeeFactsResponse = responses[0] as List<dynamic>;
      final coffeeFacts = coffeeFactsResponse
          .map((json) => CoffeeFactsCompanionExtension.fromJson(json))
          .toList();

      await _db.transaction(() async {
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.coffeeFacts, coffeeFacts);
        });
      });
    } catch (error) {
      AppLogger.error('Error fetching and storing extra data',
          errorObject: AppLogger.sanitize(error));
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
        .lte('created_at', endUtc.toIso8601String())
        .gte('water_amount', 50) // Filter out impossibly low values (< 50ml)
        .lte('water_amount',
            5000) // Filter out impossibly high values (> 5000ml)
        .timeout(const Duration(seconds: 5));
    final data = response as List<dynamic>;
    return data.fold<double>(
        0.0, (sum, element) => sum + element['water_amount'] / 1000);
  }

  /// Preferred aggregated query that avoids row-limit truncation.
  /// Uses global_stats_daily; returns 0 on failure (do not fall back to global_stats).
  Future<double> fetchGlobalBrewedCoffeeAmountAggregated(
      DateTime start, DateTime end) async {
    final client = Supabase.instance.client;
    final startIso = start.toUtc().toIso8601String();
    final endIso = end.toUtc().toIso8601String();
    final startDate = startIso.split('T').first;
    final endDate = endIso.split('T').first;

    try {
      final response = await client.rpc('global_stats_daily_range_sum', params: {
        // Function arguments are p_start_date, p_end_date (dates)
        'p_start_date': startDate,
        'p_end_date': endDate,
      }).timeout(const Duration(seconds: 5));
      final maybe = _extractTotalLiters(response);
      if (maybe != null) return maybe;
      return 0.0;
    } catch (e) {
      AppLogger.error('global_stats_daily_range_sum failed',
          errorObject: AppLogger.sanitize(e));
      // Intentionally swallow and return 0.
      return 0.0;
    }
  }

  /// Aggregated count of global brews in the date range.
  /// Uses global_stats_daily; returns 0 on failure.
  Future<int> fetchGlobalBrewsCountAggregated(
      DateTime start, DateTime end) async {
    final client = Supabase.instance.client;
    final startIso = start.toUtc().toIso8601String();
    final endIso = end.toUtc().toIso8601String();
    final startDate = startIso.split('T').first;
    final endDate = endIso.split('T').first;
    try {
      final response = await client.rpc('global_stats_daily_range_count', params: {
        'p_start_date': startDate,
        'p_end_date': endDate,
      }).timeout(const Duration(seconds: 5));
      final count = _extractCount(response);
      if (count != null) return count;
      return 0;
    } catch (e) {
      AppLogger.error('global_stats_daily_range_count failed',
          errorObject: AppLogger.sanitize(e));
      // Intentionally swallow and return 0.
      return 0;
    }
  }

  Future<List<String>> fetchGlobalTopRecipes(
      DateTime start, DateTime end) async {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final response = await Supabase.instance.client
        .from('global_stats')
        .select('recipe_id')
        .gte('created_at', startUtc.toIso8601String())
        .lte('created_at', endUtc.toIso8601String())
        .gte('water_amount', 50) // Filter out impossibly low values (< 50ml)
        .lte('water_amount',
            5000) // Filter out impossibly high values (> 5000ml)
        .timeout(const Duration(seconds: 5));

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

  /// Aggregated top recipes that leverages server-side grouping to avoid row limits.
  /// Returns top [topN] recipe_ids; falls back to legacy method if RPC is missing.
  Future<List<String>> fetchGlobalTopRecipesAggregated(
      DateTime start, DateTime end,
      {int topN = 3}) async {
    final client = Supabase.instance.client;
    final startIso = start.toUtc().toIso8601String();
    final endIso = end.toUtc().toIso8601String();
    final startDate = startIso.split('T').first;
    final endDate = endIso.split('T').first;
    try {
      // Primary: matches deployed function signature (p_start_date / p_end_date / p_top_n)
      final response = await client.rpc('global_stats_top_recipes', params: {
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_top_n': topN,
      }).timeout(const Duration(seconds: 5));
      final recipes = _extractRecipeIds(response);
      if (recipes != null) return recipes;
      return const <String>[];
    } catch (_) {
      // Intentionally swallow and fallback.
    }

    return fetchGlobalTopRecipes(start, end);
  }

  /// Fetches the user's yearly percentile based on precomputed yearly_user_liters.
  Future<YearlyPercentileResult?> fetchUserYearlyPercentile(int year) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await Supabase.instance.client
          .rpc('yearly_user_liters_percentile', params: {
            'p_year': year,
            'p_user_id': user.id,
          })
          .timeout(const Duration(seconds: 5));
      if (response is List && response.isNotEmpty && response.first is Map) {
        final row = response.first as Map;
        return YearlyPercentileResult(
          percentile: (row['percentile'] as num?)?.toDouble(),
          topPct: (row['top_pct'] as num?)?.toInt(),
          liters: (row['liters'] as num?)?.toDouble(),
          activeUsers: (row['active_users'] as num?)?.toInt(),
        );
      }
    } catch (e) {
      AppLogger.error('yearly_user_liters_percentile failed',
          errorObject: AppLogger.sanitize(e));
      // Ignore and return null.
    }
    return null;
  }

  double? _extractTotalLiters(dynamic response) {
    // Function returns SETOF table; PostgREST returns a list of rows.
    if (response is num) {
      return response.toDouble();
    }
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        final map = first;
        if (map['total_liters'] != null) {
          return (map['total_liters'] as num).toDouble();
        }
        if (map['total'] != null) return (map['total'] as num).toDouble();
        if (map['sum_liters'] != null) return (map['sum_liters'] as num).toDouble();
        if (map.values.isNotEmpty && map.values.first is num) {
          return (map.values.first as num).toDouble();
        }
      }
    } else if (response is Map) {
      if (response['total_liters'] != null) {
        return (response['total_liters'] as num).toDouble();
      }
      if (response['total'] != null) return (response['total'] as num).toDouble();
      if (response['sum_liters'] != null) return (response['sum_liters'] as num).toDouble();
    }
    return null;
  }

  List<String>? _extractRecipeIds(dynamic response) {
    // The RPC returns jsonb array; PostgREST decodes it as List<dynamic>.
    if (response is List) {
      return response
          .map((e) => e is Map ? e['recipe_id']?.toString() : e?.toString())
          .whereType<String>()
          .toList();
    } else if (response is Map && response.isNotEmpty) {
      // If PostgREST wraps scalar in a row, try to unwrap common keys
      for (final value in response.values) {
        if (value is List) {
          return value
              .map((e) => e is Map ? e['recipe_id']?.toString() : e?.toString())
              .whereType<String>()
              .toList();
        }
      }
    }
    return null;
  }

  int? _extractCount(dynamic response) {
    if (response is num) return response.toInt();
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        if (first['count'] != null && first['count'] is num) {
          return (first['count'] as num).toInt();
        }
        if (first['total'] != null && first['total'] is num) {
          return (first['total'] as num).toInt();
        }
        if (first.values.isNotEmpty && first.values.first is num) {
          return (first.values.first as num).toInt();
        }
      }
    } else if (response is Map) {
      if (response['count'] != null && response['count'] is num) {
        return (response['count'] as num).toInt();
      }
      if (response['total'] != null && response['total'] is num) {
        return (response['total'] as num).toInt();
      }
      if (response.values.isNotEmpty && response.values.first is num) {
        return (response.values.first as num).toInt();
      }
    }
    return null;
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
      AppLogger.warning('Supabase request timed out', errorObject: e);
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      AppLogger.error('Error fetching countries',
          errorObject: AppLogger.sanitize(error));
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
      AppLogger.warning('Supabase request timed out', errorObject: e);
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      AppLogger.error('Error fetching tasting notes',
          errorObject: AppLogger.sanitize(error));
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
      AppLogger.warning('Supabase request timed out', errorObject: e);
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      AppLogger.error('Error fetching processing methods',
          errorObject: AppLogger.sanitize(error));
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
      AppLogger.warning('Supabase request timed out', errorObject: e);
      // Return an empty list or handle the timeout as needed
      return [];
    } catch (error) {
      AppLogger.error('Error fetching roasters',
          errorObject: AppLogger.sanitize(error));
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

      AppLogger.debug('No matching data found for roaster',
          errorObject: {'roasterName': AppLogger.sanitize(roasterName)});
      return {'original': null, 'mirror': null};
    } catch (error) {
      AppLogger.error('Exception fetching roaster logo URLs',
          errorObject: AppLogger.sanitize(error));
      return {'original': null, 'mirror': null};
    }
  }

  Future<void> uploadUserPreferencesToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('No user logged in or user is anonymous');
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

      AppLogger.debug('Successfully uploaded preferences',
          errorObject: {'count': preferencesData.length});
    } catch (e) {
      AppLogger.error('Error uploading preferences', errorObject: e);
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
      AppLogger.debug('No user logged in or user is anonymous');
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
      AppLogger.debug('Preference updated successfully');
    } on TimeoutException catch (e) {
      AppLogger.warning('Supabase request timed out', errorObject: e);
      // Optionally, handle the timeout, e.g., by retrying or queuing the request
    } catch (e) {
      AppLogger.error('Error updating preference', errorObject: e);
      // Handle other exceptions as needed
    }
  }

  // Fetch minimal metadata for a public user recipe
  Future<Map<String, dynamic>?> getPublicUserRecipeMetadata(
      String recipeId) async {
    AppLogger.debug('getPublicUserRecipeMetadata called', errorObject: {
      'recipeId': AppLogger.sanitize(recipeId),
      'currentUser': AppLogger.sanitize(
          Supabase.instance.client.auth.currentUser?.id ?? "Not logged in")
    });

    try {
      // Step 1: Fetch basic recipe data (without name)
      AppLogger.debug('Executing Supabase query (Step 1 - Recipe)',
          errorObject: {
            'table': 'user_recipes',
            'select': 'id, last_modified',
            'where':
                'id = ${AppLogger.sanitize(recipeId)} AND ispublic = true AND is_deleted = false'
          });

      final recipeResponse = await Supabase.instance.client
          .from('user_recipes')
          .select('id, last_modified') // Fetch only existing columns
          .eq('id', recipeId)
          .eq('ispublic', true)
          .eq('is_deleted', false)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      if (recipeResponse == null) {
        AppLogger.debug('No public, non-deleted recipe found for id',
            errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
        // Optional: Check if it exists but isn't public/deleted
        AppLogger.debug(
            'Checking if recipe exists at all (ignoring public/deleted flags)...');
        final checkResponse = await Supabase.instance.client
            .from('user_recipes')
            .select('id, ispublic, is_deleted')
            .eq('id', recipeId)
            .maybeSingle()
            .timeout(const Duration(seconds: 2));
        if (checkResponse != null) {
          AppLogger.debug('Recipe exists but with flags', errorObject: {
            'ispublic': checkResponse['ispublic'],
            'is_deleted': checkResponse['is_deleted']
          });
        } else {
          AppLogger.debug('Recipe does not exist at all');
        }
        return null; // Recipe not found or not accessible
      }

      AppLogger.debug('Basic recipe metadata found',
          errorObject: AppLogger.sanitize(recipeResponse));

      // Step 2: Fetch the name from localizations
      AppLogger.debug('Executing Supabase query (Step 2 - Localization Name)',
          errorObject: {
            'table': 'user_recipe_localizations',
            'select': 'name',
            'where': 'recipe_id = ${AppLogger.sanitize(recipeId)}',
            'limit': 1
          });

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
        AppLogger.debug('Found recipe name',
            errorObject: {'recipeName': AppLogger.sanitize(recipeName)});
      } else {
        AppLogger.debug('No localization found for recipe, using default name',
            errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
      }

      // Step 3: Combine results
      final Map<String, dynamic> combinedMetadata = {
        ...recipeResponse, // Spread the basic recipe data (id, last_modified)
        'name': recipeName, // Add the fetched or default name
      };

      AppLogger.debug('Combined metadata',
          errorObject: AppLogger.sanitize(combinedMetadata));
      return combinedMetadata;
    } on TimeoutException {
      AppLogger.warning('TIMEOUT fetching metadata for recipe',
          errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
      return null;
    } catch (e) {
      AppLogger.error('ERROR fetching metadata for recipe', errorObject: e);
      AppLogger.debug('Recipe ID that had error',
          errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
      if (e is PostgrestException) {
        AppLogger.error('Postgrest error details', errorObject: {
          'code': e.code,
          'message': e.message,
          'details': e.details
        });
      }
      return null;
    }
  }

  // Fetch full data for a public user recipe
  Future<Map<String, dynamic>?> fetchFullPublicUserRecipeData(
      String recipeId) async {
    AppLogger.debug('fetchFullPublicUserRecipeData called', errorObject: {
      'recipeId': AppLogger.sanitize(recipeId),
      'currentUser': AppLogger.sanitize(
          Supabase.instance.client.auth.currentUser?.id ?? "Not logged in")
    });

    try {
      AppLogger.debug('Executing Supabase query', errorObject: {
        'table': 'user_recipes',
        'select': '*, user_recipe_localizations(*), user_steps(*)',
        'where':
            'id = ${AppLogger.sanitize(recipeId)} AND ispublic = true AND is_deleted = false'
      });

      final response = await Supabase.instance.client
          .from('user_recipes')
          .select('*, user_recipe_localizations(*), user_steps(*)')
          .eq('id', recipeId)
          .eq('ispublic', true)
          .eq('is_deleted', false)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      if (response != null) {
        AppLogger.debug('Recipe found with id', errorObject: {
          'recipeId': AppLogger.sanitize(recipeId),
          'dataPreview': AppLogger.sanitize(response
              .toString()
              .substring(0, math.min(200, response.toString().length))),
          'localizationsCount':
              (response['user_recipe_localizations'] as List?)?.length ?? 0,
          'stepsCount': (response['user_steps'] as List?)?.length ?? 0
        });

        // Check if localizations and steps are empty
        if ((response['user_recipe_localizations'] as List?)?.isEmpty ?? true) {
          AppLogger.warning('WARNING - No localizations found for recipe',
              errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
        }
        if ((response['user_steps'] as List?)?.isEmpty ?? true) {
          AppLogger.warning('WARNING - No steps found for recipe',
              errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
        }
      } else {
        AppLogger.debug('No recipe found for id',
            errorObject: {'recipeId': AppLogger.sanitize(recipeId)});

        // Check if recipe exists but isn't public
        final checkResponse = await Supabase.instance.client
            .from('user_recipes')
            .select('id, ispublic, is_deleted')
            .eq('id', recipeId)
            .maybeSingle()
            .timeout(const Duration(seconds: 2));

        if (checkResponse != null) {
          AppLogger.debug('Recipe exists but with flags', errorObject: {
            'ispublic': checkResponse['ispublic'],
            'is_deleted': checkResponse['is_deleted']
          });

          // Check if related data exists
          AppLogger.debug('Checking if localizations exist...');
          final localizationsResponse = await Supabase.instance.client
              .from('user_recipe_localizations')
              .select('id, recipe_id')
              .eq('recipe_id', recipeId)
              .limit(1)
              .maybeSingle()
              .timeout(const Duration(seconds: 2));

          AppLogger.debug('Localizations exist',
              errorObject: {'exist': localizationsResponse != null});

          AppLogger.debug('Checking if steps exist...');
          final stepsResponse = await Supabase.instance.client
              .from('user_steps')
              .select('id, recipe_id')
              .eq('recipe_id', recipeId)
              .limit(1)
              .maybeSingle()
              .timeout(const Duration(seconds: 2));

          AppLogger.debug('Steps exist',
              errorObject: {'exist': stepsResponse != null});
        } else {
          AppLogger.debug('Recipe does not exist at all');
        }
      }

      return response;
    } on TimeoutException {
      AppLogger.warning('TIMEOUT fetching full data for recipe',
          errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
      return null;
    } catch (e) {
      AppLogger.error('ERROR fetching full data for recipe', errorObject: {
        'error': e,
        'recipeId': AppLogger.sanitize(recipeId),
        'errorDetails': AppLogger.sanitize(e.toString())
      });
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
              'ispublic': false, // Set ispublic to false on deletion
              'last_modified': DateTime.now().toUtc().toIso8601String()
            }) // Also update timestamp
                .eq('id', recipeId);
            AppLogger.debug('Marked recipe as deleted and private in Supabase',
                errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
          } catch (e) {
            AppLogger.error('Error marking recipe as deleted in Supabase',
                errorObject: {
                  'error': e,
                  'recipeId': AppLogger.sanitize(recipeId)
                });
            // Decide if we should proceed with local deletion despite Supabase error
          }
        }
      }

      // Delete from local database (this should handle related data via cascades or DAO logic)
      await _db.recipesDao.deleteRecipe(recipeId);
      AppLogger.debug('Deleted recipe from local database',
          errorObject: {'recipeId': AppLogger.sanitize(recipeId)});
    } catch (error) {
      AppLogger.error('Error deleting recipe from local database',
          errorObject: {
            'error': AppLogger.sanitize(error),
            'recipeId': AppLogger.sanitize(recipeId)
          });
    }
  }

  Future<void> fetchAndInsertUserPreferencesFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('No user logged in or user is anonymous');
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
              AppLogger.error('Error parsing preference', errorObject: e);
              return null;
            }
          })
          .whereType<UserRecipePreferencesCompanion>()
          .toList();

      // Defensive: only insert preferences for recipe_ids that exist locally.
      final fetchedRecipeIds =
          preferences.map((p) => p.recipeId.value).whereType<String>().toSet();

      if (fetchedRecipeIds.isEmpty) {
        AppLogger.debug(
            'No preferences to insert (no recipe ids found in fetched prefs).');
        return;
      }

      // Query local DB for existing recipe ids from the fetched set.
      final existingLocalRecipes = await (_db.select(_db.recipes)
            ..where((tbl) => tbl.id.isIn(fetchedRecipeIds.toList())))
          .get();

      final existingRecipeIds = existingLocalRecipes.map((r) => r.id).toSet();

      // Filter preferences to those whose recipeId exists locally.
      final filteredPreferences = preferences
          .where((p) =>
              p.recipeId.present &&
              p.recipeId.value != null &&
              existingRecipeIds.contains(p.recipeId.value))
          .toList();

      final skippedCount = preferences.length - filteredPreferences.length;
      if (skippedCount > 0) {
        final skippedIds = preferences
            .where((p) =>
                p.recipeId.present &&
                p.recipeId.value != null &&
                !existingRecipeIds.contains(p.recipeId.value))
            .map((p) => p.recipeId.value)
            .take(10)
            .toList();
        AppLogger.debug(
            'Skipped preferences because referenced recipe_id not present locally',
            errorObject: {
              'skippedCount': skippedCount,
              'sampleSkippedIds': AppLogger.sanitize(skippedIds)
            });
      }

      if (filteredPreferences.isNotEmpty) {
        await _db.userRecipePreferencesDao
            .insertOrUpdateMultiplePreferences(filteredPreferences);
        AppLogger.debug(
            'Successfully fetched and inserted preferences (filtered)',
            errorObject: {'count': filteredPreferences.length});
      } else {
        AppLogger.debug(
            'No preferences inserted after filtering - nothing to do.');
      }
    } on TimeoutException catch (e) {
      AppLogger.warning('Supabase request timed out', errorObject: e);
      // Optionally, handle the timeout here
    } catch (e) {
      AppLogger.error('Error fetching and inserting preferences',
          errorObject: e);
    }
  }

  // --- Deferred Moderation Check ---
  Future<void> _performDeferredModerationChecks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('Skipping deferred moderation check for anonymous user.');
      return;
    }

    final lastCheckTime = await _getLastDeferredModerationCheckTimestamp();
    final now = DateTime.now().toUtc();
    // Check only once per day (adjust duration as needed)
    if (lastCheckTime != null &&
        now.difference(lastCheckTime) < const Duration(hours: 24)) {
      AppLogger.debug(
          'Skipping deferred moderation check, last check was at ${lastCheckTime.toIso8601String()}');
      return;
    }

    AppLogger.debug('Performing deferred moderation checks...');
    final recipesToCheck = await _db.recipesDao.getRecipesNeedingModeration();
    if (recipesToCheck.isEmpty) {
      AppLogger.debug('No recipes found needing deferred moderation check.');
      await _setLastDeferredModerationCheckTimestamp(
          now); // Update check time even if none found
      return;
    }

    AppLogger.debug('Found recipes needing moderation check',
        errorObject: {'count': recipesToCheck.length});
    int passedCount = 0;
    int failedCount = 0;

    for (final recipe in recipesToCheck) {
      // Verify ownership again just in case
      if (recipe.vendorId != 'usr-${user.id}') continue;

      AppLogger.debug('Checking recipe',
          errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
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
            AppLogger.error("Deferred Moderation Error (Function Call)",
                errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
            moderationPassed = false; // Treat function error as failure
          } else {
            final moderationResult =
                moderationResponse.data as Map<String, dynamic>;
            if (moderationResult['safe'] != true) {
              AppLogger.warning("Deferred Moderation Failed (Content Flagged)",
                  errorObject: {
                    'recipeId': AppLogger.sanitize(recipe.id),
                    'reason': AppLogger.sanitize(moderationResult['reason'])
                  });
              moderationPassed = false;
            } else {
              AppLogger.debug("Deferred Moderation Passed",
                  errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
              moderationPassed = true;
            }
          }
        } catch (e) {
          AppLogger.error("Deferred Moderation Error (Exception)",
              errorObject: {
                'error': e,
                'recipeId': AppLogger.sanitize(recipe.id)
              });
          moderationPassed = false; // Treat exceptions as failure
        }
      } else {
        AppLogger.debug("Deferred Moderation Skipped (No Text), assuming pass",
            errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
        moderationPassed = true; // No text, allow it
      }

      // Update local flag based on result
      await _db.recipesDao
          .setNeedsModerationReview(recipe.id, !moderationPassed);

      // Update Supabase if the recipe was moderated (status changed)
      if (moderationPassed && user != null && !user.isAnonymous) {
        try {
          await Supabase.instance.client.from('user_recipes').update({
            'needs_moderation_review': false,
            'last_modified': DateTime.now().toUtc().toIso8601String()
          }).eq('id', recipe.id);
          AppLogger.debug('Updated moderation status in Supabase for recipe',
              errorObject: {'recipeId': AppLogger.sanitize(recipe.id)});
        } catch (e) {
          AppLogger.warning('Failed to update moderation status in Supabase',
              errorObject: e);
          // Don't fail the whole process for this
        }
      }

      if (moderationPassed) {
        passedCount++;
      } else {
        failedCount++;
      }
    }

    // Update the last check timestamp after processing all recipes
    await _setLastDeferredModerationCheckTimestamp(now);
    AppLogger.debug('Deferred moderation checks complete', errorObject: {
      'passed': passedCount,
      'failed': failedCount,
      'message': 'Updated last check time'
    });
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
        AppLogger.debug('No profile found for user. Creating default profile.',
            errorObject: {'userId': AppLogger.sanitize(userId)});
        const defaultAvatarUrl =
            'https://mprokbemdullwezwwscn.supabase.co/storage/v1/object/public/user-profile-pictures//avatar_default.webp';
        // Format default display name as User-<first 5 chars of ID>
        final defaultDisplayName = 'User-${userId.substring(0, 5)}';
        await supabase.from('user_public_profiles').insert({
          'user_id': userId,
          'display_name': defaultDisplayName,
          'profile_picture_url': defaultAvatarUrl,
        });
        AppLogger.debug('Default profile created for user', errorObject: {
          'userId': AppLogger.sanitize(userId),
          'displayName': AppLogger.sanitize(defaultDisplayName)
        });
      } else {
        AppLogger.debug('Profile already exists for user.',
            errorObject: {'userId': AppLogger.sanitize(userId)});
      }
    } catch (e) {
      AppLogger.error('Error ensuring user profile exists',
          errorObject: {'error': e, 'userId': AppLogger.sanitize(userId)});
      // Handle error appropriately, maybe rethrow or log
    }
  }
  // --- End User Profile Management ---
}
