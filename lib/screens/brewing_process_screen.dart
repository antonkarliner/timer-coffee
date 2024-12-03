import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import 'finish_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

class _BrewingProcessScreenState extends State<BrewingProcessScreen> {
  late List<BrewStepModel> brewingSteps;
  int currentStepIndex = 0;
  int currentStepTime = 0;
  late Timer timer;
  bool _isPaused = false;
  final _player = AudioPlayer();
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
      String variable = match.group(1)!;
      return allValues.containsKey(variable)
          ? allValues[variable]!.toStringAsFixed(2)
          : match.group(0)!;
    });

    // Handle mathematical expressions like (multiplier x value)
    RegExp mathExp = RegExp(r'\(([\d.]+) x ([\d.]+)\)');
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
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (currentStepTime >= brewingSteps[currentStepIndex].time.inSeconds) {
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
          Navigator.push(
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
      } else {
        setState(() {
          currentStepTime++;
        });
      }
    });
  }

  void _togglePause() {
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
          child: Text(AppLocalizations.of(context)!.brewingprocess),
        ),
      ),
      body: Column(
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
                              identifier: 'currentStepLabel',
                              child: Text(
                                AppLocalizations.of(context)!.step + ' ',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            LocalizedNumberText(
                              currentNumber: currentStepIndex + 1,
                              totalNumber: brewingSteps.length,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          identifier: 'brewingStepDescription',
                          child: Text(
                            brewingSteps[currentStepIndex].description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    identifier: 'stepTimeCounter',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalizedNumberText(
                          currentNumber: currentStepTime,
                          totalNumber:
                              brewingSteps[currentStepIndex].time.inSeconds,
                          style: const TextStyle(fontSize: 22),
                        ),
                        Text(
                          ' ${AppLocalizations.of(context)!.seconds(brewingSteps[currentStepIndex].time.inSeconds)}',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (currentStepIndex < brewingSteps.length - 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16.0, 0, 88.0, 16.0), // Adjusted right padding
              child: Align(
                alignment: Alignment.centerLeft, // Align to the left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.next}:', // Added colon after "Next"
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
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Semantics(
              identifier: 'linearProgressIndicator',
              child: LinearProgressIndicator(
                value: brewingSteps[currentStepIndex].time.inSeconds > 0
                    ? currentStepTime /
                        brewingSteps[currentStepIndex].time.inSeconds
                    : 0,
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
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
