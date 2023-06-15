import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import 'brewing_process_screen.dart'; // Import the BrewingProcessScreen

class PreparationScreen extends StatefulWidget {
  final Recipe recipe;

  const PreparationScreen({super.key, required this.recipe});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  String replacePlaceholders(
    String description,
    double coffeeAmount,
    double waterAmount,
  ) {
    RegExp exp = RegExp(
        r'\(([\d.]+) x <(coffee_amount|water_amount|final_coffee_amount|final_water_amount)>\)');
    String replacedText = description.replaceAllMapped(exp, (match) {
      double multiplier = double.parse(match.group(1)!);
      String variable = match.group(2)!;
      double result;

      if (variable == 'coffee_amount' || variable == 'final_coffee_amount') {
        result = multiplier * coffeeAmount;
      } else {
        result = multiplier * waterAmount;
      }

      return result.toStringAsFixed(1);
    });

    replacedText = replacedText
        .replaceAll('<coffee_amount>', coffeeAmount.toStringAsFixed(1))
        .replaceAll('<water_amount>', waterAmount.toStringAsFixed(1))
        .replaceAll('<final_coffee_amount>', coffeeAmount.toStringAsFixed(1))
        .replaceAll('<final_water_amount>', waterAmount.toStringAsFixed(1));

    return replacedText;
  }

  @override
  Widget build(BuildContext context) {
    List<BrewStep> preparationSteps = widget.recipe.steps
        .map((step) => BrewStep(
              order: step.order,
              description: replacePlaceholders(
                step.description,
                widget.recipe.coffeeAmount,
                widget.recipe.waterAmount,
              ),
              time: step.time,
            ))
        .where((step) => step.time.inSeconds == 0)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Preparation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Adds padding around the column
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: preparationSteps
                .map((step) => Container(
                      width: double
                          .infinity, // Makes the container expand to fill the width of the screen
                      child: Text(
                        step.description,
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
        ),
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
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
