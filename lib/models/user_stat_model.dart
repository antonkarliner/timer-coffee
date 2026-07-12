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
  final String? grindSize;
  final double? tdsPercent;
  final double? extractionYieldPercent;
  final String versionVector;
  final bool isDeleted;

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
    this.grindSize,
    this.tdsPercent,
    this.extractionYieldPercent,
    required this.versionVector,
    required this.isDeleted,
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
    String? grindSize,
    double? tdsPercent,
    double? extractionYieldPercent,
    String? versionVector,
    bool? isDeleted,
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
      coffeeBeansUuid: coffeeBeansUuid ?? this.coffeeBeansUuid,
      grindSize: grindSize ?? this.grindSize,
      tdsPercent: tdsPercent ?? this.tdsPercent,
      extractionYieldPercent:
          extractionYieldPercent ?? this.extractionYieldPercent,
      versionVector: versionVector ?? this.versionVector,
      isDeleted: isDeleted ?? this.isDeleted,
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
          grindSize == other.grindSize &&
          tdsPercent == other.tdsPercent &&
          extractionYieldPercent == other.extractionYieldPercent &&
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
      grindSize.hashCode ^
      tdsPercent.hashCode ^
      extractionYieldPercent.hashCode ^
      versionVector.hashCode ^
      isDeleted.hashCode;
}
