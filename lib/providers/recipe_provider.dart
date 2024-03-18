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

  RecipeProvider(this._locale, this._supportedLocales, this.db) {
    _loadFavoriteRecipeIds();
    fetchAllRecipes();
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

  RecipeModel getRecipeById(String recipeId) {
    return _recipes.firstWhere((r) => r.id == recipeId,
        orElse: () => throw Exception('Recipe not found'));
  }

  Future<void> toggleFavorite(String recipeId) async {
    var recipe = getRecipeById(recipeId);
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

  void setLocale(Locale newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      await fetchAllRecipes(); // Fetch all recipes with the new locale
      notifyListeners();
    }
  }

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
