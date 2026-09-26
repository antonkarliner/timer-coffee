import 'package:coffee_timer/services/review_prompt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstSeenKey = 'advanced_in_app_review_install_date';
const _lastAttemptKey = 'advanced_in_app_remind_interval';
const _legacyLaunchCountKey = 'advanced_in_app_review_launch_times';
const _brewCountKey = 'review_prompt_brew_count';

class FakeReviewRequester implements ReviewRequester {
  FakeReviewRequester({this.available = true, this.throwOnRequest = false});

  bool available;
  bool throwOnRequest;
  int isAvailableCalls = 0;
  int requestReviewCalls = 0;

  @override
  Future<bool> isAvailable() async {
    isAvailableCalls += 1;
    return available;
  }

  @override
  Future<void> requestReview() async {
    requestReviewCalls += 1;
    if (throwOnRequest) throw StateError('request failed');
  }
}

void main() {
  late DateTime clock;
  late FakeReviewRequester requester;

  ReviewPromptService buildService({
    Duration delay = Duration.zero,
    bool isWeb = false,
  }) => ReviewPromptService(
    requester: requester,
    now: () => clock,
    isWeb: isWeb,
    delay: delay,
  );

  setUp(() {
    ReviewPromptService.resetInFlightForTest();
    clock = DateTime.utc(2026, 1, 10, 12);
    requester = FakeReviewRequester();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'first call records first seen and brew count without requesting',
    () async {
      final outcome = await buildService().onFinishScreenShown(
        stillOnFinishScreen: () => true,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(outcome, ReviewPromptOutcome.notDue);
      expect(prefs.getInt(_firstSeenKey), clock.millisecondsSinceEpoch);
      expect(prefs.getInt(_brewCountKey), 1);
      expect(requester.isAvailableCalls, 0);
      expect(requester.requestReviewCalls, 0);
    },
  );

  test('not-due state does not consult allowRequest', () async {
    var allowRequestCalls = 0;

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
      allowRequest: () async {
        allowRequestCalls += 1;
        return true;
      },
    );

    expect(outcome, ReviewPromptOutcome.notDue);
    expect(allowRequestCalls, 0);
  });

  test('second brew on the same day remains behind the age gate', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock.millisecondsSinceEpoch,
      _brewCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );

    expect(outcome, ReviewPromptOutcome.notDue);
    expect(requester.isAvailableCalls, 0);
  });

  test(
    'second brew three days after first requests and writes attempt time',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        _firstSeenKey: clock
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
        _brewCountKey: 1,
      });

      final outcome = await buildService().onFinishScreenShown(
        stillOnFinishScreen: () => true,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(outcome, ReviewPromptOutcome.requested);
      expect(requester.requestReviewCalls, 1);
      expect(prefs.getInt(_lastAttemptKey), clock.millisecondsSinceEpoch);
    },
  );

  test('six-day cooldown is not due and exactly seven days is due', () async {
    final firstSeen = clock
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: firstSeen,
      _lastAttemptKey: clock
          .subtract(const Duration(days: 6))
          .millisecondsSinceEpoch,
      _brewCountKey: 2,
    });

    final earlyOutcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );
    expect(earlyOutcome, ReviewPromptOutcome.notDue);

    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: firstSeen,
      _lastAttemptKey: clock
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch,
      _brewCountKey: 2,
    });
    final dueOutcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );

    expect(dueOutcome, ReviewPromptOutcome.requested);
    expect(requester.requestReviewCalls, 1);
  });

  test('leaving finish screen avoids requester and attempt write', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _brewCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => false,
    );
    final prefs = await SharedPreferences.getInstance();

    expect(outcome, ReviewPromptOutcome.leftFinishScreen);
    expect(requester.isAvailableCalls, 0);
    expect(requester.requestReviewCalls, 0);
    expect(prefs.containsKey(_lastAttemptKey), isFalse);
  });

  test('leaving finish screen does not consult allowRequest', () async {
    var allowRequestCalls = 0;
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _brewCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => false,
      allowRequest: () async {
        allowRequestCalls += 1;
        return true;
      },
    );

    expect(outcome, ReviewPromptOutcome.leftFinishScreen);
    expect(allowRequestCalls, 0);
  });

  test('budget denial avoids requester and attempt write', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _brewCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
      allowRequest: () async => false,
    );
    final prefs = await SharedPreferences.getInstance();

    expect(outcome, ReviewPromptOutcome.budgetDenied);
    expect(requester.isAvailableCalls, 0);
    expect(requester.requestReviewCalls, 0);
    expect(prefs.containsKey(_lastAttemptKey), isFalse);
  });

  test('allowed request consults allowRequest exactly once', () async {
    var allowRequestCalls = 0;
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _brewCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
      allowRequest: () async {
        allowRequestCalls += 1;
        return true;
      },
    );

    expect(outcome, ReviewPromptOutcome.requested);
    expect(allowRequestCalls, 1);
  });

  test(
    'unavailable requester writes attempt time without requesting',
    () async {
      requester.available = false;
      SharedPreferences.setMockInitialValues(<String, Object>{
        _firstSeenKey: clock
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch,
        _brewCountKey: 1,
      });

      final outcome = await buildService().onFinishScreenShown(
        stillOnFinishScreen: () => true,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(outcome, ReviewPromptOutcome.unavailable);
      expect(requester.requestReviewCalls, 0);
      expect(prefs.getInt(_lastAttemptKey), clock.millisecondsSinceEpoch);
    },
  );

  test('requester exception is contained and writes attempt time', () async {
    requester.throwOnRequest = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _brewCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );
    final prefs = await SharedPreferences.getInstance();

    expect(outcome, ReviewPromptOutcome.unavailable);
    expect(prefs.getInt(_lastAttemptKey), clock.millisecondsSinceEpoch);
  });

  test('legacy inflated launch count is capped before incrementing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _lastAttemptKey: clock
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch,
      _legacyLaunchCountKey: 57,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );
    final prefs = await SharedPreferences.getInstance();

    expect(outcome, ReviewPromptOutcome.notDue);
    expect(prefs.getInt(_brewCountKey), 3);
  });

  test('legacy launch count one seeds the second brew', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _legacyLaunchCountKey: 1,
    });

    final outcome = await buildService().onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );
    final prefs = await SharedPreferences.getInstance();

    expect(outcome, ReviewPromptOutcome.requested);
    expect(prefs.getInt(_brewCountKey), 2);
  });

  test('concurrent calls allow one request and one brew increment', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _firstSeenKey: clock
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      _brewCountKey: 1,
    });
    final serviceA = buildService(delay: const Duration(milliseconds: 10));
    final serviceB = buildService(delay: const Duration(milliseconds: 10));

    final outcomes = await Future.wait(<Future<ReviewPromptOutcome>>[
      serviceA.onFinishScreenShown(stillOnFinishScreen: () => true),
      serviceB.onFinishScreenShown(stillOnFinishScreen: () => true),
    ]);
    final prefs = await SharedPreferences.getInstance();

    expect(outcomes, contains(ReviewPromptOutcome.requested));
    expect(outcomes, contains(ReviewPromptOutcome.alreadyInFlight));
    expect(requester.requestReviewCalls, 1);
    expect(prefs.getInt(_brewCountKey), 2);
  });

  test('web skips without touching preferences', () async {
    final service = buildService(isWeb: true);

    final outcome = await service.onFinishScreenShown(
      stillOnFinishScreen: () => true,
    );
    final prefs = await SharedPreferences.getInstance();

    expect(outcome, ReviewPromptOutcome.skippedWeb);
    expect(prefs.getKeys(), isEmpty);
    expect(service.lastBrewCount, isNull);
  });
}
