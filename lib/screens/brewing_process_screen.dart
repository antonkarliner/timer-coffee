import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'dart:io';
import 'dart:math' as math; // Added for math functions
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for system UI constants
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animations
import 'package:uuid/uuid.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import '../models/notification_mode.dart';
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

class LocalizedNumberText extends StatelessWidget {
  final int currentNumber;
  final int totalNumber;
  final TextStyle? style;

  const LocalizedNumberText({
    Key? key,
    required this.currentNumber,
    required this.totalNumber,
    this.style,
  }) : super(key: key);

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
    Key? key,
    required this.recipe,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.notificationMode,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
    required this.brewingMethodName,
    this.coffeeChroniclerSliderPosition,
  }) : super(key: key);

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

  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  late AnimationController
  _endBrewAnimationController; // For end of brew animation
  bool _isEndBrewAnimating = false; // Flag for end of brew animation state

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
  bool _backendLiveActivitySessionStarted = false;
  bool _isStartingLiveActivityBackendSession = false;
  bool _isResyncInProgress = false;
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
    Map<String, double> allValues = {
      'coffee_amount': coffeeAmount,
      'water_amount': waterAmount,
      'final_coffee_amount': coffeeAmount,
      'final_water_amount': waterAmount,
    };

    // Handle sweetness values if applicable
    if (sweetnessSliderPosition != null) {
      List<Map<String, double>> sweetnessValues = [
        {"m1": 0.16, "m2": 0.4}, // Sweetness
        {"m1": 0.20, "m2": 0.4}, // Balance
        {"m1": 0.24, "m2": 0.4}, // Acidity
      ];
      allValues.addAll(sweetnessValues[sweetnessSliderPosition]);
    }

    // Handle strength values if applicable
    if (strengthSliderPosition != null) {
      List<Map<String, double>> strengthValues = [
        {"m3": 1.0, "m4": 0, "m5": 0}, // Light
        {"m3": 0.7, "m4": 1.0, "m5": 0}, // Balanced
        {"m3": 0.6, "m4": 0.8, "m5": 1.0}, // Strong
      ];
      allValues.addAll(strengthValues[strengthSliderPosition]);
    }

    // Handle coffeeChroniclerSwitchSlider values if applicable
    if (coffeeChroniclerSliderPosition != null) {
      List<Map<String, double>> coffeeChroniclerValues = [
        {'t7': 30.0, 't8': 55.0}, // Standard
        {'t7': 45.0, 't8': 70.0}, // Medium
        {'t7': 75.0, 't8': 55.0}, // XL
      ];
      allValues.addAll(coffeeChroniclerValues[coffeeChroniclerSliderPosition]);
    }

    // Replace placeholders in the description
    RegExp exp = RegExp(r'<([\w_]+)>');
    String replacedText = description.replaceAllMapped(exp, (match) {
      String variable = match.group(1)!.toLowerCase(); // Convert to lowercase
      if (allValues.containsKey(variable)) {
        return allValues[variable]!.toStringAsFixed(2);
      } else {
        // Using AppLogger for simple logging
        AppLogger.warning(
          "Unrecognized placeholder '${match.group(0)}' in step description. Raw description: '$description'",
        );
        return match.group(0)!; // Keep original placeholder
      }
    });

    // Handle mathematical expressions like (multiplier x value)
    RegExp mathExp = RegExp(r'\(([\d.]+)\s*(?:x|×)\s*([\d.]+)\)');
    replacedText = replacedText.replaceAllMapped(mathExp, (match) {
      double multiplier = double.parse(match.group(1)!);
      double value = double.parse(match.group(2)!);
      return (multiplier * value).toStringAsFixed(1);
    });

    return replacedText;
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

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // ColorTween will be set dynamically in build

    _endBrewAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // Adjusted duration
    );
    _endBrewAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToFinishScreen();
      }
    });

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
    timer.cancel();
    unawaited(IosBackgroundTaskService.instance.stopBrewingTask());
    _stopLiveActivityBackendSessionRetryLoop();
    _liveActivityTokenSubscription?.cancel();
    _lifecycleListener?.dispose();
    WakelockPlus.disable();
    _player.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    _endBrewAnimationController.dispose();
    super.dispose();
  }

  void _navigateToFinishScreen() {
    // Ensure it only navigates once and if mounted
    if (!mounted || !_isEndBrewAnimating) return;
    _endLiveActivity(reason: 'completed');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FinishScreen(
          brewingMethodName: widget.brewingMethodName,
          recipe: widget.recipe,
          waterAmount: widget.waterAmount,
          coffeeAmount: widget.coffeeAmount,
          sweetnessSliderPosition: widget.sweetnessSliderPosition,
          strengthSliderPosition: widget.strengthSliderPosition,
        ),
      ),
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
          _currentStepStartedAtUtc = DateTime.now().toUtc();
          _updateLiveActivity();
        } else {
          _playStepNotification();

          timer.cancel();
          _endLiveActivity(reason: 'completed');
          setState(() {
            _isEndBrewAnimating = true;
          });
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
        // Color tween logic: last 3 seconds of final step
        if (!_isEndBrewAnimating &&
            currentStepIndex == brewingSteps.length - 1 &&
            (stepDuration - currentStepTime) < 3 &&
            (stepDuration - currentStepTime) >= 0) {
          if (!_colorController.isAnimating && _colorController.value == 0.0) {
            _colorController.forward();
          }
        } else {
          if (_colorController.value != 0.0 && !_isEndBrewAnimating) {
            _colorController.reverse();
          }
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
        currentStep: args['currentStep'],
        totalSteps: args['totalSteps'],
        stepElapsedSeconds: args['stepElapsedSeconds'],
        stepTotalSeconds: args['stepTotalSeconds'],
        isPaused: args['isPaused'],
      );
    }
  }

  void _updateLiveActivity({bool isTimerTick = false}) {
    if (!_isLiveActivitySupported) return;
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

    return {
      'recipeName': widget.recipe.name,
      'stepDescription': brewingSteps[currentStepIndex].description,
      'currentStep': currentStepIndex + 1,
      'totalSteps': brewingSteps.length,
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
    if (!mounted || _isPaused || _isEndBrewAnimating || brewingSteps.isEmpty) {
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
      currentStepIndex = brewingSteps.length - 1;
      currentStepTime = brewingSteps.last.time.inSeconds;
      _isEndBrewAnimating = true;
    });
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

    timer.cancel();
    _playStepNotification();

    setState(() {
      _isEndBrewAnimating = true;
    });
    _endBrewAnimationController.forward(from: 0.0);
  }

  bool _shouldShowSkipButton() {
    // Show skip button only on last step and after first 5 seconds
    return currentStepIndex == brewingSteps.length - 1 &&
        currentStepTime >= 5 &&
        !_isEndBrewAnimating;
  }

  void _navigateToFinishScreenSkip() {
    // Ensure it only navigates once and if mounted
    if (!mounted) return;
    _endLiveActivity(reason: 'completed');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FinishScreen(
          brewingMethodName: widget.brewingMethodName,
          recipe: widget.recipe,
          waterAmount: widget.waterAmount,
          coffeeAmount: widget.coffeeAmount,
          sweetnessSliderPosition: widget.sweetnessSliderPosition,
          strengthSliderPosition: widget.strengthSliderPosition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'brewingProcessTitle',
          child: Text(
            '${AppLocalizations.of(context)!.step} ${intl.NumberFormat().format(currentStepIndex + 1)}/${intl.NumberFormat().format(brewingSteps.length)}',
          ),
        ),
      ),
      body: Stack(
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
                                Semantics(
                                  identifier: 'circularProgressIndicator',
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _pulseController,
                                      _colorController,
                                    ]),
                                    builder: (context, child) {
                                      final theme = Theme.of(context);
                                      final isFinalStep =
                                          currentStepIndex ==
                                          brewingSteps.length - 1;
                                      final remaining =
                                          brewingSteps[currentStepIndex]
                                              .time
                                              .inSeconds -
                                          currentStepTime;
                                      final isLast3 =
                                          isFinalStep &&
                                          remaining < 3 &&
                                          remaining >= 0 &&
                                          !_isEndBrewAnimating;

                                      final Color beginColor =
                                          theme.colorScheme.secondary;
                                      final Color endColor =
                                          theme.brightness == Brightness.dark
                                          ? const Color(
                                              0xffc66564,
                                            ) // Cherry (dark)
                                          : const Color(
                                              0xff8e2e2d,
                                            ); // Cherry (light)

                                      final colorTween = ColorTween(
                                        begin: beginColor,
                                        end: endColor,
                                      );

                                      final Color currentRingColor = (isLast3
                                          ? (colorTween.evaluate(
                                                  _colorController,
                                                ) ??
                                                beginColor)
                                          : beginColor);

                                      Widget
                                      progressIndicatorDisplay = SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 120,
                                              height: 120,
                                              child: CircularProgressIndicator(
                                                value:
                                                    (_isEndBrewAnimating ||
                                                        currentStepTime >=
                                                            brewingSteps[currentStepIndex]
                                                                .time
                                                                .inSeconds)
                                                    ? 1.0
                                                    : (brewingSteps[currentStepIndex]
                                                                  .time
                                                                  .inSeconds >
                                                              0
                                                          ? currentStepTime /
                                                                brewingSteps[currentStepIndex]
                                                                    .time
                                                                    .inSeconds
                                                          : 0),
                                                backgroundColor:
                                                    theme.brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF5A5A5A)
                                                    : const Color(0xFFE4E4E4),
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      _isEndBrewAnimating
                                                          ? endColor
                                                          : currentRingColor,
                                                    ),
                                                strokeWidth: 8,
                                              ),
                                            ),
                                            if (!_isEndBrewAnimating)
                                              Semantics(
                                                identifier: 'stepTimeCounter',
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    LocalizedNumberText(
                                                      currentNumber:
                                                          currentStepTime,
                                                      totalNumber:
                                                          brewingSteps[currentStepIndex]
                                                              .time
                                                              .inSeconds,
                                                      style: TextStyle(
                                                        fontSize: 20,
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
                                                        fontSize: 16,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      );

                                      if (_isEndBrewAnimating) {
                                        const int numDroplets = 10;
                                        final double dropletStartSize = 12.0;
                                        final Color dropletColor = endColor;
                                        final double initialRingRadius = 60.0;

                                        List<Widget>
                                        dropletWidgets = List.generate(
                                          numDroplets,
                                          (i) {
                                            final double angle =
                                                (i / numDroplets) * 2 * math.pi;
                                            return Animate(
                                              onPlay: (controller) =>
                                                  controller.forward(),
                                              delay: const Duration(
                                                milliseconds: 200,
                                              ), // All droplets start after 200ms
                                              effects: [
                                                FadeEffect(
                                                  duration: 50.milliseconds,
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ), // Initial fade in
                                                MoveEffect(
                                                  begin: Offset(
                                                    math.cos(angle) *
                                                        initialRingRadius,
                                                    math.sin(angle) *
                                                        initialRingRadius,
                                                  ),
                                                  end: Offset.zero,
                                                  duration: 800.milliseconds,
                                                  curve: Curves.easeOutQuart,
                                                ),
                                                ScaleEffect(
                                                  begin: const Offset(1, 1),
                                                  end: const Offset(0.2, 0.2),
                                                  duration: 800.milliseconds,
                                                  curve: Curves.easeOut,
                                                ),
                                                FadeEffect(
                                                  begin: 1.0,
                                                  end: 0.0,
                                                  duration: 700.milliseconds,
                                                  curve: Curves.easeIn,
                                                  delay: 100.milliseconds,
                                                ),
                                              ],
                                              child: Container(
                                                width: dropletStartSize,
                                                height: dropletStartSize,
                                                decoration: BoxDecoration(
                                                  color: dropletColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            );
                                          },
                                        );

                                        progressIndicatorDisplay = Animate(
                                          onPlay: (controller) =>
                                              controller.forward(),
                                          effects: [
                                            ShakeEffect(
                                              hz: 12,
                                              duration: 300.milliseconds,
                                              curve: Curves.easeInOut,
                                            ),
                                            FadeEffect(
                                              begin: 1.0,
                                              end: 0.0,
                                              delay: 1400.milliseconds,
                                              duration: 400.milliseconds,
                                            ),
                                            ScaleEffect(
                                              delay: 1400.milliseconds,
                                              begin: const Offset(1, 1),
                                              end: const Offset(0.5, 0.5),
                                              duration: 400.milliseconds,
                                            ),
                                          ],
                                          child: progressIndicatorDisplay,
                                        );

                                        progressIndicatorDisplay = Stack(
                                          alignment: Alignment.center,
                                          clipBehavior: Clip.none,
                                          children: [
                                            progressIndicatorDisplay,
                                            ...dropletWidgets,
                                          ],
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

                                      return Transform.scale(
                                        scale: enablePulse
                                            ? _pulseAnimation.value
                                            : 1.0,
                                        child: progressIndicatorDisplay,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
                  padding: EdgeInsets.fromLTRB(
                    16.0,
                    0,
                    88.0,
                    MediaQuery.of(context).padding.bottom + 16.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.next}:',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          brewingSteps[currentStepIndex + 1].description,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 22,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                child: FloatingActionButton(
                  key: ValueKey<bool>(_shouldShowSkipButton()),
                  onPressed: _shouldShowSkipButton()
                      ? () async => await _skipLastStep()
                      : _togglePause,
                  child: Icon(
                    _shouldShowSkipButton()
                        ? Icons.skip_next
                        : (_isPaused
                              ? (Directionality.of(context) == TextDirection.rtl
                                    ? Icons.arrow_back_ios_new
                                    : Icons.play_arrow)
                              : Icons.pause),
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
