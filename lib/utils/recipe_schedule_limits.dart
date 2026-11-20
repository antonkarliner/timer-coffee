/// Matches the maximum active schedule accepted by the Live Activity backend.
/// The app also carries a zero-duration preparation step in some recipes.
const maxRecipeDurationSeconds = 7 * 24 * 60 * 60;

void validateRecipeSchedule(Iterable<int> durations) {
  var total = 0;
  var stepCount = 0;
  var timedSteps = 0;
  for (final seconds in durations) {
    stepCount++;
    if (seconds > 0) timedSteps++;
    if (stepCount > 129 ||
        timedSteps > 128 ||
        seconds < 0 ||
        seconds > maxRecipeDurationSeconds - total) {
      throw const FormatException('Invalid recipe duration');
    }
    total += seconds;
  }
}

void validateImportedRecipeSchedule(Map<String, dynamic> data) {
  final byLocale = <String, List<int>>{};
  for (final row in data['user_steps'] as List? ?? const []) {
    final seconds = int.tryParse(row['time'].toString());
    if (seconds == null) throw const FormatException('Invalid step duration');
    (byLocale[row['locale'] as String? ?? 'en'] ??= []).add(seconds);
  }
  for (final durations in byLocale.values) {
    validateRecipeSchedule(durations);
  }
  final total = data['brew_time'];
  if (total is int) validateRecipeSchedule([total]);
}
