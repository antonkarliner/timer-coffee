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
import '../models/recipe_summary.dart';
import 'package:auto_route/auto_route.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'dart:html' as html;

@RoutePage()
class RecipeDetailScreen extends StatefulWidget {
  final String brewingMethodId;
  final String recipeId;

  const RecipeDetailScreen(
      {super.key,
      @PathParam('brewingMethodId') required this.brewingMethodId,
      @PathParam('recipeId') required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _coffeeController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  late double initialRatio;
  bool _editingCoffee = false;
  bool _isEditingText = false;
  double? originalCoffee;
  double? originalWater;

  Recipe? _updatedRecipe;

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
    _isEditingText = true;
    if (_coffeeController.text.isEmpty ||
        _waterController.text.isEmpty ||
        double.tryParse(_coffeeController.text.replaceAll(',', '.')) == null ||
        double.tryParse(_waterController.text.replaceAll(',', '.')) == null) {
      _isEditingText = false;
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
    _isEditingText = false;
  }

  void _onShare(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;

    await Share.share(
      'https://app.timer.coffee/recipes/${widget.brewingMethodId}/${widget.recipeId}',
      subject: 'Check out this recipe: ${_updatedRecipe!.name}',
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = Theme.of(context).textTheme.bodyLarge!;
    if (kIsWeb && _updatedRecipe != null) {
      // update HTML title
      html.document.title = '${_updatedRecipe!.name} on Timer.Coffee';
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _updatedRecipe == null
                ? 'Loading...'
                : _updatedRecipe!.brewingMethodName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            if (_updatedRecipe != null) ...[
              IconButton(
                icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
                    ? CupertinoIcons.share
                    : Icons.share),
                onPressed: () => _onShare(context),
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
                                decoration: const InputDecoration(
                                    labelText: 'Coffee amount (g)'),
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
                                decoration: const InputDecoration(
                                    labelText: 'Water amount (ml)'),
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
                        Text(
                            'Water Temperature: ${_updatedRecipe!.waterTemp ?? "Not provided"}ºC / ${(_updatedRecipe!.waterTemp != null ? (_updatedRecipe!.waterTemp! * 9 / 5 + 32).toStringAsFixed(1) : "Not provided")}ºF'),
                        const SizedBox(height: 16),
                        Text('Grind size: ${_updatedRecipe!.grindSize}'),
                        const SizedBox(height: 16),
                        Text(
                            'Brew Time: ${_updatedRecipe!.brewTime.toString().split('.').first.padLeft(8, "0")}'),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text('Recipe summary'),
                          subtitle: const Text(
                              'Note: this is a basic recipe with default coffee and water amounts.'),
                          controlAffinity: ListTileControlAffinity.leading,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  RecipeSummary.fromRecipe(_updatedRecipe!)
                                      .summary),
                            ),
                          ],
                        ),
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
              style: defaultTextStyle.copyWith(color: Colors.blue),
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
