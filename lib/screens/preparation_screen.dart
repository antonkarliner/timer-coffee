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

  const PreparationScreen({
    Key? key,
    required this.recipe,
    required this.brewingMethodName,
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
        order: step.order,
        description: replacePlaceholders(
          step.description,
          widget.recipe.coffeeAmount,
          widget.recipe.waterAmount,
          widget.recipe.sweetnessSliderPosition,
          widget.recipe.strengthSliderPosition,
        ),
        time: replaceTimePlaceholder(
          step.time,
          widget.recipe.sweetnessSliderPosition,
          widget.recipe.strengthSliderPosition,
        ),
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
                          style: const TextStyle(fontSize: 24),
                          textAlign: TextAlign.center,
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
    int sweetnessSliderPosition,
    int strengthSliderPosition,
  ) {
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
    String timeString = time.inSeconds.toString();

    List<Map<String, double>> sweetnessValues = [
      {"m1": 0.16, "m2": 0.4}, // Sweetness
      {"m1": 0.20, "m2": 0.4}, // Balance
      {"m1": 0.24, "m2": 0.4}, // Acidity
    ];

    List<Map<String, double>> strengthValues = [
      {
        "m3": 1.0,
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
        "m3": 0.7,
        "t1": 10,
        "t2": 35,
        "m4": 1.0,
        "t3": 10,
        "t4": 35,
        "m5": 0,
        "t5": 0,
        "t6": 0
      }, // Balanced
      {
        "m3": 0.6,
        "t1": 10,
        "t2": 35,
        "m4": 0.8,
        "t3": 10,
        "t4": 35,
        "m5": 1.0,
        "t5": 10,
        "t6": 35
      }, // Strong
    ];

    if (time != Duration.zero) {
      return time;
    }

    RegExp exp = RegExp(r'<(t\d+)>');
    var matches = exp.allMatches(timeString);

    for (var match in matches) {
      String placeholder = match.group(1)!;
      double? replacementValue;
      if (sweetnessValues[sweetnessSliderPosition].containsKey(placeholder)) {
        replacementValue =
            sweetnessValues[sweetnessSliderPosition][placeholder];
      } else if (strengthValues[strengthSliderPosition]
          .containsKey(placeholder)) {
        replacementValue = strengthValues[strengthSliderPosition][placeholder];
      }

      if (replacementValue != null) {
        time = Duration(seconds: replacementValue.toInt());
      }
    }

    return time;
  }
}
