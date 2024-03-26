import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/extensions.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class DatabaseProvider {
  final AppDatabase _db;

  DatabaseProvider(this._db);

  late final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  Future<bool> _isFirstLaunched() async {
    final prefs = await _prefsFuture;
    bool isFirstLaunch = prefs.getBool('FirstLaunched') ?? true;
    if (isFirstLaunch) {
      await prefs.setBool('FirstLaunched', false);
    }
    return isFirstLaunch;
  }

  Future<void> initializeDatabase() async {
    if (await _isFirstLaunched()) {
      await _fetchAllData();
    }
    await _conditionallyFetchData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchAndStoreReferenceData(),
      _fetchAndStoreAllRecipes(),
      _fetchAndStoreExtraData(),
    ]);
  }

  Future<void> _conditionallyFetchData() async {
    if (!kIsWeb) {
      // Check for internet connectivity
      bool isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        // No internet connection; skip fetching and proceed
        return;
      } else {
        await Future.wait([
          _fetchAndStoreReferenceData(),
        ]);

        await _fetchAndStoreRecipes();
        await _fetchAndStoreExtraData();
      }
    } else {
      await Future.wait([
        _fetchAndStoreReferenceData(),
      ]);

      await _fetchAndStoreRecipes();
      await _fetchAndStoreExtraData();
    }
  }

  Future<void> _fetchAndStoreReferenceData() async {
    final vendorsResponse =
        await Supabase.instance.client.from('vendors').select();
    final brewingMethodsResponse =
        await Supabase.instance.client.from('brewing_methods').select();
    final supportedLocalesResponse =
        await Supabase.instance.client.from('supported_locales').select();

    final vendors = vendorsResponse
        .map((json) => VendorsCompanionExtension.fromJson(json))
        .toList();
    final brewingMethods = brewingMethodsResponse
        .map((json) => BrewingMethodsCompanionExtension.fromJson(json))
        .toList();
    final supportedLocales = supportedLocalesResponse
        .map((json) => SupportedLocalesCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.vendors, vendors, mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.brewingMethods, brewingMethods,
            mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.supportedLocales, supportedLocales,
            mode: InsertMode.insertOrReplace);
      });
    });
  }

  Future<void> _fetchAndStoreAllRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select('*, recipe_localization(*), steps(*)');

    final recipes = response
        .map((json) => RecipesCompanionExtension.fromJson(json))
        .toList();

    // Extract and store localizations
    final localizationsJson =
        response.expand((json) => json['recipe_localization']).toList();
    final localizations = localizationsJson
        .map((json) => RecipeLocalizationsCompanionExtension.fromJson(json))
        .toList();

    // Extract and store steps
    final stepsJson = response.expand((json) => json['steps']).toList();
    final steps = stepsJson
        .map((json) => StepsCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.recipes, recipes, mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.recipeLocalizations, localizations,
            mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.steps, steps, mode: InsertMode.insertOrReplace);
      });
    });
  }

  Future<void> _fetchAndStoreRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select('id, last_modified');

    final remoteRecipes = response;
    final localRecipes = await _db.recipesDao.fetchIdsAndLastModifiedDates();

    List<RecipesCompanion> recipesToInsertOrUpdate = [];
    Map<String, List<dynamic>> recipeLocalizationsJson = {};
    Map<String, List<dynamic>> stepsJson = {};

    for (var remoteRecipe in remoteRecipes) {
      final remoteId = remoteRecipe['id'] as String;
      final remoteLastModified =
          DateTime.parse(remoteRecipe['last_modified'] as String);

      if (!localRecipes.containsKey(remoteId) ||
          remoteLastModified.isAfter(localRecipes[remoteId] ??
              DateTime.fromMillisecondsSinceEpoch(0))) {
        // Fetch and update the full recipe record with related data
        final fullRecipeResponse = await Supabase.instance.client
            .from('recipes')
            .select('*, recipe_localization(*), steps(*)')
            .eq('id', remoteId)
            .single();

        final recipe = RecipesCompanionExtension.fromJson(fullRecipeResponse);
        recipesToInsertOrUpdate.add(recipe);

        // Store related localizations and steps JSON
        recipeLocalizationsJson[remoteId] =
            fullRecipeResponse['recipe_localization'];
        stepsJson[remoteId] = fullRecipeResponse['steps'];
      }
    }

    if (recipesToInsertOrUpdate.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(_db.recipes, recipesToInsertOrUpdate,
            mode: InsertMode.insertOrReplace);
      });

      // Extract and store localizations
      final localizationsJson =
          recipeLocalizationsJson.values.expand((json) => json).toList();
      final localizations = localizationsJson
          .map((json) => RecipeLocalizationsCompanionExtension.fromJson(json))
          .toList();
      await _db.batch((batch) {
        batch.insertAll(_db.recipeLocalizations, localizations,
            mode: InsertMode.insertOrReplace);
      });

      // Extract and store steps
      final stepsList = stepsJson.values.expand((json) => json).toList();
      final steps = stepsList
          .map((json) => StepsCompanionExtension.fromJson(json))
          .toList();
      await _db.batch((batch) {
        batch.insertAll(_db.steps, steps, mode: InsertMode.insertOrReplace);
      });
    }
  }

  Future<void> _fetchAndStoreExtraData() async {
    final coffeeFactsResponse =
        await Supabase.instance.client.from('coffee_facts').select();
    final startPopupResponse =
        await Supabase.instance.client.from('start_popup').select();

    final coffeeFacts = coffeeFactsResponse
        .map((json) => CoffeeFactsCompanionExtension.fromJson(json))
        .toList();
    final startPopups = startPopupResponse
        .map((json) => StartPopupsCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.coffeeFacts, coffeeFacts,
            mode: InsertMode.insertOrReplace);
        batch.insertAll(_db.startPopups, startPopups,
            mode: InsertMode.insertOrReplace);
      });
    });
  }
}
