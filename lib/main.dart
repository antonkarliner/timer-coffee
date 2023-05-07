import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/coffee_timer_app.dart';
import 'models/brewing_method.dart';
import 'models/recipe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<BrewingMethod> brewingMethods = await loadBrewingMethodsFromAssets();
  runApp(CoffeeTimerApp(brewingMethods: brewingMethods));
}

Future<List<BrewingMethod>> loadBrewingMethodsFromAssets() async {
  String jsonString =
      await rootBundle.loadString('assets/data/brewing_methods.json');
  List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((json) => BrewingMethod.fromJson(json))
      .toList()
      .cast<BrewingMethod>();
}
