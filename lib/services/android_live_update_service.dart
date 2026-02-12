import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Service that manages Android 16+ Live Update notifications for the brewing timer.
///
/// Displays brew progress as a promoted ongoing notification with countdown timer.
/// No-ops on non-Android platforms and Android < 16 (API 36).
class AndroidLiveUpdateService {
  static final AndroidLiveUpdateService instance =
      AndroidLiveUpdateService._internal();
  factory AndroidLiveUpdateService() => instance;
  AndroidLiveUpdateService._internal();

  static const _channel = MethodChannel('com.coffee.timer/live_updates');

  bool _isActive = false;
  bool? _supportedCache;

  /// Whether the device supports Live Update notifications.
  Future<bool> get isSupported async {
    if (_supportedCache != null) return _supportedCache!;
    if (kIsWeb || !Platform.isAndroid) {
      _supportedCache = false;
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      _supportedCache = result ?? false;
      return _supportedCache!;
    } catch (e) {
      _supportedCache = false;
      return false;
    }
  }

  /// Start a Live Update notification when brewing begins.
  Future<void> startBrewingActivity({
    required String recipeName,
    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!await isSupported) return;

    final data = _buildData(
      recipeName: recipeName,
      stepDescription: stepDescription,
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepElapsedSeconds: stepElapsedSeconds,
      stepTotalSeconds: stepTotalSeconds,
      isPaused: isPaused,
    );

    try {
      await _channel.invokeMethod('startBrewing', data);
      _isActive = true;
      AppLogger.debug('Android Live Update started');
    } catch (e) {
      AppLogger.error('Failed to start Android Live Update', errorObject: e);
    }
  }

  /// Update the Live Update notification with current brewing state.
  void updateBrewingActivity({
    required String recipeName,
    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
  }) {
    if (!_isActive) return;

    final data = _buildData(
      recipeName: recipeName,
      stepDescription: stepDescription,
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepElapsedSeconds: stepElapsedSeconds,
      stepTotalSeconds: stepTotalSeconds,
      isPaused: isPaused,
    );

    // Fire-and-forget: don't await to avoid blocking the timer callback
    // and prevent queued calls from skipping updates.
    _channel.invokeMethod('updateBrewing', data).catchError((e) {
      AppLogger.error('Failed to update Android Live Update', errorObject: e);
    });
  }

  /// End the Live Update notification.
  Future<void> endBrewingActivity() async {
    if (!_isActive) return;

    _isActive = false;
    try {
      await _channel.invokeMethod('endBrewing');
      AppLogger.debug('Android Live Update ended');
    } catch (e) {
      AppLogger.error('Failed to end Android Live Update', errorObject: e);
    }
  }

  Map<String, dynamic> _buildData({
    required String recipeName,
    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
  }) {
    return {
      'recipeName': recipeName,
      'stepDescription': stepDescription,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
      'stepElapsedSeconds': stepElapsedSeconds,
      'stepTotalSeconds': stepTotalSeconds,
      'isPaused': isPaused ? 1 : 0,
    };
  }
}
