import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Service that manages iOS Live Activities for the brewing timer.
///
/// Displays brew progress on the Lock Screen and Dynamic Island.
/// No-ops on non-iOS platforms and iOS < 16.1.
class LiveActivityService {
  static final LiveActivityService instance = LiveActivityService._internal();
  factory LiveActivityService() => instance;
  LiveActivityService._internal();

  static const String _appGroupId = 'group.timer.coffee';

  final LiveActivities _plugin = LiveActivities();
  String? _currentActivityId;
  bool _initialized = false;

  /// Initialize the plugin. Call once at app startup.
  Future<void> initialize() async {
    if (kIsWeb || !Platform.isIOS) return;
    if (_initialized) return;

    try {
      await _plugin.init(appGroupId: _appGroupId);
      _initialized = true;
      AppLogger.debug('LiveActivityService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize LiveActivityService',
          errorObject: e);
    }
  }

  /// Whether the device supports Live Activities.
  Future<bool> get isSupported async {
    if (!_initialized) return false;
    try {
      final supported = await _plugin.areActivitiesSupported();
      if (!supported) return false;
      return await _plugin.areActivitiesEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Start a Live Activity when brewing begins.
  Future<void> startBrewingActivity({
    required String recipeName,

    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
  }) async {
    if (!_initialized) return;
    if (!await isSupported) return;

    // End any existing activity first
    await _endExistingActivity();

    final data = _buildActivityData(
      recipeName: recipeName,

      stepDescription: stepDescription,
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepElapsedSeconds: stepElapsedSeconds,
      stepTotalSeconds: stepTotalSeconds,
      isPaused: isPaused,
    );

    try {
      _currentActivityId = await _plugin.createActivity(
        'brewing',
        data,
        removeWhenAppIsKilled: true,
      );
      AppLogger.debug('Live Activity started: $_currentActivityId');
    } catch (e) {
      AppLogger.error('Failed to start Live Activity', errorObject: e);
    }
  }

  /// Update the Live Activity with current brewing state.
  Future<void> updateBrewingActivity({
    required String recipeName,

    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
  }) async {
    if (_currentActivityId == null) return;

    final data = _buildActivityData(
      recipeName: recipeName,

      stepDescription: stepDescription,
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepElapsedSeconds: stepElapsedSeconds,
      stepTotalSeconds: stepTotalSeconds,
      isPaused: isPaused,
    );

    try {
      await _plugin.updateActivity(_currentActivityId!, data);
    } catch (e) {
      AppLogger.error('Failed to update Live Activity', errorObject: e);
    }
  }

  /// End the Live Activity (call when brewing completes or is cancelled).
  Future<void> endBrewingActivity() async {
    if (_currentActivityId == null) return;

    try {
      await _plugin.endActivity(_currentActivityId!);
      AppLogger.debug('Live Activity ended: $_currentActivityId');
    } catch (e) {
      AppLogger.error('Failed to end Live Activity', errorObject: e);
    }
    _currentActivityId = null;
  }

  Future<void> _endExistingActivity() async {
    if (_currentActivityId != null) {
      try {
        await _plugin.endActivity(_currentActivityId!);
      } catch (_) {}
      _currentActivityId = null;
    }
  }

  Map<String, dynamic> _buildActivityData({
    required String recipeName,

    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
  }) {
    final now = DateTime.now();
    final stepRemainingSeconds = stepTotalSeconds - stepElapsedSeconds;
    final stepEndDate = now.add(Duration(seconds: stepRemainingSeconds));
    final stepStartDate =
        now.subtract(Duration(seconds: stepElapsedSeconds));

    return {
      'recipeName': recipeName,
      'stepDescription': stepDescription,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
      'stepElapsedSeconds': stepElapsedSeconds,
      'stepTotalSeconds': stepTotalSeconds,
      'isPaused': isPaused ? 1 : 0,
      'stepStartDate': stepStartDate.millisecondsSinceEpoch,
      'stepEndDate': stepEndDate.millisecondsSinceEpoch,
    };
  }

  void dispose() {
    _plugin.dispose();
  }
}
