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
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final double? customCoffeeAmount;
  final double? customWaterAmount;

  Recipe({
    required this.id,
    required this.name,
    required this.brewingMethodId,
    required this.brewingMethodName,
    required this.coffeeAmount,
    required this.waterAmount,
    this.waterTemp,
    required this.grindSize,
    required this.brewTime,
    required this.shortDescription,
    required this.steps,
    this.lastUsed,
    this.isFavorite = false,
    this.sweetnessSliderPosition = 1,
    this.strengthSliderPosition = 2,
    this.customCoffeeAmount,
    this.customWaterAmount,
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
      customCoffeeAmount: json['custom_coffee_amount']?.toDouble(),
      customWaterAmount: json['custom_water_amount']?.toDouble(),
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
        'custom_coffee_amount': customCoffeeAmount,
        'custom_water_amount': customWaterAmount,
      };

  Recipe copyWith({
    double? coffeeAmount,
    double? waterAmount,
    DateTime? lastUsed,
    bool? isFavorite,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    double? customCoffeeAmount,
    double? customWaterAmount,
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
      sweetnessSliderPosition:
          sweetnessSliderPosition ?? this.sweetnessSliderPosition,
      strengthSliderPosition:
          strengthSliderPosition ?? this.strengthSliderPosition,
      customCoffeeAmount: customCoffeeAmount ?? this.customCoffeeAmount,
      customWaterAmount: customWaterAmount ?? this.customWaterAmount,
    );
  }
}
