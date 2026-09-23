import 'package:coffee_timer/services/layout_choice_prompt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late LayoutChoicePromptService service;

  // Sets the mock store first, then grabs an instance sharing it, so the
  // service's reads/writes and the test's assertions see the same store.
  Future<void> reinit({bool seen = false, bool dismissed = false}) async {
    SharedPreferences.setMockInitialValues({
      'layout_picker_seen': seen,
      'layout_picker_dismissed': dismissed,
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

    test('an assigned arm beats pourEnabled: arm + pour on → secondBrew', () async {
      await reinit();
      expect(resolve(arm: 'pour', pourEnabled: true), LayoutChoiceTrigger.secondBrew);
    });

    test('any assigned arm routes to secondBrew', () async {
      await reinit();
      expect(resolve(arm: 'classic'), LayoutChoiceTrigger.secondBrew);
      expect(resolve(arm: 'pour'), LayoutChoiceTrigger.secondBrew);
    });

    test('already on immersive with no arm → null, and is the mark-seen case', () async {
      await reinit();
      expect(resolve(pourEnabled: true), isNull);

      // The contract: the caller must mark the picker seen here, or a later
      // brew that IS eligible would be interrupted about a choice already
      // made from the gear sheet.
      expect(service.pickerSeen, isFalse);
      await service.markSeenIfAlreadyOnPour(isWeb: false, firstBrewDone: true);
      expect(service.pickerSeen, isTrue);
      expect(prefs.getBool('layout_picker_seen'), isTrue);
    });

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

  group('flags and analytics names', () {
    test('markPickerSeen / markPickerDismissed persist', () async {
      await reinit();
      expect(service.pickerSeen, isFalse);
      expect(service.pickerDismissed, isFalse);

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
