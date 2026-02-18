import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:coffee_timer/utils/app_logger.dart';

class LiveActivityPushTokenUpdate {
  const LiveActivityPushTokenUpdate({
    required this.activityId,
    required this.activityToken,
  });

  final String activityId;
  final String activityToken;
}

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
  final StreamController<LiveActivityPushTokenUpdate>
  _pushTokenUpdatesController =
      StreamController<LiveActivityPushTokenUpdate>.broadcast();
  StreamSubscription<ActivityUpdate>? _activityUpdatesSubscription;

  String? _currentActivityId;
  bool _initialized = false;

  String? get currentActivityId => _currentActivityId;
  Stream<LiveActivityPushTokenUpdate> get pushTokenUpdates =>
      _pushTokenUpdatesController.stream;

  /// Initialize the plugin. Call once at app startup.
  Future<void> initialize() async {
    if (kIsWeb || !Platform.isIOS) return;
    if (_initialized) return;

    try {
      await _plugin.init(appGroupId: _appGroupId);
      _initialized = true;
      AppLogger.debug('LiveActivityService initialized');
      _subscribeToActivityUpdates();
    } catch (e) {
      AppLogger.error(
        'Failed to initialize LiveActivityService',
        errorObject: e,
      );
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
  Future<String?> startBrewingActivity({
    required String recipeName,
    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
    required bool removeWhenAppIsKilled,
    List<int>? stepDurationsSeconds,
    List<String>? stepDescriptions,
    int? brewStartDate,
    int? stepStartDateMs,
    int? stepEndDateMs,
    Duration? staleIn,
  }) async {
    if (!_initialized) return null;
    if (!await isSupported) return null;

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
      stepDurationsSeconds: stepDurationsSeconds,
      stepDescriptions: stepDescriptions,
      brewStartDate: brewStartDate,
      stepStartDateMs: stepStartDateMs,
      stepEndDateMs: stepEndDateMs,
    );

    try {
      _currentActivityId = await _plugin.createActivity(
        'brewing',
        data,
        removeWhenAppIsKilled: removeWhenAppIsKilled,
        staleIn: staleIn,
      );
      AppLogger.debug('Live Activity started: $_currentActivityId');

      final activityId = _currentActivityId;
      if (activityId != null) {
        final token = await _plugin.getPushToken(activityId);
        if (token != null && token.isNotEmpty) {
          _pushTokenUpdatesController.add(
            LiveActivityPushTokenUpdate(
              activityId: activityId,
              activityToken: token,
            ),
          );
        }
      }
      return _currentActivityId;
    } catch (e) {
      AppLogger.error('Failed to start Live Activity', errorObject: e);
      return null;
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
    List<int>? stepDurationsSeconds,
    List<String>? stepDescriptions,
    int? brewStartDate,
    int? stepStartDateMs,
    int? stepEndDateMs,
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
      stepDurationsSeconds: stepDurationsSeconds,
      stepDescriptions: stepDescriptions,
      brewStartDate: brewStartDate,
      stepStartDateMs: stepStartDateMs,
      stepEndDateMs: stepEndDateMs,
    );

    try {
      await _plugin.updateActivity(_currentActivityId!, data);
    } catch (e) {
      AppLogger.error('Failed to update Live Activity', errorObject: e);
    }
  }

  /// Recreate the Live Activity with fresh data.
  ///
  /// NOTE: iOS does not allow creating a new activity while app is in
  /// background ("Target is not foreground"). For safety, this method falls
  /// back to update/start semantics instead of ending the current activity.
  Future<void> recreateBrewingActivity({
    required String recipeName,
    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
    bool removeWhenAppIsKilled = false,
    List<int>? stepDurationsSeconds,
    List<String>? stepDescriptions,
    int? brewStartDate,
    int? stepStartDateMs,
    int? stepEndDateMs,
    Duration? staleIn,
  }) async {
    if (!_initialized) return;

    if (_currentActivityId == null) {
      await startBrewingActivity(
        recipeName: recipeName,
        stepDescription: stepDescription,
        currentStep: currentStep,
        totalSteps: totalSteps,
        stepElapsedSeconds: stepElapsedSeconds,
        stepTotalSeconds: stepTotalSeconds,
        isPaused: isPaused,
        removeWhenAppIsKilled: removeWhenAppIsKilled,
        stepDurationsSeconds: stepDurationsSeconds,
        stepDescriptions: stepDescriptions,
        brewStartDate: brewStartDate,
        stepStartDateMs: stepStartDateMs,
        stepEndDateMs: stepEndDateMs,
        staleIn: staleIn,
      );
      return;
    }

    await updateBrewingActivity(
      recipeName: recipeName,
      stepDescription: stepDescription,
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepElapsedSeconds: stepElapsedSeconds,
      stepTotalSeconds: stepTotalSeconds,
      isPaused: isPaused,
      stepDurationsSeconds: stepDurationsSeconds,
      stepDescriptions: stepDescriptions,
      brewStartDate: brewStartDate,
      stepStartDateMs: stepStartDateMs,
      stepEndDateMs: stepEndDateMs,
    );
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

  Future<String?> getPushToken(String activityId) async {
    if (!_initialized || activityId.isEmpty) return null;
    try {
      return await _plugin.getPushToken(activityId);
    } catch (e) {
      AppLogger.error(
        'Failed to get push token for Live Activity',
        errorObject: e,
      );
      return null;
    }
  }

  Future<String?> getCurrentActivityPushToken() async {
    final activityId = _currentActivityId;
    if (activityId == null) return null;
    return getPushToken(activityId);
  }

  Future<void> _endExistingActivity() async {
    if (_currentActivityId != null) {
      try {
        await _plugin.endActivity(_currentActivityId!);
      } catch (_) {}
      _currentActivityId = null;
    }
  }

  void _subscribeToActivityUpdates() {
    _activityUpdatesSubscription?.cancel();
    _activityUpdatesSubscription = _plugin.activityUpdateStream.listen(
      (event) {
        event.map(
          active: (activeEvent) {
            if (activeEvent.activityId != _currentActivityId) return;
            _pushTokenUpdatesController.add(
              LiveActivityPushTokenUpdate(
                activityId: activeEvent.activityId,
                activityToken: activeEvent.activityToken,
              ),
            );
          },
          ended: (endedEvent) {
            if (endedEvent.activityId == _currentActivityId) {
              _currentActivityId = null;
            }
          },
          stale: (_) {},
          unknown: (_) {},
        );
      },
      onError: (Object e) {
        AppLogger.error('Live Activity update stream error', errorObject: e);
      },
    );
  }

  Map<String, dynamic> _buildActivityData({
    required String recipeName,
    required String stepDescription,
    required int currentStep,
    required int totalSteps,
    required int stepElapsedSeconds,
    required int stepTotalSeconds,
    required bool isPaused,
    List<int>? stepDurationsSeconds,
    List<String>? stepDescriptions,
    int? brewStartDate,
    int? stepStartDateMs,
    int? stepEndDateMs,
  }) {
    final now = DateTime.now();
    final fallbackStepStartDate = now.subtract(
      Duration(seconds: stepElapsedSeconds),
    );
    final fallbackStepEndDate = fallbackStepStartDate.add(
      Duration(seconds: stepTotalSeconds),
    );
    final resolvedStepStartDateMs =
        stepStartDateMs ?? fallbackStepStartDate.millisecondsSinceEpoch;
    var resolvedStepEndDateMs =
        stepEndDateMs ?? fallbackStepEndDate.millisecondsSinceEpoch;
    if (resolvedStepEndDateMs < resolvedStepStartDateMs) {
      resolvedStepEndDateMs =
          resolvedStepStartDateMs +
          ((stepTotalSeconds < 0 ? 0 : stepTotalSeconds) * 1000);
    }

    final data = {
      'recipeName': recipeName,
      'stepDescription': stepDescription,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
      'stepElapsedSeconds': stepElapsedSeconds,
      'stepTotalSeconds': stepTotalSeconds,
      'isPaused': isPaused ? 1 : 0,
      'stepStartDate': resolvedStepStartDateMs,
      'stepEndDate': resolvedStepEndDateMs,
    };

    if (stepDurationsSeconds != null) {
      data['stepDurationsSeconds'] = stepDurationsSeconds;
    }
    if (stepDescriptions != null) {
      data['stepDescriptions'] = stepDescriptions;
    }
    if (brewStartDate != null) {
      data['brewStartDate'] = brewStartDate;
    }

    return data;
  }

  void dispose() {
    _activityUpdatesSubscription?.cancel();
    _pushTokenUpdatesController.close();
    _plugin.dispose();
  }
}
