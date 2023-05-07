class BrewStep {
  final int order;
  final String description;
  final Duration time;

  BrewStep({
    required this.order,
    required this.description,
    required this.time,
  });

  factory BrewStep.fromJson(Map<String, dynamic> json) {
    return BrewStep(
      order: json['order'] as int,
      description: json['description'] as String,
      time: Duration(seconds: json['time'] as int),
    );
  }
}
