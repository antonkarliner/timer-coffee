import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import 'brewing_process_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreparationScreen extends StatefulWidget {
  final RecipeModel recipe;
  final String brewingMethodName;
  final int? coffeeChroniclerSliderPosition;

  const PreparationScreen({
    Key? key,
    required this.recipe,
    required this.brewingMethodName,
    this.coffeeChroniclerSliderPosition,
  }) : super(key: key);

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  late AudioPlayer player;
  bool _soundEnabled = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    _loadSoundSetting();
    _preloadAudio();
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? false;
    });
  }

  Future<void> _preloadAudio() async {
    try {
      await player.setAsset('assets/audio/next.mp3');
    } catch (e) {
      // Handle loading error if necessary
    }
  }

  void _toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    bool currentSetting = prefs.getBool('soundEnabled') ?? false;
    setState(() {
      _soundEnabled = !currentSetting;
    });
    await prefs.setBool('soundEnabled', _soundEnabled);

    if (_soundEnabled) {
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'preparationBackButton',
          child: const BackButton(),
        ),
        title: Semantics(
          identifier: 'preparationScreenTitle',
          child: Text(appLocalizations.preparation),
        ),
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
            widget.recipe.coffeeChroniclerSliderPosition),
        time: replaceTimePlaceholder(
            step.time,
            widget.recipe.sweetnessSliderPosition,
            widget.recipe.strengthSliderPosition,
            widget.recipe.coffeeChroniclerSliderPosition),
      );
    }).toList();

    return Center(
      child: Semantics(
        identifier: 'preparationSteps',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: preparationSteps
                .map((step) => Semantics(
                      identifier: 'preparationStep_${step.order}',
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                            bottom: 16), // Add space between text widgets
                        child: Text(
                          step.description,
                          style: const TextStyle(fontSize: 24, height: 1.3),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ))
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
            identifier: 'soundToggleButton',
            child: FloatingActionButton(
              heroTag: 'soundButton',
              onPressed: _toggleSound,
              child: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
            ),
          ),
          Semantics(
            identifier: 'playButton',
            child: FloatingActionButton(
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
                      brewingMethodName: widget.brewingMethodName,
                      coffeeChroniclerSliderPosition:
                          widget.coffeeChroniclerSliderPosition,
                    ),
                  ),
                );
              },
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
    Map<String, double> allValues = {
      'coffee_amount': coffeeAmount,
      'water_amount': waterAmount,
      'final_coffee_amount': coffeeAmount,
      'final_water_amount': waterAmount,
    };

    // Handle sweetness values if applicable
    if (sweetnessSliderPosition != null) {
      List<Map<String, double>> sweetnessValues = [
        {"m1": 0.16, "m2": 0.24}, // Sweetness
        {"m1": 0.20, "m2": 0.20}, // Balance
        {"m1": 0.24, "m2": 0.16}, // Acidity
      ];
      allValues.addAll(sweetnessValues[sweetnessSliderPosition]);
    }

    // Handle strength values if applicable
    if (strengthSliderPosition != null) {
      List<Map<String, double>> strengthValues = [
        {"m3": 0.6, "m4": 0, "m5": 0}, // Light
        {"m3": 0.3, "m4": 0.3, "m5": 0}, // Balanced
        {"m3": 0.2, "m4": 0.2, "m5": 0.2}, // Strong
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
        {
          "t3": 0,
          "t4": 0,
          "t5": 0,
          "t6": 0,
        }, // Light
        {
          "t3": 10,
          "t4": 35,
          "t5": 0,
          "t6": 0,
        }, // Balanced
        {
          "t3": 10,
          "t4": 35,
          "t5": 10,
          "t6": 35,
        }, // Strong
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
