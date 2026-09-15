import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'dart:io';
import 'dart:math' as math; // Added for math functions
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import '../models/notification_mode.dart';
import '../providers/recipe_provider.dart';
import 'finish_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl; // Corrected import statement
import '../utils/app_logger.dart'; // Import AppLogger
import '../services/live_activity_service.dart';
import '../services/android_live_update_service.dart';
import '../services/live_activity_sync_service.dart';
import '../services/ios_background_task_service.dart';
import '../services/analytics_service.dart';
import '../services/advanced_features_service.dart';
import '../services/recipe_expression_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/brewing/brew_timer_ring.dart';
import '../widgets/brewing/next_step_preview.dart';

class LocalizedNumberText extends StatelessWidget {
  final int currentNumber;
  final int totalNumber;
  final TextStyle? style;

  const LocalizedNumberText({
    super.key,
    required this.currentNumber,
    required this.totalNumber,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    var isRTL = Directionality.of(context) == TextDirection.rtl;
    var formattedText = isRTL
        ? '${intl.NumberFormat().format(currentNumber)}\\${intl.NumberFormat().format(totalNumber)}'
        : '${intl.NumberFormat().format(currentNumber)}/${intl.NumberFormat().format(totalNumber)}';

    return Semantics(
      identifier: 'localizedNumberText_${currentNumber}_of_$totalNumber',
      child: Text(formattedText, style: style, textAlign: TextAlign.center),
    );
  }
}

class BrewingProcessScreen extends StatefulWidget {
  final RecipeModel recipe;
  final double coffeeAmount;
  final double waterAmount;
  final NotificationMode notificationMode;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final String brewingMethodName;
  final int? coffeeChroniclerSliderPosition;

  const BrewingProcessScreen({
    super.key,
    required this.recipe,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.notificationMode,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
    required this.brewingMethodName,
    this.coffeeChroniclerSliderPosition,
  });

  @override
  State<BrewingProcessScreen> createState() => _BrewingProcessScreenState();
}

class _BrewingProcessScreenState extends State<BrewingProcessScreen>
    with TickerProviderStateMixin {
  late List<BrewStepModel> brewingSteps;
  int currentStepIndex = 0;
  int currentStepTime = 0;
  late Timer timer;
  bool _isPaused = false;
  final _player = AudioPlayer();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController
  _endBrewAnimationController; // For end of brew animation
  bool _isEndBrewAnimating = false; // Flag for end of brew animation state

  // Plan 061 Direction B — derived end-sequence animations. Every visual is
  // driven from _endBrewAnimationController via Intervals (R1, one clock).
  late CurvedAnimation _endArc; // 0.00–0.15: arc lerps to 1.0
  late CurvedAnimation _endCountdownFade; // 0.00–0.15: countdown 1 -> 0
  late CurvedAnimation _endFill; // 0.10–0.70: fill 0 -> 1
  late CurvedAnimation _endAmplitudeDecay; // 0.61–0.79: wave decay 1 -> 0
  late CurvedAnimation _endAccord; // 0.87–1.00: swell, then collapse
  late CurvedAnimation _endAccordFade; // 0.90–1.00: fade out on collapse

  /// Arc fraction the ring stood at when the end sequence was triggered; the
  /// end arc lerps from here to 1.0 instead of snapping (plan 061 B2.2).
  double _endArcStartValue = 0.0;

  /// One-shot flag for the end-sequence haptic (plan 061 R7). Never reset —
  /// one brew, one haptic.
  bool _endHapticFired = false;

  /// Whether the OS asks for reduced motion. Re-read at the top of every
  /// build() (plan 061 R4).
  bool _reduceMotion = false;

  bool _brewFinishedEmitted = false; // Guards brew_finished (plan 042, A1)
  bool _lastStepReachedEmitted =
      false; // Guards last_step_reached (plan 042, E1)

  DateTime? _brewAnchorUtc; // Wall-clock anchor for brew start
  DateTime? _currentStepStartedAtUtc; // Wall-clock anchor for current step
  DateTime? _pausedAtUtc; // When pause was pressed (null if running)
  AppLifecycleListener? _lifecycleListener;
  final LiveActivitySyncService _liveActivitySyncService =
      LiveActivitySyncService.instance;
  StreamSubscription<LiveActivityPushTokenUpdate>?
  _liveActivityTokenSubscription;
  Timer? _liveActivitySessionRetryTimer;
  String? _brewSessionId;
  String? _liveActivityId;
  String? _lastActivityPushToken;
  bool _hasEndedLiveActivity = false;
  bool _navigatedToFinish = false;
  bool _backendLiveActivitySessionStarted = false;
  bool _isStartingLiveActivityBackendSession = false;
  bool _isResyncInProgress = false;
  // Manual step control (Advanced/Beta feature) is read reactively in build()
  // from AdvancedFeaturesService so it reflects the persisted value as soon as
  // the service finishes its async init (and any later toggle changes).
  // Set true the first time the user uses a manual override in this session.
  // Once engaged, Live Activities / backend sync / resync are suppressed
  // because a manual jump invalidates the wall-clock projection they rely on.
  bool _manualOverrideEngaged = false;
  static const Duration _liveActivitySessionRetryInterval = Duration(
    seconds: 4,
  );

  bool get _isLiveActivitySupported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  bool get _shouldSyncLiveActivitySession => !kIsWeb && Platform.isIOS;

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
        {"m1": 0.16, "m2": 0.4},
        {"m1": 0.20, "m2": 0.4},
        {"m1": 0.24, "m2": 0.4},
      ];
      allValues.addAll(sweetnessValues[sweetnessSliderPosition]);
    }

    if (strengthSliderPosition != null) {
      final strengthValues = [
        {"m3": 1.0, "m4": 0.0, "m5": 0.0},
        {"m3": 0.7, "m4": 1.0, "m5": 0.0},
        {"m3": 0.6, "m4": 0.8, "m5": 1.0},
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
      if (allValues.containsKey(variable)) {
        return allValues[variable]!.toStringAsFixed(2);
      }
      return match.group(0)!;
    });
  }

  Duration replaceTimePlaceholder(
    Duration time,
    String? timeString,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    int? coffeeChroniclerSliderPosition,
  ) {
    if (time != Duration.zero) {
      return time;
    }

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
    if (timeString != null) {
      RegExp exp = RegExp(r'<(t\d+)>');
      var matches = exp.allMatches(timeString);

      for (var match in matches) {
        String placeholder = match.group(1)!;
        int? replacementTime = allTimeValues[placeholder];

        if (replacementTime != null && replacementTime > 0) {
          time = Duration(seconds: replacementTime);
        }
      }
    }

    return time;
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    AnalyticsService.instance.track(
      'brew_started',
      properties: {
        'recipe_id': widget.recipe.id,
        'brewing_method_id': widget.recipe.brewingMethodId,
        'coffee_amount': widget.coffeeAmount,
        'water_amount': widget.waterAmount,
      },
    );

    if (!kIsWeb && Platform.isIOS) {
      _activateLiveActivityPlanB(trigger: 'session_start');
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Plan 061 B2.1: the whole end sequence is timed by this single
    // controller. See _endSequenceFullDuration for the pacing rationale.
    _endBrewAnimationController = AnimationController(
      vsync: this,
      duration: _endSequenceFullDuration,
    );
    // Plan 061 B2.2: derived animations, all on the one clock (R1).
    _endArc = CurvedAnimation(
      parent: _endBrewAnimationController,
      curve: const Interval(0.0, 0.151, curve: Curves.easeOut),
    );
    _endCountdownFade = CurvedAnimation(
      parent: _endBrewAnimationController,
      curve: const Interval(0.0, 0.151, curve: Curves.easeOut),
    );
    _endFill = CurvedAnimation(
      parent: _endBrewAnimationController,
      curve: const Interval(0.10, 0.660, curve: Curves.easeInOutCubic),
    );
    _endAmplitudeDecay = CurvedAnimation(
      parent: _endBrewAnimationController,
      curve: const Interval(0.660, 0.774, curve: Curves.easeOut),
    );
    // The closing accord. easeInBack undershoots below 0 before it climbs,
    // and because the scale lerps 1.0 -> 0.5 that undershoot reads as a small
    // swell before the collapse — one curve gives both beats.
    _endAccord = CurvedAnimation(
      parent: _endBrewAnimationController,
      curve: const Interval(0.830, 1.0, curve: Curves.easeInBack),
    );
    _endAccordFade = CurvedAnimation(
      parent: _endBrewAnimationController,
      curve: const Interval(0.868, 1.0, curve: Curves.easeIn),
    );
    _endBrewAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToFinishScreen();
      }
    });
    _endBrewAnimationController.addListener(_onEndBrewAnimationTick);

    brewingSteps = widget.recipe.steps
        .map((step) {
          Duration stepDuration = replaceTimePlaceholder(
            step.time,
            step.timePlaceholder,
            widget.sweetnessSliderPosition,
            widget.strengthSliderPosition,
            widget.coffeeChroniclerSliderPosition, // Pass the slider position
          );

          String description = replacePlaceholders(
            step.description,
            widget.coffeeAmount,
            widget.waterAmount,
            widget.sweetnessSliderPosition,
            widget.strengthSliderPosition,
            widget.coffeeChroniclerSliderPosition, // Pass the slider position
          );

          return BrewStepModel(
            id: step.id,
            order: step.order,
            description: description,
            time: stepDuration,
          );
        })
        .where((step) => step.time.inSeconds > 0)
        .toList();

    _preloadAudio();

    _lifecycleListener = AppLifecycleListener(onResume: _onAppResumed);

    _brewAnchorUtc = DateTime.now().toUtc();
    startTimer();
    // Covers single-step recipes, where the brew starts already on the last
    // step (plan 042, E1).
    _maybeEmitLastStepReached();
    // Keep Flutter alive in background so step-transition activity.update()
    // calls can reach the Lock Screen Live Activity on iOS.
    unawaited(IosBackgroundTaskService.instance.startBrewingTask());
    unawaited(_startLiveActivity());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resyncFromLocalAndServer(trigger: 'init'));
    });
  }

  Future<void> _preloadAudio() async {
    try {
      await _player.setAsset('assets/audio/next.mp3');
    } catch (e) {
      // catch load errors
    }
  }

  @override
  void dispose() {
    if (!_navigatedToFinish) {
      AnalyticsService.instance.track(
        'brew_abandoned',
        properties: {
          'recipe_id': widget.recipe.id,
          'step_reached': currentStepIndex,
          'total_steps': brewingSteps.length,
        },
      );
    }
    timer.cancel();
    unawaited(IosBackgroundTaskService.instance.stopBrewingTask());
    _stopLiveActivityBackendSessionRetryLoop();
    _liveActivityTokenSubscription?.cancel();
    _lifecycleListener?.dispose();
    WakelockPlus.disable();
    _player.dispose();
    _pulseController.dispose();
    _endBrewAnimationController.dispose();
    super.dispose();
  }

  /// Fires the heavy-impact haptic once, on iOS/Android only, independent of
  /// `notificationMode` (plan 061 R7).
  ///
  /// 0.898 puts it on the peak of the accord's swell rather than before it:
  /// the accord runs 0.830-1.0 on an easeInBack curve, whose undershoot — and
  /// so the widest point of the cup — lands about 40% in. Felt and seen then
  /// land together instead of a beat apart.
  static const double _endHapticAt = 0.898;

  void _onEndBrewAnimationTick() {
    if (_endHapticFired) return;
    if (_endBrewAnimationController.value < _endHapticAt) return;
    _endHapticFired = true;
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      HapticFeedback.heavyImpact();
    }
  }

  /// The unhurried pour. The first pass ran this in 1400 ms, which read as
  /// hurried — the brew is over and there is nothing left to wait for, so the
  /// sequence should feel like a reward rather than a loading step.
  ///
  /// Retimed 2026-09-15: an earlier 3900 ms cut left 1020 ms of near-dead
  /// screen between the liquid reaching the top and the closing accord, which
  /// read as waiting rather than savouring. The settle and hold are now much
  /// shorter and the whole thing is tighter. Beats land at roughly: arc
  /// closing 400 ms, liquid rising 1485 ms, surface settling 300 ms, hold
  /// 150 ms, then a 450 ms accord — the filled cup swells very slightly and
  /// collapses away. Gap between "full" and the accord: 450 ms.
  ///
  /// The wave phase is derived from the controller's own value, so lengthening
  /// this slows the lapping to match rather than leaving it churning.
  static const Duration _endSequenceFullDuration = Duration(
    milliseconds: 2650,
  );

  /// Settled-state hold under reduced motion (plan 061 R4): no animation, just
  /// long enough for the finished ring to register before the screen changes.
  static const Duration _endSequenceReducedDuration = Duration(
    milliseconds: 250,
  );

  /// How long the end sequence runs, honouring reduced motion.
  Duration get _endSequenceDuration =>
      _reduceMotion ? _endSequenceReducedDuration : _endSequenceFullDuration;

  /// Skip-on-tap during the end sequence (plan 061 R5): jump the master
  /// controller straight to its end value; its `completed` status navigates.
  void _skipEndBrewAnimation() {
    if (!_isEndBrewAnimating || _navigatedToFinish) return;
    _endBrewAnimationController.value = 1.0;
  }

  void _navigateToFinishScreen() {
    // Ensure it only navigates once and if mounted
    if (!mounted || !_isEndBrewAnimating) return;
    _navigatedToFinish = true;
    _endLiveActivity(reason: 'completed');

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: _reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        reverseTransitionDuration: _reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => FinishScreen(
          brewingMethodName: widget.brewingMethodName,
          recipe: widget.recipe,
          waterAmount: widget.waterAmount,
          coffeeAmount: widget.coffeeAmount,
          sweetnessSliderPosition: widget.sweetnessSliderPosition,
          strengthSliderPosition: widget.strengthSliderPosition,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // Emits `brew_finished` at most once per brew (plan 042, A1). This is the
  // signal that a brew genuinely reached its end from this screen, as
  // opposed to `brew_completed`, which is emitted later from
  // FinishScreen.initState and is lost if that screen never mounts.
  void _emitBrewFinished(String completionPath) {
    if (_brewFinishedEmitted) return;
    _brewFinishedEmitted = true;
    AnalyticsService.instance.track(
      'brew_finished',
      properties: {
        'recipe_id': widget.recipe.id,
        'total_steps': brewingSteps.length,
        'completion_path': completionPath,
      },
    );
  }

  // Emits `last_step_reached` once per brew, the first time the user is on
  // the final step (plan 042, E1). This is the denominator for the skip
  // rate and for measuring drawdown abandonment.
  void _maybeEmitLastStepReached() {
    if (_lastStepReachedEmitted) return;
    if (brewingSteps.isEmpty) return;
    if (currentStepIndex != brewingSteps.length - 1) return;
    _lastStepReachedEmitted = true;
    AnalyticsService.instance.track(
      'last_step_reached',
      properties: {
        'recipe_id': widget.recipe.id,
        'total_steps': brewingSteps.length,
        'step_duration_seconds': brewingSteps[currentStepIndex].time.inSeconds,
      },
    );
  }

  void startTimer() {
    // Set wall-clock anchor for the current step
    _currentStepStartedAtUtc = DateTime.now().toUtc().subtract(
      Duration(seconds: currentStepTime),
    );
    if (_brewAnchorUtc == null) {
      final elapsedBeforeCurrentStep = brewingSteps
          .take(currentStepIndex)
          .fold<int>(0, (sum, step) => sum + step.time.inSeconds);
      _brewAnchorUtc = _currentStepStartedAtUtc!.subtract(
        Duration(seconds: elapsedBeforeCurrentStep),
      );
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final stepDuration = brewingSteps[currentStepIndex].time.inSeconds;
      final last5Start = stepDuration - 5;
      if (currentStepTime >= stepDuration) {
        if (currentStepIndex < brewingSteps.length - 1) {
          _playStepNotification();

          setState(() {
            currentStepIndex++;
            currentStepTime = 0;
          });
          _maybeEmitLastStepReached();
          _currentStepStartedAtUtc = DateTime.now().toUtc();
          _updateLiveActivity();
        } else {
          _playStepNotification();

          timer.cancel();
          _endLiveActivity(reason: 'completed');
          setState(() {
            // Capture the arc BEFORE raising the flag: _currentArcProgress
            // short-circuits to 1.0 once _isEndBrewAnimating is true, so
            // reading it afterwards always yields 1.0 and the sweep in the
            // builder degenerates into a snap (lerp from 1.0 to 1.0).
            _endArcStartValue = _currentArcProgress;
            _isEndBrewAnimating = true;
          });
          _emitBrewFinished('timer');
          _endBrewAnimationController.duration = _endSequenceDuration;
          _endBrewAnimationController.forward(from: 0.0);
        }
      } else {
        setState(() {
          currentStepTime++;
        });
        _updateLiveActivity(isTimerTick: true);
        // Pulse logic: last 5 seconds of the step
        if (!_isEndBrewAnimating &&
            currentStepTime > last5Start &&
            currentStepTime <= stepDuration) {
          _pulseController
              .forward(from: 0.0)
              .then((_) => _pulseController.reverse());
        }
      }
    });
  }

  void _togglePause() {
    // Prevent pausing during the final animation
    if (_isEndBrewAnimating) return;
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      timer.cancel();
      _pausedAtUtc = DateTime.now().toUtc();
      _updateLiveActivity();
      if (_shouldSyncLiveActivitySession &&
          _backendLiveActivitySessionStarted &&
          _brewSessionId != null) {
        final elapsedTotalSeconds = _elapsedTotalSecondsForSync();
        AppLogger.info(
          'Live activity pause sync -> elapsed_total=${elapsedTotalSeconds}s',
        );
        unawaited(
          _liveActivitySyncService.pauseSession(
            brewSessionId: _brewSessionId!,
            elapsedTotalSeconds: elapsedTotalSeconds,
          ),
        );
      }
    } else {
      // Shift the step anchor forward by the paused duration
      if (_pausedAtUtc != null && _currentStepStartedAtUtc != null) {
        final pausedDuration = DateTime.now().toUtc().difference(_pausedAtUtc!);
        _currentStepStartedAtUtc = _currentStepStartedAtUtc!.add(
          pausedDuration,
        );
        if (_brewAnchorUtc != null) {
          _brewAnchorUtc = _brewAnchorUtc!.add(pausedDuration);
        }
      }
      _pausedAtUtc = null;
      startTimer();
      _updateLiveActivity();
      if (_shouldSyncLiveActivitySession && _brewSessionId != null) {
        if (_backendLiveActivitySessionStarted) {
          final elapsedTotalSeconds = _elapsedTotalSecondsForSync();
          AppLogger.info(
            'Live activity resume sync -> elapsed_total=${elapsedTotalSeconds}s',
          );
          unawaited(
            _liveActivitySyncService.resumeSession(
              brewSessionId: _brewSessionId!,
              elapsedTotalSeconds: elapsedTotalSeconds,
            ),
          );
        } else {
          unawaited(_tryStartLiveActivityBackendSession(trigger: 'resume'));
        }
      }
    }
  }

  Future<void> _playStepNotification() async {
    if (widget.notificationMode == NotificationMode.soundOnly) {
      await _player.setAsset('assets/audio/next.mp3');
      _player.play();
    }
    if (widget.notificationMode == NotificationMode.vibrationOnly) {
      Vibration.vibrate(preset: VibrationPreset.longAlarmBuzz);
    }
  }

  // ── Live Activity helpers ──

  void _activateLiveActivityPlanB({required String trigger}) {
    if (!_shouldSyncLiveActivitySession || _hasEndedLiveActivity) return;

    _brewSessionId ??= const Uuid().v4();
    _liveActivityTokenSubscription ??= LiveActivityService
        .instance
        .pushTokenUpdates
        .listen(_onLiveActivityPushTokenUpdate);
    _ensureLiveActivityBackendSessionRetryLoop();
    unawaited(_tryStartLiveActivityBackendSession(trigger: trigger));
  }

  void _ensureLiveActivityBackendSessionRetryLoop() {
    if (!_shouldSyncLiveActivitySession ||
        _hasEndedLiveActivity ||
        _backendLiveActivitySessionStarted) {
      _stopLiveActivityBackendSessionRetryLoop();
      return;
    }

    _brewSessionId ??= const Uuid().v4();
    if (_liveActivitySessionRetryTimer != null) return;

    _liveActivitySessionRetryTimer = Timer.periodic(
      _liveActivitySessionRetryInterval,
      (_) {
        if (!_shouldSyncLiveActivitySession ||
            _hasEndedLiveActivity ||
            _backendLiveActivitySessionStarted) {
          _stopLiveActivityBackendSessionRetryLoop();
          return;
        }
        if (_isPaused) return;
        unawaited(_tryStartLiveActivityBackendSession(trigger: 'retry_timer'));
      },
    );
  }

  void _stopLiveActivityBackendSessionRetryLoop() {
    _liveActivitySessionRetryTimer?.cancel();
    _liveActivitySessionRetryTimer = null;
  }

  Duration _iosLiveActivityStaleIn(List<int> stepDurationsSeconds) {
    final totalDurationSeconds = stepDurationsSeconds.fold<int>(
      0,
      (sum, seconds) => sum + seconds,
    );
    final withBufferSeconds = totalDurationSeconds + 120;
    final roundedUpMinutes = math.max(2, (withBufferSeconds / 60).ceil());
    return Duration(minutes: roundedUpMinutes);
  }

  Future<void> _startLiveActivity() async {
    if (!_isLiveActivitySupported || _hasEndedLiveActivity) return;
    final args = _liveActivityArgs();
    if (!kIsWeb && Platform.isIOS) {
      final stepDurations = (args['stepDurationsSeconds'] as List).cast<int>();
      final activityId = await LiveActivityService.instance
          .startBrewingActivity(
            recipeName: args['recipeName'],
            stepDescription: args['stepDescription'],
            pausedLabel: args['pausedLabel'],
            stepProgressLabel: args['stepProgressLabel'],
            currentStep: args['currentStep'],
            totalSteps: args['totalSteps'],
            stepElapsedSeconds: args['stepElapsedSeconds'],
            stepTotalSeconds: args['stepTotalSeconds'],
            isPaused: args['isPaused'],
            removeWhenAppIsKilled: true,
            stepDurationsSeconds: stepDurations,
            stepDescriptions: (args['stepDescriptions'] as List).cast<String>(),
            brewStartDate: args['brewStartDate'],
            stepStartDateMs: args['stepStartDateMs'],
            stepEndDateMs: args['stepEndDateMs'],
            staleIn: _iosLiveActivityStaleIn(stepDurations),
          );
      _liveActivityId = activityId;
      if (_shouldSyncLiveActivitySession) {
        await _tryStartLiveActivityBackendSession(
          activityId: activityId,
          trigger: 'start_live_activity',
        );
      }
    } else if (!kIsWeb && Platform.isAndroid) {
      await AndroidLiveUpdateService.instance.startBrewingActivity(
        recipeName: args['recipeName'],
        stepDescription: args['stepDescription'],
        channelName: args['brewingChannelName'],
        channelDescription: args['brewingChannelDescription'],
        contentText: args['liveUpdateContentText'],
        currentStep: args['currentStep'],
        totalSteps: args['totalSteps'],
        stepElapsedSeconds: args['stepElapsedSeconds'],
        stepTotalSeconds: args['stepTotalSeconds'],
        isPaused: args['isPaused'],
      );
    }
  }

  void _updateLiveActivity({bool isTimerTick = false}) {
    if (!_isLiveActivitySupported || _manualOverrideEngaged) return;
    final args = _liveActivityArgs();
    if (!kIsWeb && Platform.isIOS) {
      // iOS 18 throttles Live Activity re-renders to every 5-15 seconds.
      // Text(timerInterval:) animates the countdown autonomously between
      // step transitions, so periodic heartbeats are not needed.
      // Only step transitions, pause/resume, and app-resume updates are sent.
      if (isTimerTick) return;

      LiveActivityService.instance.updateBrewingActivity(
        recipeName: args['recipeName'],
        stepDescription: args['stepDescription'],
        pausedLabel: args['pausedLabel'],
        stepProgressLabel: args['stepProgressLabel'],
        currentStep: args['currentStep'],
        totalSteps: args['totalSteps'],
        stepElapsedSeconds: args['stepElapsedSeconds'],
        stepTotalSeconds: args['stepTotalSeconds'],
        isPaused: args['isPaused'],
        stepDurationsSeconds: (args['stepDurationsSeconds'] as List)
            .cast<int>(),
        stepDescriptions: (args['stepDescriptions'] as List).cast<String>(),
        brewStartDate: args['brewStartDate'],
        stepStartDateMs: args['stepStartDateMs'],
        stepEndDateMs: args['stepEndDateMs'],
      );
    } else if (!kIsWeb && Platform.isAndroid) {
      AndroidLiveUpdateService.instance.updateBrewingActivity(
        recipeName: args['recipeName'],
        stepDescription: args['stepDescription'],
        channelName: args['brewingChannelName'],
        channelDescription: args['brewingChannelDescription'],
        contentText: args['liveUpdateContentText'],
        currentStep: args['currentStep'],
        totalSteps: args['totalSteps'],
        stepElapsedSeconds: args['stepElapsedSeconds'],
        stepTotalSeconds: args['stepTotalSeconds'],
        isPaused: args['isPaused'],
      );
    }
  }

  void _endLiveActivity({String reason = 'completed'}) {
    if (_hasEndedLiveActivity) return;
    _hasEndedLiveActivity = true;
    unawaited(IosBackgroundTaskService.instance.stopBrewingTask());
    _stopLiveActivityBackendSessionRetryLoop();
    _liveActivityTokenSubscription?.cancel();
    _liveActivityTokenSubscription = null;

    if (_backendLiveActivitySessionStarted && _brewSessionId != null) {
      _backendLiveActivitySessionStarted = false;
      unawaited(
        _liveActivitySyncService.endSession(
          brewSessionId: _brewSessionId!,
          reason: reason,
        ),
      );
    }

    if (!_isLiveActivitySupported) return;
    if (!kIsWeb && Platform.isIOS) {
      _liveActivityId = null;
      _lastActivityPushToken = null;
      LiveActivityService.instance.endBrewingActivity();
    } else if (!kIsWeb && Platform.isAndroid) {
      AndroidLiveUpdateService.instance.endBrewingActivity();
    }
  }

  void _onLiveActivityPushTokenUpdate(LiveActivityPushTokenUpdate update) {
    if (!_shouldSyncLiveActivitySession || _hasEndedLiveActivity) return;
    if (_liveActivityId != null && update.activityId != _liveActivityId) return;

    _liveActivityId ??= update.activityId;

    if (_lastActivityPushToken == update.activityToken) return;
    _lastActivityPushToken = update.activityToken;

    if (_backendLiveActivitySessionStarted && _brewSessionId != null) {
      unawaited(
        _liveActivitySyncService.refreshToken(
          brewSessionId: _brewSessionId!,
          activityId: update.activityId,
          activityPushToken: update.activityToken,
        ),
      );
      return;
    }

    _ensureLiveActivityBackendSessionRetryLoop();
    unawaited(
      _tryStartLiveActivityBackendSession(
        activityId: update.activityId,
        activityPushToken: update.activityToken,
        trigger: 'push_token_update',
      ),
    );
  }

  Future<void> _tryStartLiveActivityBackendSession({
    String? activityId,
    String? activityPushToken,
    String trigger = 'unknown',
  }) async {
    if (!_shouldSyncLiveActivitySession ||
        _hasEndedLiveActivity ||
        _backendLiveActivitySessionStarted ||
        _isPaused ||
        _isStartingLiveActivityBackendSession) {
      return;
    }

    final brewSessionId = _brewSessionId;
    if (brewSessionId == null) {
      _ensureLiveActivityBackendSessionRetryLoop();
      return;
    }

    final resolvedActivityId =
        activityId ??
        _liveActivityId ??
        LiveActivityService.instance.currentActivityId;
    if (resolvedActivityId == null || resolvedActivityId.isEmpty) {
      _ensureLiveActivityBackendSessionRetryLoop();
      return;
    }
    _liveActivityId = resolvedActivityId;

    var resolvedPushToken = activityPushToken;
    if (resolvedPushToken == null || resolvedPushToken.isEmpty) {
      resolvedPushToken = await LiveActivityService.instance.getPushToken(
        resolvedActivityId,
      );
    }
    if (resolvedPushToken == null || resolvedPushToken.isEmpty) {
      _ensureLiveActivityBackendSessionRetryLoop();
      return;
    }

    _lastActivityPushToken = resolvedPushToken;
    final args = _liveActivityArgs();
    _isStartingLiveActivityBackendSession = true;

    try {
      final startResult = await _liveActivitySyncService.startSession(
        brewSessionId: brewSessionId,
        recipeId: widget.recipe.id,
        recipeName: args['recipeName'] as String,
        activityId: resolvedActivityId,
        activityPushToken: resolvedPushToken,
        stepDurationsSeconds: (args['stepDurationsSeconds'] as List)
            .cast<int>(),
        stepDescriptions: (args['stepDescriptions'] as List).cast<String>(),
        brewStartDateMs: args['brewStartDate'] as int,
      );
      _backendLiveActivitySessionStarted = startResult.started;
      AppLogger.info(
        'Live activity backend start [$trigger] '
        'brew_session=$brewSessionId activity_id=$resolvedActivityId '
        'started=${startResult.started} reason=${startResult.reasonCode.value} '
        'retryable=${startResult.retryable}',
      );

      if (startResult.started) {
        _stopLiveActivityBackendSessionRetryLoop();
      } else if (startResult.retryable) {
        _ensureLiveActivityBackendSessionRetryLoop();
      } else {
        _stopLiveActivityBackendSessionRetryLoop();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to start backend live activity session [$trigger]',
        errorObject: e,
      );
      _ensureLiveActivityBackendSessionRetryLoop();
    } finally {
      _isStartingLiveActivityBackendSession = false;
    }
  }

  Map<String, dynamic> _liveActivityArgs() {
    final l10n = lookupAppLocalizations(
      context.read<RecipeProvider>().currentLocale,
    );
    final nowUtc = DateTime.now().toUtc();
    final currentStepTotalSeconds =
        brewingSteps[currentStepIndex].time.inSeconds;
    final boundedCurrentStepTime = currentStepTime
        .clamp(0, currentStepTotalSeconds)
        .toInt();
    final currentStepStartUtc =
        _currentStepStartedAtUtc ??
        nowUtc.subtract(Duration(seconds: boundedCurrentStepTime));
    final elapsedBeforeCurrentStep = brewingSteps
        .take(currentStepIndex)
        .fold<int>(0, (sum, step) => sum + step.time.inSeconds);
    final resolvedBrewAnchorUtc =
        _brewAnchorUtc ??
        currentStepStartUtc.subtract(
          Duration(seconds: elapsedBeforeCurrentStep),
        );
    _brewAnchorUtc ??= resolvedBrewAnchorUtc;
    final stepEndUtc = currentStepStartUtc.add(
      Duration(seconds: currentStepTotalSeconds),
    );
    final currentStep = currentStepIndex + 1;
    final totalSteps = brewingSteps.length;
    final stepDescription = brewingSteps[currentStepIndex].description;

    return {
      'recipeName': widget.recipe.name,
      'stepDescription': stepDescription,
      'brewingChannelName': l10n.notificationChannelBrewingName,
      'brewingChannelDescription':
          l10n.notificationChannelBrewingDescription,
      'liveUpdateContentText': l10n.liveUpdateStepDescription(
        currentStep,
        totalSteps,
        stepDescription,
      ),
      'pausedLabel': l10n.liveActivityPaused,
      'stepProgressLabel': l10n.liveActivityStepProgress(
        currentStep,
        totalSteps,
      ),
      'currentStep': currentStep,
      'totalSteps': totalSteps,
      'stepElapsedSeconds': boundedCurrentStepTime,
      'stepTotalSeconds': currentStepTotalSeconds,
      'isPaused': _isPaused,
      'stepDurationsSeconds': brewingSteps
          .map((step) => step.time.inSeconds)
          .toList(growable: false),
      'stepDescriptions': brewingSteps
          .map((step) => step.description)
          .toList(growable: false),
      'brewStartDate': resolvedBrewAnchorUtc.millisecondsSinceEpoch,
      'stepStartDateMs': currentStepStartUtc.millisecondsSinceEpoch,
      'stepEndDateMs': stepEndUtc.millisecondsSinceEpoch,
    };
  }

  int _elapsedTotalSecondsForSync() {
    if (brewingSteps.isEmpty) return 0;

    final totalDurationSeconds = brewingSteps.fold<int>(
      0,
      (sum, step) => sum + step.time.inSeconds,
    );

    final elapsedBeforeCurrentStep = brewingSteps
        .take(currentStepIndex)
        .fold<int>(0, (sum, step) => sum + step.time.inSeconds);

    if (_isPaused || _currentStepStartedAtUtc == null) {
      return math.max(0, elapsedBeforeCurrentStep + currentStepTime);
    }

    if (_brewAnchorUtc != null) {
      final elapsed = DateTime.now()
          .toUtc()
          .difference(_brewAnchorUtc!)
          .inSeconds
          .clamp(0, totalDurationSeconds)
          .toInt();
      return math.max(0, elapsed);
    }

    final currentStepDuration = brewingSteps[currentStepIndex].time.inSeconds;
    final liveStepElapsed = DateTime.now()
        .toUtc()
        .difference(_currentStepStartedAtUtc!)
        .inSeconds
        .clamp(0, currentStepDuration)
        .toInt();

    return math.max(0, elapsedBeforeCurrentStep + liveStepElapsed);
  }

  void _onAppResumed() {
    unawaited(_resyncFromLocalAndServer(trigger: 'resume'));
  }

  Future<void> _resyncFromLocalAndServer({required String trigger}) async {
    if (!mounted ||
        _isPaused ||
        _isEndBrewAnimating ||
        brewingSteps.isEmpty ||
        _manualOverrideEngaged) {
      return;
    }
    if (_isResyncInProgress) return;

    _isResyncInProgress = true;
    try {
      final localState = _buildLocalResyncState();
      final localWasAhead = _applyResyncStateIfAhead(
        localState,
        source: 'local',
        trigger: trigger,
      );
      if (localState.isFinished) return;

      if (!_shouldSyncLiveActivitySession || _brewSessionId == null) {
        if (!localWasAhead) {
          AppLogger.debug(
            'Live activity resync [$trigger] local state already current',
          );
        }
        return;
      }

      final backendStatus = await _liveActivitySyncService.fetchSessionStatus(
        brewSessionId: _brewSessionId!,
      );

      if (backendStatus == null) {
        AppLogger.debug(
          'Live activity resync [$trigger] backend status unavailable',
        );
        return;
      }

      AppLogger.debug(
        'Live activity resync [$trigger] local=${localState.stepIndex + 1}/${brewingSteps.length} '
        'local_elapsed=${localState.stepElapsedSeconds}s backend=${backendStatus.currentStep}/${backendStatus.totalSteps} '
        'backend_elapsed=${backendStatus.stepElapsedSeconds}s backend_finished=${backendStatus.isFinished}',
      );

      final backendState = _buildResyncStateFromBackend(backendStatus);
      _applyResyncStateIfAhead(
        backendState,
        source: 'backend',
        trigger: trigger,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to resync brewing state on app resume',
        errorObject: e,
      );
    } finally {
      _isResyncInProgress = false;
    }
  }

  _BrewingResyncState _buildLocalResyncState() {
    final nowUtc = DateTime.now().toUtc();
    final stepStartUtc =
        _currentStepStartedAtUtc ??
        nowUtc.subtract(Duration(seconds: currentStepTime));

    final elapsedBeforeCurrentStep = brewingSteps
        .take(currentStepIndex)
        .fold<int>(0, (sum, step) => sum + step.time.inSeconds);
    final brewStartUtc =
        _brewAnchorUtc ??
        stepStartUtc.subtract(Duration(seconds: elapsedBeforeCurrentStep));
    _brewAnchorUtc ??= brewStartUtc;
    final elapsedTotalSeconds = math.max(
      0,
      nowUtc.difference(brewStartUtc).inSeconds,
    );

    return _buildResyncStateFromElapsedTotal(elapsedTotalSeconds);
  }

  _BrewingResyncState _buildResyncStateFromBackend(
    LiveActivitySessionStatus status,
  ) {
    if (status.isFinished || brewingSteps.isEmpty) {
      return const _BrewingResyncState(isFinished: true);
    }

    final maxIndex = brewingSteps.length - 1;
    final clampedIndex = (status.currentStep - 1).clamp(0, maxIndex).toInt();
    final stepTotal = brewingSteps[clampedIndex].time.inSeconds;
    final clampedElapsed = status.stepElapsedSeconds
        .clamp(0, stepTotal)
        .toInt();

    return _BrewingResyncState(
      stepIndex: clampedIndex,
      stepElapsedSeconds: clampedElapsed,
      isFinished: false,
    );
  }

  _BrewingResyncState _buildResyncStateFromElapsedTotal(
    int elapsedTotalSeconds,
  ) {
    if (brewingSteps.isEmpty) {
      return const _BrewingResyncState(isFinished: true);
    }

    final totalDurationSeconds = brewingSteps.fold<int>(
      0,
      (sum, step) => sum + step.time.inSeconds,
    );
    if (elapsedTotalSeconds >= totalDurationSeconds) {
      return const _BrewingResyncState(isFinished: true);
    }

    var stepIndex = 0;
    var remaining = elapsedTotalSeconds;
    while (stepIndex < brewingSteps.length - 1 &&
        remaining >= brewingSteps[stepIndex].time.inSeconds) {
      remaining -= brewingSteps[stepIndex].time.inSeconds;
      stepIndex++;
    }

    final stepTotal = brewingSteps[stepIndex].time.inSeconds;
    final stepElapsed = remaining.clamp(0, stepTotal).toInt();

    return _BrewingResyncState(
      stepIndex: stepIndex,
      stepElapsedSeconds: stepElapsed,
      isFinished: false,
    );
  }

  bool _applyResyncStateIfAhead(
    _BrewingResyncState state, {
    required String source,
    required String trigger,
  }) {
    if (state.isFinished) {
      _finishFromResync(source: source, trigger: trigger);
      return true;
    }

    final isAheadStep = state.stepIndex > currentStepIndex;
    final isAheadElapsed =
        state.stepIndex == currentStepIndex &&
        state.stepElapsedSeconds > currentStepTime + 1;
    if (!isAheadStep && !isAheadElapsed) return false;

    if (!mounted) return false;

    setState(() {
      currentStepIndex = state.stepIndex;
      currentStepTime = state.stepElapsedSeconds;
    });
    _maybeEmitLastStepReached();
    _currentStepStartedAtUtc = DateTime.now().toUtc().subtract(
      Duration(seconds: state.stepElapsedSeconds),
    );
    final elapsedBeforeResyncedStep = brewingSteps
        .take(state.stepIndex)
        .fold<int>(0, (sum, step) => sum + step.time.inSeconds);
    _brewAnchorUtc = _currentStepStartedAtUtc!.subtract(
      Duration(seconds: elapsedBeforeResyncedStep),
    );
    _pausedAtUtc = null;
    _updateLiveActivity();

    AppLogger.info(
      'Live activity hard jump [$trigger][$source] '
      '-> step=${state.stepIndex + 1}/${brewingSteps.length}, '
      'elapsed=${state.stepElapsedSeconds}s',
    );
    return true;
  }

  void _finishFromResync({required String source, required String trigger}) {
    if (_isEndBrewAnimating) return;

    timer.cancel();
    _endLiveActivity(reason: 'completed');
    if (!mounted || brewingSteps.isEmpty) return;

    setState(() {
      // Capture the arc where the ring actually was — before both the jump
      // to the last step and the flag, either of which forces
      // _currentArcProgress to 1.0 and turns the sweep into a snap.
      _endArcStartValue = _currentArcProgress;
      currentStepIndex = brewingSteps.length - 1;
      currentStepTime = brewingSteps.last.time.inSeconds;
      _isEndBrewAnimating = true;
    });
    // A brew that resyncs straight to finished did reach the last step.
    _maybeEmitLastStepReached();
    _emitBrewFinished('resync');
    _endBrewAnimationController.duration = _endSequenceDuration;
    _endBrewAnimationController.forward(from: 0.0);

    AppLogger.info(
      'Live activity resync [$trigger][$source] marked brew as completed',
    );
  }

  Future<void> _skipLastStep() async {
    // Only allow skipping on the last step
    if (currentStepIndex != brewingSteps.length - 1 || _isEndBrewAnimating) {
      return;
    }

    // Capture timing values before any state mutation.
    final secondsIntoStep = currentStepTime;
    final secondsRemaining = math.max(
      0,
      brewingSteps[currentStepIndex].time.inSeconds - currentStepTime,
    );
    AnalyticsService.instance.track(
      'last_step_skipped',
      properties: {
        'recipe_id': widget.recipe.id,
        'total_steps': brewingSteps.length,
        'seconds_into_step': secondsIntoStep,
        'seconds_remaining': secondsRemaining,
      },
    );
    _emitBrewFinished('skip');

    timer.cancel();
    _playStepNotification();

    setState(() {
      // Arc first, flag second — see _currentArcProgress. On this path the
      // ring is genuinely mid-step, so this is the sweep the user sees.
      _endArcStartValue = _currentArcProgress;
      _isEndBrewAnimating = true;
    });
    _endBrewAnimationController.duration = _endSequenceDuration;
    _endBrewAnimationController.forward(from: 0.0);
  }

  bool _shouldShowSkipButton() {
    // Show the finish button for the entire last step, from the moment it
    // starts (prototype: immediate swap, no five-second delay).
    return currentStepIndex == brewingSteps.length - 1 &&
        !_isEndBrewAnimating;
  }

  /// The arc fraction the ring shows in the normal state — full once the
  /// step time is up (or the end sequence is running), otherwise
  /// elapsed/total. Mirrors the value logic of the CircularProgressIndicator
  /// that BrewTimerRing replaces (plan 061 B1).
  double get _currentArcProgress {
    final int stepTotalSeconds = brewingSteps[currentStepIndex].time.inSeconds;
    if (_isEndBrewAnimating || currentStepTime >= stepTotalSeconds) {
      return 1.0;
    }
    return stepTotalSeconds > 0 ? currentStepTime / stepTotalSeconds : 0.0;
  }

  // Tear the Live Activity / backend session down once, the first time the
  // user takes manual control. A manual jump invalidates the wall-clock
  // projection that the Live Activity, backend push, and resync rely on.
  void _engageManualOverride() {
    if (_manualOverrideEngaged) return;
    _manualOverrideEngaged = true;
    _endLiveActivity(reason: 'manual_control');
  }

  void _recomputeAnchorsForStep(int stepIndex, DateTime nowUtc) {
    _currentStepStartedAtUtc = nowUtc;
    final elapsedBeforeStep = brewingSteps
        .take(stepIndex)
        .fold<int>(0, (sum, step) => sum + step.time.inSeconds);
    _brewAnchorUtc = nowUtc.subtract(Duration(seconds: elapsedBeforeStep));
  }

  void _goToNextStepManually() {
    if (_isEndBrewAnimating) return;
    _engageManualOverride();

    if (currentStepIndex < brewingSteps.length - 1) {
      timer.cancel();
      setState(() {
        currentStepIndex++;
        currentStepTime = 0;
      });
      _maybeEmitLastStepReached();
      _recomputeAnchorsForStep(currentStepIndex, DateTime.now().toUtc());
      if (!_isPaused) {
        startTimer();
      }
    } else {
      // Next on the last step finishes the brew (same path as auto-finish).
      // Not one of the three paths enumerated in plan 042 A1, but it is a
      // real brew-ending path (manual step control, Advanced/Beta feature)
      // and omitting it would corrupt the brew_finished/brew_completed
      // measurement this event exists to support — see final report.
      timer.cancel();
      setState(() {
        // Arc first, flag second — see _currentArcProgress. Like the skip
        // path, the ring is mid-step here and should sweep, not snap.
        _endArcStartValue = _currentArcProgress;
        _isEndBrewAnimating = true;
      });
      _emitBrewFinished('manual_next');
      _endBrewAnimationController.duration = _endSequenceDuration;
      _endBrewAnimationController.forward(from: 0.0);
    }
  }

  void _goToPreviousStepManually() {
    if (_isEndBrewAnimating || currentStepIndex == 0) return;
    _engageManualOverride();

    timer.cancel();
    final nowUtc = DateTime.now().toUtc();
    setState(() {
      currentStepIndex--;
      currentStepTime = 0;
      _isPaused = true;
    });
    _recomputeAnchorsForStep(currentStepIndex, nowUtc);
    _pausedAtUtc = nowUtc;
  }

  Widget _buildManualStepArrow({required bool isBack}) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // In RTL the chevrons are visually mirrored.
    final pointsLeft = isBack ? !isRtl : isRtl;
    final isDisabled = isBack && currentStepIndex == 0;
    return Semantics(
      identifier: isBack ? 'previousStepButton' : 'nextStepButton',
      child: IconButton(
        tooltip: isBack ? loc.previousStep : loc.nextStep,
        iconSize: AppIconSize.large,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.2),
        onPressed: isDisabled
            ? null
            : (isBack ? _goToPreviousStepManually : _goToNextStepManually),
        icon: Icon(pointsLeft ? Icons.chevron_left : Icons.chevron_right),
      ),
    );
  }

  // Vertical room the next-step preview leaves below itself so it never
  // overlaps the floating pause/skip button: FAB height (56) + the FAB's
  // margin above the safe area (kFloatingActionButtonMargin) + a small gap.
  static const double _bottomControlClearance =
      56.0 + kFloatingActionButtonMargin + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    // Re-read every frame so the end sequence (and its route) always sees the
    // current OS reduced-motion setting (plan 061 R4).
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final manualStepControlEnabled = context
        .watch<AdvancedFeaturesService>()
        .manualStepControlEnabled;
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'brewingProcessTitle',
          child: Text(
            '${AppLocalizations.of(context)!.step} ${intl.NumberFormat().format(currentStepIndex + 1)}/${intl.NumberFormat().format(brewingSteps.length)}',
          ),
        ),
      ),
      // Tap anywhere to skip the end sequence (plan 061 R5). The behaviour
      // must be conditional: an opaque detector with a null onTap would still
      // absorb taps and deaden the pause/skip FAB during normal brewing.
      body: GestureDetector(
        behavior: _isEndBrewAnimating
            ? HitTestBehavior.opaque
            : HitTestBehavior.deferToChild,
        onTap: _isEndBrewAnimating ? _skipEndBrewAnimation : null,
        child: Stack(
          children: [
            Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Semantics(
                  identifier: 'brewingStepsContent',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (manualStepControlEnabled &&
                                    !_isEndBrewAnimating)
                                  _buildManualStepArrow(isBack: true),
                                Semantics(
                                  identifier: 'circularProgressIndicator',
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _pulseController,
                                      _endBrewAnimationController,
                                    ]),
                                    builder: (context, child) {
                                      final theme = Theme.of(context);

                                      // One ring colour for the whole brew.
                                      // The last three seconds of the final
                                      // step used to tween to a cherry red
                                      // and then back again; that flash read
                                      // as an error rather than a countdown,
                                      // so the warning colour is gone. The
                                      // scale pulse still marks the final
                                      // seconds.
                                      final Color ringColor =
                                          theme.colorScheme.secondary;

                                      final ringDiameter =
                                          brewTimerRingDiameterForWidth(
                                            MediaQuery.sizeOf(context).width,
                                          );

                                      final Color trackColor =
                                          theme.brightness == Brightness.dark
                                          ? const Color(0xFF5A5A5A)
                                          : const Color(0xFFE4E4E4);

                                      final Widget countdownContent =
                                          Semantics(
                                            identifier: 'stepTimeCounter',
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                LocalizedNumberText(
                                                  currentNumber:
                                                      currentStepTime,
                                                  totalNumber:
                                                      brewingSteps[currentStepIndex]
                                                          .time
                                                          .inSeconds,
                                                  style: TextStyle(
                                                    fontSize: ringDiameter / 6,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  ' ${AppLocalizations.of(context)!.secondsAbbreviation}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        ringDiameter / 7.5,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                      // Plan 061 Direction B. The widget
                                      // type at this tree position stays
                                      // BrewTimerRing in every state (R3);
                                      // the end sequence only changes the
                                      // values handed to its painter. All
                                      // end values derive from the one
                                      // master controller (R1), and the
                                      // ring keeps the normal secondary
                                      // colour — cherry stays reserved for
                                      // the last-3-seconds warning above
                                      // (R6).
                                      final Widget progressIndicatorDisplay;
                                      if (_isEndBrewAnimating) {
                                        final double arc = _reduceMotion
                                            ? 1.0
                                            : lerpDouble(
                                                _endArcStartValue,
                                                1.0,
                                                _endArc.value,
                                              )!;
                                        final double fillLevel = _reduceMotion
                                            ? 1.0
                                            : _endFill.value;
                                        final double wavePhase =
                                            _endBrewAnimationController.value *
                                                4 *
                                                math.pi;
                                        final double waveAmplitude =
                                            _reduceMotion
                                            ? 0.0
                                            : ringDiameter *
                                                0.045 *
                                                (1 - _endAmplitudeDecay.value);
                                        progressIndicatorDisplay =
                                            BrewTimerRing(
                                          diameter: ringDiameter,
                                          progress: arc,
                                          fillLevel: fillLevel,
                                          wavePhase: wavePhase,
                                          waveAmplitude: waveAmplitude,
                                          ringColor: ringColor,
                                          trackColor: trackColor,
                                          fillColor: AppBrewColors.brewFill(
                                            theme.colorScheme,
                                          ),
                                          strokeWidth: 8,
                                          countdownOpacity: _reduceMotion
                                              ? 0.0
                                              : 1 - _endCountdownFade.value,
                                          countdown: countdownContent,
                                        );
                                      } else {
                                        progressIndicatorDisplay =
                                            BrewTimerRing(
                                          diameter: ringDiameter,
                                          progress: _currentArcProgress,
                                          fillLevel: 0,
                                          wavePhase: 0,
                                          waveAmplitude: 0,
                                          ringColor: ringColor,
                                          trackColor: trackColor,
                                          fillColor: AppBrewColors.brewFill(
                                            theme.colorScheme,
                                          ),
                                          strokeWidth: 8,
                                          countdownOpacity: 1.0,
                                          countdown: countdownContent,
                                        );
                                      }

                                      final bool
                                      enablePulse = // Pulsation continues during color change, stops for end animation
                                          !_isEndBrewAnimating &&
                                          (brewingSteps[currentStepIndex]
                                                          .time
                                                          .inSeconds -
                                                      currentStepTime <=
                                                  5 &&
                                              brewingSteps[currentStepIndex]
                                                          .time
                                                          .inSeconds -
                                                      currentStepTime >=
                                                  0);

                                      // The closing accord (plan 061,
                                      // operator request 2026-09-15): once the
                                      // liquid has settled, the filled cup
                                      // swells a touch and collapses away, so
                                      // the sequence ends on a beat instead of
                                      // just stopping. Driven from the same
                                      // master controller as everything else
                                      // (R1) and applied as values on the
                                      // always-present Transform/Opacity pair,
                                      // never by swapping widgets (R3).
                                      final double accordScale =
                                          _isEndBrewAnimating && !_reduceMotion
                                          ? lerpDouble(
                                              1.0,
                                              0.5,
                                              _endAccord.value,
                                            )!
                                          : 1.0;
                                      final double accordOpacity =
                                          _isEndBrewAnimating && !_reduceMotion
                                          ? (1.0 - _endAccordFade.value).clamp(
                                              0.0,
                                              1.0,
                                            )
                                          : 1.0;

                                      return Opacity(
                                        opacity: accordOpacity,
                                        child: Transform.scale(
                                          scale:
                                              (enablePulse
                                                  ? _pulseAnimation.value
                                                  : 1.0) *
                                              accordScale,
                                          child: progressIndicatorDisplay,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (manualStepControlEnabled &&
                                    !_isEndBrewAnimating)
                                  _buildManualStepArrow(isBack: false),
                              ],
                            ),
                            // Explicit paused state text; the FAB only
                            // changes its icon when the brew is paused.
                            if (_isPaused && !_isEndBrewAnimating) ...[
                              const SizedBox(height: AppSpacing.sm),
                              BrewPausedLabel(
                                label:
                                    AppLocalizations.of(context)!
                                        .liveActivityPaused,
                              ),
                            ],
                            SizedBox(
                              height:
                                  (MediaQuery.of(context).size.height * 0.05)
                                      .clamp(24.0, 48.0),
                            ),
                            Container(
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height * 0.15,
                              ),
                              child: Semantics(
                                identifier: 'brewingStepDescription',
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        (MediaQuery.of(context).size.width *
                                                0.08)
                                            .clamp(16.0, 32.0),
                                  ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: _isEndBrewAnimating
                                        ? const SizedBox.shrink()
                                        : Text(
                                            brewingSteps[currentStepIndex]
                                                .description,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 28,
                                              height: 1.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (currentStepIndex < brewingSteps.length - 1 &&
                  !_isEndBrewAnimating)
                Padding(
                  // Full content width above the bottom control area. The
                  // bottom inset clears the floating pause/skip button and
                  // the safe area; height is intrinsic, so two lines of
                  // larger text wrap instead of clipping.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    MediaQuery.of(context).padding.bottom +
                        _bottomControlClearance,
                  ),
                  child: NextStepPreview(
                    label: '${AppLocalizations.of(context)!.next}:',
                    description:
                        brewingSteps[currentStepIndex + 1].description,
                  ),
                ),
            ],
          ),
          ],
        ),
      ),
      floatingActionButton: _isEndBrewAnimating
          ? null
          : Semantics(
              identifier: _shouldShowSkipButton()
                  ? 'skipLastStepButton'
                  : 'togglePauseButton',
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: _shouldShowSkipButton()
                    ? FloatingActionButton.extended(
                        key: ValueKey<bool>(_shouldShowSkipButton()),
                        onPressed: () async => await _skipLastStep(),
                        icon: const Icon(Icons.skip_next),
                        label: Text(
                          AppLocalizations.of(context)!.brewingSkipStepLabel,
                        ),
                      )
                    : FloatingActionButton(
                        key: ValueKey<bool>(_shouldShowSkipButton()),
                        onPressed: _togglePause,
                        child: Icon(
                          _isPaused
                              ? (Directionality.of(context) == TextDirection.rtl
                                    ? Icons.arrow_back_ios_new
                                    : Icons.play_arrow)
                              : Icons.pause,
                        ),
                      ),
              ),
            ),
    );
  }
}

class _BrewingResyncState {
  const _BrewingResyncState({
    this.stepIndex = 0,
    this.stepElapsedSeconds = 0,
    this.isFinished = false,
  });

  final int stepIndex;
  final int stepElapsedSeconds;
  final bool isFinished;
}
