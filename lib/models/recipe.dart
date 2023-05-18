import 'package:coffee_timer/models/brew_step.dart';

class Recipe {
  final String id;
  final String name;
  final String brewingMethodId;
  final String brewingMethodName;
  final double coffeeAmount;
  final double waterAmount;
  final double? waterTemp;
  final String grindSize;
  final Duration brewTime;
  final String shortDescription;
  final List<BrewStep> steps;
  final DateTime? lastUsed;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.brewingMethodId,
    required this.brewingMethodName,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.waterTemp,
    required this.grindSize,
    required this.brewTime,
    required this.shortDescription,
    required this.steps,
    this.lastUsed,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<dynamic> stepsJson = json['steps'];
    List<BrewStep> steps = stepsJson.map((s) => BrewStep.fromJson(s)).toList();

    RegExp regExp = RegExp(r"(\d+)min (\d+)s");

    Match match = regExp.firstMatch(json['brew_time'])!;
    int minutes = int.parse(match.group(1)!);
    int seconds = int.parse(match.group(2)!);

    Duration brewTime = Duration(minutes: minutes, seconds: seconds);

    DateTime? lastUsed =
        json['last_used'] != null ? DateTime.parse(json['last_used']) : null;
    bool isFavorite = json['is_favorite'] ?? false;

    return Recipe(
      id: json['id'],
      name: json['name'],
      brewingMethodId: json['brewing_method_id'],
      brewingMethodName: json['brewing_method'],
      coffeeAmount: json['coffee_amount'].toDouble(),
      waterAmount: json['water_amount'].toDouble(),
      waterTemp:
          json['water_temp'] != null ? json['water_temp'].toDouble() : null,
      grindSize: json['grind_size'],
      brewTime: brewTime,
      shortDescription: json['short_description'],
      steps: steps,
      lastUsed: lastUsed,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brewing_method_id': brewingMethodId,
        'brewing_method': brewingMethodName,
        'coffee_amount': coffeeAmount,
        'water_amount': waterAmount,
        'water_temp': waterTemp,
        'grind_size': grindSize,
        'brew_time':
            '${brewTime.inMinutes}min ${brewTime.inSeconds.remainder(60)}s',
        'short_description': shortDescription,
        'steps': steps.map((step) => step.toJson()).toList(),
        'last_used': lastUsed?.toIso8601String(),
        'is_favorite': isFavorite,
      };

  Recipe copyWith({
    double? coffeeAmount,
    double? waterAmount,
    DateTime? lastUsed,
    bool? isFavorite,
  }) {
    return Recipe(
      id: this.id,
      name: this.name,
      brewingMethodId: this.brewingMethodId,
      brewingMethodName: this.brewingMethodName,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      waterTemp: this.waterTemp,
      grindSize: this.grindSize,
      brewTime: this.brewTime,
      shortDescription: this.shortDescription,
      steps: this.steps,
      lastUsed: lastUsed ?? this.lastUsed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
