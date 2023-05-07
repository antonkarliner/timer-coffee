class BrewingMethod {
  final int id;
  final String name;

  BrewingMethod({required this.id, required this.name});
}

class Recipe {
  final int id;
  final String name;
  final String brewingMethod;
  final int coffeeAmount;
  final int waterAmount;
  final String grindSize;
  final String brewTime;
  final String shortDescription;
  final List<BrewStep> steps;

  Recipe({
    required this.id,
    required this.name,
    required this.brewingMethod,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.grindSize,
    required this.brewTime,
    required this.shortDescription,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      brewingMethod: json['brewing_method'],
      coffeeAmount: json['coffee_amount'],
      waterAmount: json['water_amount'],
      grindSize: json['grind_size'],
      brewTime: json['brew_time'],
      shortDescription: json['short_description'],
      steps: (json['steps'] as List<dynamic>)
          .map((step) => BrewStep.fromJson(step))
          .toList(),
    );
  }
}

class BrewStep {
  final int order;
  final String description;
  final Duration time;

  BrewStep(
      {required this.order, required this.description, required this.time});

  factory BrewStep.fromJson(Map<String, dynamic> json) {
    return BrewStep(
      order: json['order'],
      description: json['description'],
      time: Duration(seconds: json['time']),
    );
  }
}
