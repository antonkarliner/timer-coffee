import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/widgets/recipe_detail/rich_text_links.dart';
import 'package:coffee_timer/widgets/recipe_detail/bean_selection_row.dart';
import 'package:coffee_timer/widgets/recipe_detail/amount_fields.dart';
import 'package:coffee_timer/widgets/recipe_detail/meta_info_section.dart';
import 'package:coffee_timer/widgets/recipe_detail/slider_chronicler_1002.dart';
import 'package:coffee_timer/widgets/recipe_detail/sliders_106.dart';
import 'package:coffee_timer/widgets/recipe_detail/recipe_summary_tile.dart';

/// Widget that builds the main recipe content including all sections
class RecipeContentBuilder extends StatefulWidget {
  final RecipeModel recipe;
  final RecipeDetailController controller;
  final String? effectiveRecipeId;
  final VoidCallback onSelectBeans;
  final VoidCallback onClearBeanSelection;
  final VoidCallback onCoffeeAmountChanged;
  final VoidCallback onWaterAmountChanged;
  final VoidCallback onCoffeeFocus;
  final VoidCallback onWaterFocus;

  const RecipeContentBuilder({
    Key? key,
    required this.recipe,
    required this.controller,
    required this.effectiveRecipeId,
    required this.onSelectBeans,
    required this.onClearBeanSelection,
    required this.onCoffeeAmountChanged,
    required this.onWaterAmountChanged,
    required this.onCoffeeFocus,
    required this.onWaterFocus,
  }) : super(key: key);

  @override
  State<RecipeContentBuilder> createState() => _RecipeContentBuilderState();
}

class _RecipeContentBuilderState extends State<RecipeContentBuilder> {
  bool _isEditingGrindSize = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final recipe = widget.recipe;
    final controller = widget.controller;
    final effectiveRecipeId = widget.effectiveRecipeId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        // Rich text with markdown-like links; disable for user recipes
        if (!(effectiveRecipeId?.startsWith('usr-') ?? false))
          RichTextLinks(
            text: recipe.shortDescription,
            onTapUrl: (uri) async {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          )
        else
          Text(
            recipe.shortDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: 16),
        BeanSelectionRow(
          selectedBeanUuid: controller.selectedBeanUuid,
          selectedBeanName: controller.selectedBeanName,
          originalRoasterLogoUrl: controller.originalRoasterLogoUrl,
          mirrorRoasterLogoUrl: controller.mirrorRoasterLogoUrl,
          onSelectBeans: widget.onSelectBeans,
          onClearSelection: widget.onClearBeanSelection,
        ),
        const SizedBox(height: 24),
        AmountFields(
          coffeeController: controller.coffeeController,
          waterController: controller.waterController,
          onCoffeeChanged: widget.onCoffeeAmountChanged,
          onWaterChanged: widget.onWaterAmountChanged,
          onCoffeeFocus: widget.onCoffeeFocus,
          onWaterFocus: widget.onWaterFocus,
        ),
        const SizedBox(height: 16),
        // Grind size: read-only by default, editable on tap of edit icon
        if (_isEditingGrindSize)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.grindSizeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: loc.grindsize,
                    border: const OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) {
                    setState(() => _isEditingGrindSize = false);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  setState(() => _isEditingGrindSize = false);
                },
              ),
            ],
          )
        else
          Row(
            children: [
              Flexible(
                child: Text(
                  '${loc.grindsize}: ${controller.grindSizeController.text.isNotEmpty ? controller.grindSizeController.text : loc.notProvided}',
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() => _isEditingGrindSize = true);
                },
                child: const Icon(Icons.edit, size: 18),
              ),
            ],
          ),
        const SizedBox(height: 16),
        MetaInfoSection(
          waterTempCelsius: recipe.waterTemp,
          brewTime: recipe.brewTime,
        ),
        const SizedBox(height: 16),
        // Use effective ID for slider logic
        if (effectiveRecipeId == '1002')
          CoffeeChroniclerSizeSlider(
            position: controller.coffeeChroniclerSliderPosition,
            onChanged: (int value) {
              final mapped =
                  controller.setChroniclerPositionAndMapAmounts(value);
              if (recipe.id == '1002' && mapped != null) {
                controller.applyAmounts(mapped['coffee']!, mapped['water']!);
              }
            },
          ),
        if (effectiveRecipeId == '106')
          SweetnessStrengthSliders(
            sweetnessPosition: controller.sweetnessSliderPosition,
            strengthPosition: controller.strengthSliderPosition,
            onSweetnessChanged: (v) {
              controller.setSweetnessPosition(v);
            },
            onStrengthChanged: (v) {
              controller.setStrengthPosition(v);
            },
          ),
        if (effectiveRecipeId != '106' && effectiveRecipeId != '1002')
          RecipeSummaryTile(
            recipe: recipe,
            controller: controller,
          ),
      ],
    );
  }
}
