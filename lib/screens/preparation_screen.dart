// lib/screens/preparation_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'brewing_process_screen.dart'; // Import the BrewingProcessScreen
import '../models/brew_step.dart';

class PreparationScreen extends StatefulWidget {
  final Recipe recipe;

  PreparationScreen({required this.recipe});

  @override
  _PreparationScreenState createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  @override
  Widget build(BuildContext context) {
    List<BrewStep> preparationSteps =
        widget.recipe.steps.where((step) => step.time.inSeconds == 0).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Preparation')),
      body: ListView.builder(
        itemCount: preparationSteps.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(preparationSteps[index].description),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BrewingProcessScreen(
                recipe: widget.recipe,
                coffeeAmount: widget.recipe.coffeeAmount,
                waterAmount: widget.recipe.waterAmount,
              ),
            ),
          );
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
