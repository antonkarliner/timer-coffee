import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/coffee_timer_app.dart';
import 'models/brewing_method.dart';
import 'models/recipe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<BrewingMethod> brewingMethods = await loadBrewingMethodsFromAssets();

  runApp(MyApp(brewingMethods: brewingMethods));
}

class MyApp extends StatelessWidget {
  final List<BrewingMethod> brewingMethods;

  MyApp({required this.brewingMethods});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Timer App',
      theme: ThemeData(
        fontFamily: kIsWeb ? 'Lato' : null,
      ),
      home: CoffeeTimerApp(brewingMethods: brewingMethods),
    );
  }
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
