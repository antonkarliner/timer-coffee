import 'package:coffee_timer/models/coffee_fact_model.dart';
import 'package:coffee_timer/models/contributor_model.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/models/vendor_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../models/recipe_model.dart';
import '../models/supported_locale_model.dart';

class RecipeProvider extends ChangeNotifier {
  List<RecipeModel> _recipes = [];
  final ValueNotifier<Set<String>> _favoriteRecipeIds =
      ValueNotifier<Set<String>>({});
  Locale _locale;
  List<Locale> _supportedLocales;
  final AppDatabase db;

  bool _isDataLoaded = false;

  RecipeProvider(this._locale, this._supportedLocales, this.db) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadFavoriteRecipeIds();
    await fetchAllRecipes();
    _isDataLoaded = true;
    notifyListeners();
  }

  Future<List<RecipeModel>> get recipes async {
    await ensureDataReady();
    return _recipes;
  }

  Future<void> ensureDataReady() async {
    if (!_isDataLoaded) {
      await _initialize();
    }
  }

  Locale get currentLocale => _locale;

  Future<void> _loadFavoriteRecipeIds() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteRecipeIds =
        prefs.getStringList('favoriteRecipes') ?? [];
    _favoriteRecipeIds.value = Set.from(favoriteRecipeIds);
  }

  Future<void> fetchAllRecipes() async {
    _recipes.clear();
    List<RecipeModel> recipesList =
        await db.recipesDao.getAllRecipes(currentLocale.toString());
    _recipes.addAll(recipesList);
    notifyListeners();
  }

  Future<List<RecipeModel>> fetchRecipesForBrewingMethod(
      String brewingMethodId) async {
    await ensureDataReady();
    return _recipes
        .where((recipe) =>
            recipe.brewingMethodId == brewingMethodId &&
            recipe.vendorId == "timercoffee")
        .toList();
  }

  Future<String> getBrewingMethodName(String? brewingMethodId) async {
    if (brewingMethodId == null) {
      return "Default name";
    }

    // Use the DAO to fetch the brewing method name
    String? brewingMethodName =
        await db.brewingMethodsDao.getBrewingMethodNameById(brewingMethodId);

    if (brewingMethodName != null) {
      return brewingMethodName;
    } else {
      throw Exception('Unknown brewing method ID: $brewingMethodId');
    }
  }

  Future<RecipeModel> getRecipeById(String recipeId) async {
    await ensureDataReady();
    // Assume _locale is a variable holding the current locale set in RecipeProvider
    RecipeModel? recipe =
        await db.recipesDao.getRecipeModelById(recipeId, _locale.languageCode);
    if (recipe != null) {
      return recipe;
    } else {
      throw Exception('Recipe not found');
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    var index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      var recipe = _recipes[index];
      var isFavorite = !recipe.isFavorite;

      await db.userRecipePreferencesDao
          .updatePreferences(recipeId, isFavorite: isFavorite);
      _recipes[index] = recipe.copyWith(isFavorite: isFavorite);

      // Check if the favorite status has indeed toggled.
      if (_favoriteRecipeIds.value.contains(recipeId) != isFavorite) {
        if (isFavorite) {
          _favoriteRecipeIds.value.add(recipeId);
        } else {
          _favoriteRecipeIds.value.remove(recipeId);
        }
        _favoriteRecipeIds.notifyListeners(); // Notify favorite IDs changes.

        // This ensures we only notify listeners when there's a change.
        notifyListeners();
      }
    } else {
      throw Exception('Recipe not found: $recipeId');
    }
  }

  Future<void> saveCustomAmounts(
      String recipeId, double coffeeAmount, double waterAmount) async {
    await db.userRecipePreferencesDao.updatePreferences(
      recipeId,
      customCoffeeAmount: coffeeAmount,
      customWaterAmount: waterAmount,
    );
    await fetchAllRecipes();
  }

  Future<void> saveSliderPositions(String recipeId, int sweetnessSliderPosition,
      int strengthSliderPosition) async {
    await db.userRecipePreferencesDao.updatePreferences(
      recipeId,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
    );
    await fetchAllRecipes();
  }

  Future<RecipeModel?> getLastUsedRecipe() async {
    var lastUsedPreference =
        await db.userRecipePreferencesDao.getLastUsedRecipe();
    if (lastUsedPreference != null) {
      return getRecipeById(lastUsedPreference.recipeId);
    }
    return null;
  }

  Future<String> fetchBrewingMethodName(String brewingMethodId) async {
    String? brewingMethodName =
        await db.brewingMethodsDao.getBrewingMethodNameById(brewingMethodId);
    return brewingMethodName ?? "Unknown Brewing Method";
  }

  List<RecipeModel> getFavoriteRecipes() {
    return _recipes
        .where((recipe) => _favoriteRecipeIds.value.contains(recipe.id))
        .toList();
  }

  Future<List<RecipeModel>> fetchFavoriteRecipes(String locale) async {
    await ensureDataReady();
    final List<UserRecipePreference> favoritePrefs =
        await db.userRecipePreferencesDao.getFavoritePreferences();
    List<RecipeModel> favoriteRecipes = [];

    for (var pref in favoritePrefs) {
      final recipe =
          await db.recipesDao.getRecipeModelById(pref.recipeId, locale);
      if (recipe != null) {
        favoriteRecipes.add(recipe);
      }
    }

    return favoriteRecipes;
  }

  Future<List<VendorModel>> fetchAllActiveVendors() async {
    await ensureDataReady(); // Ensure all initial data is loaded.
    return db.vendorsDao.getAllActiveVendors();
  }

  Future<List<RecipeModel>> fetchRecipesForVendor(String vendorId) async {
    await ensureDataReady(); // Ensure all initial data is loaded.
    return _recipes.where((recipe) => recipe.vendorId == vendorId).toList();
  }

  Future<String> fetchVendorName(String vendorId) async {
    await ensureDataReady();
    var vendor = await db.vendorsDao.getVendorById(vendorId);
    return vendor?.vendorName ?? "Unknown Vendor";
  }

  Future<VendorModel?> fetchVendorById(String vendorId) async {
    return db.vendorsDao.getVendorById(vendorId);
  }

  Future<LaunchPopupModel?> fetchLatestLaunchPopup(String locale) async {
    await ensureDataReady(); // Make sure the database is initialized
    return await db.launchPopupsDao.getLatestLaunchPopup(locale);
  }

  Future<List<SupportedLocaleModel>> fetchAllSupportedLocales() async {
    List<SupportedLocaleModel> supportedLocales =
        await db.supportedLocalesDao.getAllSupportedLocales();

    // Sorting the list alphabetically by localeName
    supportedLocales.sort((a, b) => a.locale.compareTo(b.locale));

    return supportedLocales;
  }

  Future<String> getLocaleName(String localeCode) async {
    final supportedLocales = await fetchAllSupportedLocales();
    return supportedLocales
        .firstWhere(
          (locale) => locale.locale == localeCode,
          orElse: () =>
              SupportedLocaleModel(locale: localeCode, localeName: "Unknown"),
        )
        .localeName;
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      await fetchAllRecipes(); // Fetch all recipes with the new locale
      notifyListeners();
    }
  }

  Future<String> getRandomCoffeeFactFromDB() async {
    final CoffeeFactModel? coffeeFact =
        await db.coffeeFactsDao.getRandomCoffeeFact(_locale.languageCode);
    if (coffeeFact != null) {
      return coffeeFact.fact;
    } else {
      throw Exception('No coffee facts found for the current locale');
    }
  }

  Future<String?> fetchVendorBannerUrl(String vendorId) async {
    await ensureDataReady();
    VendorModel? vendor = await db.vendorsDao.getVendorById(vendorId);
    return vendor?.bannerUrl;
  }

  Future<List<ContributorModel>> fetchAllContributorsForCurrentLocale() async {
    await ensureDataReady(); // Ensure all initial data is loaded.
    String localeCode = _locale.languageCode;
    final contributors =
        await db.contributorsDao.getAllContributorsForLocale(localeCode);
    return contributors
        .map((contributor) => ContributorModel(
              id: contributor.id,
              content: contributor.content,
              locale: contributor.locale,
            ))
        .toList();
  }

  Future<void> insertUserStat({
    required String userId,
    required String recipeId,
    required double coffeeAmount,
    required double waterAmount,
    required int sweetnessSliderPosition,
    required int strengthSliderPosition,
    required String brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
  }) async {
    await db.userStatsDao.insertUserStat(
      userId: userId,
      recipeId: recipeId,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
      brewingMethodId: brewingMethodId,
      notes: notes,
      beans: beans,
      roaster: roaster,
      rating: rating,
    );
  }

  Future<void> updateUserStat({
    required int id,
    String? userId,
    String? recipeId,
    double? coffeeAmount,
    double? waterAmount,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    String? brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
  }) async {
    await db.userStatsDao.updateUserStat(
      id: id,
      userId: userId,
      recipeId: recipeId,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
      brewingMethodId: brewingMethodId,
      notes: notes,
      beans: beans,
      roaster: roaster,
      rating: rating,
    );
  }

  Future<List<UserStatsModel>> fetchAllUserStats() async {
    return await db.userStatsDao.fetchAllStats();
  }

  Future<UserStatsModel?> fetchUserStatById(int id) async {
    return await db.userStatsDao.fetchStatById(id);
  }

  Future<String> getLocalizedRecipeName(String recipeId) async {
    RecipeLocalization? localization = await db.recipeLocalizationsDao
        .getLocalizationForRecipe(recipeId, _locale.languageCode);
    return localization?.name ?? "Unknown Recipe";
  }

  // Fetch all distinct roasters from the database
  Future<List<String>> fetchAllDistinctRoasters() async {
    try {
      return await db.userStatsDao.fetchAllDistinctRoasters();
    } catch (e) {
      print('Error fetching roasters: $e');
      return [];
    }
  }

// Fetch all distinct beans from the database
  Future<List<String>> fetchAllDistinctBeans() async {
    try {
      return await db.userStatsDao.fetchAllDistinctBeans();
    } catch (e) {
      print('Error fetching beans: $e');
      return [];
    }
  }

  // Search for roasters that match a given filter
  Future<List<String>> searchRoasters(String filter) async {
    List<String> roasters = await fetchAllDistinctRoasters();
    return roasters.where((roaster) => roaster.contains(filter)).toList();
  }

  // Search for beans that match a given filter
  Future<List<String>> searchBeans(String filter) async {
    List<String> beans = await fetchAllDistinctBeans();
    return beans.where((bean) => bean.contains(filter)).toList();
  }

  Future<void> deleteUserStat(int id) async {
    await db.userStatsDao.deleteUserStat(id);
  }

  Future<double> fetchBrewedCoffeeAmountForPeriod(
      DateTime start, DateTime end) async {
    return await db.userStatsDao.fetchBrewedCoffeeAmount(start, end);
  }

  Future<List<String>> fetchTopRecipeIdsForPeriod(
      DateTime start, DateTime end) async {
    return await db.userStatsDao.fetchTopRecipes(start, end);
  }

  DateTime getStartOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime getEndOfToday() {
    return getStartOfToday()
        .add(Duration(days: 1))
        .subtract(Duration(milliseconds: 1));
  }

  DateTime getStartOfWeek() {
    final now = DateTime.now();
    // Adjust to first day of week as Monday
    int weekday = now.weekday;
    DateTime startOfWeek = now.subtract(Duration(days: weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
