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
  Locale _locale;

  RecipeProvider(this._locale) {
    _loadFavoriteRecipeIds();
    fetchAllRecipes();
  }

  Locale get currentLocale => _locale;

  Future<void> _loadFavoriteRecipeIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteRecipeIds =
        prefs.getStringList('favoriteRecipes') ?? [];
    _favoriteRecipeIds.value =
        favoriteRecipeIds.map((id) => id.toString()).toSet();
  }

  List<Recipe> getRecipes() {
    return [..._recipes];
  }

  Recipe getRecipeById(String recipeId) {
    return _recipes.firstWhere((r) => r.id == recipeId,
        orElse: () => throw Exception('Recipe not found'));
  }

  Future<void> fetchAllRecipes() async {
    _recipes.clear();
    List<String> brewingMethods = [
      'hario_v60',
      'aeropress',
      'chemex',
      'french_press',
      'clever_dripper',
      'kalita_wave',
      'wilfa_svart',
      'origami'
    ];
    for (var method in brewingMethods) {
      await fetchRecipes(method);
    }
  }

  Future<void> fetchRecipes(String? brewingMethodId) async {
    if (brewingMethodId == null) return;

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

    String localizedPath = 'assets/data/${_locale.languageCode}/$jsonFileName';
    String jsonString = await rootBundle.loadString(localizedPath);
    List<dynamic> jsonData = json.decode(jsonString);
    List<Recipe> newRecipes =
        jsonData.map((json) => Recipe.fromJson(json)).toList();

    for (var recipe in newRecipes) {
      if (!_recipes.any((r) => r.id == recipe.id)) {
        _recipes.add(recipe.copyWith(
            isFavorite: _favoriteRecipeIds.value.contains(recipe.id)));
      }
    }

    notifyListeners();
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
      return Recipe.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  Future<Recipe> updateLastUsed(String recipeId) async {
    int index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index != -1) {
      Recipe updatedRecipe = _recipes[index].copyWith(lastUsed: DateTime.now());
      _recipes[index] = updatedRecipe;
      await saveLastUsedRecipe(updatedRecipe);
      notifyListeners();
      return updatedRecipe;
    } else {
      throw Exception('Recipe not found');
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    // Check if the recipe is currently loaded in _recipes
    int index = _recipes.indexWhere((recipe) => recipe.id == recipeId);

    // If found, update its favorite status
    if (index != -1) {
      _recipes[index] =
          _recipes[index].copyWith(isFavorite: !_recipes[index].isFavorite);
    }

    // Update the set of favorite recipe IDs
    if (_favoriteRecipeIds.value.contains(recipeId)) {
      _favoriteRecipeIds.value.remove(recipeId);
    } else {
      _favoriteRecipeIds.value.add(recipeId);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favoriteRecipes', _favoriteRecipeIds.value.toList());

    notifyListeners();
  }

  void setLocale(Locale newLocale) async {
    if (_locale.languageCode != newLocale.languageCode) {
      _locale = newLocale;
      await fetchAllRecipes(); // Fetch all recipes with the new locale
      notifyListeners();
    }
  }

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
