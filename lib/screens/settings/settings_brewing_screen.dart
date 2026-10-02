import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notification_mode.dart';
import '../../providers/recipe_provider.dart';
import '../../services/advanced_features_service.dart';
import '../../services/analytics_service.dart';
import '../../services/brew_alert_preference.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../utils/recipe_step_resolution.dart';
import '../../widgets/brewing/layout_preview_cards.dart';
import '../../widgets/settings/layout_switch_back_reason_row.dart';
import '../../widgets/settings/settings_list.dart';

/// The first timed step (and the one after it) that the layout preview cards
/// render — the same record shape [layoutPreviewStepsFor] returns.
typedef _LayoutPreviewSteps = ({
  String instruction,
  String? nextInstruction,
  int stepSeconds,
});

/// Brewing settings page (Settings → Brewing): the brewing-screen layout
/// (classic vs. immersive), manual step control and the brew alerts.
@RoutePage()
class SettingsBrewingScreen extends StatefulWidget {
  const SettingsBrewingScreen({super.key});

  /// Clears the session preview-steps cache. Tests must call this so each
  /// test starts with an unresolved first visit, as a fresh app run would.
  @visibleForTesting
  static void resetSessionPreviewStepsForTesting() =>
      _SettingsBrewingScreenState._sessionPreviewSteps = null;

  @override
  State<SettingsBrewingScreen> createState() => _SettingsBrewingScreenState();
}

class _SettingsBrewingScreenState extends State<SettingsBrewingScreen> {
  /// The last resolved preview steps, remembered across visits to this page
  /// so a later visit draws them on its very first frame (the last-used
  /// recipe's first timed step, or the sample when there is none). Every
  /// visit still re-resolves and replaces them, like the Brew Coffee tab's
  /// memoized last-used recipe.
  static _LayoutPreviewSteps? _sessionPreviewSteps;

  /// The step-less look the cards show while the first visit's future is
  /// still pending — never the sample, which must not flash ahead of a real
  /// recipe.
  static final _LayoutPreviewSteps _emptyPreviewSteps =
      (instruction: '', nextInstruction: null, stepSeconds: 0);

  _LayoutPreviewSteps _previewSteps = _emptyPreviewSteps;

  @override
  void initState() {
    super.initState();
    // The choice row below renders the stored brew-alert mode; load it
    // before its first build if possible. The ValueListenableBuilder also
    // picks up a later change made elsewhere (e.g. the Preparation screen).
    BrewAlertPreference.instance.load();
    // Later visits draw the remembered steps on their first frame, but every
    // visit still re-resolves them: the last-used recipe changes whenever
    // the user brews something else. Resolve after the first frame — the
    // sample fallback needs an AppLocalizations lookup, which must not run
    // in initState.
    final cached = _sessionPreviewSteps;
    if (cached != null) _previewSteps = cached;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPreviewSteps();
    });
  }

  Future<void> _loadPreviewSteps() async {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    final sample = (
      instruction: loc.settingsLayoutPreviewStep,
      nextInstruction: loc.settingsLayoutPreviewNextStep,
      stepSeconds: 30,
    );
    _LayoutPreviewSteps preview = sample;
    var resolved = false;
    try {
      final recipe = await context.read<RecipeProvider>().getLastUsedRecipe();
      final steps = recipe == null ? null : layoutPreviewStepsFor(recipe);
      // No last recipe, or one without a timed step: use the sample.
      preview = steps != null && steps.instruction.isNotEmpty ? steps : sample;
      resolved = true;
    } catch (_) {
      // A failed lookup falls back to the sample but is not remembered, so
      // a later visit can still pick up a real recipe.
      preview = sample;
    }
    if (!mounted) return;
    if (resolved) _sessionPreviewSteps = preview;
    setState(() => _previewSteps = preview);
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
        // The preview cards are a non-row block, so the section is headed.
        SettingsSection(
          header: l10n.settingsBrewingScreenLayout,
          children: [
            // Same left/right rhythm as the rows below.
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.base,
              ),
              child: LayoutPreviewCards(
                current: advanced.pourLayoutEnabled
                    ? LayoutChoice.pour
                    : LayoutChoice.classic,
                onSelected: (choice) =>
                    _setLayout(advanced, choice == LayoutChoice.pour),
                instruction: _previewSteps.instruction,
                nextInstruction: _previewSteps.nextInstruction,
                stepSeconds: _previewSteps.stepSeconds,
              ),
            ),
            // The same gap as in the Preparation gear sheet.
            const SizedBox(height: AppSpacing.sm),
            // Reacts to the immersive → classic flip, so it must sit directly
            // under the layout control and receive the live service value on
            // every rebuild. Always present; hides itself via
            // SizedBox.shrink().
            LayoutSwitchBackReasonRow(
              pourEnabled: advanced.pourLayoutEnabled,
              source: 'settings',
            ),
          ],
        ),
        SettingsSection(
          children: [
            SettingsSwitchRow(
              identifier: 'settingsManualStepControlSwitch',
              title: l10n.manualStepControl,
              subtitle: l10n.manualStepControlDescription,
              value: advanced.manualStepControlEnabled,
              onChanged: (value) => _setManualStepControl(advanced, value),
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
        ),
      ],
    );
  }
}
