class BrewStep {
  final int order;
  final String description;
  Duration time;

  BrewStep({
    required this.order,
    required this.description,
    required this.time,
  });

  factory BrewStep.fromJson(Map<String, dynamic> json) {
    var timeData = json['time'];
    Duration timeDuration;

    if (timeData is String && timeData.contains('<')) {
      // Since it's a placeholder, let's initially set it as zero Duration
      // but ideally, this should be processed later to replace with actual values
      timeDuration = Duration.zero;
    } else {
      int seconds = int.tryParse(timeData.toString()) ?? 0;
      timeDuration = Duration(seconds: seconds);
    }

    return BrewStep(
      order: json['order'] as int,
      description: json['description'] as String,
      time: timeDuration,
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
