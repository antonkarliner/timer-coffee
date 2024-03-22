import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../screens/preparation_screen.dart';
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

  const RecipeDetailTKScreen({
    super.key,
    @PathParam('brewingMethodId') required this.brewingMethodId,
    @PathParam('recipeId') required this.recipeId,
  });

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

  RecipeModel? _updatedRecipe;
  String _brewingMethodName = "Unknown Brewing Method"; // Default value

  // Slider positions with default values
  int _sweetnessSliderPosition = 1;
  int _strengthSliderPosition = 2;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    try {
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      RecipeModel recipeModel =
          await recipeProvider.getRecipeById(widget.recipeId);
      String brewingMethodName =
          await recipeProvider.fetchBrewingMethodName(widget.brewingMethodId);

      setState(() {
        _updatedRecipe = recipeModel;
        _brewingMethodName = brewingMethodName;

        double customCoffee =
            recipeModel.customCoffeeAmount ?? recipeModel.coffeeAmount;
        double customWater =
            recipeModel.customWaterAmount ?? recipeModel.waterAmount;
        _sweetnessSliderPosition =
            recipeModel.sweetnessSliderPosition ?? _sweetnessSliderPosition;
        _strengthSliderPosition =
            recipeModel.strengthSliderPosition ?? _strengthSliderPosition;

        originalCoffee = customCoffee;
        originalWater = customWater;
        initialRatio = originalWater! / originalCoffee!;
        _coffeeController.text = customCoffee.toString();
        _waterController.text = customWater.toString();
      });
    } catch (e) {
      // Optionally, update the UI or state to reflect the error.
      print("Error loading recipe details: $e");
    }
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _updateAmounts(BuildContext context, RecipeModel updatedRecipe) {
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
    if (_updatedRecipe == null) return; // Guard clause

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Rect rect = box.localToGlobal(Offset.zero) & box.size;
    final String textToShare =
        'https://app.timer.coffee/recipes/${_updatedRecipe!.brewingMethodId}/${_updatedRecipe!.id}';

    await Share.share(
      textToShare,
      subject:
          '${AppLocalizations.of(context)!.sharemsg} ${_updatedRecipe!.name}',
      sharePositionOrigin: rect,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only build the UI if the recipe details have been loaded.
    if (_updatedRecipe == null) {
      // Placeholder view while loading or if the recipe could not be loaded.
      return Scaffold(body: Center(child: Text('Preparing recipe details...')));
    }

    RecipeModel recipe = _updatedRecipe!;

    // Update HTML title for web platforms.
    if (kIsWeb) {
      html.document.title = '${recipe.name} on Timer.Coffee';
    }

    // Main content now uses the recipe details.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(context, recipe),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: _buildRecipeContent(context, recipe),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(context, recipe),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, RecipeModel recipe) {
    // Adjusted to use RecipeModel directly
    return AppBar(
      leading: const BackButton(),
      title: Row(
        children: [
          getIconByBrewingMethod(widget.brewingMethodId),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _brewingMethodName, // Use the brewing method name stored in the state
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
              ? CupertinoIcons.share
              : Icons.share),
          onPressed: () => _onShare(context), // Pass recipe directly
        ),
        FavoriteButton(recipeId: recipe.id),
      ],
    );
  }

  Widget _buildRecipeContent(BuildContext context, RecipeModel recipe) {
    String formattedBrewTime = recipe.brewTime != null
        ? '${recipe.brewTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${recipe.brewTime.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : "Not provided";

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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      _buildRichText(context, recipe.shortDescription),
      const SizedBox(height: 16),
      _buildAmountFields(context, recipe),
      const SizedBox(height: 16),
      Text(
          '${localizations.watertemp}: ${recipe.waterTemp ?? "Not Provided"}ºC / ${recipe.waterTemp != null ? ((recipe.waterTemp! * 9 / 5) + 32).toStringAsFixed(1) : "Not Provided"}ºF'),
      const SizedBox(height: 16),
      Text('${localizations.grindsize}: ${recipe.grindSize}'),
      const SizedBox(height: 16),
      Text('${AppLocalizations.of(context)!.brewtime}: $formattedBrewTime'),
      const SizedBox(height: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.slidertitle),
          // Sweetness Slider with Labels
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        label: sweetnessLabels[_sweetnessSliderPosition],
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
              ],
            ),
          ),
          // Strength Slider with Labels
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      )
    ]);
  }

  Widget _buildAmountFields(BuildContext context, RecipeModel recipe) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _coffeeController,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.coffeeamount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) {
              _updateAmounts(context, recipe);
            },
            onTap: () {
              _editingCoffee = true;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _waterController,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wateramount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) {
              _updateAmounts(context, recipe);
            },
            onTap: () {
              _editingCoffee = false;
            },
          ),
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton(
      BuildContext context, RecipeModel recipe) {
    return FloatingActionButton(
      onPressed: () => _saveCustomAmountsAndNavigate(context, recipe),
      child: const Icon(Icons.arrow_forward),
    );
  }

  Future<void> _saveCustomAmountsAndNavigate(
      BuildContext context, RecipeModel recipe) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    double customCoffeeAmount =
        double.tryParse(_coffeeController.text.replaceAll(',', '.')) ??
            recipe.coffeeAmount;
    double customWaterAmount =
        double.tryParse(_waterController.text.replaceAll(',', '.')) ??
            recipe.waterAmount;

    // Save the custom coffee and water amounts
    await recipeProvider.saveCustomAmounts(
        widget.recipeId, customCoffeeAmount, customWaterAmount);

    // Assuming that the RecipeModel has been updated to include sweetnessSliderPosition and strengthSliderPosition
    // And assuming that the saveSliderPositions method updates the RecipeModel accordingly
    await recipeProvider.saveSliderPositions(
        widget.recipeId, _sweetnessSliderPosition, _strengthSliderPosition);

    // Use copyWith to create a new RecipeModel instance with updated values
    RecipeModel updatedRecipe = recipe.copyWith(
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
      sweetnessSliderPosition: _sweetnessSliderPosition,
      strengthSliderPosition: _strengthSliderPosition,
    );

    // Navigate to the PreparationScreen with the updated recipe
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreparationScreen(
          recipe: updatedRecipe,
          brewingMethodName: _brewingMethodName,
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
    final RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    final Iterable<RegExpMatch> matches = linkRegExp.allMatches(text);

    TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyLarge!;
    List<TextSpan> spanList = [];

    int lastMatchEnd = 0;

    for (final match in matches) {
      final String precedingText = text.substring(lastMatchEnd, match.start);
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;

      // Add preceding text span
      if (precedingText.isNotEmpty) {
        spanList.add(TextSpan(text: precedingText, style: defaultTextStyle));
      }

      // Add link text span
      spanList.add(TextSpan(
        text: linkText,
        style: defaultTextStyle.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (await canLaunchUrl(Uri.parse(linkUrl))) {
              await launchUrl(Uri.parse(linkUrl));
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastMatchEnd < text.length) {
      spanList.add(TextSpan(
          text: text.substring(lastMatchEnd), style: defaultTextStyle));
    }

    return RichText(
      text: TextSpan(children: spanList),
    );
  }
}
