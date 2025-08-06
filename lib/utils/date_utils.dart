import 'package:intl/intl.dart';

/// Utility class for date formatting operations.
///
/// Provides centralized date formatting methods to ensure consistency
/// across the application and reduce code duplication.
class DateUtils {
  /// Private constructor to prevent instantiation.
  DateUtils._();

  /// Formats a DateTime using the localized medium date format (yMMMd).
  ///
  /// Returns a string representation of the date in the format "Jan 1, 2024".
  ///
  /// Example:
  /// ```dart
  /// final formattedDate = DateUtils.formatMediumDate(DateTime.now());
  /// // Returns: "Aug 4, 2025"
  /// ```
  ///
  /// [date] The DateTime to format.
  /// Returns the formatted date string.
  static String formatMediumDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Formats a DateTime using the localized medium date format (yMMMd).
  /// Returns null if the input date is null.
  ///
  /// This is a null-safe version of [formatMediumDate] for optional dates.
  ///
  /// Example:
  /// ```dart
  /// final formattedDate = DateUtils.formatMediumDateSafe(bean.roastDate);
  /// // Returns: "Aug 4, 2025" or null if roastDate is null
  /// ```
  ///
  /// [date] The DateTime to format, can be null.
  /// Returns the formatted date string or null if input is null.
  static String? formatMediumDateSafe(DateTime? date) {
    return date != null ? DateFormat.yMMMd().format(date) : null;
  }
}
