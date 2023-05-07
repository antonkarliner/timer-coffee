import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import 'package:flutter/foundation.dart';

class RecipeProvider extends ChangeNotifier {
  Future<List<Recipe>> fetchRecipes(String brewingMethodId) async {
    String jsonFileName;

    switch (brewingMethodId) {
      case 'hario_v60':
        jsonFileName = 'recipes_v60.json';
        break;
      case 'aeropress':
        jsonFileName = 'recipes_aeropress.json';
        break;
      // Add more cases here for other brewing methods
      default:
        throw Exception('Unknown brewing method ID: $brewingMethodId');
    }

    String jsonString =
        await rootBundle.loadString('assets/data/$jsonFileName');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((json) => Recipe.fromJson(json)).toList();
  }
}
