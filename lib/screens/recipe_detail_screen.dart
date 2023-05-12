import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'preparation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _coffeeController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  late double initialRatio;

  Recipe? _updatedRecipe;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    await recipeProvider.fetchRecipes(widget.recipe.brewingMethodId);
    _updatedRecipe = recipeProvider.getRecipeById(widget.recipe.id);
    initialRatio = _updatedRecipe!.waterAmount / _updatedRecipe!.coffeeAmount;
    _coffeeController.text = _updatedRecipe!.coffeeAmount.toString();
    _waterController.text = _updatedRecipe!.waterAmount.toString();
    _coffeeController
        .addListener(() => _updateAmounts(context, _updatedRecipe!));
    _waterController
        .addListener(() => _updateAmounts(context, _updatedRecipe!));
    setState(() {});
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _updateAmounts(BuildContext context, Recipe updatedRecipe) {
    double? newCoffee = double.tryParse(_coffeeController.text);
    double? newWater = double.tryParse(_waterController.text);

    if (newCoffee == null || newWater == null) {
      return;
    }

    double currentCoffee = updatedRecipe.coffeeAmount;
    double currentWater = updatedRecipe.waterAmount;

    if (_coffeeController.text != currentCoffee.toString()) {
      double ratio = currentWater / currentCoffee;
      currentCoffee = newCoffee;
      currentWater = newCoffee * ratio;
      _waterController
          .removeListener(() => _updateAmounts(context, updatedRecipe));
      _waterController.text = currentWater.toStringAsFixed(1);
      _waterController
          .addListener(() => _updateAmounts(context, updatedRecipe));
    } else if (_waterController.text != currentWater.toString()) {
      double ratio = currentCoffee / currentWater;
      currentWater = newWater;
      currentCoffee = newWater * ratio;
      _coffeeController
          .removeListener(() => _updateAmounts(context, updatedRecipe));
      _coffeeController.text = currentCoffee.toStringAsFixed(1);
      _coffeeController
          .addListener(() => _updateAmounts(context, updatedRecipe));
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = Theme.of(context).textTheme.bodyText1!;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_updatedRecipe == null ? 'Loading...' : _updatedRecipe!.name),
        actions: [
          if (_updatedRecipe != null) ...[
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
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_updatedRecipe!.brewingMethodName),
                  SizedBox(height: 16),
                  _buildRichText(context, _updatedRecipe!.shortDescription),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _coffeeController,
                          decoration:
                              InputDecoration(labelText: 'Coffee amount (g)'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _waterController,
                          decoration:
                              InputDecoration(labelText: 'Water amount (ml)'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Grind size: ${_updatedRecipe!.grindSize}'),
                  SizedBox(height: 16),
                  Text(
                      'Brew Time: ${_updatedRecipe!.brewTime.toString().split('.').first.padLeft(8, "0")}')
                ],
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
                  coffeeAmount: double.tryParse(_coffeeController.text),
                  waterAmount: double.tryParse(_waterController.text),
                ),
              ),
            ),
          );
        },
        child: Icon(Icons.arrow_forward),
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

    TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyText1!;

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
              style: defaultTextStyle.copyWith(
                  color: Colors.blue, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  Uri url = Uri.parse(linkUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Could not launch $linkUrl';
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
      return Text(text);
    }
  }
}
