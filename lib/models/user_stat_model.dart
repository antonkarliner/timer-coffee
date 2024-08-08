class UserStatsModel {
  final String statUuid;
  final int? id; // Change to nullable
  final String recipeId;
  final double coffeeAmount;
  final double waterAmount;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final String brewingMethodId;
  final DateTime createdAt;
  final String? notes;
  final String? beans;
  final String? roaster;
  final double? rating;
  final int? coffeeBeansId;
  final bool isMarked;
  final String? coffeeBeansUuid;

  UserStatsModel({
    required this.statUuid,
    this.id, // Change to optional
    required this.recipeId,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
    required this.brewingMethodId,
    required this.createdAt,
    this.notes,
    this.beans,
    this.roaster,
    this.rating,
    this.coffeeBeansId,
    required this.isMarked,
    this.coffeeBeansUuid,
  });
}
