import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/extensions.dart';

class DatabaseProvider {
  final AppDatabase _db;

  DatabaseProvider(this._db);

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<bool> _isFirstLaunch() async {
    final prefs = await _prefs;
    bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;
    if (isFirstLaunch) {
      prefs.setBool('firstLaunch', false);
    }
    return isFirstLaunch;
  }

  Future<DateTime?> _getLastFetchTime(String key) async {
    final prefs = await _prefs;
    final lastFetch = prefs.getString(key);
    return lastFetch != null ? DateTime.parse(lastFetch) : null;
  }

  Future<void> _updateLastFetchTime(String key) async {
    final prefs = await _prefs;
    prefs.setString(key, DateTime.now().toIso8601String());
  }

  Future<String?> _getLastAppVersion() async {
    final prefs = await _prefs;
    return prefs.getString('appVersion');
  }

  Future<void> _updateAppVersion(String currentVersion) async {
    final prefs = await _prefs;
    prefs.setString('appVersion', currentVersion);
  }

  Future<void> initializeDatabase() async {
    if (await _isFirstLaunch()) {
      await _fetchAllData();
    } else {
      await _conditionallyFetchData();
    }
  }

  Future<void> _fetchAllData() async {
    await _fetchAndStoreVendors();
    await _fetchAndStoreBrewingMethods();
    await _fetchAndStoreSupportedLocales();
    await _fetchAndStoreRecipes();
    await _fetchAndStoreCoffeeFacts();
    await _fetchAndStoreStartPopup();
  }

  Future<void> _conditionallyFetchData() async {
    final now = DateTime.now();

    // Fetch vendors, brewing methods, and supported locales if more than 2 hours have passed
    final twoHoursAgo = now.subtract(Duration(hours: 2));
    if ((await _getLastFetchTime('vendors'))?.isBefore(twoHoursAgo) ?? true) {
      await _fetchAndStoreVendors();
    }
    if ((await _getLastFetchTime('brewingMethods'))?.isBefore(twoHoursAgo) ??
        true) {
      await _fetchAndStoreBrewingMethods();
    }
    if ((await _getLastFetchTime('supportedLocales'))?.isBefore(twoHoursAgo) ??
        true) {
      await _fetchAndStoreSupportedLocales();
    }

    // Fetch coffee facts if more than 7 days have passed
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    if ((await _getLastFetchTime('coffeeFacts'))?.isBefore(sevenDaysAgo) ??
        true) {
      await _fetchAndStoreCoffeeFacts();
    }

    // Fetch start popup if the app version has changed
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    if ((await _getLastAppVersion()) != currentVersion) {
      await _fetchAndStoreStartPopup();
      await _updateAppVersion(currentVersion);
    }

    // Conditions for recipes, localizations, and steps will be designed later
  }

  Future<void> _fetchAndStoreVendors() async {
    final response = await Supabase.instance.client.from('vendors').select();

    for (var json in response) {
      final vendor = VendorsCompanionExtension.fromJson(json);
      await _db
          .into(_db.vendors)
          .insert(vendor, mode: InsertMode.insertOrReplace);
    }

    await _updateLastFetchTime('vendors');
  }

  Future<void> _fetchAndStoreBrewingMethods() async {
    final response =
        await Supabase.instance.client.from('brewing_methods').select();
    for (var json in response) {
      final brewingMethod = BrewingMethodsCompanionExtension.fromJson(json);
      await _db
          .into(_db.brewingMethods)
          .insert(brewingMethod, mode: InsertMode.insertOrReplace);
    }

    await _updateLastFetchTime('brewingMethods');
  }

  Future<void> _fetchAndStoreSupportedLocales() async {
    final response =
        await Supabase.instance.client.from('supported_locales').select();
    for (var json in response) {
      final supportedLocale = SupportedLocalesCompanionExtension.fromJson(json);
      await _db
          .into(_db.supportedLocales)
          .insert(supportedLocale, mode: InsertMode.insertOrReplace);
    }

    await _updateLastFetchTime('supportedLocales');
  }

  Future<void> _fetchAndStoreRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select('id, last_modified');

    final remoteRecipes = response as List<Map<String, dynamic>>;
    final localRecipes = await _db.recipesDao.fetchIdsAndLastModifiedDates();

    for (var remoteRecipe in remoteRecipes) {
      final remoteId = remoteRecipe['id'] as String;
      final remoteLastModified =
          DateTime.parse(remoteRecipe['last_modified'] as String);

      if (!localRecipes.containsKey(remoteId) ||
          remoteLastModified.isAfter(localRecipes[remoteId] ??
              DateTime.fromMillisecondsSinceEpoch(0))) {
        // Fetch and update the full recipe record
        final fullRecipeResponse = await Supabase.instance.client
            .from('recipes')
            .select('*')
            .eq('id', remoteId)
            .single();

        final recipe = RecipesCompanionExtension.fromJson(
            fullRecipeResponse as Map<String, dynamic>);
        await _db.recipesDao.insertOrUpdateRecipe(recipe);

        // Fetch and update related recipe localizations and steps
        await _fetchAndStoreRecipeLocalizationsForRecipe(remoteId);
        await _fetchAndStoreStepsForRecipe(remoteId);
      }
    }
  }

  Future<void> _fetchAndStoreRecipeLocalizationsForRecipe(
      String recipeId) async {
    final response = await Supabase.instance.client
        .from('recipe_localization')
        .select('*')
        .eq('recipe_id', recipeId);

    final localizations = response as List<Map<String, dynamic>>;
    for (var localization in localizations) {
      final loc = RecipeLocalizationsCompanionExtension.fromJson(localization);
      await _db.recipeLocalizationsDao.insertOrUpdateLocalization(loc);
    }
  }

  Future<void> _fetchAndStoreStepsForRecipe(String recipeId) async {
    final response = await Supabase.instance.client
        .from('steps')
        .select('*')
        .eq('recipe_id', recipeId);

    final steps = response as List<Map<String, dynamic>>;
    for (var step in steps) {
      final s = StepsCompanionExtension.fromJson(step);
      await _db.stepsDao.insertOrUpdateStep(s);
    }
  }

  Future<void> _fetchAndStoreCoffeeFacts() async {
    final response =
        await Supabase.instance.client.from('coffee_facts').select();

    for (var json in response) {
      final coffeeFact = CoffeeFactsCompanionExtension.fromJson(json);
      await _db
          .into(_db.coffeeFacts)
          .insert(coffeeFact, mode: InsertMode.insertOrReplace);
    }

    await _updateLastFetchTime('coffeeFacts');
  }

  Future<void> _fetchAndStoreStartPopup() async {
    final response =
        await Supabase.instance.client.from('start_popup').select();

    for (var json in response) {
      final startPopup = StartPopupsCompanionExtension.fromJson(json);
      await _db
          .into(_db.startPopups)
          .insert(startPopup, mode: InsertMode.insertOrReplace);
    }
  }
}
