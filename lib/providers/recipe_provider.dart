import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class RecipeProvider extends ChangeNotifier {
  final List<Recipe> _recipes = [];
  final ValueNotifier<Set<String>> _favoriteRecipeIds =
      ValueNotifier<Set<String>>({});
  Locale _locale; // Non-nullable

  RecipeProvider(this._locale) {
    _loadFavoriteRecipeIds();
    fetchRecipes(null); // Initial fetch with the provided locale
  }

  Locale get currentLocale => _locale;

  Future<void> _loadFavoriteRecipeIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteRecipesJson =
        prefs.getStringList('favoriteRecipes') ?? [];
    _favoriteRecipeIds.value = favoriteRecipesJson
        .map((item) => jsonDecode(item)['id'] as String)
        .toSet();
  }

  List<Recipe> getRecipes() {
    return [..._recipes];
  }

  Recipe getRecipeById(String recipeId) {
    int index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      return _recipes[index];
    } else {
      throw Exception('Recipe not found');
    }
  }

  Future<List<Recipe>> fetchRecipes(String? brewingMethodId) async {
    if (brewingMethodId == null || _locale == null) {
      _recipes.clear();
      return [..._recipes];
    }

    String jsonFileName;

    switch (brewingMethodId) {
      case 'hario_v60':
        jsonFileName = 'recipes_v60.json';
        break;
      case 'aeropress':
        jsonFileName = 'recipes_aeropress.json';
        break;
      case 'chemex':
        jsonFileName = 'recipes_chemex.json';
        break;
      case 'french_press':
        jsonFileName = 'recipes_frenchpress.json';
        break;
      case 'clever_dripper':
        jsonFileName = 'recipes_clever.json';
        break;
      case 'kalita_wave':
        jsonFileName = 'recipes_kalita.json';
        break;
      case 'wilfa_svart':
        jsonFileName = 'recipes_wilfa.json';
        break;
      case 'origami':
        jsonFileName = 'recipes_origami.json';
        break;
      default:
        throw Exception('Unknown brewing method ID: $brewingMethodId');
    }

    String localizedPath = 'assets/data/${_locale?.languageCode}/$jsonFileName';
    String jsonString = await rootBundle.loadString(localizedPath);
    final List<dynamic> jsonData = json.decode(jsonString);
    _recipes.clear();
    List<Recipe> recipes =
        jsonData.map((json) => Recipe.fromJson(json)).toList();

    for (Recipe recipe in recipes) {
      int index = _recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _recipes[index] = recipe.copyWith(
            isFavorite: _favoriteRecipeIds.value.contains(recipe.id));
      } else {
        _recipes.add(recipe.copyWith(
            isFavorite: _favoriteRecipeIds.value.contains(recipe.id)));
      }
    }

    notifyListeners();
    return [..._recipes];
  }

  Future<String> getBrewingMethodName(String? brewingMethodId) async {
    if (brewingMethodId == null) {
      return "Default name";
    }

    final brewingMethods = {
      'hario_v60': 'Hario V60',
      'aeropress': 'Aeropress',
      'chemex': 'Chemex',
      'french_press': 'French Press',
      'clever_dripper': 'Clever Dripper',
      'kalita_wave': 'Kalita Wave',
      'wilfa_svart': 'Wilfa Svart Pour Over',
      'origami': 'Origami Dripper'
    };

    if (!brewingMethods.containsKey(brewingMethodId)) {
      throw Exception('Unknown brewing method ID: $brewingMethodId');
    }

    return brewingMethods[brewingMethodId]!;
  }

  Future<void> saveLastUsedRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lastUsedRecipe', jsonEncode(recipe.toJson()));
  }

  Future<Recipe?> getLastUsedRecipe() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('lastUsedRecipe');

    if (jsonString != null) {
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      return Recipe.fromJson(jsonData);
    } else {
      return null;
    }
  }

  Future<Recipe> updateLastUsed(String recipeId) async {
    int index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      Recipe updatedRecipe = _recipes[index].copyWith(
        lastUsed: DateTime.now(),
      );
      _recipes[index] = updatedRecipe;
      await saveLastUsedRecipe(updatedRecipe);
      notifyListeners();
      return updatedRecipe;
    } else {
      throw Exception('Recipe not found');
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    int index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      Recipe updatedRecipe = _recipes[index].copyWith(
        isFavorite: !_recipes[index].isFavorite,
      );
      _recipes[index] = updatedRecipe;

      if (updatedRecipe.isFavorite) {
        _favoriteRecipeIds.value.add(updatedRecipe.id);
      } else {
        _favoriteRecipeIds.value.remove(updatedRecipe.id);
      }

      // Update the favorite recipes in SharedPreferences to match _favoriteRecipeIds
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> favoriteRecipesJson = _favoriteRecipeIds.value
          .map((recipeId) => jsonEncode(
              _recipes.firstWhere((recipe) => recipe.id == recipeId).toJson()))
          .toList();
      prefs.setStringList('favoriteRecipes', favoriteRecipesJson);

      notifyListeners();
    } else {
      throw Exception('Recipe not found');
    }
  }

  void setLocale(Locale newLocale) async {
    if (_locale.languageCode != newLocale.languageCode) {
      _locale = newLocale;
      await fetchRecipes(null); // Reload recipes with the new locale
      notifyListeners();
    }
  }

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
