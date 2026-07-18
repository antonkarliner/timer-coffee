import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _forbiddenCopyByFile = <String, List<String>>{
  'android/app/src/main/kotlin/com/coffee/timer/BrewingLiveUpdateService.kt': [
    '"Brewing Timer"',
    '"Shows brewing progress during active brew"',
    r'"Step $currentStep/$totalSteps · $stepDescription"',
  ],
  'ios/TimerCoffeeWidgetExtension/BrewingData.swift': ['?? "Brewing"'],
  'ios/TimerCoffeeWidgetExtension/BrewingTimerLiveActivity.swift': [
    'Text("Paused")',
    r'Text("Step \(data.stepLabel)")',
  ],
  'lib/screens/account_screen.dart': [
    '"User not found."',
    '"Failed to load profile. Showing cached data."',
    "Text('Account')",
    "'Loading...'",
  ],
  'lib/screens/coffee_beans_screen.dart': [
    r"'Error: ${controller.error}'",
    "label: 'Retry'",
  ],
  'lib/screens/donation_screen.dart': ["label: 'OK'", "'Unknown Product'"],
  'lib/screens/favorite_recipes_screen.dart': ['"Error loading favorites"'],
  'lib/screens/finish_screen.dart': [r"'Error: ${content.error}'"],
  'lib/screens/info_screen.dart': [
    "Text('Privacy Policy')",
    "Text('Error loading Privacy Policy')",
  ],
  'lib/screens/manual_brew_entry_screen.dart': [r"'Error saving entry: $e'"],
  'lib/screens/new_beans_screen.dart': [r"'Error saving coffee beans: $e'"],
  'lib/screens/recipe_list_screen.dart': ["tooltip: 'Toggle edit mode'"],
  'lib/screens/settings_screen.dart': [r"'Icon change failed: $iconName'"],
  'lib/screens/user_recipe_management_screen.dart': [
    r"'Failed to delete recipe: $e'",
  ],
  'lib/services/authentication_service.dart': [
    "Text('Invalid email format')",
    r'"Error syncing data: ${e.toString()}"',
  ],
  'lib/services/local_notification_manager.dart': [
    "CHANNEL_NAME_GENERAL = 'General'",
    "CHANNEL_DESC_GENERAL = 'General app notifications'",
  ],
  'lib/widgets/autocomplete_input_field.dart': ["Text('Failed to load data')"],
  'lib/widgets/autocomplete_tag_input_field.dart': [
    r'''Text('"$tag" is already added')''',
  ],
  'lib/widgets/coffee_bean_details/coffee_beans_hero_header.dart': [
    r"'${bean.name} from ${bean.roaster}, ${bean.origin}'",
    r"'Logo for ${bean.roaster}'",
    r"'Coffee bean name: ${bean.name}'",
    r"'Roaster: ${bean.roaster}'",
    r"'Origin: ${bean.origin}'",
    "'Remove from favorites'",
    "'Add to favorites'",
    "'Quick statistics'",
  ],
  'lib/widgets/delete_button.dart': ["tooltip ?? 'Delete'"],
  'lib/widgets/fields/time_field.dart': ["label: 'AM'", "label: 'PM'"],
  'lib/widgets/launch_popup.dart': [r"'Could not launch $href'"],
  'lib/widgets/recipe_detail/app_bar_actions.dart': ["?? 'Edit'"],
  'lib/widgets/recipe_detail/bean_selection_row.dart': [
    "clearTooltip = 'Clear'",
    "message: 'Clear'",
  ],
  'lib/widgets/roaster_profile/review_form.dart': [
    "label: 'Yes'",
    "label: 'No'",
  ],
  'lib/widgets/stats/beans_stat_list_card.dart': [
    r"'Error: ${snapshot.error}'",
  ],
  'lib/widgets/user_recipe_management/recipe_list_item.dart': [
    "tooltip: 'Unpublish recipe'",
    "tooltip: 'Delete recipe'",
  ],
};

const _requiredPayloadPlumbingByFile = <String, List<String>>{
  'lib/screens/brewing_process_screen.dart': [
    'l10n.notificationChannelBrewingName',
    'l10n.notificationChannelBrewingDescription',
    'l10n.liveUpdateStepDescription(',
    'l10n.liveActivityPaused',
    'l10n.liveActivityStepProgress(',
  ],
  'lib/services/android_live_update_service.dart': [
    "'channelName': channelName",
    "'channelDescription': channelDescription",
    "'contentText': contentText",
  ],
  'lib/services/live_activity_service.dart': [
    "'pausedLabel': pausedLabel",
    "'stepProgressLabel': stepProgressLabel",
  ],
  'android/app/src/main/kotlin/com/coffee/timer/BrewingLiveUpdateService.kt': [
    'data["channelName"]',
    'data["channelDescription"]',
    'data["contentText"]',
    '?: "Timer.Coffee"',
  ],
  'ios/TimerCoffeeWidgetExtension/BrewingData.swift': [
    'key("pausedLabel")',
    'key("stepProgressLabel")',
    '?? "Timer.Coffee"',
  ],
  'ios/TimerCoffeeWidgetExtension/BrewingTimerLiveActivity.swift': [
    'Text(data.pausedLabel)',
    'Text(data.stepProgressLabel)',
    'Image(systemName: "pause.fill")',
  ],
};

void main() {
  test(
    'removed production copy cannot be reintroduced at audited call sites',
    () {
      for (final entry in _forbiddenCopyByFile.entries) {
        final source = File(entry.key).readAsStringSync();
        for (final forbiddenCopy in entry.value) {
          expect(
            source,
            isNot(contains(forbiddenCopy)),
            reason: '${entry.key} reintroduced `$forbiddenCopy`',
          );
        }
      }
    },
  );

  test('localized live-surface payload plumbing remains complete', () {
    for (final entry in _requiredPayloadPlumbingByFile.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final requiredContract in entry.value) {
        expect(
          source,
          contains(requiredContract),
          reason: '${entry.key} dropped `$requiredContract`',
        );
      }
    }
  });
}
