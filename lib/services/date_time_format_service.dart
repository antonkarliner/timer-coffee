import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DateStyle { auto, dmy, mdy, ymd }

enum TimeStyle { auto, h12, h24 }

class DateTimeFormatService extends ChangeNotifier {
  static const _kDateStyleKey = 'datetime_date_style';
  static const _kTimeStyleKey = 'datetime_time_style';

  DateStyle _dateStyle = DateStyle.auto;
  TimeStyle _timeStyle = TimeStyle.auto;

  DateStyle get dateStyle => _dateStyle;
  TimeStyle get timeStyle => _timeStyle;

  DateTimeFormatService();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dateIndex = prefs.getInt(_kDateStyleKey);
    final timeIndex = prefs.getInt(_kTimeStyleKey);
    if (dateIndex != null && dateIndex < DateStyle.values.length) {
      _dateStyle = DateStyle.values[dateIndex];
    }
    if (timeIndex != null && timeIndex < TimeStyle.values.length) {
      _timeStyle = TimeStyle.values[timeIndex];
    }
    notifyListeners();
  }

  /// Returns the date format pattern to use.
  /// When style is [DateStyle.auto], falls back to [localeDefault].
  String datePattern(String localeDefault) {
    switch (_dateStyle) {
      case DateStyle.auto:
        return localeDefault;
      case DateStyle.dmy:
        return 'dd/MM/yyyy';
      case DateStyle.mdy:
        return 'MM/dd/yyyy';
      case DateStyle.ymd:
        return 'yyyy-MM-dd';
    }
  }

  /// Returns whether to use 24-hour format.
  /// When style is [TimeStyle.auto], falls back to [deviceDefault].
  bool use24Hour(bool deviceDefault) {
    switch (_timeStyle) {
      case TimeStyle.auto:
        return deviceDefault;
      case TimeStyle.h12:
        return false;
      case TimeStyle.h24:
        return true;
    }
  }

  Future<void> setDateStyle(DateStyle style) async {
    if (_dateStyle == style) return;
    _dateStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDateStyleKey, style.index);
  }

  Future<void> setTimeStyle(TimeStyle style) async {
    if (_timeStyle == style) return;
    _timeStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimeStyleKey, style.index);
  }
}
