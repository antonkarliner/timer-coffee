import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'dart:math' as math; // Added for math functions
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for animations
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import 'finish_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl; // Corrected import statement

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
      child: Text(
        formattedText,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BrewingProcessScreen extends StatefulWidget {
  final RecipeModel recipe;
  final double coffeeAmount;
  final double waterAmount;
  final bool soundEnabled;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final String brewingMethodName;
  final int? coffeeChroniclerSliderPosition;

  const BrewingProcessScreen({
    Key? key,
    required this.recipe,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.soundEnabled,
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
        // Using print for simple logging as seen elsewhere in the project
        print(
            "Warning: Unrecognized placeholder '${match.group(0)}' in step description. Raw description: '$description'");
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
      allTimeValues
          .addAll(coffeeChroniclerTimeValues[coffeeChroniclerSliderPosition]);
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

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
    startTimer();
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
    WakelockPlus.disable();
    _player.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    _endBrewAnimationController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _navigateToFinishScreen() {
    // Ensure it only navigates once and if mounted
    if (!mounted || !_isEndBrewAnimating) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FinishScreen(
            brewingMethodName: widget.brewingMethodName,
            recipe: widget.recipe,
            waterAmount: widget.waterAmount,
            coffeeAmount: widget.coffeeAmount,
            sweetnessSliderPosition: widget.sweetnessSliderPosition,
            strengthSliderPosition: widget.strengthSliderPosition),
      ),
    );
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final stepDuration = brewingSteps[currentStepIndex].time.inSeconds;
      final last5Start = stepDuration - 5;
      if (currentStepTime >= stepDuration) {
        if (currentStepIndex < brewingSteps.length - 1) {
          if (widget.soundEnabled) {
            await _player.setAsset('assets/audio/next.mp3');
            _player.play();
          }
          setState(() {
            currentStepIndex++;
            currentStepTime = 0;
          });
        } else {
          if (widget.soundEnabled) {
            await _player.setAsset('assets/audio/next.mp3');
            _player.play();
          }
          timer.cancel();
          // Instead of navigating directly, trigger the end brew animation
          setState(() {
            _isEndBrewAnimating = true;
          });
          _endBrewAnimationController.forward(from: 0.0);
          // _navigateToFinishScreen() will be called by the controller's status listener
        }
      } else {
        setState(() {
          currentStepTime++;
        });
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
            // Check _isEndBrewAnimating here too
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
    } else {
      startTimer();
    }
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
                                    animation: Listenable.merge(
                                        [_pulseController, _colorController]),
                                    builder: (context, child) {
                                      final theme = Theme.of(context);
                                      final isFinalStep = currentStepIndex ==
                                          brewingSteps.length - 1;
                                      final remaining =
                                          brewingSteps[currentStepIndex]
                                                  .time
                                                  .inSeconds -
                                              currentStepTime;
                                      final isLast3 = isFinalStep &&
                                          remaining < 3 &&
                                          remaining >= 0 &&
                                          !_isEndBrewAnimating;

                                      final Color beginColor =
                                          theme.colorScheme.secondary;
                                      final Color endColor =
                                          theme.brightness == Brightness.dark
                                              ? const Color(
                                                  0xffc66564) // Cherry (dark)
                                              : const Color(
                                                  0xff8e2e2d); // Cherry (light)

                                      final colorTween = ColorTween(
                                          begin: beginColor, end: endColor);

                                      final Color currentRingColor = (isLast3
                                          ? (colorTween
                                                  .evaluate(_colorController) ??
                                              beginColor)
                                          : beginColor);

                                      Widget progressIndicatorDisplay =
                                          SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 120,
                                              height: 120,
                                              child: CircularProgressIndicator(
                                                value: (_isEndBrewAnimating ||
                                                        currentStepTime >=
                                                            brewingSteps[
                                                                    currentStepIndex]
                                                                .time
                                                                .inSeconds)
                                                    ? 1.0
                                                    : (brewingSteps[currentStepIndex]
                                                                .time
                                                                .inSeconds >
                                                            0
                                                        ? currentStepTime /
                                                            brewingSteps[
                                                                    currentStepIndex]
                                                                .time
                                                                .inSeconds
                                                        : 0),
                                                backgroundColor: theme
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF5A5A5A)
                                                    : const Color(0xFFE4E4E4),
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        _isEndBrewAnimating
                                                            ? endColor
                                                            : currentRingColor),
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
                                                      totalNumber: brewingSteps[
                                                              currentStepIndex]
                                                          .time
                                                          .inSeconds,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: theme.colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    Text(
                                                      ' ${AppLocalizations.of(context)!.secondsAbbreviation}',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: theme.colorScheme
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

                                        List<Widget> dropletWidgets =
                                            List.generate(numDroplets, (i) {
                                          final double angle =
                                              (i / numDroplets) * 2 * math.pi;
                                          return Animate(
                                            onPlay: (controller) =>
                                                controller.forward(),
                                            delay: const Duration(
                                                milliseconds:
                                                    200), // All droplets start after 200ms
                                            effects: [
                                              FadeEffect(
                                                  duration: 50.milliseconds,
                                                  begin: 0.0,
                                                  end: 1.0), // Initial fade in
                                              MoveEffect(
                                                begin: Offset(
                                                    math.cos(angle) *
                                                        initialRingRadius,
                                                    math.sin(angle) *
                                                        initialRingRadius),
                                                end: Offset.zero,
                                                duration: 800.milliseconds,
                                                curve: Curves.easeOutQuart,
                                              ),
                                              ScaleEffect(
                                                  begin: const Offset(1, 1),
                                                  end: const Offset(0.2, 0.2),
                                                  duration: 800.milliseconds,
                                                  curve: Curves.easeOut),
                                              FadeEffect(
                                                  begin: 1.0,
                                                  end: 0.0,
                                                  duration: 700.milliseconds,
                                                  curve: Curves.easeIn,
                                                  delay: 100.milliseconds),
                                            ],
                                            child: Container(
                                              width: dropletStartSize,
                                              height: dropletStartSize,
                                              decoration: BoxDecoration(
                                                  color: dropletColor,
                                                  shape: BoxShape.circle),
                                            ),
                                          );
                                        });

                                        progressIndicatorDisplay = Animate(
                                          onPlay: (controller) =>
                                              controller.forward(),
                                          effects: [
                                            ShakeEffect(
                                                hz: 12,
                                                duration: 300.milliseconds,
                                                curve: Curves.easeInOut),
                                            FadeEffect(
                                                begin: 1.0,
                                                end: 0.0,
                                                delay: 1400.milliseconds,
                                                duration: 400.milliseconds),
                                            ScaleEffect(
                                                delay: 1400.milliseconds,
                                                begin: const Offset(1, 1),
                                                end: const Offset(0.5, 0.5),
                                                duration: 400.milliseconds),
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
                                                fontSize: 28, height: 1.3),
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
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 88.0, 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.next}:',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          brewingSteps[currentStepIndex + 1].description,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
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
              identifier: 'togglePauseButton',
              child: FloatingActionButton(
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
    );
  }
}
