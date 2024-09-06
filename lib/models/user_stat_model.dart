import '../utils/version_vector.dart';

class UserStatsModel {
  final String statUuid;
  final int? id;
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
  final String versionVector;
  final bool isDeleted; // New field to track deletion status

  UserStatsModel({
    required this.statUuid,
    this.id,
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
    required this.versionVector,
    required this.isDeleted, // Initialize the new field
  });

  VersionVector get versionVectorObject =>
      VersionVector.fromString(versionVector);

  UserStatsModel copyWith({
    String? statUuid,
    int? id,
    String? recipeId,
    double? coffeeAmount,
    double? waterAmount,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    String? brewingMethodId,
    DateTime? createdAt,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
    int? coffeeBeansId,
    bool? isMarked,
    String? coffeeBeansUuid,
    String? versionVector,
    bool? isDeleted, // Allow updating the isDeleted field
  }) {
    return UserStatsModel(
      statUuid: statUuid ?? this.statUuid,
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      sweetnessSliderPosition:
          sweetnessSliderPosition ?? this.sweetnessSliderPosition,
      strengthSliderPosition:
          strengthSliderPosition ?? this.strengthSliderPosition,
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      beans: beans ?? this.beans,
      roaster: roaster ?? this.roaster,
      rating: rating ?? this.rating,
      coffeeBeansId: coffeeBeansId ?? this.coffeeBeansId,
      isMarked: isMarked ?? this.isMarked,
      coffeeBeansUuid: coffeeBeansUuid, // Remove null-coalescing operator here
      versionVector: versionVector ?? this.versionVector,
      isDeleted:
          isDeleted ?? this.isDeleted, // Update or keep current isDeleted value
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsModel &&
          runtimeType == other.runtimeType &&
          statUuid == other.statUuid &&
          id == other.id &&
          recipeId == other.recipeId &&
          coffeeAmount == other.coffeeAmount &&
          waterAmount == other.waterAmount &&
          sweetnessSliderPosition == other.sweetnessSliderPosition &&
          strengthSliderPosition == other.strengthSliderPosition &&
          brewingMethodId == other.brewingMethodId &&
          createdAt == other.createdAt &&
          notes == other.notes &&
          beans == other.beans &&
          roaster == other.roaster &&
          rating == other.rating &&
          coffeeBeansId == other.coffeeBeansId &&
          isMarked == other.isMarked &&
          coffeeBeansUuid == other.coffeeBeansUuid &&
          versionVector == other.versionVector &&
          isDeleted == other.isDeleted;

  // Hash code
  @override
  int get hashCode =>
      statUuid.hashCode ^
      id.hashCode ^
      recipeId.hashCode ^
      coffeeAmount.hashCode ^
      waterAmount.hashCode ^
      sweetnessSliderPosition.hashCode ^
      strengthSliderPosition.hashCode ^
      brewingMethodId.hashCode ^
      createdAt.hashCode ^
      notes.hashCode ^
      beans.hashCode ^
      roaster.hashCode ^
      rating.hashCode ^
      coffeeBeansId.hashCode ^
      isMarked.hashCode ^
      coffeeBeansUuid.hashCode ^
      versionVector.hashCode ^
      isDeleted.hashCode;
}
