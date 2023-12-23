import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import 'preparation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import 'package:auto_route/auto_route.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class RecipeDetailTKScreen extends StatefulWidget {
  final String brewingMethodId;
  final String recipeId;

  const RecipeDetailTKScreen(
      {super.key,
      @PathParam('brewingMethodId') required this.brewingMethodId,
      @PathParam('recipeId') required this.recipeId});

  @override
  State<RecipeDetailTKScreen> createState() => _RecipeDetailTKScreenState();
}

class _RecipeDetailTKScreenState extends State<RecipeDetailTKScreen> {
  final TextEditingController _coffeeController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  late double initialRatio;
  bool _editingCoffee = false;
  double? originalCoffee;
  double? originalWater;

  Recipe? _updatedRecipe;

  int _sweetnessSliderPosition = 1; // Default position for Sweetness slider
  int _strengthSliderPosition = 2; // Default position for Strength slider

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    await recipeProvider.fetchRecipes(widget.brewingMethodId);
    _updatedRecipe = recipeProvider.getRecipeById(widget.recipeId);
    originalCoffee = _updatedRecipe!.coffeeAmount;
    originalWater = _updatedRecipe!.waterAmount;
    initialRatio = originalWater! / originalCoffee!;
    _coffeeController.text = _updatedRecipe!.coffeeAmount.toString();
    _waterController.text = _updatedRecipe!.waterAmount.toString();
    setState(() {});
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _updateAmounts(BuildContext context, Recipe updatedRecipe) {
    if (_coffeeController.text.isEmpty ||
        _waterController.text.isEmpty ||
        double.tryParse(_coffeeController.text.replaceAll(',', '.')) == null ||
        double.tryParse(_waterController.text.replaceAll(',', '.')) == null) {
      return;
    }

    double newCoffee =
        double.parse(_coffeeController.text.replaceAll(',', '.'));
    double newWater = double.parse(_waterController.text.replaceAll(',', '.'));

    if (_editingCoffee) {
      double newWaterAmount = newCoffee * initialRatio;
      _waterController.text = newWaterAmount.toStringAsFixed(1);
    } else {
      double newCoffeeAmount = newWater / initialRatio;
      _coffeeController.text = newCoffeeAmount.toStringAsFixed(1);
    }
  }

  bool isIpad() {
    if (Platform.isIOS) {
      final double scale = window.devicePixelRatio;
      final double width = window.physicalSize.width;
      final double height = window.physicalSize.height;
      final double largerSide = (width > height) ? width : height;
      return largerSide > 1366.0 * scale;
    }
    return false;
  }

  void _onShare(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Rect rect = box.localToGlobal(Offset.zero) & box.size;
    final String textToShare =
        'https://app.timer.coffee/recipes/${widget.brewingMethodId}/${widget.recipeId}';

    await Share.share(
      textToShare,
      subject:
          '${AppLocalizations.of(context)!.sharemsg} ${_updatedRecipe!.name}',
      sharePositionOrigin: rect,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _updatedRecipe != null) {
      // Update HTML title
      html.document.title = '${_updatedRecipe!.name} on Timer.Coffee';
    }

    final localizations = AppLocalizations.of(context)!;

    // Define the localized labels for the sliders
    List<String> sweetnessLabels = [
      localizations.sweet, // "Sweet"
      localizations.balance, // "Balance"
      localizations.acidic, // "Acidic"
    ];
    List<String> strengthLabels = [
      localizations.light, // "Light"
      localizations.balance, // "Balance"
      localizations.strong, // "Strong"
    ];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // Dismiss the keyboard when tapping outside
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(), // This is your back button
          title: Row(
            children: [
              getIconByBrewingMethod(
                  widget.brewingMethodId), // This is your brewing method icon
              const SizedBox(
                  width:
                      8), // Optional: Add a little space between the icon and text
              Flexible(
                child: Text(
                  _updatedRecipe == null
                      ? 'Loading...'
                      : _updatedRecipe!.brewingMethodName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
            ],
          ),
          actions: [
            if (_updatedRecipe != null) ...[
              Builder(
                builder: (BuildContext context) => IconButton(
                  icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
                      ? CupertinoIcons.share
                      : Icons.share),
                  onPressed: () => _onShare(context),
                ),
              ),
              FavoriteButton(
                recipeId: _updatedRecipe!.id,
                onToggleFavorite: (isFavorite) {
                  Provider.of<RecipeProvider>(context, listen: false)
                      .toggleFavorite(_updatedRecipe!.id);
                },
              )
            ]
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _updatedRecipe == null
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (OverscrollIndicatorNotification overscroll) {
                    FocusScope.of(context).unfocus();
                    return true;
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _updatedRecipe!.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildRichText(
                            context, _updatedRecipe!.shortDescription),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _coffeeController,
                                decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .coffeeamount),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (text) {
                                  _updateAmounts(context, _updatedRecipe!);
                                },
                                onTap: () {
                                  _editingCoffee = true;
                                },
                                onSubmitted: (text) {
                                  _coffeeController.text =
                                      text.replaceAll(',', '.');
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _waterController,
                                decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .wateramount),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (text) {
                                  _updateAmounts(context, _updatedRecipe!);
                                },
                                onTap: () {
                                  _editingCoffee = false;
                                },
                                onSubmitted: (text) {
                                  _waterController.text =
                                      text.replaceAll(',', '.');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.slidertitle),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.sweet),
                            Expanded(
                              child: Slider(
                                value: _sweetnessSliderPosition.toDouble(),
                                min: 0,
                                max: 2,
                                divisions: 2,
                                label:
                                    sweetnessLabels[_sweetnessSliderPosition],
                                onChanged: (double value) {
                                  setState(() {
                                    _sweetnessSliderPosition = value.toInt();
                                  });
                                },
                              ),
                            ),
                            Text(AppLocalizations.of(context)!.acidic),
                          ],
                        ),

                        // Strength Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context)!.light),
                            Expanded(
                              child: Slider(
                                value: _strengthSliderPosition.toDouble(),
                                min: 0,
                                max: 2,
                                divisions: 2,
                                label: strengthLabels[_strengthSliderPosition],
                                onChanged: (double value) {
                                  setState(() {
                                    _strengthSliderPosition = value.toInt();
                                  });
                                },
                              ),
                            ),
                            Text(AppLocalizations.of(context)!.strong),
                          ],
                        ),
                        Text(
                            '${AppLocalizations.of(context)!.watertemp}: ${_updatedRecipe!.waterTemp ?? "Not provided"}ºC / ${(_updatedRecipe!.waterTemp != null ? (_updatedRecipe!.waterTemp! * 9 / 5 + 32).toStringAsFixed(1) : "Not provided")}ºF'),
                        const SizedBox(height: 16),
                        Text(
                            '${AppLocalizations.of(context)!.grindsize}: ${_updatedRecipe!.grindSize}'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final recipeProvider =
                Provider.of<RecipeProvider>(context, listen: false);
            Recipe updatedRecipe =
                await recipeProvider.updateLastUsed(_updatedRecipe!.id);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreparationScreen(
                  recipe: updatedRecipe.copyWith(
                    coffeeAmount: double.tryParse(
                        _coffeeController.text.replaceAll(',', '.')),
                    waterAmount: double.tryParse(
                        _waterController.text.replaceAll(',', '.')),
                    // Add slider values here
                    sweetnessSliderPosition: _sweetnessSliderPosition,
                    strengthSliderPosition: _strengthSliderPosition,
                  ),
                ),
              ),
            );
          },
          child: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }

  Future<bool> canLaunchUrl(Uri url) async {
    return await canLaunch(url.toString());
  }

  Future<void> launchUrl(Uri url) async {
    await launch(url.toString());
  }

  Widget _buildRichText(BuildContext context, String text) {
    RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    Match? match = linkRegExp.firstMatch(text);

    TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyLarge!;

    if (match != null) {
      String linkText = match.group(1)!;
      String linkUrl = match.group(2)!;

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text.substring(0, match.start),
              style: defaultTextStyle,
            ),
            TextSpan(
              text: linkText,
              style: defaultTextStyle.copyWith(color: Colors.brown),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  if (await canLaunchUrl(Uri.parse(linkUrl))) {
                    launchUrl(Uri.parse(linkUrl));
                  }
                },
            ),
            TextSpan(
              text: text.substring(match.end),
              style: defaultTextStyle,
            ),
          ],
        ),
      );
    } else {
      return Text(text, style: defaultTextStyle);
    }
  }
}
