import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
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
  final Recipe recipe;
  final double coffeeAmount;
  final double waterAmount;
  final bool soundEnabled;

  const BrewingProcessScreen({
    super.key,
    required this.recipe,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.soundEnabled,
  });

  @override
  State<BrewingProcessScreen> createState() => _BrewingProcessScreenState();
}

class _BrewingProcessScreenState extends State<BrewingProcessScreen> {
  late List<BrewStep> brewingSteps;
  int currentStepIndex = 0;
  int currentStepTime = 0;
  late Timer timer;
  bool _isPaused = false;
  final _player = AudioPlayer();

  String replacePlaceholders(
    String description,
    double coffeeAmount,
    double waterAmount,
  ) {
    RegExp exp = RegExp(
        r'\(([\d.]+) x <(coffee_amount|water_amount|final_coffee_amount|final_water_amount)>\)');
    String replacedText = description.replaceAllMapped(exp, (match) {
      double multiplier = double.parse(match.group(1)!);
      String variable = match.group(2)!;
      double result;

      if (variable == 'coffee_amount' || variable == 'final_coffee_amount') {
        result = multiplier * coffeeAmount;
      } else {
        result = multiplier * waterAmount;
      }

      return result.toStringAsFixed(1);
    });

    replacedText = replacedText
        .replaceAll('<coffee_amount>', coffeeAmount.toStringAsFixed(1))
        .replaceAll('<water_amount>', waterAmount.toStringAsFixed(1))
        .replaceAll('<final_coffee_amount>', coffeeAmount.toStringAsFixed(1))
        .replaceAll('<final_water_amount>', waterAmount.toStringAsFixed(1));

    return replacedText;
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    brewingSteps = widget.recipe.steps
        .map((step) => BrewStep(
              order: step.order,
              description: replacePlaceholders(
                step.description,
                widget.coffeeAmount,
                widget.waterAmount,
              ),
              time: step.time,
            ))
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
                  brewingMethodName: widget.recipe.brewingMethodName),
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
