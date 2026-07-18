import 'package:flutter/foundation.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Time windows available in Stats
enum TimePeriod { today, thisWeek, thisMonth, custom }

/// Central controller for the Stats feature: holds the selected time window,
/// custom date range, and the running global brewed total. UI subscribes via ChangeNotifier.
class StatsController extends ChangeNotifier {
  StatsController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Set by deep link handler before navigating to stats screen.
  /// StatsScreen reads and clears this on init.
  static TimePeriod? pendingInitialPeriod;

  final DateTime Function() _clock;

  TimePeriod selectedPeriod = TimePeriod.today;
  DateTime? customStartDate;
  DateTime? customEndDate;
  DateTime? calendarMonth;

  double totalGlobalCoffeeBrewed = 0.0;
  double _temporaryUpdates = 0.0;
  bool includesToday = true;

  // --- Period helpers ---
  DateTime getStartDate(UserStatProvider provider) {
    switch (selectedPeriod) {
      case TimePeriod.today:
        return provider.getStartOfToday();
      case TimePeriod.thisWeek:
        return provider.getStartOfWeek();
      case TimePeriod.thisMonth:
        return provider.getStartOfMonth();
      case TimePeriod.custom:
        return customStartDate ?? _now();
    }
  }

  DateTime getEndDate() {
    if (selectedPeriod == TimePeriod.custom &&
        calendarMonth != null &&
        _isCurrentCalendarMonth(calendarMonth!, _now())) {
      return _now();
    }
    return selectedPeriod == TimePeriod.custom
        ? (customEndDate ?? _now())
        : _now();
  }

  /// Applies route query parameters before the legacy pending-period fallback.
  ///
  /// A valid civil range wins over a calendar month and consumes any stale
  /// pending period. Invalid or incomplete inputs preserve the existing
  /// calendar-month and weekly-notification/default paths.
  void initializePeriod(
    UserStatProvider provider, {
    int? initialYear,
    int? initialMonth,
    String? initialStartDate,
    String? initialEndDate,
  }) {
    final initialRange = _parseCivilRange(initialStartDate, initialEndDate);
    if (initialRange != null) {
      pendingInitialPeriod = null;
      setCustomRange(provider, initialRange.start, initialRange.end);
      return;
    }

    if (_isValidCalendarMonth(initialYear, initialMonth)) {
      pendingInitialPeriod = null;
      selectCalendarMonth(provider, initialYear!, initialMonth!);
      return;
    }

    final pendingPeriod = pendingInitialPeriod;
    pendingInitialPeriod = null;
    selectPeriod(provider, pendingPeriod ?? selectedPeriod);
  }

  void selectPeriod(UserStatProvider provider, TimePeriod p) {
    calendarMonth = null;
    selectedPeriod = p;
    _recalcIncludesToday(provider);
    notifyListeners();
  }

  void selectCalendarMonth(UserStatProvider provider, int year, int month) {
    if (!_isValidCalendarMonth(year, month)) return;

    final now = _now();
    final normalizedMonth = DateTime(year, month);
    final isCurrentMonth = _isCurrentCalendarMonth(normalizedMonth, now);

    calendarMonth = normalizedMonth;
    customStartDate = normalizedMonth;
    customEndDate = isCurrentMonth
        ? now
        : DateTime(year, month + 1).subtract(const Duration(microseconds: 1));
    selectedPeriod = TimePeriod.custom;
    _recalcIncludesToday(provider);
    notifyListeners();
  }

  void setCustomRange(UserStatProvider provider, DateTime start, DateTime end) {
    calendarMonth = null;
    customStartDate = start;
    customEndDate = end;
    selectedPeriod = TimePeriod.custom;
    _recalcIncludesToday(provider);
    notifyListeners();
  }

  void _recalcIncludesToday(UserStatProvider provider) {
    final start = getStartDate(provider);
    final end = getEndDate();
    final now = _now();
    includesToday =
        !_isBeforeInclusive(now, start) && !_isAfterInclusive(now, end);
  }

  DateTime _now() => _clock().toLocal();

  bool _isCurrentCalendarMonth(DateTime month, DateTime now) =>
      month.year == now.year && month.month == now.month;

  bool _isValidCalendarMonth(int? year, int? month) =>
      year != null &&
      year >= 1 &&
      year <= 9999 &&
      month != null &&
      month >= DateTime.january &&
      month <= DateTime.december;

  ({DateTime start, DateTime end})? _parseCivilRange(
    String? rawStart,
    String? rawEnd,
  ) {
    final start = _parseCivilDate(rawStart);
    final inclusiveEnd = _parseCivilDate(rawEnd);
    if (start == null || inclusiveEnd == null || inclusiveEnd.isBefore(start)) {
      return null;
    }
    final end = DateTime(
      inclusiveEnd.year,
      inclusiveEnd.month,
      inclusiveEnd.day + 1,
    ).subtract(const Duration(microseconds: 1));
    return (start: start, end: end);
  }

  DateTime? _parseCivilDate(String? raw) {
    if (raw == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return null;
    }
    final parts = raw.split('-').map(int.parse).toList(growable: false);
    final parsed = DateTime(parts[0], parts[1], parts[2]);
    if (parsed.year != parts[0] ||
        parsed.month != parts[1] ||
        parsed.day != parts[2]) {
      return null;
    }
    return parsed;
  }

  bool _isBeforeInclusive(DateTime a, DateTime b) => a.isBefore(b);
  bool _isAfterInclusive(DateTime a, DateTime b) => a.isAfter(b);

  // --- Global total helpers ---
  void setInitialTotal(double initial) {
    totalGlobalCoffeeBrewed =
        initial + (includesToday ? _temporaryUpdates : 0.0);
    _temporaryUpdates = 0.0;
    notifyListeners();
  }

  void addToTotalIfInRange(
    UserStatProvider provider,
    DateTime createdAt,
    double deltaLiters,
  ) {
    if (isDateWithinRange(provider, createdAt)) {
      totalGlobalCoffeeBrewed += deltaLiters;
      notifyListeners();
    }
  }

  bool isDateWithinRange(UserStatProvider provider, DateTime date) {
    final start = getStartDate(provider);
    final end = getEndDate();
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String labelForPeriod(AppLocalizations l10n, TimePeriod period) {
    if (period == TimePeriod.custom && calendarMonth != null) {
      return DateFormat.yMMMM(l10n.localeName).format(calendarMonth!);
    }

    switch (period) {
      case TimePeriod.today:
        return l10n.timePeriodToday;
      case TimePeriod.thisWeek:
        return l10n.timePeriodThisWeek;
      case TimePeriod.thisMonth:
        return l10n.timePeriodThisMonth;
      case TimePeriod.custom:
        return l10n.timePeriodCustom;
    }
  }
}
