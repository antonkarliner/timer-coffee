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

  bool _isDataLoaded = false; // Add this line

  RecipeProvider(this._locale, this._supportedLocales, this.db) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadFavoriteRecipeIds();
    await fetchAllRecipes();
    _isDataLoaded = true; // Mark data as loaded
    notifyListeners();
  }

  // Modify getters to ensure they await data readiness
  Future<List<RecipeModel>> get recipes async {
    await ensureDataReady();
    return _recipes;
  }

  // Add ensureDataReady method
  Future<void> ensureDataReady() async {
    if (!_isDataLoaded) {
      // Wait for the initial data load to complete
      await _initialize();
    }
  }

  Locale get currentLocale => _locale;

  Future<void> _loadFavoriteRecipeIds() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteRecipeIds =
        prefs.getStringList('favoriteRecipes') ?? [];
    _favoriteRecipeIds.value = favoriteRecipeIds.map((id) => id).toSet();
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
    return db.recipesDao
        .fetchRecipesForBrewingMethod(brewingMethodId, _locale.toString());
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
    var recipe = await getRecipeById(recipeId); // Use await here
    await db.userRecipePreferencesDao.updatePreferences(
      recipeId,
      isFavorite: !recipe.isFavorite,
    );
    // Reflect changes in the local list
    await fetchAllRecipes();
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

  void setLocale(Locale newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      await fetchAllRecipes(); // Fetch all recipes with the new locale
      notifyListeners();
    }
  }

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
