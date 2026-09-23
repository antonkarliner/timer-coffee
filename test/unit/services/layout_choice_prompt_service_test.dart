import 'package:coffee_timer/services/layout_choice_prompt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late LayoutChoicePromptService service;

  // Sets the mock store first, then grabs an instance sharing it, so the
  // service's reads/writes and the test's assertions see the same store.
  Future<void> reinit({
    bool seen = false,
    bool dismissed = false,
    bool finishCardShown = false,
    int finishesSinceDismissal = 0,
  }) async {
    SharedPreferences.setMockInitialValues({
      'layout_picker_seen': seen,
      'layout_picker_dismissed': dismissed,
      'layout_finish_card_shown': finishCardShown,
      'layout_finishes_since_dismissal': finishesSinceDismissal,
    });
    prefs = await SharedPreferences.getInstance();
    service = LayoutChoicePromptService(prefs);
  }

  LayoutChoiceTrigger? resolve({
    bool isWeb = false,
    bool firstBrewDone = true,
    String? arm,
    bool pourEnabled = false,
  }) => service.resolvePickerTrigger(
    isWeb: isWeb,
    firstBrewDone: firstBrewDone,
    arm: arm,
    pourEnabled: pourEnabled,
  );

  group('resolvePickerTrigger order', () {
    test('web never shows the picker', () async {
      await reinit();
      expect(resolve(isWeb: true), isNull);
      // Even when everything else would qualify.
      expect(resolve(isWeb: true, arm: 'pour'), isNull);
    });

    test('a seen picker suppresses every other gate', () async {
      await reinit(seen: true);
      expect(resolve(), isNull);
      expect(resolve(arm: 'pour'), isNull);
      expect(resolve(arm: 'pour', pourEnabled: true), isNull);
    });

    test('never interrupts an install’s first brew', () async {
      await reinit();
      expect(resolve(firstBrewDone: false), isNull);
      // Even a pour arm must not turn the first brew into a picker moment.
      expect(resolve(firstBrewDone: false, arm: 'pour'), isNull);
    });

    test(
      'an assigned arm beats pourEnabled: arm + pour on → secondBrew',
      () async {
        await reinit();
        expect(
          resolve(arm: 'pour', pourEnabled: true),
          LayoutChoiceTrigger.secondBrew,
        );
      },
    );

    test('any assigned arm routes to secondBrew', () async {
      await reinit();
      expect(resolve(arm: 'classic'), LayoutChoiceTrigger.secondBrew);
      expect(resolve(arm: 'pour'), LayoutChoiceTrigger.secondBrew);
    });

    test(
      'already on immersive with no arm → null, and is the mark-seen case',
      () async {
        await reinit();
        expect(resolve(pourEnabled: true), isNull);

        // The contract: the caller must mark the picker seen here, or a later
        // brew that IS eligible would be interrupted about a choice already
        // made from the gear sheet.
        expect(service.pickerSeen, isFalse);
        await service.markSeenIfAlreadyOnPour(
          isWeb: false,
          firstBrewDone: true,
        );
        expect(service.pickerSeen, isTrue);
        expect(prefs.getBool('layout_picker_seen'), isTrue);
      },
    );

    test('an eligible existing user gets existingUser', () async {
      await reinit();
      expect(resolve(), LayoutChoiceTrigger.existingUser);
    });
  });

  group('markSeenIfAlreadyOnPour gates', () {
    test('does nothing on web', () async {
      await reinit();
      await service.markSeenIfAlreadyOnPour(isWeb: true, firstBrewDone: true);
      expect(service.pickerSeen, isFalse);
    });

    test('does nothing before the first brew is done', () async {
      await reinit();
      await service.markSeenIfAlreadyOnPour(isWeb: false, firstBrewDone: false);
      expect(service.pickerSeen, isFalse);
    });

    test('is a no-op when already seen', () async {
      await reinit(seen: true);
      await service.markSeenIfAlreadyOnPour(isWeb: false, firstBrewDone: true);
      expect(service.pickerSeen, isTrue);
    });
  });

  group('finishCardEligible (plan 067 Phase 4)', () {
    // Convenience defaults for the finish-card gates.
    bool eligible({bool isWeb = false, bool pourEnabled = false}) =>
        service.finishCardEligible(isWeb: isWeb, pourEnabled: pourEnabled);

    test(
      'first finish after dismissal is skipped; second is eligible',
      () async {
        await reinit(dismissed: true);
        await service.recordFinishForLayoutTry();
        expect(service.finishesSinceDismissal, 1);
        expect(eligible(), isFalse);

        await service.recordFinishForLayoutTry();
        expect(service.finishesSinceDismissal, 2);
        expect(eligible(), isTrue);
      },
    );

    test('web never gets the card', () async {
      await reinit(
        dismissed: true,
        finishesSinceDismissal:
            LayoutChoicePromptService.kFinishesBeforeLayoutTry,
      );
      expect(eligible(isWeb: true), isFalse);
    });

    test('a picker that was never dismissed → no card', () async {
      await reinit();
      expect(eligible(), isFalse);
      // Seen (chosen) but somehow not dismissed → still no card.
      await reinit(seen: true);
      expect(eligible(), isFalse);
    });

    test('already shown → never again', () async {
      await reinit(
        seen: true,
        dismissed: true,
        finishCardShown: true,
        finishesSinceDismissal:
            LayoutChoicePromptService.kFinishesBeforeLayoutTry,
      );
      expect(eligible(), isFalse);
    });

    test('already brewing immersive → nothing to offer', () async {
      await reinit(
        dismissed: true,
        finishesSinceDismissal:
            LayoutChoicePromptService.kFinishesBeforeLayoutTry,
      );
      expect(eligible(pourEnabled: true), isFalse);
    });

    test('markFinishCardShown persists and flips eligibility off', () async {
      await reinit(
        dismissed: true,
        finishesSinceDismissal:
            LayoutChoicePromptService.kFinishesBeforeLayoutTry,
      );
      expect(service.finishCardShown, isFalse);
      expect(eligible(), isTrue);

      await service.markFinishCardShown();
      expect(service.finishCardShown, isTrue);
      expect(prefs.getBool('layout_finish_card_shown'), isTrue);
      expect(eligible(), isFalse);
    });

    test('counter does not increment before dismissal', () async {
      await reinit();

      await service.recordFinishForLayoutTry();

      expect(service.finishesSinceDismissal, 0);
      expect(prefs.getInt('layout_finishes_since_dismissal'), 0);
    });

    test('counter does not increment after the card was shown', () async {
      await reinit(
        dismissed: true,
        finishCardShown: true,
        finishesSinceDismissal:
            LayoutChoicePromptService.kFinishesBeforeLayoutTry,
      );

      await service.recordFinishForLayoutTry();

      expect(
        service.finishesSinceDismissal,
        LayoutChoicePromptService.kFinishesBeforeLayoutTry,
      );
    });
  });

  group('flags and analytics names', () {
    test('markPickerSeen / markPickerDismissed persist', () async {
      await reinit();
      expect(service.pickerSeen, isFalse);
      expect(service.pickerDismissed, isFalse);
      expect(service.finishesSinceDismissal, 0);

      await service.markPickerSeen();
      expect(service.pickerSeen, isTrue);
      expect(prefs.getBool('layout_picker_seen'), isTrue);

      await service.markPickerDismissed();
      expect(service.pickerDismissed, isTrue);
      expect(prefs.getBool('layout_picker_dismissed'), isTrue);
    });

    test('missing flags default to false', () async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = LayoutChoicePromptService(prefs);
      expect(service.pickerSeen, isFalse);
      expect(service.pickerDismissed, isFalse);
    });

    test('analyticsName matches the agreed event vocabulary', () {
      expect(LayoutChoiceTrigger.existingUser.analyticsName, 'existing_user');
      expect(LayoutChoiceTrigger.secondBrew.analyticsName, 'second_brew');
      expect(LayoutChoiceTrigger.finishCard.analyticsName, 'finish_card');
    });
  });
}
