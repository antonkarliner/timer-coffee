import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import 'package:coffee_timer/screens/preparation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import '../models/recipe_summary.dart';
import 'package:auto_route/auto_route.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class RecipeDetailScreen extends StatefulWidget {
  final String brewingMethodId;
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    @PathParam('brewingMethodId') required this.brewingMethodId,
    @PathParam('recipeId') required this.recipeId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _coffeeController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  late double initialRatio;
  bool _editingCoffee = false;
  double? originalCoffee;
  double? originalWater;

  RecipeModel? _updatedRecipe;
  String _brewingMethodName = "Unknown Brewing Method"; // Default value

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
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

      originalCoffee = customCoffee;
      originalWater = customWater;
      initialRatio = originalWater! / originalCoffee!;
      _coffeeController.text = customCoffee.toString();
      _waterController.text = customWater.toString();
    });
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
    return Consumer<RecipeProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<RecipeModel>(
          future: provider.getRecipeById(widget.recipeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError) {
              return Scaffold(
                  body: Center(
                      child: Text('Error: ${snapshot.error.toString()}')));
            } else if (snapshot.hasData) {
              RecipeModel recipe = snapshot.data!;
              // Update HTML title for web platforms
              if (kIsWeb) {
                html.document.title = '${recipe.name} on Timer.Coffee';
              }
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
                  floatingActionButton:
                      _buildFloatingActionButton(context, recipe),
                ),
              );
            } else {
              return const Scaffold(
                  body: Center(child: Text('No data available')));
            }
          },
        );
      },
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
    // Calculate minutes and seconds from brewTime
    String formattedBrewTime = recipe.brewTime != null
        ? '${recipe.brewTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${recipe.brewTime.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : "Not provided";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildRichText(context, recipe.shortDescription),
        const SizedBox(height: 16),
        _buildAmountFields(context, recipe),
        const SizedBox(height: 16),
        Text(
            '${AppLocalizations.of(context)!.watertemp}: ${recipe.waterTemp?.toStringAsFixed(1) ?? "Not provided"}ºC / ${(recipe.waterTemp != null) ? ((recipe.waterTemp! * 9 / 5) + 32).toStringAsFixed(1) : "Not provided"}ºF'),
        const SizedBox(height: 16),
        Text('${AppLocalizations.of(context)!.grindsize}: ${recipe.grindSize}'),
        const SizedBox(height: 16),
        Text('${AppLocalizations.of(context)!.brewtime}: $formattedBrewTime'),
        const SizedBox(height: 16),
        _buildRecipeSummary(context, recipe),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAmountFields(BuildContext context, RecipeModel recipe) {
    initialRatio = recipe.waterAmount / recipe.coffeeAmount;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _coffeeController,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.coffeeamount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) => _updateAmounts(context, recipe),
            onTap: () => _editingCoffee = true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _waterController,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wateramount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) => _updateAmounts(context, recipe),
            onTap: () => _editingCoffee = false,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeSummary(BuildContext context, RecipeModel recipe) {
    return ExpansionTile(
      title: Text(AppLocalizations.of(context)!.recipesummary),
      subtitle: Text(AppLocalizations.of(context)!.recipesummarynote),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(RecipeSummary.fromRecipe(recipe)
              .summary), // Assume RecipeSummary exists
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

    double customCoffee =
        double.tryParse(_coffeeController.text.replaceAll(',', '.')) ??
            recipe.coffeeAmount;
    double customWater =
        double.tryParse(_waterController.text.replaceAll(',', '.')) ??
            recipe.waterAmount;

    await recipeProvider.saveCustomAmounts(
        widget.recipeId, customCoffee, customWater);

    RecipeModel updatedRecipe =
        await recipeProvider.getRecipeById(widget.recipeId);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PreparationScreen(
                  recipe: updatedRecipe, // Pass the updated recipe model
                  brewingMethodName:
                      _brewingMethodName, // Assuming this is defined elsewhere in your class
                )));
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
