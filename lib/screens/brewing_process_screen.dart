import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import 'finish_screen.dart';
import 'package:wakelock/wakelock.dart';

class BrewingProcessScreen extends StatefulWidget {
  final Recipe recipe;
  final double coffeeAmount;
  final double waterAmount;
  final bool soundEnabled; // new parameter

  const BrewingProcessScreen({
    super.key,
    required this.recipe,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.soundEnabled, // new initializer
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
  final _player = AudioPlayer(); // new player instance

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
    Wakelock.enable();
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
      print('Failed to load audio: $e');
    }
  }

  @override
  void dispose() {
    timer.cancel();
    Wakelock.disable();
    _player.dispose(); // dispose the player when the screen is disposed
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (currentStepTime >= brewingSteps[currentStepIndex].time.inSeconds) {
        if (currentStepIndex < brewingSteps.length - 1) {
          if (widget.soundEnabled) {
            await _player.setAsset('assets/audio/next.mp3');
            await _player.play();
          }
          setState(() {
            currentStepIndex++;
            currentStepTime = 0;
          });
        } else {
          if (widget.soundEnabled) {
            await _player.setAsset('assets/audio/next.mp3');
            await _player.play();
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
      appBar: AppBar(title: const Text('Brewing Process')),
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
                      Text(
                        'Step ${currentStepIndex + 1}/${brewingSteps.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(
                          height: 20), // Add some space between the texts
                      Text(
                        brewingSteps[currentStepIndex].description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                    '$currentStepTime/${brewingSteps[currentStepIndex].time.inSeconds} seconds',
                    style: const TextStyle(fontSize: 22)),
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
        child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
      ),
    );
  }
}
