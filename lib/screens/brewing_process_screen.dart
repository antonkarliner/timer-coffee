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

    return Text(
      formattedText,
      style: style,
      textAlign: TextAlign.center,
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

  const BrewingProcessScreen({
    Key? key,
    required this.recipe,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.soundEnabled,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
    required this.brewingMethodName,
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
    int sweetnessSliderPosition,
    int strengthSliderPosition,
  ) {
    // Define the values based on slider positions for sweetness and strength
    List<Map<String, double>> sweetnessValues = [
      {"m1": 0.16, "m2": 0.4}, // Sweetness
      {"m1": 0.20, "m2": 0.4}, // Balance
      {"m1": 0.24, "m2": 0.4}, // Acidity
    ];

    List<Map<String, double>> strengthValues = [
      {"m3": 1.0, "m4": 0, "m5": 0}, // Light
      {"m3": 0.7, "m4": 1.0, "m5": 0}, // Balanced
      {"m3": 0.6, "m4": 0.8, "m5": 1.0}, // Strong
    ];

    // Replace sweetness and strength placeholders
    Map<String, double> selectedSweetnessValues =
        sweetnessValues[sweetnessSliderPosition];
    Map<String, double> selectedStrengthValues =
        strengthValues[strengthSliderPosition];
    Map<String, double> allValues = {
      ...selectedSweetnessValues,
      ...selectedStrengthValues,
      'coffee_amount': coffeeAmount,
      'water_amount': waterAmount,
      'final_coffee_amount': coffeeAmount,
      'final_water_amount': waterAmount,
    };

    RegExp exp = RegExp(r'<([\w_]+)>');
    String replacedText = description.replaceAllMapped(exp, (match) {
      String variable = match.group(1)!;
      return allValues.containsKey(variable)
          ? allValues[variable]!.toStringAsFixed(2)
          : match.group(0)!;
    });

    // Handle mathematical expressions (e.g., "(0.8 x <final_water_amount>)")
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
    int strengthSliderPosition,
  ) {
    if (timeString == null) return time;

    // Define the mapping of placeholders to actual time values based on strengthSliderPosition
    List<Map<String, int>> strengthTimeValues = [
      // For strengthSliderPosition = 0
      {"t1": 10, "t2": 35, "t3": 0, "t4": 0, "t5": 0, "t6": 0},
      // For strengthSliderPosition = 1
      {"t1": 10, "t2": 35, "t3": 10, "t4": 35, "t5": 0, "t6": 0},
      // For strengthSliderPosition = 2
      {"t1": 10, "t2": 35, "t3": 10, "t4": 35, "t5": 10, "t6": 35},
    ];

    // Assume that the placeholder is in a predictable format, such as <t1> or <t2>, etc.
    RegExp exp = RegExp(r'<(t\d+)>');
    var matches = exp.allMatches(timeString);

    for (var match in matches) {
      String placeholder = match.group(1)!; // e.g., "t1", "t2"
      int? replacementTime =
          strengthTimeValues[strengthSliderPosition][placeholder];

      // If a replacement value was found, create a Duration object with it
      if (replacementTime != null && replacementTime > 0) {
        return Duration(seconds: replacementTime);
      }
    }

    return time; // Return the original time if no placeholders matched
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    // Use updated logic with step.timePlaceholder
    brewingSteps = widget.recipe.steps
        .map((step) {
          Duration stepDuration = replaceTimePlaceholder(
            step.time,
            step.timePlaceholder, // Use step.timePlaceholder for time placeholders
            widget.strengthSliderPosition, // Only pass strengthSliderPosition
          );

          String description = replacePlaceholders(
            step.description,
            widget.coffeeAmount,
            widget.waterAmount,
            widget.sweetnessSliderPosition,
            widget.strengthSliderPosition,
          );

          return BrewStepModel(
            order: step.order,
            description: description,
            time: stepDuration,
          );
        })
        .where((step) => step.time.inSeconds > 0)
        .toList(); // Ensure steps with meaningful duration are kept

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
                  recipe: widget.recipe, // Pass the recipe object
                  waterAmount: widget.waterAmount, // Pass the water amount
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.brewingprocess)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
                          Text(
                            AppLocalizations.of(context)!.step + ' ',
                            style: const TextStyle(fontSize: 20),
                          ),
                          LocalizedNumberText(
                            currentNumber: currentStepIndex + 1,
                            totalNumber: brewingSteps.length,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        brewingSteps[currentStepIndex].description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LinearProgressIndicator(
              value: brewingSteps[currentStepIndex].time.inSeconds > 0
                  ? currentStepTime /
                      brewingSteps[currentStepIndex].time.inSeconds
                  : 0,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePause,
        child: Icon(
          _isPaused
              ? (Directionality.of(context) == TextDirection.rtl
                  ? Icons
                      .arrow_back_ios_new // or another suitable RTL icon for play
                  : Icons.play_arrow) // default LTR play icon
              : Icons.pause, // pause icon remains the same
        ),
      ),
    );
  }
}
