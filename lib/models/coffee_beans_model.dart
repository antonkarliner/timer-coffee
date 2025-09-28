import '../utils/version_vector.dart';

class CoffeeBeansModel {
  final String beansUuid;
  final int? id;
  final String roaster;
  final String name;
  final String origin;
  final String? variety;
  final String? tastingNotes;
  final String? processingMethod;
  final int? elevation;
  final DateTime? harvestDate;
  final DateTime? roastDate;
  final String? region;
  final String? roastLevel;
  final double? cuppingScore;
  final String? notes;
  final String? farmer; // New optional field
  final String? farm; // New optional field
  final double? packageWeightGrams;
  final bool isFavorite;
  final bool isDeleted; // New field to track soft deletion
  final String versionVector;

  CoffeeBeansModel({
    required this.beansUuid,
    this.id,
    required this.roaster,
    required this.name,
    required this.origin,
    this.variety,
    this.tastingNotes,
    this.processingMethod,
    this.elevation,
    this.harvestDate,
    this.roastDate,
    this.region,
    this.roastLevel,
    this.cuppingScore,
    this.notes,
    this.farmer,
    this.farm,
    this.packageWeightGrams,
    this.isFavorite = false,
    this.isDeleted = false, // Default value set to false
    required this.versionVector,
  });

  VersionVector get versionVectorObject =>
      VersionVector.fromString(versionVector);

  double? get validatedPackageWeightGrams {
    final value = packageWeightGrams;
    if (value == null) return null;
    if (value < 0) return 0.0;
    if (value < 0.1) return null;
    return value;
  }

  CoffeeBeansModel copyWith({
    String? beansUuid,
    int? id,
    String? roaster,
    String? name,
    String? origin,
    String? variety,
    String? tastingNotes,
    String? processingMethod,
    int? elevation,
    DateTime? harvestDate,
    DateTime? roastDate,
    String? region,
    String? roastLevel,
    double? cuppingScore,
    String? notes,
    String? farmer,
    String? farm,
    double? packageWeightGrams,
    bool? isFavorite,
    bool? isDeleted, // Optional field in the copyWith method
    String? versionVector,
  }) {
    return CoffeeBeansModel(
      beansUuid: beansUuid ?? this.beansUuid,
      id: id ?? this.id,
      roaster: roaster ?? this.roaster,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      variety: variety ?? this.variety,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      processingMethod: processingMethod ?? this.processingMethod,
      elevation: elevation ?? this.elevation,
      harvestDate: harvestDate ?? this.harvestDate,
      roastDate: roastDate ?? this.roastDate,
      region: region ?? this.region,
      roastLevel: roastLevel ?? this.roastLevel,
      cuppingScore: cuppingScore ?? this.cuppingScore,
      notes: notes ?? this.notes,
      farmer: farmer ?? this.farmer,
      farm: farm ?? this.farm,
      packageWeightGrams: packageWeightGrams ?? this.packageWeightGrams,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted, // Handle isDeleted in copyWith
      versionVector: versionVector ?? this.versionVector,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffeeBeansModel &&
          runtimeType == other.runtimeType &&
          beansUuid == other.beansUuid &&
          id == other.id &&
          roaster == other.roaster &&
          name == other.name &&
          origin == other.origin &&
          variety == other.variety &&
          tastingNotes == other.tastingNotes &&
          processingMethod == other.processingMethod &&
          elevation == other.elevation &&
          harvestDate == other.harvestDate &&
          roastDate == other.roastDate &&
          region == other.region &&
          roastLevel == other.roastLevel &&
          cuppingScore == other.cuppingScore &&
          notes == other.notes &&
          farmer == other.farmer &&
          farm == other.farm &&
          packageWeightGrams == other.packageWeightGrams &&
          isFavorite == other.isFavorite &&
          isDeleted == other.isDeleted && // Include isDeleted in equality
          versionVector == other.versionVector;

  @override
  int get hashCode =>
      beansUuid.hashCode ^
      id.hashCode ^
      roaster.hashCode ^
      name.hashCode ^
      origin.hashCode ^
      variety.hashCode ^
      tastingNotes.hashCode ^
      processingMethod.hashCode ^
      elevation.hashCode ^
      harvestDate.hashCode ^
      roastDate.hashCode ^
      region.hashCode ^
      roastLevel.hashCode ^
      cuppingScore.hashCode ^
      notes.hashCode ^
      farmer.hashCode ^
      farm.hashCode ^
      packageWeightGrams.hashCode ^
      isFavorite.hashCode ^
      isDeleted.hashCode ^ // Include isDeleted in hashCode
      versionVector.hashCode;
}
