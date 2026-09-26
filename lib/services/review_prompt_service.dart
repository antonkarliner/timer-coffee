import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coffee_timer/utils/app_logger.dart';

/// Ask id used with EngagementSurface.nativeReviewPrompt in the engagement budget.
const String kNativeReviewAskId = 'store_review';

abstract class ReviewRequester {
  Future<bool> isAvailable();

  Future<void> requestReview();
}

class InAppReviewRequester implements ReviewRequester {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

enum ReviewPromptOutcome {
  skippedWeb,
  alreadyInFlight,
  notDue,
  leftFinishScreen,
  budgetDenied,
  unavailable,
  requested,
}

/// Keeps review attempts tied to the finish screen that earned them.
class ReviewPromptService {
  ReviewPromptService({
    ReviewRequester? requester,
    DateTime Function()? now,
    bool? isWeb,
    Duration delay = const Duration(seconds: 4),
    Future<SharedPreferences> Function()? prefs,
  }) : _requester = requester ?? InAppReviewRequester(),
       _now = now ?? DateTime.now,
       _isWeb = isWeb ?? kIsWeb,
       _delay = delay,
       _prefs = prefs ?? SharedPreferences.getInstance;

  static const int minBrews = 2;
  static const int minDaysSinceFirstBrew = 2;
  static const int minDaysBetweenAttempts = 7;

  // Keep the old plugin names so existing users retain their first-seen and
  // cooldown history.
  static const _firstSeenKey = 'advanced_in_app_review_install_date';
  static const _lastAttemptKey = 'advanced_in_app_remind_interval';
  static const _legacyLaunchCountKey = 'advanced_in_app_review_launch_times';
  static const _brewCountKey = 'review_prompt_brew_count';

  static const _millisecondsPerDay = 24 * 60 * 60 * 1000;
  static bool _inFlight = false;

  final ReviewRequester _requester;
  final DateTime Function() _now;
  final bool _isWeb;
  final Duration _delay;
  final Future<SharedPreferences> Function() _prefs;

  int? _lastBrewCount;

  /// Supports analytics without making preference storage part of the caller.
  int? get lastBrewCount => _lastBrewCount;

  @visibleForTesting
  static void resetInFlightForTest() {
    _inFlight = false;
  }

  /// Counts a completed brew and, when due, asks the OS for a review after
  /// [_delay]. No lifecycle observer: the old plugin re-ran this on every app
  /// resume, so the sheet could land over the brewing timer. If the user has
  /// left the finish screen by the time the delay ends, the attempt is dropped
  /// without consuming the cooldown window. [allowRequest] can likewise deny
  /// the ask without consuming the cooldown or contacting the requester.
  Future<ReviewPromptOutcome> onFinishScreenShown({
    required bool Function() stillOnFinishScreen,
    Future<bool> Function()? allowRequest,
  }) async {
    if (_isWeb) return ReviewPromptOutcome.skippedWeb;
    if (_inFlight) return ReviewPromptOutcome.alreadyInFlight;

    _inFlight = true;
    try {
      final preferences = await _prefs();
      final gateTime = _now().millisecondsSinceEpoch;

      var firstSeen = preferences.getInt(_firstSeenKey);
      if (firstSeen == null) {
        firstSeen = gateTime;
        await preferences.setInt(_firstSeenKey, firstSeen);
      }

      var brewCount = preferences.getInt(_brewCountKey);
      if (brewCount == null) {
        final legacyCount = preferences.getInt(_legacyLaunchCountKey) ?? 0;
        brewCount = legacyCount.clamp(0, minBrews);
      }
      brewCount += 1;
      _lastBrewCount = brewCount;
      await preferences.setInt(_brewCountKey, brewCount);

      final lastAttempt = preferences.getInt(_lastAttemptKey);
      final oldEnough =
          gateTime - firstSeen >= minDaysSinceFirstBrew * _millisecondsPerDay;
      final cooldownElapsed =
          lastAttempt == null ||
          gateTime - lastAttempt >=
              minDaysBetweenAttempts * _millisecondsPerDay;
      if (brewCount < minBrews || !oldEnough || !cooldownElapsed) {
        return ReviewPromptOutcome.notDue;
      }

      await Future<void>.delayed(_delay);
      if (!stillOnFinishScreen()) {
        return ReviewPromptOutcome.leftFinishScreen;
      }
      if (allowRequest != null && !await allowRequest()) {
        return ReviewPromptOutcome.budgetDenied;
      }

      try {
        if (!await _requester.isAvailable()) {
          await _writeAttemptTime(preferences);
          return ReviewPromptOutcome.unavailable;
        }
        await _requester.requestReview();
      } catch (error, stackTrace) {
        AppLogger.error(
          'Failed to request an in-app review',
          errorObject: error,
          stackTrace: stackTrace,
        );
        await _writeAttemptTime(preferences);
        return ReviewPromptOutcome.unavailable;
      }

      await _writeAttemptTime(preferences);
      return ReviewPromptOutcome.requested;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _writeAttemptTime(SharedPreferences preferences) =>
      preferences.setInt(_lastAttemptKey, _now().millisecondsSinceEpoch);
}
