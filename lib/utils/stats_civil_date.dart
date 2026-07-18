/// Formats [date] as `YYYY-MM-DD` using its own civil date components.
///
/// This is intended for backend parameters whose PostgreSQL type is `date`.
String formatStatsCivilDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
