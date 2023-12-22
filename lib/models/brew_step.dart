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
    var timeData = json['time'];
    Duration timeDuration;

    if (timeData is String && timeData.contains('<')) {
      // Placeholder case - initially set as zero Duration
      timeDuration = Duration.zero;
    } else {
      // Numerical value case
      timeDuration = Duration(seconds: int.tryParse(timeData.toString()) ?? 0);
    }

    return BrewStep(
      order: json['order'] as int,
      description: json['description'] as String,
      time: timeDuration,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert time to appropriate format for JSON
    return {
      'order': order,
      'description': description,
      'time': time.inSeconds,
    };
  }
}
