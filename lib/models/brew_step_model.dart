class BrewStepModel {
  /// NEW – immutable, stable per step
  final String id;

  final int order;
  final String description;
  final Duration time;
  final String? timePlaceholder;

  BrewStepModel({
    required this.id,
    required this.order,
    required this.description,
    required this.time,
    this.timePlaceholder,
  });

  /// convenient helper – makes the update code shorter
  BrewStepModel copyWith({
    String? id,
    int? order,
    String? description,
    Duration? time,
    String? timePlaceholder,
  }) =>
      BrewStepModel(
        id: id ?? this.id,
        order: order ?? this.order,
        description: description ?? this.description,
        time: time ?? this.time,
        timePlaceholder: timePlaceholder ?? this.timePlaceholder,
      );
}
