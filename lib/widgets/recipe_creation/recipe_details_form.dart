import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import '../../models/brewing_method_model.dart';
import '../../theme/design_tokens.dart';
import 'recipe_basic_info_card.dart';
import 'recipe_brewing_method_card.dart';
import 'recipe_parameters_card.dart';

class RecipeDetailsForm extends StatelessWidget {
  final TextEditingController recipeNameController;
  final TextEditingController shortDescriptionController;
  final List<BrewingMethodModel> brewingMethods;
  final String? selectedBrewingMethodId;
  final double coffeeAmount;
  final double waterAmount;
  final double? waterTemp;
  final String grindSize;
  final int brewMinutes;
  final int brewSeconds;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onShortDescriptionChanged;
  final ValueChanged<String?> onBrewingMethodChanged;
  final ValueChanged<double> onCoffeeAmountChanged;
  final ValueChanged<double> onWaterAmountChanged;
  final ValueChanged<double?> onWaterTempChanged;
  final ValueChanged<String> onGrindSizeChanged;
  final ValueChanged<int> onBrewMinutesChanged;
  final ValueChanged<int> onBrewSecondsChanged;
  final VoidCallback? onContinue;

  const RecipeDetailsForm({
    super.key,
    required this.recipeNameController,
    required this.shortDescriptionController,
    required this.brewingMethods,
    required this.selectedBrewingMethodId,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.waterTemp,
    required this.grindSize,
    required this.brewMinutes,
    required this.brewSeconds,
    required this.onNameChanged,
    required this.onShortDescriptionChanged,
    required this.onBrewingMethodChanged,
    required this.onCoffeeAmountChanged,
    required this.onWaterAmountChanged,
    required this.onWaterTempChanged,
    required this.onGrindSizeChanged,
    required this.onBrewMinutesChanged,
    required this.onBrewSecondsChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      key: const PageStorageKey('recipeCreationFirstPage'),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: Recipe Name and Description
            RecipeBasicInfoCard(
              recipeNameController: recipeNameController,
              shortDescriptionController: shortDescriptionController,
              onNameChanged: onNameChanged,
              onShortDescriptionChanged: onShortDescriptionChanged,
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // Card 2: Brewing Method
            RecipeBrewingMethodCard(
              brewingMethods: brewingMethods,
              selectedBrewingMethodId: selectedBrewingMethodId,
              onBrewingMethodChanged: onBrewingMethodChanged,
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // Card 3: Recipe Parameters
            RecipeParametersCard(
              coffeeAmount: coffeeAmount,
              waterAmount: waterAmount,
              waterTemp: waterTemp,
              grindSize: grindSize,
              brewMinutes: brewMinutes,
              brewSeconds: brewSeconds,
              onCoffeeAmountChanged: onCoffeeAmountChanged,
              onWaterAmountChanged: onWaterAmountChanged,
              onWaterTempChanged: onWaterTempChanged,
              onGrindSizeChanged: onGrindSizeChanged,
              onBrewMinutesChanged: onBrewMinutesChanged,
              onBrewSecondsChanged: onBrewSecondsChanged,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Continue Button
            AppElevatedButton(
              label: l10n.recipeCreationScreenContinueButton,
              onPressed: onContinue,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ],
        ),
      ),
    );
  }
}
