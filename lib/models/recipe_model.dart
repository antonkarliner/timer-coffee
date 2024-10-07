import 'package:coffee_timer/models/brew_step_model.dart';

class RecipeModel {
  final String id;
  final String name;
  final String brewingMethodId;
  final double coffeeAmount;
  final double waterAmount;
  final double? waterTemp;
  final String grindSize;
  final Duration brewTime;
  final String shortDescription;
  final List<BrewStepModel> steps;
  final DateTime? lastUsed;
  final bool isFavorite;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final double? customCoffeeAmount;
  final double? customWaterAmount;
  final String? vendorId;
  final int? coffeeChroniclerSliderPosition;

  RecipeModel({
    required this.id,
    required this.name,
    required this.brewingMethodId,
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
    this.vendorId,
    this.coffeeChroniclerSliderPosition,
  });

  RecipeModel copyWith({
    String? id,
    String? name,
    String? brewingMethodId,
    double? coffeeAmount,
    double? waterAmount,
    double? waterTemp,
    String? grindSize,
    Duration? brewTime,
    String? shortDescription,
    List<BrewStepModel>? steps,
    DateTime? lastUsed,
    bool? isFavorite,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    double? customCoffeeAmount,
    double? customWaterAmount,
    String? vendorId,
    int? coffeeChroniclerSliderPosition,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      waterTemp: waterTemp ?? this.waterTemp,
      grindSize: grindSize ?? this.grindSize,
      brewTime: brewTime ?? this.brewTime,
      shortDescription: shortDescription ?? this.shortDescription,
      steps: steps ?? this.steps,
      lastUsed: lastUsed ?? this.lastUsed,
      isFavorite: isFavorite ?? this.isFavorite,
      sweetnessSliderPosition:
          sweetnessSliderPosition ?? this.sweetnessSliderPosition,
      strengthSliderPosition:
          strengthSliderPosition ?? this.strengthSliderPosition,
      customCoffeeAmount: customCoffeeAmount ?? this.customCoffeeAmount,
      customWaterAmount: customWaterAmount ?? this.customWaterAmount,
      vendorId: vendorId ?? this.vendorId,
      coffeeChroniclerSliderPosition:
          coffeeChroniclerSliderPosition ?? this.coffeeChroniclerSliderPosition,
    );
  }
}
