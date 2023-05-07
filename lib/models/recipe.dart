import 'package:coffee_timer/models/brew_step.dart';

class Recipe {
  final String id;
  final String name;
  final String brewingMethodId;
  final String brewingMethodName;
  final double coffeeAmount;
  final double waterAmount;
  final String grindSize;
  final Duration brewTime;
  final String shortDescription;
  final List<BrewStep> steps;

  Recipe({
    required this.id,
    required this.name,
    required this.brewingMethodId,
    required this.brewingMethodName,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.grindSize,
    required this.brewTime,
    required this.shortDescription,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<dynamic> stepsJson = json['steps'];
    List<BrewStep> steps = stepsJson.map((s) => BrewStep.fromJson(s)).toList();

    // Regular expression to match the "3min 30s" format
    RegExp regExp = RegExp(r"(\d+)min (\d+)s");

    // Extract the minutes and seconds from the brew_time string
    Match match = regExp.firstMatch(json['brew_time'])!;
    int minutes = int.parse(match.group(1)!);
    int seconds = int.parse(match.group(2)!);

    // Create a Duration object with the extracted minutes and seconds
    Duration brewTime = Duration(minutes: minutes, seconds: seconds);

    return Recipe(
      id: json['id'],
      name: json['name'],
      brewingMethodId: json['brewing_method_id'],
      brewingMethodName: json['brewing_method'],
      coffeeAmount: json['coffee_amount'].toDouble(),
      waterAmount: json['water_amount'].toDouble(),
      grindSize: json['grind_size'],
      brewTime: brewTime, // use the parsed brewTime
      shortDescription: json['short_description'],
      steps: steps,
    );
  }

  Recipe copyWith({
    double? coffeeAmount,
    double? waterAmount,
  }) {
    return Recipe(
      id: this.id,
      name: this.name,
      brewingMethodId: this.brewingMethodId,
      brewingMethodName: this.brewingMethodName,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      grindSize: this.grindSize,
      brewTime: this.brewTime,
      shortDescription: this.shortDescription,
      steps: this.steps,
    );
  }
}
