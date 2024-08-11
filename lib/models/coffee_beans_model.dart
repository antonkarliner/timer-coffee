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
  final bool isFavorite;

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
    this.isFavorite = false,
  });
}
