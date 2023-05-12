import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import 'package:flutter/foundation.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  ValueNotifier<Set<String>> _favoriteRecipeIds =
      ValueNotifier<Set<String>>({});

  RecipeProvider() {
    _loadFavoriteRecipeIds();
  }

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

  Future<List<Recipe>> fetchRecipes(String brewingMethodId) async {
    String jsonFileName;

    switch (brewingMethodId) {
      case 'hario_v60':
        jsonFileName = 'recipes_v60.json';
        break;
      case 'aeropress':
        jsonFileName = 'recipes_aeropress.json';
        break;
      default:
        throw Exception('Unknown brewing method ID: $brewingMethodId');
    }

    String jsonString =
        await rootBundle.loadString('assets/data/$jsonFileName');
    final List<dynamic> jsonData = json.decode(jsonString);
    List<Recipe> recipes =
        jsonData.map((json) => Recipe.fromJson(json)).toList();

    // Update the _recipes list instead of overwriting it
    for (Recipe recipe in recipes) {
      int index = _recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        // Update existing recipe
        _recipes[index] = recipe.copyWith(
            isFavorite: _favoriteRecipeIds.value.contains(recipe.id));
      } else {
        // Add new recipe
        _recipes.add(recipe.copyWith(
            isFavorite: _favoriteRecipeIds.value.contains(recipe.id)));
      }
    }

    notifyListeners();

    return [..._recipes];
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

  ValueNotifier<Set<String>> get favoriteRecipeIds => _favoriteRecipeIds;
}
