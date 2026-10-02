import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import '../models/notification_mode.dart';
import '../widgets/smart_back_button.dart';
import 'brewing_process_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../services/layout_choice_prompt_service.dart';
import '../services/advanced_features_service.dart';
import '../services/analytics_service.dart';
import '../services/brew_alert_preference.dart';
import '../services/settings_analytics.dart';
import '../services/feature_flags/feature_flags_repository.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';
import '../utils/recipe_step_resolution.dart';
import '../widgets/brewing/layout_choice_sheet.dart';
import '../widgets/brewing/layout_preview_cards.dart';
import '../widgets/settings/layout_switch_back_reason_row.dart';
import '../widgets/settings/settings_list.dart';

class PreparationScreen extends StatefulWidget {
  final RecipeModel recipe;
  final String brewingMethodName;
  final int? coffeeChroniclerSliderPosition;

  const PreparationScreen({
    super.key,
    required this.recipe,
    required this.brewingMethodName,
    this.coffeeChroniclerSliderPosition,
  });

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  late AudioPlayer player;
  // Initialised from the shared preference, not a hardcoded mode: the stored
  // default is none, and starting at soundOnly flashed the wrong first frame.
  NotificationMode _notificationMode = BrewAlertPreference.instance.mode.value;
  bool _startingBrew = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    // Same notifier the Settings brewing page listens to, so a mode changed
    // there while this screen sits below on the stack still shows here.
    BrewAlertPreference.instance.mode.addListener(_onBrewAlertModeChanged);
    BrewAlertPreference.instance.load();
    _preloadAudio();
  }

  void _onBrewAlertModeChanged() {
    if (!mounted) return;
    setState(() {
      _notificationMode = BrewAlertPreference.instance.mode.value;
    });
  }

  Future<void> _preloadAudio() async {
    try {
      await player.setAsset('assets/audio/next.mp3');
    } catch (e) {
      // Handle loading error if necessary
    }
  }

  Future<void> _startBrew() async {
    if (_startingBrew) return;
    _startingBrew = true;
    try {
      // Read every provider up front, before the first await.
      final advancedFeatures = context.read<AdvancedFeaturesService>();
      final onboardingService = context.read<OnboardingService>();
      final featureFlags = context.read<FeatureFlagsRepository>();
      final analytics = AnalyticsService.maybeInstance;

      if (analytics != null) {
        await advancedFeatures.assignLayoutArmIfEligible(
          firstBrewDone: onboardingService.firstBrewDone,
          installId: analytics.installId,
          experimentActive: featureFlags.isEnabled(
            FeatureFlagKeys.pourLayoutExperiment,
            defaultValue: true,
          ),
        );
      }

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      // The layout the picker would be choosing from, read once before any
      // of the calls below can change it.
      final String currentLayout = advancedFeatures.pourLayoutEnabled
          ? 'pour'
          : 'classic';
      final String? arm = advancedFeatures.layoutArm;

      final picker = LayoutChoicePromptService(prefs);
      final LayoutChoiceTrigger? trigger = picker.resolvePickerTrigger(
        isWeb: kIsWeb,
        firstBrewDone: onboardingService.firstBrewDone,
        arm: arm,
        pourEnabled: advancedFeatures.pourLayoutEnabled,
      );

      if (trigger == null) {
        // Already brewing immersive by their own choice (e.g. from the gear
        // sheet), with no arm: the picker would only ever ask about a choice
        // already made, so record that it is moot. BrewingProcessScreen reads
        // the layout once in initState, so nothing here needs to propagate.
        if (advancedFeatures.pourLayoutEnabled) {
          await picker.markSeenIfAlreadyOnPour(
            isWeb: kIsWeb,
            firstBrewDone: onboardingService.firstBrewDone,
          );
        }
        if (!mounted) return;
        _pushBrewingScreen();
        return;
      }

      // Mark seen on SHOW: an app kill while the sheet is up must never
      // re-interrupt a later brew with it.
      await picker.markPickerSeen();
      analytics?.track(
        'layout_choice_shown',
        properties: {
          'trigger': trigger.analyticsName,
          'current_layout': currentLayout,
          'arm': arm ?? 'none',
        },
      );

      if (!mounted) return;

      final preview = layoutPreviewStepsFor(widget.recipe);
      final choice = await showLayoutChoiceSheet(
        context,
        trigger: trigger,
        current: advancedFeatures.pourLayoutEnabled
            ? LayoutChoice.pour
            : LayoutChoice.classic,
        instruction: preview.instruction,
        nextInstruction: preview.nextInstruction,
        stepSeconds: preview.stepSeconds,
      );

      if (!mounted) return;

      if (choice == null) {
        await picker.markPickerDismissed();
        analytics?.track(
          'layout_choice_made',
          properties: {
            'trigger': trigger.analyticsName,
            'choice': 'dismissed',
            'previous': currentLayout,
            'arm': arm ?? 'none',
          },
        );
        // Stay on Preparation; no brew starts.
        return;
      }

      // Sets the field and notifies synchronously before its first await, so
      // the push below always hands BrewingProcessScreen the chosen layout.
      await advancedFeatures.setPourLayoutEnabled(
        choice == LayoutChoice.pour,
        source: 'layout_picker',
      );
      analytics?.track(
        'layout_choice_made',
        properties: {
          'trigger': trigger.analyticsName,
          'choice': choice == LayoutChoice.pour ? 'pour' : 'classic',
          'previous': currentLayout,
          'arm': arm ?? 'none',
        },
      );

      if (!mounted) return;
      _pushBrewingScreen();
    } finally {
      _startingBrew = false;
    }
  }

  /// Feedback + push, the old tail of [_startBrew]. Both the picker-free
  /// path and the picker-chosen path end here, with the sound/vibration
  /// right before the transition either way.
  void _pushBrewingScreen() {
    // Sound feedback for modes that include sound
    if (_notificationMode == NotificationMode.soundOnly) {
      player.seek(Duration.zero);
      player.play();
    }

    // Vibration feedback for modes that include vibration
    if (_notificationMode == NotificationMode.vibrationOnly) {
      Vibration.vibrate(preset: VibrationPreset.longAlarmBuzz);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrewingProcessScreen(
          recipe: widget.recipe,
          coffeeAmount: widget.recipe.coffeeAmount,
          waterAmount: widget.recipe.waterAmount,
          sweetnessSliderPosition: widget.recipe.sweetnessSliderPosition,
          strengthSliderPosition: widget.recipe.strengthSliderPosition,
          notificationMode: _notificationMode,
          brewingMethodName: widget.brewingMethodName,
          coffeeChroniclerSliderPosition: widget.coffeeChroniclerSliderPosition,
        ),
      ),
    );
  }

  void _cycleNotificationMode() async {
    final currentMode = _notificationMode;
    final nextMode =
        NotificationMode.fromValue((currentMode.value + 1) % 3);

    // Updates the shared notifier synchronously; the listener above mirrors
    // it into _notificationMode before the first await.
    await BrewAlertPreference.instance.set(nextMode);

    SettingsAnalytics.settingChanged(
      key: SettingKey.brewAlerts,
      value: nextMode.wireName,
      previous: currentMode.wireName,
      source: SettingSource.preparationScreen,
    );

    // Provide feedback based on the new mode
    switch (nextMode) {
      case NotificationMode.vibrationOnly:
        Vibration.vibrate(preset: VibrationPreset.longAlarmBuzz);
        break;
      case NotificationMode.soundOnly:
        await player.seek(Duration.zero); // Reset to beginning
        player.play();
        break;
      case NotificationMode.none:
        // No feedback
        break;
    }
  }

  Widget _buildNotificationIcon() {
    switch (_notificationMode) {
      case NotificationMode.none:
        return Icon(Icons.volume_off);
      case NotificationMode.vibrationOnly:
        return Icon(Icons.vibration);
      case NotificationMode.soundOnly:
        return Icon(Icons.volume_up);
    }
  }

  void _setManualStepControl(
    AdvancedFeaturesService advancedFeatures,
    bool enabled,
  ) {
    advancedFeatures.setManualStepControlEnabled(enabled);
    AnalyticsService.instance.track(
      'beta_feature_toggled',
      properties: {
        'feature': 'manual_step_control',
        'enabled': enabled,
        'source': 'preparation_settings_sheet',
      },
    );
  }

  void _openAdvancedFeaturesSheet(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // The content still scrolls if a large text scale outgrows the screen.
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer<AdvancedFeaturesService>(
            builder: (context, advancedFeatures, _) {
              // This recipe's first timed step (and the one after it),
              // resolved fresh on every sheet rebuild.
              final preview = layoutPreviewStepsFor(widget.recipe);
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: Text(
                        appLocalizations.settingsBrewingTitle,
                        style: AppTextStyles.title,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: LayoutPreviewCards(
                        current: advancedFeatures.pourLayoutEnabled
                            ? LayoutChoice.pour
                            : LayoutChoice.classic,
                        onSelected: (choice) =>
                            advancedFeatures.setPourLayoutEnabled(
                              choice == LayoutChoice.pour,
                              source: 'preparation_settings_sheet',
                            ),
                        instruction: preview.instruction,
                        nextInstruction: preview.nextInstruction,
                        stepSeconds: preview.stepSeconds,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Reacts to the immersive → classic flip, so it must sit
                    // directly under the layout control and receive the live
                    // service value on every rebuild. Always present; hides
                    // itself via SizedBox.shrink().
                    LayoutSwitchBackReasonRow(
                      pourEnabled: advancedFeatures.pourLayoutEnabled,
                      source: 'preparation_settings_sheet',
                    ),
                    SettingsSwitchRow(
                      identifier: 'manualStepControlToggleButton',
                      title: appLocalizations.manualStepControl,
                      subtitle: appLocalizations.manualStepControlDescription,
                      value: advancedFeatures.manualStepControlEnabled,
                      onChanged: (value) =>
                          _setManualStepControl(advancedFeatures, value),
                    ),
                    SettingsNavRow(
                      identifier: 'preparationAllBrewingSettingsRow',
                      title: appLocalizations.settingsAllBrewingSettings,
                      onTap: () {
                        // Captured before the pop — the sheet's context
                        // dies with it — and there is no async gap between
                        // this lookup and the push below.
                        final router = context.router;
                        Navigator.of(sheetContext).pop();
                        SettingsAnalytics.shortcutTapped(
                          source: ShortcutSource.preparationSheet,
                          target: SettingsTarget.brewing,
                        );
                        router.push(const SettingsBrewingRoute());
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'preparationBackButton',
          child: const SmartBackButton(),
        ),
        title: Semantics(
          identifier: 'preparationScreenTitle',
          child: Text(appLocalizations.preparation),
        ),
        actions: [
          Semantics(
            identifier: 'preparationAdvancedFeaturesButton',
            child: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: appLocalizations.settingsBrewingTitle,
              onPressed: () => _openAdvancedFeaturesSheet(context),
            ),
          ),
        ],
      ),
      body: Semantics(
        identifier: 'preparationBody',
        child: _buildBody(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Semantics(
        identifier: 'floatingActionButtons',
        child: _buildFloatingActionButton(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final preparationSteps = widget.recipe.steps
        .where((step) => step.order == 1 && step.time.inSeconds == 0)
        .map((step) {
          return BrewStepModel(
            id: step.id,
            order: step.order,
            description: replacePlaceholders(
              step.description,
              widget.recipe.coffeeAmount,
              widget.recipe.waterAmount,
              widget.recipe.sweetnessSliderPosition,
              widget.recipe.strengthSliderPosition,
              widget.recipe.coffeeChroniclerSliderPosition,
            ),
            time: replaceTimePlaceholder(
              step.time,
              widget.recipe.sweetnessSliderPosition,
              widget.recipe.strengthSliderPosition,
              widget.recipe.coffeeChroniclerSliderPosition,
            ),
          );
        })
        .toList();

    return Center(
      child: Semantics(
        identifier: 'preparationSteps',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: preparationSteps
                .map(
                  (step) => Semantics(
                    identifier: 'preparationStep_${step.order}',
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        bottom: 16,
                      ), // Add space between text widgets
                      child: Text(
                        step.description,
                        style: const TextStyle(fontSize: 24, height: 1.3),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            identifier: 'notificationToggleButton',
            child: FloatingActionButton(
              heroTag: 'notificationButton',
              onPressed: _cycleNotificationMode,
              child: _buildNotificationIcon(),
            ),
          ),
          Semantics(
            identifier: 'playButton',
            child: FloatingActionButton(
              heroTag: 'playButton',
              onPressed: _startBrew,
              child: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_new
                    : Icons.play_arrow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    BrewAlertPreference.instance.mode.removeListener(_onBrewAlertModeChanged);
    player.dispose();
    super.dispose();
  }
}
