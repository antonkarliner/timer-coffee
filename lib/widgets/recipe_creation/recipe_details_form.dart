import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../models/brewing_method_model.dart';

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
            TextFormField(
              controller: recipeNameController,
              decoration: InputDecoration(
                labelText: l10n.recipeCreationScreenRecipeNameLabel,
                border: OutlineInputBorder(),
              ),
              onChanged: onNameChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.recipeCreationScreenRecipeNameValidator;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: shortDescriptionController,
              decoration: InputDecoration(
                labelText: l10n.recipeCreationScreenShortDescriptionLabel,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: onShortDescriptionChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.recipeCreationScreenShortDescriptionValidator;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: l10n.recipeCreationScreenBrewingMethodLabel,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
              value: selectedBrewingMethodId,
              items: brewingMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method.brewingMethodId,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      method.brewingMethod,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onBrewingMethodChanged,
              validator: (value) {
                if (value == null) {
                  return l10n.recipeCreationScreenBrewingMethodValidator;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: coffeeAmount.toString(),
                    decoration: InputDecoration(
                      labelText: l10n.recipeCreationScreenCoffeeAmountLabel,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      onCoffeeAmountChanged(double.tryParse(value) ?? 0);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.recipeCreationScreenRequiredValidator;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.recipeCreationScreenInvalidNumberValidator;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: waterAmount.toString(),
                    decoration: InputDecoration(
                      labelText: l10n.recipeCreationScreenWaterAmountLabel,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      onWaterAmountChanged(double.tryParse(value) ?? 0);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.recipeCreationScreenRequiredValidator;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.recipeCreationScreenInvalidNumberValidator;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: waterTemp?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: l10n.recipeCreationScreenWaterTempLabel,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      onWaterTempChanged(
                          value.isEmpty ? null : double.tryParse(value));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: grindSize,
                    decoration: InputDecoration(
                      labelText: l10n.recipeCreationScreenGrindSizeLabel,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onGrindSizeChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.recipeCreationScreenRequiredValidator;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(l10n.recipeCreationScreenTotalBrewTimeLabel),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: brewMinutes.toString(),
                    decoration: InputDecoration(
                      labelText: l10n.recipeCreationScreenMinutesLabel,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      onBrewMinutesChanged(int.tryParse(value) ?? 0);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: brewSeconds.toString(),
                    decoration: InputDecoration(
                      labelText: l10n.recipeCreationScreenSecondsLabel,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      onBrewSecondsChanged(int.tryParse(value) ?? 0);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onPressed: onContinue,
              child: Text(l10n.recipeCreationScreenContinueButton),
            ),
          ],
        ),
      ),
    );
  }
}
