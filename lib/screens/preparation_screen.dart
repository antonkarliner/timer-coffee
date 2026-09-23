import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../services/recipe_expression_service.dart';
import '../services/advanced_features_service.dart';
import '../services/analytics_service.dart';
import '../services/feature_flags/feature_flags_repository.dart';
import '../services/onboarding_service.dart';
import '../widgets/app_switch_list_tile.dart';
import '../widgets/brewing/layout_choice_sheet.dart';

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
  NotificationMode _notificationMode = NotificationMode.soundOnly;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    _loadNotificationSetting();
    _preloadAudio();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationModeIndex =
        prefs.getInt('notificationMode') ?? 0; // Default to none
    setState(() {
      _notificationMode = NotificationMode.fromValue(notificationModeIndex);
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

    final preview = _layoutPreviewSteps();
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

  /// The recipe's first timed step (and the timed step after it), resolved
  /// with the same placeholder replacement the preparation list uses —
  /// BrewingProcessScreen filters to steps with positive time, and the
  /// layout picker's previews must show what this user is about to brew
  /// with. Empty instruction and 0 seconds when the recipe has no timed
  /// step, so the picker never crashes on such a recipe.
  ({String instruction, String? nextInstruction, int stepSeconds})
  _layoutPreviewSteps() {
    final timedSteps = widget.recipe.steps
        .map(
          (step) => BrewStepModel(
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
          ),
        )
        .where((step) => step.time.inSeconds > 0)
        .toList();

    return (
      instruction: timedSteps.isNotEmpty ? timedSteps.first.description : '',
      nextInstruction: timedSteps.length > 1 ? timedSteps[1].description : null,
      stepSeconds: timedSteps.isNotEmpty ? timedSteps.first.time.inSeconds : 0,
    );
  }

  void _cycleNotificationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final currentModeIndex = _notificationMode.value;
    final nextModeIndex = (currentModeIndex + 1) % 3;

    setState(() {
      _notificationMode = NotificationMode.fromValue(nextModeIndex);
    });

    await prefs.setInt('notificationMode', nextModeIndex);

    // Provide feedback based on the new mode
    switch (_notificationMode) {
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
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer<AdvancedFeaturesService>(
            builder: (context, advancedFeatures, _) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        appLocalizations.advancedFeatures,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'manualStepControlToggleButton',
                      toggled: advancedFeatures.manualStepControlEnabled,
                      child: AppSwitchListTile(
                        title: appLocalizations.manualStepControl,
                        subtitle: appLocalizations.manualStepControlDescription,
                        value: advancedFeatures.manualStepControlEnabled,
                        onChanged: (value) =>
                            _setManualStepControl(advancedFeatures, value),
                      ),
                    ),
                    Semantics(
                      identifier: 'pourLayoutToggleButton',
                      toggled: advancedFeatures.pourLayoutEnabled,
                      child: AppSwitchListTile(
                        title: appLocalizations.pourLayout,
                        subtitle: appLocalizations.pourLayoutDescription,
                        value: advancedFeatures.pourLayoutEnabled,
                        onChanged: (value) =>
                            advancedFeatures.setPourLayoutEnabled(
                              value,
                              source: 'preparation_settings_sheet',
                            ),
                      ),
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
              tooltip: appLocalizations.advancedFeatures,
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
    player.dispose();
    super.dispose();
  }

  String replacePlaceholders(
    String description,
    double coffeeAmount,
    double waterAmount,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    int? coffeeChroniclerSliderPosition,
  ) {
    return RecipeExpressionService.renderDescription(
      _replaceLegacyPlaceholders(
        description,
        sweetnessSliderPosition,
        strengthSliderPosition,
        coffeeChroniclerSliderPosition,
      ),
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
    );
  }

  String _replaceLegacyPlaceholders(
    String description,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    int? coffeeChroniclerSliderPosition,
  ) {
    final allValues = <String, double>{};

    if (sweetnessSliderPosition != null) {
      final sweetnessValues = [
        {"m1": 0.16, "m2": 0.24},
        {"m1": 0.20, "m2": 0.20},
        {"m1": 0.24, "m2": 0.16},
      ];
      allValues.addAll(sweetnessValues[sweetnessSliderPosition]);
    }

    if (strengthSliderPosition != null) {
      final strengthValues = [
        {"m3": 0.6, "m4": 0.0, "m5": 0.0},
        {"m3": 0.3, "m4": 0.3, "m5": 0.0},
        {"m3": 0.2, "m4": 0.2, "m5": 0.2},
      ];
      allValues.addAll(strengthValues[strengthSliderPosition]);
    }

    if (coffeeChroniclerSliderPosition != null) {
      final coffeeChroniclerValues = [
        {'t7': 30.0, 't8': 55.0},
        {'t7': 45.0, 't8': 70.0},
        {'t7': 75.0, 't8': 55.0},
      ];
      allValues.addAll(coffeeChroniclerValues[coffeeChroniclerSliderPosition]);
    }

    return description.replaceAllMapped(RegExp(r'<([\w_]+)>'), (match) {
      final variable = match.group(1)!.toLowerCase();
      return allValues.containsKey(variable)
          ? allValues[variable]!.toStringAsFixed(2)
          : match.group(0)!;
    });
  }

  Duration replaceTimePlaceholder(
    Duration time,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    int? coffeeChroniclerSliderPosition,
  ) {
    // If the time is already set, return it
    if (time != Duration.zero) {
      return time;
    }

    // Prepare all possible time values
    Map<String, int> allTimeValues = {};

    // Handle sweetness time values if applicable
    if (sweetnessSliderPosition != null) {
      List<Map<String, int>> sweetnessTimeValues = [
        {"t1": 10, "t2": 35}, // Sweetness
        {"t1": 10, "t2": 35}, // Balance
        {"t1": 10, "t2": 35}, // Acidity
      ];
      allTimeValues.addAll(sweetnessTimeValues[sweetnessSliderPosition]);
    }

    // Handle strength time values if applicable
    if (strengthSliderPosition != null) {
      List<Map<String, int>> strengthTimeValues = [
        {"t3": 0, "t4": 0, "t5": 0, "t6": 0}, // Light
        {"t3": 10, "t4": 35, "t5": 0, "t6": 0}, // Balanced
        {"t3": 10, "t4": 35, "t5": 10, "t6": 35}, // Strong
      ];
      allTimeValues.addAll(strengthTimeValues[strengthSliderPosition]);
    }

    // Handle coffeeChroniclerSwitchSlider time values if applicable
    if (coffeeChroniclerSliderPosition != null) {
      List<Map<String, int>> coffeeChroniclerTimeValues = [
        {'t7': 30, 't8': 55}, // Standard
        {'t7': 45, 't8': 70}, // Medium
        {'t7': 75, 't8': 55}, // XL
      ];
      allTimeValues.addAll(
        coffeeChroniclerTimeValues[coffeeChroniclerSliderPosition],
      );
    }

    // Replace time placeholders
    RegExp exp = RegExp(r'<(t\d+)>');
    String timeString = time.inSeconds.toString();
    var matches = exp.allMatches(timeString);

    for (var match in matches) {
      String placeholder = match.group(1)!;
      int? replacementTime = allTimeValues[placeholder];

      if (replacementTime != null && replacementTime > 0) {
        time = Duration(seconds: replacementTime);
      }
    }

    return time;
  }
}
