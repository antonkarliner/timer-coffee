import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  Future<DateTime?> _getLastFetchTime(String key) async {
    final prefs = await _prefsFuture;
    final lastFetch = prefs.getString(key);
    return lastFetch != null ? DateTime.parse(lastFetch) : null;
  }

  Future<void> _updateLastFetchTime(String key) async {
    final prefs = await _prefsFuture;
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  Future<String?> _getLastAppVersion() async {
    final prefs = await _prefsFuture;
    return prefs.getString('appVersion');
  }

  Future<void> _updateAppVersion(String currentVersion) async {
    final prefs = await _prefsFuture;
    await prefs.setString('appVersion', currentVersion);
  }

  Future<void> initializeDatabase() async {
    if (await _isFirstLaunched()) {
      await _fetchAllData();
    }
    await _conditionallyFetchData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchAndStoreVendors(),
      _fetchAndStoreBrewingMethods(),
      _fetchAndStoreSupportedLocales(),
      _fetchAndStoreAllRecipes(),
      _fetchAndStoreCoffeeFacts(),
      _fetchAndStoreStartPopup(),
    ]);
  }

  Future<void> _conditionallyFetchData() async {
    // Check for internet connectivity
    bool isConnected = await InternetConnectionChecker().hasConnection;
    if (!isConnected) {
      // No internet connection; skip fetching and proceed
      print('No internet connection. Skipping data fetch.');
      return;
    } else {
      await Future.wait([
        _fetchAndStoreVendors(),
        _fetchAndStoreBrewingMethods(),
        _fetchAndStoreSupportedLocales(),
      ]);

      await _fetchAndStoreRecipes();
      await _checkAndFetchCoffeeFacts();
      await _checkAndUpdateForNewAppVersion();
    }
  }

  Future<void> _checkAndFetchCoffeeFacts() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    if ((await _getLastFetchTime('coffeeFacts'))?.isBefore(sevenDaysAgo) ??
        true) {
      await _fetchAndStoreCoffeeFacts();
    }
  }

  Future<void> _checkAndUpdateForNewAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    if ((await _getLastAppVersion()) != currentVersion) {
      await _fetchAndStoreStartPopup();
      await _updateAppVersion(currentVersion);
    }
  }

  Future<void> _fetchAndStoreVendors() async {
    final response = await Supabase.instance.client.from('vendors').select();

    final vendors = response
        .map((json) => VendorsCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.vendors, vendors, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> _fetchAndStoreBrewingMethods() async {
    final response =
        await Supabase.instance.client.from('brewing_methods').select();
    final brewingMethods = response
        .map((json) => BrewingMethodsCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.brewingMethods, brewingMethods,
          mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> _fetchAndStoreSupportedLocales() async {
    final response =
        await Supabase.instance.client.from('supported_locales').select();
    final supportedLocales = response
        .map((json) => SupportedLocalesCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.supportedLocales, supportedLocales,
          mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> _fetchAndStoreAllRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select('*, recipe_localization(*), steps(*)');

    final recipes = response
        .map((json) => RecipesCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.recipes, recipes, mode: InsertMode.insertOrReplace);
    });

    // Extract and store localizations
    final localizationsJson =
        response.expand((json) => json['recipe_localization']).toList();
    final localizations = localizationsJson
        .map((json) => RecipeLocalizationsCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.recipeLocalizations, localizations,
          mode: InsertMode.insertOrReplace);
    });

    // Extract and store steps
    final stepsJson = response.expand((json) => json['steps']).toList();
    final steps = stepsJson
        .map((json) => StepsCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.steps, steps, mode: InsertMode.insertOrReplace);
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

  Future<void> _fetchAndStoreCoffeeFacts() async {
    final response =
        await Supabase.instance.client.from('coffee_facts').select();

    final coffeeFacts = response
        .map((json) => CoffeeFactsCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.coffeeFacts, coffeeFacts,
          mode: InsertMode.insertOrReplace);
    });

    await _updateLastFetchTime('coffeeFacts');
  }

  Future<void> _fetchAndStoreStartPopup() async {
    final response =
        await Supabase.instance.client.from('start_popup').select();

    final startPopups = response
        .map((json) => StartPopupsCompanionExtension.fromJson(json))
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.startPopups, startPopups,
          mode: InsertMode.insertOrReplace);
    });
  }
}
