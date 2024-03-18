class BrewStepModel {
  final int order;
  final String description;
  Duration time;
  String? timePlaceholder;

  BrewStepModel({
    required this.order,
    required this.description,
    required this.time,
    this.timePlaceholder,
  });

  // Remove database entity dependencies from domain model
}
