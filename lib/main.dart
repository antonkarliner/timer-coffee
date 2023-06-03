import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import './models/brewing_method.dart';
import './providers/recipe_provider.dart';
import './screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<BrewingMethod> brewingMethods = await loadBrewingMethodsFromAssets();

  runApp(CoffeeTimerApp(brewingMethods: brewingMethods));
}

class CoffeeTimerApp extends StatelessWidget {
  final List<BrewingMethod> brewingMethods;

  const CoffeeTimerApp({super.key, required this.brewingMethods});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecipeProvider>(
      create: (context) => RecipeProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coffee Timer App',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: kIsWeb ? 'Lato' : null,
        ),
        home: HomeScreen(brewingMethods: brewingMethods),
      ),
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
