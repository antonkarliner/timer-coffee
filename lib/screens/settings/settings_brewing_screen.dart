import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notification_mode.dart';
import '../../services/advanced_features_service.dart';
import '../../services/analytics_service.dart';
import '../../services/brew_alert_preference.dart';
import '../../services/settings_analytics.dart';
import '../../widgets/app_switch_list_tile.dart';
import '../../widgets/settings/layout_switch_back_reason_row.dart';
import '../../widgets/settings/settings_list.dart';

/// Brewing settings page (Settings → Brewing): the brewing-screen layout
/// (classic vs. immersive), manual step control and the brew alerts.
@RoutePage()
class SettingsBrewingScreen extends StatefulWidget {
  const SettingsBrewingScreen({super.key});

  @override
  State<SettingsBrewingScreen> createState() => _SettingsBrewingScreenState();
}

class _SettingsBrewingScreenState extends State<SettingsBrewingScreen> {
  @override
  void initState() {
    super.initState();
    // The choice row below renders the stored brew-alert mode; load it
    // before its first build if possible. The ValueListenableBuilder also
    // picks up a later change made elsewhere (e.g. the Preparation screen).
    BrewAlertPreference.instance.load();
  }

  void _setLayout(AdvancedFeaturesService advanced, bool immersive) {
    // Emits beta_feature_toggled with source 'settings' itself; no
    // layout_choice_* or setting_changed event here — those measure the
    // Play-tap prompt, not this page.
    advanced.setPourLayoutEnabled(immersive, source: 'settings');
  }

  void _setManualStepControl(AdvancedFeaturesService advanced, bool value) {
    final previous = advanced.manualStepControlEnabled;
    advanced.setManualStepControlEnabled(value);
    if (previous != value) {
      AnalyticsService.maybeInstance?.track(
        'beta_feature_toggled',
        properties: {
          'feature': 'manual_step_control',
          'enabled': value,
          'source': 'settings',
        },
      );
    }
  }

  void _setBrewAlertMode(NotificationMode m) {
    final previous = BrewAlertPreference.instance.mode.value;
    BrewAlertPreference.instance.set(m);
    SettingsAnalytics.settingChanged(
      key: SettingKey.brewAlerts,
      value: m.wireName,
      previous: previous.wireName,
      source: SettingSource.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final advanced = context.watch<AdvancedFeaturesService>();

    return SettingsPageScaffold(
      title: l10n.settingsBrewingTitle,
      children: [
        // No section header: it would repeat this row's title word for word.
        SettingsChoiceRow<bool>(
          identifier: 'settingsBrewingLayoutTile',
          title: l10n.settingsBrewingScreenLayout,
          options: [
            SettingsChoiceOption(
              value: false,
              label: l10n.layoutPickerClassic,
              subtitle: l10n.settingsLayoutClassicDescription,
              identifier: 'layoutClassicListTile',
            ),
            SettingsChoiceOption(
              value: true,
              label: l10n.layoutPickerImmersive,
              subtitle: l10n.pourLayoutDescription,
              identifier: 'layoutImmersiveListTile',
            ),
          ],
          current: advanced.pourLayoutEnabled,
          onChanged: (immersive) => _setLayout(advanced, immersive),
        ),
        // Reacts to the immersive → classic flip, so it must sit directly
        // under the layout row and receive the live service value on every
        // rebuild. Always present; hides itself via SizedBox.shrink().
        LayoutSwitchBackReasonRow(
          pourEnabled: advanced.pourLayoutEnabled,
          source: 'settings',
        ),
        Semantics(
          identifier: 'settingsManualStepControlSwitch',
          container: true,
          child: AppSwitchListTile(
            title: l10n.manualStepControl,
            subtitle: l10n.manualStepControlDescription,
            value: advanced.manualStepControlEnabled,
            onChanged: (value) => _setManualStepControl(advanced, value),
          ),
        ),
        // Bound to the shared notifier, so a mode changed on the
        // Preparation screen shows here without reloading the page.
        ValueListenableBuilder<NotificationMode>(
          valueListenable: BrewAlertPreference.instance.mode,
          builder: (context, mode, _) => SettingsChoiceRow<NotificationMode>(
            identifier: 'settingsBrewAlertsTile',
            title: l10n.settingsBrewAlerts,
            options: [
              SettingsChoiceOption(
                value: NotificationMode.none,
                label: l10n.settingsBrewAlertsSilent,
                identifier: 'brewAlertSilentListTile',
              ),
              SettingsChoiceOption(
                value: NotificationMode.vibrationOnly,
                label: l10n.settingsBrewAlertsVibration,
                identifier: 'brewAlertVibrationListTile',
              ),
              SettingsChoiceOption(
                value: NotificationMode.soundOnly,
                label: l10n.settingsBrewAlertsSound,
                identifier: 'brewAlertSoundListTile',
              ),
            ],
            current: mode,
            onChanged: _setBrewAlertMode,
          ),
        ),
      ],
    );
  }
}
