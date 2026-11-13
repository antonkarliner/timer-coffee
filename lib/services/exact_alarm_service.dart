import 'dart:io';

import 'package:flutter/services.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Reports whether exact alarms are allowed; the app never requests permission.
/// On other platforms it returns granted to keep call sites simple.
class ExactAlarmService {
  static const _channel = MethodChannel('com.coffee.timer/exact_alarm');

  /// Returns whether we currently can schedule exact alarms.
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ??
          false;
    } catch (e) {
      AppLogger.error('Failed to check exact alarm permission', errorObject: e);
      return false;
    }
  }
}
