import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../providers/database_provider.dart';
import '../screens/preparation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/favorite_button.dart';
import '../models/recipe_summary.dart';
import 'package:auto_route/auto_route.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../webhelper/web_helper.dart' as web;
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../providers/coffee_beans_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage(name: 'RecipeDetailRoute')
class RecipeDetailScreen extends StatelessWidget {
  final String brewingMethodId;
  final String recipeId;

  const RecipeDetailScreen({
    Key? key,
    @PathParam('brewingMethodId') required this.brewingMethodId,
    @PathParam('recipeId') required this.recipeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RecipeDetailBase(
      brewingMethodId: brewingMethodId,
      recipeId: recipeId,
    );
  }
}

@RoutePage(name: 'VendorRecipeDetailRoute')
class VendorRecipeDetailScreen extends StatelessWidget {
  final String vendorId;
  final String recipeId;

  const VendorRecipeDetailScreen({
    Key? key,
    @PathParam('vendorId') required this.vendorId,
    @PathParam('recipeId') required this.recipeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RecipeDetailBase(
      vendorId: vendorId,
      recipeId: recipeId,
    );
  }
}

// The base widget that contains the actual implementation
class RecipeDetailBase extends StatefulWidget {
  final String? brewingMethodId;
  final String recipeId;
  final String? vendorId;

  const RecipeDetailBase({
    Key? key,
    this.brewingMethodId,
    required this.recipeId,
    this.vendorId,
  }) : super(key: key);

  @override
  _RecipeDetailBaseState createState() => _RecipeDetailBaseState();
}

class _RecipeDetailBaseState extends State<RecipeDetailBase> {
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

  // Sliders for recipe id 106
  int _sweetnessSliderPosition = 1;
  int _strengthSliderPosition = 2;
  int _coffeeChroniclerSliderPosition = 0;

  // Vendor-specific variables
  String? vendorId;
  String? vendorName;
  String? vendorBannerUrl;

  // Roaster logo URLs
  String? originalRoasterLogoUrl;
  String? mirrorRoasterLogoUrl;

  @override
  void initState() {
    super.initState();
    vendorId = widget.vendorId;
    _loadRecipeDetails();
    _loadSelectedBean();
  }

  Future<void> _loadRecipeDetails() async {
    try {
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      RecipeModel recipeModel =
          await recipeProvider.getRecipeById(widget.recipeId);

      String brewingMethodName = "Unknown Brewing Method";

      if (widget.vendorId != null && widget.vendorId != 'timercoffee') {
        // Vendor Recipe
        vendorId = widget.vendorId;
        _brewingMethodName = "Vendor Recipe";
        await _loadVendorData(vendorId!);
      } else {
        // Regular Recipe
        brewingMethodName = await recipeProvider
            .fetchBrewingMethodName(recipeModel.brewingMethodId);
        _brewingMethodName = brewingMethodName;
      }

      setState(() {
        _updatedRecipe = recipeModel;

        double customCoffee =
            recipeModel.customCoffeeAmount ?? recipeModel.coffeeAmount;
        double customWater =
            recipeModel.customWaterAmount ?? recipeModel.waterAmount;
        originalCoffee = customCoffee;
        originalWater = customWater;
        initialRatio = originalWater! / originalCoffee!;
        _coffeeController.text = customCoffee.toString();
        _waterController.text = customWater.toString();

        if (recipeModel.id == '106') {
          _sweetnessSliderPosition =
              recipeModel.sweetnessSliderPosition ?? _sweetnessSliderPosition;
          _strengthSliderPosition =
              recipeModel.strengthSliderPosition ?? _strengthSliderPosition;
        }
        if (recipeModel.id == '1002') {
          _coffeeChroniclerSliderPosition =
              recipeModel.coffeeChroniclerSliderPosition ??
                  _coffeeChroniclerSliderPosition;
        }
      });
    } catch (e) {
      print("Error loading recipe details: $e");
    }
  }

  Future<void> _loadVendorData(String vendorId) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    vendorName = await recipeProvider.fetchVendorName(vendorId);
    vendorBannerUrl = await recipeProvider.fetchVendorBannerUrl(vendorId);
  }

  Future<void> _loadSelectedBean() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('selectedBeanUuid');
    if (uuid != null) {
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

      String? originalUrl;
      String? mirrorUrl;
      if (bean != null && bean.roaster != null) {
        final databaseProvider =
            Provider.of<DatabaseProvider>(context, listen: false);
        final logoUrls =
            await databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
        originalUrl = logoUrls['original'];
        mirrorUrl = logoUrls['mirror'];
      }

      setState(() {
        selectedBeanUuid = uuid;
        selectedBeanName = bean?.name;
        originalRoasterLogoUrl = originalUrl;
        mirrorRoasterLogoUrl = mirrorUrl;
      });
    } else {
      setState(() {
        selectedBeanUuid = null;
        selectedBeanName = null;
        originalRoasterLogoUrl = null;
        mirrorRoasterLogoUrl = null;
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

      String? originalUrl;
      String? mirrorUrl;
      if (bean != null && bean.roaster != null) {
        final databaseProvider =
            Provider.of<DatabaseProvider>(context, listen: false);
        final logoUrls =
            await databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
        originalUrl = logoUrls['original'];
        mirrorUrl = logoUrls['mirror'];
      }

      setState(() {
        selectedBeanUuid = uuid;
        selectedBeanName = bean?.name;
        originalRoasterLogoUrl = originalUrl;
        mirrorRoasterLogoUrl = mirrorUrl;
      });
    } else {
      await prefs.remove('selectedBeanUuid');
      setState(() {
        selectedBeanUuid = null;
        selectedBeanName = null;
        originalRoasterLogoUrl = null;
        mirrorRoasterLogoUrl = null;
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
      newWater =
          newWaterAmount; // Update newWater to reflect the adjusted value
    } else {
      double newCoffeeAmount = newWater / initialRatio;
      _coffeeController.text = newCoffeeAmount.toStringAsFixed(1);
      newCoffee =
          newCoffeeAmount; // Update newCoffee to reflect the adjusted value
    }

    // For recipe id 1002, update slider position based on amounts
    if (updatedRecipe.id == '1002') {
      int newSliderPosition = _coffeeChroniclerSliderPosition;

      if (newCoffee <= 26 || newWater <= 416) {
        newSliderPosition = 0; // Standard
      } else if ((newCoffee > 26 && newCoffee < 37) ||
          (newWater > 416 && newWater < 592)) {
        newSliderPosition = 1; // Medium
      } else if (newCoffee >= 37 || newWater >= 592) {
        newSliderPosition = 2; // XL
      }

      if (newSliderPosition != _coffeeChroniclerSliderPosition) {
        setState(() {
          _coffeeChroniclerSliderPosition = newSliderPosition;
        });
      }
    }
  }

  void _onShare(BuildContext context) async {
    if (_updatedRecipe == null) return; // Guard clause

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Rect rect = box.localToGlobal(Offset.zero) & box.size;
    String textToShare;

    if (vendorId != null && vendorId != 'timercoffee') {
      textToShare =
          'https://app.timer.coffee/roasters/${_updatedRecipe!.vendorId}/${_updatedRecipe!.id}';
    } else {
      textToShare =
          'https://app.timer.coffee/recipes/${_updatedRecipe!.brewingMethodId}/${_updatedRecipe!.id}';
    }

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
      web.document.title = '${recipe.name} on Timer.Coffee';
    }

    // Replace kFloatingActionButtonSize with 56.0
    final double fabHeight = 76.0 + 16.0; // FAB height + some extra space

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(context, recipe),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, fabHeight),
              child: SingleChildScrollView(
                child: _buildRecipeContent(context, recipe),
              ),
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: _buildFloatingActionButton(context, recipe),
            ),
          ],
        ),
        // Remove the floatingActionButton from Scaffold to prevent overlap
        // floatingActionButton: _buildFloatingActionButton(context, recipe),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, RecipeModel recipe) {
    if (vendorId != null && vendorId != 'timercoffee') {
      // Vendor-specific AppBar
      return AppBar(
        leading: const BackButton(),
        toolbarHeight: 90,
        title: FutureBuilder<String>(
          future: Provider.of<RecipeProvider>(context, listen: false)
              .fetchVendorName(vendorId!),
          builder: (context, snapshot) {
            bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
            String logoUrl = isDarkTheme
                ? "https://timercoffeeapp.fra1.cdn.digitaloceanspaces.com/$vendorId/logo-dark.png"
                : "https://timercoffeeapp.fra1.cdn.digitaloceanspaces.com/$vendorId/logo.png";

            return Image.network(
              logoUrl,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Text(snapshot.data ?? "Unknown Vendor");
              },
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
                ? CupertinoIcons.share
                : Icons.share),
            onPressed: () => _onShare(context),
          ),
          FavoriteButton(recipeId: recipe.id),
        ],
      );
    } else {
      // Default AppBar
      return AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            getIconByBrewingMethod(recipe.brewingMethodId),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _brewingMethodName,
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
            onPressed: () => _onShare(context),
          ),
          FavoriteButton(recipeId: recipe.id),
        ],
      );
    }
  }

  Widget _buildRecipeContent(BuildContext context, RecipeModel recipe) {
    String formattedBrewTime = recipe.brewTime != null
        ? '${recipe.brewTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${recipe.brewTime.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : "Not provided";

    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildRichText(context, recipe.shortDescription),
        const SizedBox(height: 16),
        _buildBeanSelectionRow(context),
        const SizedBox(height: 16),
        _buildAmountFields(context, recipe),
        const SizedBox(height: 16),
        Text(
            '${loc.watertemp}: ${recipe.waterTemp?.toStringAsFixed(1) ?? "Not provided"}ºC / ${(recipe.waterTemp != null) ? ((recipe.waterTemp! * 9 / 5) + 32).toStringAsFixed(1) : "Not provided"}ºF'),
        const SizedBox(height: 16),
        Text('${loc.grindsize}: ${recipe.grindSize}'),
        const SizedBox(height: 16),
        Text('${loc.brewtime}: $formattedBrewTime'),
        const SizedBox(height: 16),
        if (recipe.id == '1002') _buildCoffeeChroniclerSlider(context),
        if (recipe.id == '106') _buildSliders(context),
        if (recipe.id != '106' &&
            recipe.id != '1002' &&
            (recipe.vendorId == null || recipe.vendorId == 'timercoffee'))
          _buildRecipeSummary(context, recipe),
        if (recipe.vendorId != null && recipe.vendorId != 'timercoffee')
          _buildVendorBanner(context),
      ],
    );
  }

  Widget _buildBeanSelectionRow(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          '${loc.beans}: ',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _openAddBeansPopup(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(48), // Adjust height as needed
            ),
            child: Stack(
              children: [
                Center(
                  child: selectedBeanUuid == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            loc.selectBeans,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (originalRoasterLogoUrl != null ||
                                mirrorRoasterLogoUrl != null)
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4), // Rounded corners
                                child: CachedNetworkImage(
                                  imageUrl: originalRoasterLogoUrl ??
                                      mirrorRoasterLogoUrl!,
                                  placeholder: (context, url) => const Icon(
                                      Coffeico.bag_with_bean,
                                      size: 24),
                                  errorWidget: (context, url, error) {
                                    if (url == originalRoasterLogoUrl &&
                                        mirrorRoasterLogoUrl != null) {
                                      // Attempt to load mirror URL
                                      return CachedNetworkImage(
                                        imageUrl: mirrorRoasterLogoUrl!,
                                        placeholder: (context, url) =>
                                            const Icon(Coffeico.bag_with_bean,
                                                size: 24),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Coffeico.bag_with_bean,
                                                size: 24),
                                        height:
                                            24, // Maintain consistent height
                                        fit: BoxFit
                                            .contain, // Preserve aspect ratio
                                      );
                                    }
                                    // If mirror also fails or not available
                                    return const Icon(Coffeico.bag_with_bean,
                                        size: 24);
                                  },
                                  height: 24, // Set fixed height
                                  fit: BoxFit.contain, // Preserve aspect ratio
                                ),
                              ),
                            if (originalRoasterLogoUrl != null ||
                                mirrorRoasterLogoUrl != null)
                              const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedBeanName!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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
              labelText: AppLocalizations.of(context)!.coffeeamount,
            ),
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
              labelText: AppLocalizations.of(context)!.wateramount,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (text) => _updateAmounts(context, recipe),
            onTap: () => _editingCoffee = false,
          ),
        ),
      ],
    );
  }

  Widget _buildSliders(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    List<String> sweetnessLabels = [
      localizations.sweet,
      localizations.balance,
      localizations.acidic,
    ];
    List<String> strengthLabels = [
      localizations.light,
      localizations.balance,
      localizations.strong,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sweetness Slider
        Text(localizations.slidertitle),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.sweet),
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
            Text(localizations.acidic),
          ],
        ),
        // Strength Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.light),
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
            Text(localizations.strong),
          ],
        ),
      ],
    );
  }

  Widget _buildCoffeeChroniclerSlider(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    List<String> sizeLabels = [
      localizations.sizeStandard,
      localizations.sizeMedium,
      localizations.sizeXL,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.selectSize),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.sizeStandard),
            Expanded(
              child: Slider(
                value: _coffeeChroniclerSliderPosition.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: sizeLabels[_coffeeChroniclerSliderPosition],
                onChanged: (double value) {
                  setState(() {
                    _coffeeChroniclerSliderPosition = value.toInt();

                    // Update coffee and water amounts
                    if (_updatedRecipe!.id == '1002') {
                      double newCoffeeAmount;
                      double newWaterAmount;

                      switch (_coffeeChroniclerSliderPosition) {
                        case 0:
                          newCoffeeAmount = 20;
                          newWaterAmount = 320;
                          break;
                        case 1:
                          newCoffeeAmount = 30;
                          newWaterAmount = 480;
                          break;
                        case 2:
                          newCoffeeAmount = 45;
                          newWaterAmount = 720;
                          break;
                        default:
                          newCoffeeAmount = _updatedRecipe!.coffeeAmount;
                          newWaterAmount = _updatedRecipe!.waterAmount;
                      }

                      // Update the text controllers
                      _coffeeController.text = newCoffeeAmount.toString();
                      _waterController.text = newWaterAmount.toString();

                      // Update initialRatio
                      initialRatio = newWaterAmount / newCoffeeAmount;
                    }
                  });
                },
              ),
            ),
            Text(localizations.sizeXL),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorBanner(BuildContext context) {
    if (vendorBannerUrl == null) {
      return _buildRecipeSummary(context, _updatedRecipe!);
    }
    String vendorId = this.vendorId!;
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(vendorBannerUrl!))) {
          await launchUrl(Uri.parse(vendorBannerUrl!));
        }
      },
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.width > 1024
            ? (1024 / MediaQuery.of(context).size.aspectRatio)
            : MediaQuery.of(context).size.width *
                (9 / 16), // Maintain aspect ratio
        child: Image.network(
          "https://timercoffeeapp.fra1.cdn.digitaloceanspaces.com/$vendorId/banner.png",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If can't load image, show the recipe summary widget
            return _buildRecipeSummary(context, _updatedRecipe!);
          },
        ),
      ),
    );
  }

  Widget _buildRecipeSummary(BuildContext context, RecipeModel recipe) {
    return ExpansionTile(
      title: Text(AppLocalizations.of(context)!.recipesummary),
      subtitle: Text(AppLocalizations.of(context)!.recipesummarynote),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(RecipeSummary.fromRecipe(recipe).summary),
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

    // Save slider positions
    if (recipe.id == '106' || recipe.id == '1002') {
      await recipeProvider.saveSliderPositions(
        widget.recipeId,
        sweetnessSliderPosition:
            recipe.id == '106' ? _sweetnessSliderPosition : null,
        strengthSliderPosition:
            recipe.id == '106' ? _strengthSliderPosition : null,
        coffeeChroniclerSliderPosition:
            recipe.id == '1002' ? _coffeeChroniclerSliderPosition : null,
      );
    }

    // Use copyWith to create a new RecipeModel instance with updated values
    RecipeModel updatedRecipe = recipe.copyWith(
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
      sweetnessSliderPosition:
          recipe.id == '106' ? _sweetnessSliderPosition : null,
      strengthSliderPosition:
          recipe.id == '106' ? _strengthSliderPosition : null,
      coffeeChroniclerSliderPosition:
          recipe.id == '1002' ? _coffeeChroniclerSliderPosition : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreparationScreen(
            recipe: updatedRecipe,
            brewingMethodName: _brewingMethodName,
            coffeeChroniclerSliderPosition:
                updatedRecipe.coffeeChroniclerSliderPosition),
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
