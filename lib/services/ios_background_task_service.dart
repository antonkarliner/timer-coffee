import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages iOS background task to keep the Flutter engine alive while
/// a coffee brew is in progress. This prevents iOS from suspending the
/// process, allowing step-transition `activity.update()` calls to reach
/// the Lock Screen Live Activity.
///
/// Uses `UIApplication.beginBackgroundTask(withName:)` via a platform
/// channel. iOS typically grants ~30 s of execution time (up to ~180 s
/// under favourable conditions). For the average recipe (60-120 s) this
/// is sufficient to cover the entire brew.
class IosBackgroundTaskService {
  IosBackgroundTaskService._();
  static final IosBackgroundTaskService instance =
      IosBackgroundTaskService._();

  static const MethodChannel _channel =
      MethodChannel('com.coffee.timer/background_task');

  bool _isRunning = false;

  /// Whether a background task is currently active.
  bool get isRunning => _isRunning;

  /// Request iOS to keep the Flutter process alive in the background.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> startBrewingTask() async {
    if (_isRunning) return;
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<bool>('startBrewingBackgroundTask');
      _isRunning = true;
    } on PlatformException catch (e) {
      debugPrint('[IosBackgroundTask] start failed: $e');
    }
  }

  /// Tell iOS we no longer need background execution time.
  /// Safe to call even when no task is active.
  Future<void> stopBrewingTask() async {
    if (!_isRunning) return;
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<bool>('stopBrewingBackgroundTask');
    } on PlatformException catch (e) {
      debugPrint('[IosBackgroundTask] stop failed: $e');
    } finally {
      _isRunning = false;
    }
  }
}
