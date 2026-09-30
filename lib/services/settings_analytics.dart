import 'analytics_service.dart';

/// Settings keys emitted by [SettingsAnalytics].
///
/// There is deliberately no `analyticsGeneral` member: product decision D6a
/// forbids sending anything about the general-analytics switch in either
/// direction.
enum SettingKey {
  theme('theme'),
  language('language'),
  dateFormat('date_format'),
  timeFormat('time_format'),
  appIcon('app_icon'),
  snowEffect('snow_effect'),
  brewAlerts('brew_alerts'),
  brewingMethodVisible('brewing_method_visible'),
  brewingMethodsReset('brewing_methods_reset'),
  analyticsBrews('analytics_brews'),
  analyticsBeans('analytics_beans');

  const SettingKey(this.wireName);

  final String wireName;
}

/// Surface from which a setting was changed.
enum SettingSource {
  settings('settings'),
  preparationScreen('preparation_screen');

  const SettingSource(this.wireName);

  final String wireName;
}

/// Surface containing a shortcut into Settings.
enum ShortcutSource {
  preparationSheet('preparation_sheet'),
  brewMethodList('brew_method_list'),
  deepLink('deep_link');

  const ShortcutSource(this.wireName);

  final String wireName;
}

/// Settings category targeted by a shortcut.
enum SettingsTarget {
  brewing('brewing'),
  homeScreen('home_screen'),
  notifications('notifications'),
  appearance('appearance'),
  languageRegion('language_region'),
  privacyData('privacy_data');

  const SettingsTarget(this.wireName);

  final String wireName;
}

/// Surface containing an account entry point.
enum AccountEntrySource {
  hub('hub'),
  settings('settings');

  const AccountEntrySource(this.wireName);

  final String wireName;
}

/// Typed analytics helpers for Settings interactions.
abstract final class SettingsAnalytics {
  /// Converts a boolean setting value to its analytics representation.
  static String onOff(bool value) => value ? 'on' : 'off';

  /// Records a setting change, skipping no-op changes and startup restores.
  ///
  /// For [SettingKey.analyticsBrews] and [SettingKey.analyticsBeans], call this
  /// after applying the switch so [AnalyticsService.track]'s category check
  /// drops the event when general analytics is off.
  static void settingChanged({
    required SettingKey key,
    required String value,
    required String? previous,
    required SettingSource source,
    String? brewingMethodId,
  }) {
    assert(
      key != SettingKey.brewingMethodsReset,
      'Use brewingMethodsReset() for reset events.',
    );
    assert(
      key != SettingKey.brewingMethodVisible || brewingMethodId != null,
      'brewingMethodVisible requires a brewingMethodId.',
    );
    assert(
      brewingMethodId == null || key == SettingKey.brewingMethodVisible,
      'brewingMethodId is only valid for brewingMethodVisible.',
    );
    if (value == previous) return;

    final properties = <String, dynamic>{
      'key': key.wireName,
      'value': value,
      'source': source.wireName,
      'previous': ?previous,
      'brewing_method_id': ?brewingMethodId,
    };
    AnalyticsService.maybeInstance?.track(
      'setting_changed',
      properties: properties,
    );
  }

  /// Records the explicit reset of all brewing methods.
  static void brewingMethodsReset({required SettingSource source}) {
    AnalyticsService.maybeInstance?.track(
      'setting_changed',
      properties: {
        'key': SettingKey.brewingMethodsReset.wireName,
        'value': 'reset',
        'source': source.wireName,
      },
    );
  }

  /// Records use of a shortcut into a Settings category.
  static void shortcutTapped({
    required ShortcutSource source,
    required SettingsTarget target,
    String? section,
  }) {
    AnalyticsService.maybeInstance?.track(
      'settings_shortcut_tapped',
      properties: {
        'source': source.wireName,
        'target': target.wireName,
        'section': ?section,
      },
    );
  }

  /// Records entry into account management from the Hub or Settings.
  static void accountEntryTapped({
    required AccountEntrySource source,
    required bool signedIn,
  }) {
    AnalyticsService.maybeInstance?.track(
      'account_entry_tapped',
      properties: {
        'source': source.wireName,
        'state': signedIn ? 'signed_in' : 'anonymous',
      },
    );
  }
}
