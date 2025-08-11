import 'package:flutter/foundation.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Time windows available in Stats
enum TimePeriod { today, thisWeek, thisMonth, custom }

/// Central controller for the Stats feature: holds the selected time window,
/// custom date range, and the running global brewed total. UI subscribes via ChangeNotifier.
class StatsController extends ChangeNotifier {
  TimePeriod selectedPeriod = TimePeriod.today;
  DateTime? customStartDate;
  DateTime? customEndDate;

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
        return customStartDate ?? DateTime.now();
    }
  }

  DateTime getEndDate() {
    return selectedPeriod == TimePeriod.custom
        ? (customEndDate ?? DateTime.now())
        : DateTime.now();
  }

  void selectPeriod(UserStatProvider provider, TimePeriod p) {
    selectedPeriod = p;
    _recalcIncludesToday(provider);
    notifyListeners();
  }

  void setCustomRange(UserStatProvider provider, DateTime start, DateTime end) {
    customStartDate = start;
    customEndDate = end;
    selectedPeriod = TimePeriod.custom;
    _recalcIncludesToday(provider);
    notifyListeners();
  }

  void _recalcIncludesToday(UserStatProvider provider) {
    final start = getStartDate(provider);
    final end = getEndDate();
    includesToday =
        DateTime.now().isAfter(start) && DateTime.now().isBefore(end);
  }

  // --- Global total helpers ---
  void setInitialTotal(double initial) {
    totalGlobalCoffeeBrewed =
        initial + (includesToday ? _temporaryUpdates : 0.0);
    _temporaryUpdates = 0.0;
    notifyListeners();
  }

  void addToTotalIfInRange(
      UserStatProvider provider, DateTime createdAt, double deltaLiters) {
    if (isDateWithinRange(provider, createdAt)) {
      totalGlobalCoffeeBrewed += deltaLiters;
      notifyListeners();
    }
  }

  bool isDateWithinRange(UserStatProvider provider, DateTime date) {
    final start = getStartDate(provider);
    final end = getEndDate();
    return date.isAfter(start) && date.isBefore(end);
  }

  String labelForPeriod(AppLocalizations l10n, TimePeriod period) {
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
