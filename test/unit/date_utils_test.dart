import 'package:coffee_timer/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

// NOTE: `DateUtils` below refers to the app utility from
// package:coffee_timer/utils/date_utils.dart, not Flutter material's
// DateUtils. Only date_utils.dart is imported (material is never brought
// into scope), so the reference compiles unambiguously.

void main() {
  setUp(() {
    // DateFormat.yMMMd() without an explicit locale resolves against
    // Intl.defaultLocale. Pin it to en_US so the expectations below are
    // deterministic regardless of the ambient test-runner locale.
    Intl.defaultLocale = 'en_US';
  });

  tearDown(() {
    // Restore ambient state for any tests that run after this suite.
    Intl.defaultLocale = null;
  });

  group('DateUtils.formatMediumDate', () {
    test('formats a date using the localized yMMMd medium format', () {
      final date = DateTime(2024, 1, 5);
      expect(
        DateUtils.formatMediumDate(date),
        DateFormat.yMMMd().format(date),
      );
    });

    test('renders the pinned en_US medium pattern "MMM d, y"', () {
      expect(DateUtils.formatMediumDate(DateTime(2024, 1, 5)), 'Jan 5, 2024');
      expect(DateUtils.formatMediumDate(DateTime(2025, 12, 31)), 'Dec 31, 2025');
      expect(DateUtils.formatMediumDate(DateTime(1999, 7, 4)), 'Jul 4, 1999');
    });

    test('handles single- and double-digit days without extra padding', () {
      expect(DateUtils.formatMediumDate(DateTime(2024, 8, 1)), 'Aug 1, 2024');
      expect(DateUtils.formatMediumDate(DateTime(2024, 8, 22)), 'Aug 22, 2024');
    });

    test('keeps month, day, and year for dates far from the present', () {
      final early = DateTime(1900, 3, 15);
      final late = DateTime(2100, 11, 30);
      expect(
        DateUtils.formatMediumDate(early),
        DateFormat.yMMMd().format(early),
      );
      expect(
        DateUtils.formatMediumDate(late),
        DateFormat.yMMMd().format(late),
      );
    });
  });

  group('DateUtils.formatMediumDateSafe', () {
    test('formats a non-null date identically to formatMediumDate', () {
      final date = DateTime(2025, 8, 4);
      expect(
        DateUtils.formatMediumDateSafe(date),
        DateUtils.formatMediumDate(date),
      );
      expect(DateUtils.formatMediumDateSafe(date), 'Aug 4, 2025');
    });

    test('returns null when the date is null', () {
      expect(DateUtils.formatMediumDateSafe(null), isNull);
    });
  });
}
