import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(AnalyticsService.resetForTesting);

  List<Map<String, dynamic>> eventsNamed(String name) {
    return AnalyticsService.instance.bufferedEventsForTesting
        .where((event) => event['event_name'] == name)
        .toList();
  }

  test('settingChanged emits wire names and optional method id', () {
    SettingsAnalytics.settingChanged(
      key: SettingKey.brewingMethodVisible,
      value: 'off',
      previous: 'on',
      source: SettingSource.preparationScreen,
      brewingMethodId: 'v60',
    );

    expect(eventsNamed('setting_changed').single['properties'], {
      'key': 'brewing_method_visible',
      'value': 'off',
      'previous': 'on',
      'source': 'preparation_screen',
      'brewing_method_id': 'v60',
    });
  });

  test('settingChanged skips unchanged values', () {
    SettingsAnalytics.settingChanged(
      key: SettingKey.theme,
      value: 'dark',
      previous: 'dark',
      source: SettingSource.settings,
    );

    expect(eventsNamed('setting_changed'), isEmpty);
  });

  test('settingChanged omits null previous and unrelated method id', () {
    SettingsAnalytics.settingChanged(
      key: SettingKey.language,
      value: 'fr',
      previous: null,
      source: SettingSource.settings,
    );

    final properties =
        eventsNamed('setting_changed').single['properties']
            as Map<String, dynamic>;
    expect(properties, {
      'key': 'language',
      'value': 'fr',
      'source': 'settings',
    });
    expect(properties, isNot(contains('previous')));
    expect(properties, isNot(contains('brewing_method_id')));
  });

  test('brewingMethodsReset always emits reset value', () {
    SettingsAnalytics.brewingMethodsReset(source: SettingSource.settings);

    expect(eventsNamed('setting_changed').single['properties'], {
      'key': 'brewing_methods_reset',
      'value': 'reset',
      'source': 'settings',
    });
  });

  test('shortcut maps wire names and omits a null section', () {
    SettingsAnalytics.shortcutTapped(
      source: ShortcutSource.brewMethodList,
      target: SettingsTarget.homeScreen,
    );

    final properties =
        eventsNamed('settings_shortcut_tapped').single['properties']
            as Map<String, dynamic>;
    expect(properties, {'source': 'brew_method_list', 'target': 'home_screen'});
    expect(properties, isNot(contains('section')));
  });

  test('shortcut includes a legacy deep-link section', () {
    SettingsAnalytics.shortcutTapped(
      source: ShortcutSource.deepLink,
      target: SettingsTarget.languageRegion,
      section: 'language',
    );

    expect(eventsNamed('settings_shortcut_tapped').single['properties'], {
      'source': 'deep_link',
      'target': 'language_region',
      'section': 'language',
    });
  });

  test('account entry maps signed-in and anonymous states', () {
    SettingsAnalytics.accountEntryTapped(
      source: AccountEntrySource.hub,
      signedIn: true,
    );
    SettingsAnalytics.accountEntryTapped(
      source: AccountEntrySource.settings,
      signedIn: false,
    );

    expect(
      eventsNamed('account_entry_tapped').map((event) => event['properties']),
      [
        {'source': 'hub', 'state': 'signed_in'},
        {'source': 'settings', 'state': 'anonymous'},
      ],
    );
  });

  test('onOff maps booleans to stable values', () {
    expect(SettingsAnalytics.onOff(true), 'on');
    expect(SettingsAnalytics.onOff(false), 'off');
  });

  test('every SettingKey has an allowed snake_case wire name', () {
    final names = SettingKey.values.map((key) => key.wireName).toList();

    expect(names, everyElement(matches(RegExp(r'^[a-z]+(?:_[a-z]+)*$'))));
    expect(names, isNot(contains('analytics_general')));
    expect(names, {
      'theme',
      'language',
      'date_format',
      'time_format',
      'app_icon',
      'snow_effect',
      'brew_alerts',
      'brewing_method_visible',
      'brewing_methods_reset',
      'analytics_brews',
      'analytics_beans',
    });
  });

  test('all 11 settings events are registered', () {
    SettingsAnalytics.settingChanged(
      key: SettingKey.theme,
      value: 'dark',
      previous: 'light',
      source: SettingSource.settings,
    );
    SettingsAnalytics.shortcutTapped(
      source: ShortcutSource.preparationSheet,
      target: SettingsTarget.brewing,
    );
    SettingsAnalytics.accountEntryTapped(
      source: AccountEntrySource.hub,
      signedIn: false,
    );

    const helperlessEvents = [
      'profile_updated',
      'signed_out',
      'account_deleted',
      'account_deletion_failed',
      'data_export_started',
      'data_export_code_sent',
      'data_export_completed',
      'data_export_failed',
    ];
    for (final event in helperlessEvents) {
      AnalyticsService.instance.track(event);
    }

    expect(
      AnalyticsService.instance.bufferedEventsForTesting
          .map((event) => event['event_name'])
          .toSet(),
      {
        'setting_changed',
        'settings_shortcut_tapped',
        'account_entry_tapped',
        ...helperlessEvents,
      },
    );
  });

  test('general opt-out drops analytics category setting changes', () async {
    await AnalyticsService.instance.setGeneralEnabled(false);

    SettingsAnalytics.settingChanged(
      key: SettingKey.analyticsBrews,
      value: 'off',
      previous: 'on',
      source: SettingSource.settings,
    );

    expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
  });
}
