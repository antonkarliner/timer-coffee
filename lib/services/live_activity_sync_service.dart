import 'dart:async';
import 'dart:math' as math;

import 'package:coffee_timer/services/notification_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveActivitySessionStatus {
  const LiveActivitySessionStatus({
    required this.status,
    required this.isPaused,
    required this.pausedElapsedSeconds,
    required this.currentStep,
    required this.totalSteps,
    required this.stepElapsedSeconds,
    required this.stepTotalSeconds,
    required this.stepDescription,
    required this.recipeName,
    required this.brewStartMs,
    required this.expectedEndMs,
    required this.serverNowMs,
    required this.isFinished,
  });

  final String status;
  final bool isPaused;
  final int? pausedElapsedSeconds;
  final int currentStep;
  final int totalSteps;
  final int stepElapsedSeconds;
  final int stepTotalSeconds;
  final String stepDescription;
  final String recipeName;
  final int brewStartMs;
  final int expectedEndMs;
  final int serverNowMs;
  final bool isFinished;

  static int _asInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool _asBool(Object? value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  factory LiveActivitySessionStatus.fromJson(Map<String, dynamic> json) {
    final pausedElapsed = _asInt(json['paused_elapsed_seconds'], -1);
    return LiveActivitySessionStatus(
      status: (json['status'] as String?)?.trim() ?? 'unknown',
      isPaused: _asBool(json['is_paused'], false),
      pausedElapsedSeconds: pausedElapsed >= 0 ? pausedElapsed : null,
      currentStep: _asInt(json['current_step'], 1),
      totalSteps: _asInt(json['total_steps'], 1),
      stepElapsedSeconds: _asInt(json['step_elapsed_seconds'], 0),
      stepTotalSeconds: _asInt(json['step_total_seconds'], 0),
      stepDescription: (json['step_description'] as String?) ?? '',
      recipeName: (json['recipe_name'] as String?) ?? 'Brewing',
      brewStartMs: _asInt(json['brew_start_ms'], 0),
      expectedEndMs: _asInt(json['expected_end_ms'], 0),
      serverNowMs: _asInt(json['server_now_ms'], 0),
      isFinished: _asBool(json['is_finished'], false),
    );
  }
}

/// Syncs iOS Live Activity sessions/tokens with backend scheduling services.
class LiveActivitySyncService {
  static final LiveActivitySyncService instance =
      LiveActivitySyncService._internal();
  factory LiveActivitySyncService() => instance;
  LiveActivitySyncService._internal();

  static const String _functionName = 'live-activity-api';
  static const Duration _requestTimeout = Duration(seconds: 8);

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<bool> startSession({
    required String brewSessionId,
    required String recipeId,
    required String recipeName,
    required String activityId,
    required String activityPushToken,
    required List<int> stepDurationsSeconds,
    required List<String> stepDescriptions,
    required int brewStartDateMs,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      AppLogger.warning(
          'Skipping live activity session start: user is not authenticated');
      return false;
    }
    if (activityPushToken.isEmpty) {
      AppLogger.warning(
          'Skipping live activity session start: missing activity push token');
      return false;
    }

    final fcmToken = await _resolveFcmToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      AppLogger.warning(
          'Skipping live activity session start: missing FCM token');
      return false;
    }

    return _invokeWithRetry(
      action: 'start',
      payload: {
        'brew_session_id': brewSessionId,
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'activity_id': activityId,
        'activity_push_token': activityPushToken,
        'fcm_token': fcmToken,
        'step_durations_seconds': stepDurationsSeconds,
        'step_descriptions': stepDescriptions,
        'brew_start_ms': brewStartDateMs,
      },
      logLabel: 'start',
    );
  }

  Future<void> pauseSession({
    required String brewSessionId,
    required int elapsedTotalSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _invokeWithRetry(
      action: 'pause',
      payload: {
        'brew_session_id': brewSessionId,
        'elapsed_total_seconds': elapsedTotalSeconds,
      },
      logLabel: 'pause',
    );
  }

  Future<void> resumeSession({
    required String brewSessionId,
    required int elapsedTotalSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _invokeWithRetry(
      action: 'resume',
      payload: {
        'brew_session_id': brewSessionId,
        'elapsed_total_seconds': elapsedTotalSeconds,
      },
      logLabel: 'resume',
    );
  }

  Future<void> refreshToken({
    required String brewSessionId,
    required String activityId,
    required String activityPushToken,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || activityPushToken.isEmpty) return;

    final fcmToken = await _resolveFcmToken();

    await _invokeWithRetry(
      action: 'token',
      payload: {
        'brew_session_id': brewSessionId,
        'activity_id': activityId,
        'activity_push_token': activityPushToken,
        'fcm_token': fcmToken,
      },
      logLabel: 'token_refresh',
    );
  }

  Future<void> endSession({
    required String brewSessionId,
    String reason = 'completed',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _invokeWithRetry(
      action: 'end',
      payload: {
        'brew_session_id': brewSessionId,
        'reason': reason,
      },
      logLabel: 'end',
    );
  }

  Future<LiveActivitySessionStatus?> fetchSessionStatus({
    required String brewSessionId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _invokeWithRetryRaw(
      action: 'status',
      payload: {
        'brew_session_id': brewSessionId,
      },
      logLabel: 'status',
    );

    if (data == null || data.isEmpty) return null;

    try {
      return LiveActivitySessionStatus.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to parse live activity status response',
          errorObject: e);
      return null;
    }
  }

  Future<String?> _resolveFcmToken() async {
    try {
      final fcmProvider = NotificationService.instance.fcm;
      var token = fcmProvider.currentToken;
      if (token != null && token.isNotEmpty) return token;

      await fcmProvider.ensureActiveToken();
      token = fcmProvider.currentToken;
      token ??= await fcmProvider.getToken();

      return token;
    } catch (e) {
      AppLogger.error('Failed to resolve FCM token for live activity sync',
          errorObject: e);
      return null;
    }
  }

  Future<bool> _invokeWithRetry({
    required String action,
    required Map<String, Object?> payload,
    required String logLabel,
  }) async {
    final data = await _invokeWithRetryRaw(
      action: action,
      payload: payload,
      logLabel: logLabel,
    );
    return data != null;
  }

  Future<Map<String, dynamic>?> _invokeWithRetryRaw({
    required String action,
    required Map<String, Object?> payload,
    required String logLabel,
  }) async {
    const maxAttempts = 3;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _supabase.functions.invoke(
          _functionName,
          method: HttpMethod.post,
          body: {
            'action': action,
            ...payload,
          },
        ).timeout(_requestTimeout);

        if (response.status < 200 || response.status >= 300) {
          throw StateError(
              'HTTP ${response.status} from $_functionName [$action]');
        }

        Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else {
          data = <String, dynamic>{};
        }

        final error = data['error'];
        if (error is String && error.isNotEmpty) {
          throw StateError(error);
        }

        return data;
      } catch (e) {
        if (attempt == maxAttempts) {
          AppLogger.error(
              'Live activity sync failed ($logLabel) after $maxAttempts attempts',
              errorObject: e);
          return null;
        }

        final backoffMillis =
            (math.pow(2, attempt - 1).toInt() * 400) + (attempt * 100);
        await Future.delayed(Duration(milliseconds: backoffMillis));
      }
    }

    return null;
  }
}
