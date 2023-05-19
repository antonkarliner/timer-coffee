import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this line
import '../models/brewing_method.dart';
import 'home_screen.dart';
import '../providers/recipe_provider.dart'; // Add this line

class CoffeeTimerApp extends StatelessWidget {
  final List<BrewingMethod> brewingMethods;

  CoffeeTimerApp({required this.brewingMethods});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecipeProvider>(
      create: (context) => RecipeProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Timer.Coffee',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(brewingMethods: brewingMethods),
      ),
    );
  }
}
