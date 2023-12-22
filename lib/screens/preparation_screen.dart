import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import 'brewing_process_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreparationScreen extends StatefulWidget {
  final Recipe recipe;

  const PreparationScreen({super.key, required this.recipe});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  bool _soundEnabled = false;
  late AudioPlayer player;

  String replacePlaceholders(
    String description,
    double coffeeAmount,
    double waterAmount,
    int sweetnessSliderPosition,
    int strengthSliderPosition,
  ) {
    // Define the values based on slider positions for sweetness and strength
    List<Map<String, double>> sweetnessValues = [
      {"m1": 0.16, "m2": 0.24}, // Sweetness
      {"m1": 0.20, "m2": 0.20}, // Balance
      {"m1": 0.24, "m2": 0.16}, // Acidity
    ];

    List<Map<String, double>> strengthValues = [
      {"m3": 0.6, "m4": 0, "m5": 0}, // Light
      {"m3": 0.3, "m4": 0.3, "m5": 0}, // Balanced
      {"m3": 0.2, "m4": 0.2, "m5": 0.2}, // Strong
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
    int sweetnessSliderPosition,
    int strengthSliderPosition,
  ) {
    // First, check if time is a placeholder that needs replacement
    String timeString = time.inSeconds
        .toString(); // Convert Duration to string representation of seconds for matching

    // Define the values based on slider positions for sweetness and strength
    List<Map<String, double>> sweetnessValues = [
      {"m1": 0.16, "m2": 0.24}, // Sweetness
      {"m1": 0.20, "m2": 0.20}, // Balance
      {"m1": 0.24, "m2": 0.16}, // Acidity
    ];

    List<Map<String, double>> strengthValues = [
      {
        "m3": 0.6,
        "t1": 10,
        "t2": 35,
        "m4": 0,
        "t3": 0,
        "t4": 0,
        "m5": 0,
        "t5": 0,
        "t6": 0
      }, // Light
      {
        "m3": 0.3,
        "t1": 10,
        "t2": 35,
        "m4": 0.3,
        "t3": 10,
        "t4": 35,
        "m5": 0,
        "t5": 0,
        "t6": 0
      }, // Balanced
      {
        "m3": 0.2,
        "t1": 10,
        "t2": 35,
        "m4": 0.2,
        "t3": 10,
        "t4": 35,
        "m5": 0.2,
        "t5": 10,
        "t6": 35
      }, // Strong
    ];

    // Check if time is a direct numerical value (if time is a placeholder, it would be set to zero initially)
    if (time != Duration.zero) {
      return time; // It's a direct value, return as is.
    }

    // Assume that the placeholder is in a predictable format, such as <t1> or <t2>, etc.
    RegExp exp = RegExp(r'<(t\d+)>');
    var matches = exp.allMatches(timeString);

    for (var match in matches) {
      String placeholder = match.group(1)!;
      // Identify which value set to use and replace placeholders
      double? replacementValue;
      if (sweetnessValues[sweetnessSliderPosition].containsKey(placeholder)) {
        replacementValue =
            sweetnessValues[sweetnessSliderPosition][placeholder];
      } else if (strengthValues[strengthSliderPosition]
          .containsKey(placeholder)) {
        replacementValue = strengthValues[strengthSliderPosition][placeholder];
      }

      // Convert the replacement value to a Duration, assuming the values are seconds
      if (replacementValue != null) {
        time = Duration(seconds: replacementValue.toInt());
      }
    }

    return time; // Return the modified Duration
  }

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    _loadSoundSetting();
    _preloadAudio();
  }

  Future<void> _loadSoundSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? false;
    });
  }

  Future<void> _preloadAudio() async {
    try {
      await player.setAsset('assets/audio/next.mp3');
    } catch (e) {
      // catch load errors
    }
  }

  void _toggleSound() {
    SharedPreferences.getInstance().then((prefs) {
      bool currentSoundSetting = prefs.getBool('soundEnabled') ?? false;
      prefs.setBool('soundEnabled', !currentSoundSetting);
      setState(() {
        _soundEnabled = !currentSoundSetting;
      });
      if (_soundEnabled) {
        player.seek(Duration.zero);
        player.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<BrewStep> preparationSteps = widget.recipe.steps
        .map((step) => BrewStep(
              order: step.order,
              description: replacePlaceholders(
                step.description,
                widget.recipe.coffeeAmount,
                widget.recipe.waterAmount,
                widget.recipe.sweetnessSliderPosition,
                widget.recipe.strengthSliderPosition,
              ),
              time: step.time,
            ))
        .where((step) =>
            step.time is Duration &&
            step.time.inSeconds == 0 &&
            step.order == 1)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.preparation)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: preparationSteps
                .map((step) => Container(
                      width: double.infinity,
                      child: Text(
                        step.description,
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'soundButton',
              onPressed: _toggleSound,
              child: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
            ),
            FloatingActionButton(
              heroTag: 'playButton',
              onPressed: () {
                if (_soundEnabled) {
                  player.seek(Duration.zero);
                  player.play();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrewingProcessScreen(
                      recipe: widget.recipe,
                      coffeeAmount: widget.recipe.coffeeAmount,
                      waterAmount: widget.recipe.waterAmount,
                      sweetnessSliderPosition:
                          widget.recipe.sweetnessSliderPosition,
                      strengthSliderPosition:
                          widget.recipe.strengthSliderPosition,
                      soundEnabled: _soundEnabled,
                    ),
                  ),
                );
              },
              // Check the directionality and choose the icon accordingly
              child: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_new
                    : Icons.play_arrow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
