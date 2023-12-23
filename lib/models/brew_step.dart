class BrewStep {
  final int order;
  final String description;
  Duration time;
  String? timePlaceholder;

  BrewStep({
    required this.order,
    required this.description,
    required this.time,
    this.timePlaceholder,
  });

  factory BrewStep.fromJson(Map<String, dynamic> json) {
    var timeData = json['time'];
    Duration timeDuration;
    String? timePlaceholder;

    if (timeData is String && timeData.contains('<')) {
      // Since it's a placeholder, let's initially set it as zero Duration
      // but ideally, this should be processed later to replace with actual values
      timeDuration = Duration.zero;
      timePlaceholder = timeData;
    } else {
      int seconds = int.tryParse(timeData.toString()) ?? 0;
      timeDuration = Duration(seconds: seconds);
    }

    return BrewStep(
      order: json['order'] as int,
      description: json['description'] as String,
      time: timeDuration,
      timePlaceholder: timePlaceholder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'description': description,
      'time': time.inSeconds,
    };
  }
}
