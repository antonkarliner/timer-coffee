import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import '../models/recipe_summary.dart';
import 'package:share_plus/share_plus.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:ui';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/preparation_screen.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../providers/coffee_beans_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _brewingMethodName = "Unknown Brewing Method";
  String? selectedBeanUuid;
  String? selectedBeanName;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
    _loadSelectedBean();
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
        originalCoffee = customCoffee;
        originalWater = customWater;
        initialRatio = originalWater! / originalCoffee!;
        _coffeeController.text = customCoffee.toString();
        _waterController.text = customWater.toString();
      });
    } catch (e) {
      print("Error loading recipe details: $e");
    }
  }

  Future<void> _loadSelectedBean() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('selectedBeanUuid');
    if (uuid != null) {
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);
      setState(() {
        selectedBeanUuid = uuid;
        selectedBeanName = bean?.name;
      });
    } else {
      setState(() {
        selectedBeanUuid = null;
        selectedBeanName = null;
      });
    }
  }

  void _openAddBeansPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCoffeeBeansWidget(
          onSelect: (String selectedBeanUuid) async {
            await _updateSelectedBean(selectedBeanUuid);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _updateSelectedBean(String? uuid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uuid != null) {
      await prefs.setString('selectedBeanUuid', uuid);
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);
      setState(() {
        selectedBeanUuid = uuid;
        selectedBeanName = bean?.name;
      });
    } else {
      await prefs.remove('selectedBeanUuid');
      setState(() {
        selectedBeanUuid = null;
        selectedBeanName = null;
      });
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
    if (_updatedRecipe == null) return;

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
    if (_updatedRecipe == null) {
      return Scaffold(
        body: Container(),
      );
    }

    RecipeModel recipe = _updatedRecipe!;

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
        floatingActionButton: Semantics(
          identifier: 'recipeDetailFloatingActionButton',
          child: _buildFloatingActionButton(context, recipe),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, RecipeModel recipe) {
    return AppBar(
      leading: Semantics(
        identifier: 'recipeDetailBackButton',
        child: const BackButton(),
      ),
      title: Semantics(
        identifier: 'recipeDetailAppBarTitle',
        child: Row(
          children: [
            Semantics(
              identifier: 'brewingMethodIcon_${widget.brewingMethodId}',
              child: getIconByBrewingMethod(widget.brewingMethodId),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _brewingMethodName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Semantics(
          identifier: 'shareButton',
          child: IconButton(
            icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
                ? CupertinoIcons.share
                : Icons.share),
            onPressed: () => _onShare(context),
          ),
        ),
        Semantics(
          identifier: 'favoriteButton_${recipe.id}',
          child: FavoriteButton(recipeId: recipe.id),
        ),
      ],
    );
  }

  Widget _buildRecipeContent(BuildContext context, RecipeModel recipe) {
    String formattedBrewTime = recipe.brewTime != null
        ? '${recipe.brewTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${recipe.brewTime.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : "Not provided";

    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'recipeName',
          child: Text(recipe.name,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'recipeShortDescription',
          child: _buildRichText(context, recipe.shortDescription),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'beanSelectionRow',
          child: Row(
            children: [
              Text('${loc.beans}: ',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openAddBeansPopup(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize:
                        const Size.fromHeight(48), // Adjust height as needed
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            selectedBeanName ?? loc.selectBeans,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (selectedBeanUuid != null)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              _updateSelectedBean(null);
                            },
                            child: Container(
                              width: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.cancel,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'recipeAmountFields',
          child: _buildAmountFields(context, recipe),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'waterTemperature',
          child: Text(
              '${loc.watertemp}: ${recipe.waterTemp?.toStringAsFixed(1) ?? "Not provided"}ºC / ${(recipe.waterTemp != null) ? ((recipe.waterTemp! * 9 / 5) + 32).toStringAsFixed(1) : "Not provided"}ºF'),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'grindSize',
          child: Text('${loc.grindsize}: ${recipe.grindSize}'),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'brewTime',
          child: Text(
              '${AppLocalizations.of(context)!.brewtime}: $formattedBrewTime'),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'recipeSummary',
          child: _buildRecipeSummary(context, recipe),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAmountFields(BuildContext context, RecipeModel recipe) {
    initialRatio = recipe.waterAmount / recipe.coffeeAmount;
    return Semantics(
      identifier: 'recipeAmountFields',
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              identifier: 'coffeeAmountField',
              child: TextField(
                controller: _coffeeController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.coffeeamount,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (text) => _updateAmounts(context, recipe),
                onTap: () => _editingCoffee = true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              identifier: 'waterAmountField',
              child: TextField(
                controller: _waterController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.wateramount,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (text) => _updateAmounts(context, recipe),
                onTap: () => _editingCoffee = false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSummary(BuildContext context, RecipeModel recipe) {
    return Semantics(
      identifier: 'recipeSummaryTile',
      child: ExpansionTile(
        title: Text(AppLocalizations.of(context)!.recipesummary),
        subtitle: Text(AppLocalizations.of(context)!.recipesummarynote),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(RecipeSummary.fromRecipe(recipe).summary),
          ),
        ],
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton(
      BuildContext context, RecipeModel recipe) {
    return FloatingActionButton(
      onPressed: () => _saveCustomAmountsAndNavigate(context, recipe),
      child: Semantics(
        identifier: 'nextButton',
        child: const Icon(Icons.arrow_forward),
      ),
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

    await recipeProvider.saveCustomAmounts(
        widget.recipeId, customCoffeeAmount, customWaterAmount);

    RecipeModel updatedRecipe = recipe.copyWith(
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
    );

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

      if (precedingText.isNotEmpty) {
        spanList.add(TextSpan(text: precedingText, style: defaultTextStyle));
      }

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

    if (lastMatchEnd < text.length) {
      spanList.add(TextSpan(
          text: text.substring(lastMatchEnd), style: defaultTextStyle));
    }

    return RichText(
      text: TextSpan(children: spanList),
    );
  }
}
