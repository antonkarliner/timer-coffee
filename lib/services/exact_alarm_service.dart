import 'dart:io';

import 'package:flutter/services.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Helper to manage Android exact alarm permission flow (Android 12+).
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

  /// Opens the system prompt/settings to request exact alarm permission.
  /// Returns true if granted immediately; otherwise false (caller should re-check later).
  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('requestExactAlarmPermission') ??
          false;
    } catch (e) {
      AppLogger.error('Failed to request exact alarm permission',
          errorObject: e);
      return false;
    }
  }

  /// Ensures permission, requesting it if missing. Returns final status.
  static Future<bool> ensureExactAlarmPermission() async {
    final hasPermission = await canScheduleExactAlarms();
    if (hasPermission) return true;
    return await requestExactAlarmPermission();
  }
}
