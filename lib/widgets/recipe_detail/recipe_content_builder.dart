import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/roaster_profile_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/utils/grind_suggestions.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/recipe_detail/rich_text_links.dart';
import 'package:coffee_timer/widgets/recipe_detail/bean_selection_row.dart';
import 'package:coffee_timer/widgets/recipe_detail/amount_fields.dart';
import 'package:coffee_timer/widgets/recipe_detail/slider_chronicler_1002.dart';
import 'package:coffee_timer/widgets/recipe_detail/sliders_106.dart';
import 'package:coffee_timer/widgets/recipe_detail/recipe_summary_tile.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/utils/temperature_format.dart';

import 'package:coffee_timer/services/recipe_publication.dart';
import 'package:coffee_timer/widgets/account/account_identity.dart';

/// Widget that builds the main recipe content including all sections
class RecipeContentBuilder extends StatefulWidget {
  final RecipeModel recipe;
  final RecipeDetailController controller;
  final String? effectiveRecipeId;
  final bool isPreview;
  final VoidCallback onSelectBeans;
  final VoidCallback onClearBeanSelection;
  final VoidCallback onCoffeeAmountChanged;
  final VoidCallback onWaterAmountChanged;
  final VoidCallback onCoffeeFocus;
  final VoidCallback onWaterFocus;

  const RecipeContentBuilder({
    super.key,
    required this.recipe,
    required this.controller,
    required this.effectiveRecipeId,
    this.isPreview = false,
    required this.onSelectBeans,
    required this.onClearBeanSelection,
    required this.onCoffeeAmountChanged,
    required this.onWaterAmountChanged,
    required this.onCoffeeFocus,
    required this.onWaterFocus,
  });

  @override
  State<RecipeContentBuilder> createState() => _RecipeContentBuilderState();
}

class _RecipeContentBuilderState extends State<RecipeContentBuilder> {
  bool _isEditingGrindSize = false;
  bool _isEditingWaterTemperature = false;
  ({String name, String? roasterSlug})? _author;
  ({String name, String? roasterSlug})? _originalAuthor;
  Future<List<String>>? _grindSizeOptions;
  late final FocusNode _grindSizeFocusNode;

  @override
  void initState() {
    super.initState();
    _grindSizeFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _lookupRoasterProfile(),
    );
  }

  Future<List<String>> _loadGrindSizeOptions() =>
      _grindSizeOptions ??= mergedGrindSizeSuggestions(
        brewHistoryGrinds: Provider.of<UserStatProvider>(
          context,
          listen: false,
        ).fetchAllDistinctGrindSizes(),
        beanGrinds: Provider.of<CoffeeBeansProvider>(
          context,
          listen: false,
        ).fetchAllDistinctGrindSizes(),
      );

  @override
  void dispose() {
    _grindSizeFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RecipeContentBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.id != widget.recipe.id ||
        oldWidget.recipe.vendorId != widget.recipe.vendorId ||
        oldWidget.recipe.importId != widget.recipe.importId ||
        oldWidget.recipe.originalAuthorId != widget.recipe.originalAuthorId) {
      _author = null;
      _originalAuthor = null;
      _lookupRoasterProfile();
    }
  }

  Future<void> _lookupRoasterProfile() async {
    if (!mounted) return;
    final recipe = widget.recipe;
    final provider = Provider.of<RoasterProfileProvider>(
      context,
      listen: false,
    );

    final vendorId = recipe.vendorId;
    final sourceId = recipe.importId;
    // Confirmed imports carry the immediate publication ID. Legacy imports
    // may have flattened ancestry, so don't attribute their text to that ID.
    final hasExactSource =
        sourceId != null &&
        vendorId != null &&
        vendorId.startsWith('usr-') &&
        isExactImportedRecipe(recipe.id, vendorId.substring(4), sourceId);
    final authorVendorId = hasExactSource
        ? RegExp(r'^usr-[a-f0-9-]{36}(?=-)').stringMatch(sourceId)
        : recipe.isImported
        ? null
        : vendorId;
    final originalId = recipe.originalAuthorId;
    final originalVendorId = originalId == null ? null : 'usr-$originalId';
    final profiles = await Future.wait([
      _attribution(provider, authorVendorId),
      _attribution(
        provider,
        originalVendorId == authorVendorId ? null : originalVendorId,
      ),
    ]);
    if (mounted &&
        widget.recipe.id == recipe.id &&
        widget.recipe.vendorId == recipe.vendorId &&
        widget.recipe.importId == recipe.importId &&
        widget.recipe.originalAuthorId == recipe.originalAuthorId) {
      setState(() {
        _author = profiles[0];
        _originalAuthor = profiles[1];
      });
    }
  }

  Future<({String name, String? roasterSlug})?> _attribution(
    RoasterProfileProvider provider,
    String? vendorId,
  ) async {
    if (vendorId == null ||
        !RegExp(r'^usr-[a-f0-9-]{36}$').hasMatch(vendorId)) {
      return null;
    }
    try {
      final roaster = await provider.fetchRoasterProfileByVendorId(vendorId);
      if (roaster != null) {
        return (name: roaster.roasterName, roasterSlug: roaster.slug);
      }
      final displayName = await fetchAccountDisplayName(vendorId.substring(4));
      if (displayName != null && displayName.isNotEmpty) {
        return (name: displayName, roasterSlug: null);
      }
    } catch (_) {
      // Attribution lookup must not prevent reading the recipe.
    }
    return null;
  }

  Widget _buildAttribution(
    BuildContext context,
    ({String name, String? roasterSlug}) author,
    String label,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final slug = author.roasterSlug;
    return InkWell(
      onTap: slug == null
          ? null
          : () => context.router.push(RoasterProfileRoute(slug: slug)),
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Text.rich(
        TextSpan(
          text: label,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: author.name,
              style: AppTextStyles.caption.copyWith(
                color: slug == null
                    ? colorScheme.onSurface
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        if (_author case final author?) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildAttribution(context, author, loc.recipeByPrefix),
        ],
        if (_originalAuthor case final author?) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildAttribution(context, author, loc.originalRecipeByPrefix),
        ],
        const SizedBox(height: 16),
        // Rich text with markdown-like links; disable for user recipes
        if (recipe.shortDescription.isNotEmpty) ...[
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
        ],
        if (widget.isPreview) ...[
          RecipeSummaryTile(recipe: recipe, controller: controller),
          for (final step in recipe.steps)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(step.description, style: AppTextStyles.body),
            ),
        ] else ...[
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
          const SizedBox(height: AppSpacing.base),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          // Keep editable settings aligned, with full-size accessible edit targets.
          if (_isEditingGrindSize)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownSearchField(
                    controller: controller.grindSizeController,
                    focusNode: _grindSizeFocusNode,
                    label: loc.grindsize,
                    hintText: loc.enterBeanGrindSize,
                    initialSuggestions: (currentText) =>
                        loadRecentGrindSuggestions(
                          recent: Provider.of<UserStatProvider>(
                            this.context,
                            listen: false,
                          ).fetchRecentDistinctGrindSizes(limit: 4),
                          beans: Provider.of<CoffeeBeansProvider>(
                            this.context,
                            listen: false,
                          ).fetchAllDistinctGrindSizes(),
                          exclude: currentText,
                        ),
                    onSearch: (query) async {
                      final options = await _loadGrindSizeOptions();
                      if (query.isEmpty) return options;
                      return options
                          .where(
                            (option) => option.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();
                    },
                    onChanged: (_) {
                      controller.markGrindSizeManuallyEdited();
                    },
                    onSubmitted: (_) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.grindsize, style: AppTextStyles.caption),
                      Text(
                        controller.grindSizeController.text.isNotEmpty
                            ? controller.grindSizeController.text
                            : loc.notProvided,
                        style: AppTextStyles.fieldLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: '${loc.edit}: ${loc.grindsize}',
                  constraints: const BoxConstraints.tightFor(
                    width: AppButton.heightMedium,
                    height: AppButton.heightMedium,
                  ),
                  onPressed: () {
                    setState(() => _isEditingGrindSize = true);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _grindSizeFocusNode.requestFocus(),
                    );
                  },
                  icon: const Icon(Icons.edit, size: AppIconSize.small),
                ),
              ],
            ),
          if (controller.shouldShowGrindSuggestion)
            Row(
              children: [
                Expanded(
                  child: Text(
                    switch (controller.suggestedGrindTasteBalance) {
                      -1 => loc.grindSuggestionSour,
                      1 => loc.grindSuggestionBitter,
                      _ => loc.lastGrindSuggestion(
                        controller.suggestedGrindSize!.trim(),
                      ),
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppTextButton(
                  label: loc.useGrindSuggestion,
                  onPressed: controller.applyGrindSuggestion,
                  isFullWidth: false,
                  height: AppButton.heightSmall,
                  padding: AppButton.paddingSmall,
                  textStyle: AppTextStyles.caption,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          if (_isEditingWaterTemperature)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NumericTextField(
                    label: '${loc.watertemp} (°C)',
                    initialValue: controller.waterTemperature,
                    labelInsideField: true,
                    autofocus: true,
                    helperText: formatTemperatureInputHelper(
                      controller.waterTemperature,
                    ),
                    allowDecimal: true,
                    onChanged: controller.markWaterTemperatureManuallyEdited,
                    onSubmitted: (_) {
                      setState(() => _isEditingWaterTemperature = false);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    setState(() => _isEditingWaterTemperature = false);
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.watertemp, style: AppTextStyles.caption),
                      Text(
                        formatTemperatureDual(
                              controller.effectiveWaterTemperature,
                            ) ??
                            loc.notProvided,
                        style: AppTextStyles.fieldLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: '${loc.edit}: ${loc.watertemp}',
                  constraints: const BoxConstraints.tightFor(
                    width: AppButton.heightMedium,
                    height: AppButton.heightMedium,
                  ),
                  onPressed: () {
                    setState(() => _isEditingWaterTemperature = true);
                  },
                  icon: const Icon(Icons.edit, size: AppIconSize.small),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Use effective ID for slider logic
          if (effectiveRecipeId == '1002')
            CoffeeChroniclerSizeSlider(
              position: controller.coffeeChroniclerSliderPosition,
              onChanged: (int value) {
                final mapped = controller.setChroniclerPositionAndMapAmounts(
                  value,
                );
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
            RecipeSummaryTile(recipe: recipe, controller: controller),
        ],
      ],
    );
  }
}
