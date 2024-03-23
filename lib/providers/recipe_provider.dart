import 'package:coffee_timer/models/start_popup_model.dart';
import 'package:coffee_timer/models/vendor_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../models/recipe_model.dart';

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
    return _recipes.firstWhere((r) => r.id == recipeId, orElse: () {
      throw Exception('Recipe not found');
    });
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

  Future<StartPopupModel?> fetchStartPopup(
      String version, String locale) async {
    await ensureDataReady(); // Make sure the database is initialized
    return await db.startPopupsDao.getStartPopup(version, locale);
  }

  void setLocale(Locale newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      await fetchAllRecipes(); // Fetch all recipes with the new locale
      notifyListeners();
    }
  }

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
