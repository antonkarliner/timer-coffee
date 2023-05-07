import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'preparation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

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

  @override
  void initState() {
    super.initState();
    initialRatio = widget.recipe.waterAmount / widget.recipe.coffeeAmount;
    _coffeeController.text = widget.recipe.coffeeAmount.toString();
    _waterController.text = widget.recipe.waterAmount.toString();
    _coffeeController.addListener(_updateAmounts);
    _waterController.addListener(_updateAmounts);
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _updateAmounts() {
    double? newCoffee = double.tryParse(_coffeeController.text);
    double? newWater = double.tryParse(_waterController.text);

    if (newCoffee == null || newWater == null) {
      return;
    }

    double currentCoffee = widget.recipe.coffeeAmount;
    double currentWater = widget.recipe.waterAmount;

    if (_coffeeController.text != currentCoffee.toString()) {
      setState(() {
        double ratio = currentWater / currentCoffee;
        currentCoffee = newCoffee;
        currentWater = newCoffee * ratio;
        _waterController.removeListener(_updateAmounts);
        _waterController.text = currentWater.toStringAsFixed(1);
        _waterController.addListener(_updateAmounts);
      });
    } else if (_waterController.text != currentWater.toString()) {
      setState(() {
        double ratio = currentCoffee / currentWater;
        currentWater = newWater;
        currentCoffee = newWater * ratio;
        _coffeeController.removeListener(_updateAmounts);
        _coffeeController.text = currentCoffee.toStringAsFixed(1);
        _coffeeController.addListener(_updateAmounts);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = Theme.of(context).textTheme.bodyText1!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipe.brewingMethodName),
            SizedBox(height: 16),
            _buildRichText(context, widget.recipe.shortDescription),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _coffeeController,
                    decoration: InputDecoration(labelText: 'Coffee amount (g)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _waterController,
                    decoration: InputDecoration(labelText: 'Water amount (ml)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Grind size: ${widget.recipe.grindSize}'),
            SizedBox(height: 16),
            Text(
                'Brew Time: ${widget.recipe.brewTime.toString().split('.').first.padLeft(8, "0")}')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreparationScreen(
                recipe: widget.recipe.copyWith(
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

  Future<bool> canLaunchUrl(String urlString) async {
    return await canLaunch(urlString);
  }

  Future<void> launchUrl(String urlString) async {
    await launch(urlString);
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
                  if (await canLaunchUrl(linkUrl)) {
                    await launchUrl(linkUrl);
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
