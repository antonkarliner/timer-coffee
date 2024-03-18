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
  });
}
