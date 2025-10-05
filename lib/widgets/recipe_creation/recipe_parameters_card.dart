import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';

class RecipeParametersCard extends StatelessWidget {
  final double coffeeAmount;
  final double waterAmount;
  final double? waterTemp;
  final String grindSize;
  final int brewMinutes;
  final int brewSeconds;
  final ValueChanged<double> onCoffeeAmountChanged;
  final ValueChanged<double> onWaterAmountChanged;
  final ValueChanged<double?> onWaterTempChanged;
  final ValueChanged<String> onGrindSizeChanged;
  final ValueChanged<int> onBrewMinutesChanged;
  final ValueChanged<int> onBrewSecondsChanged;

  const RecipeParametersCard({
    super.key,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.waterTemp,
    required this.grindSize,
    required this.brewMinutes,
    required this.brewSeconds,
    required this.onCoffeeAmountChanged,
    required this.onWaterAmountChanged,
    required this.onWaterTempChanged,
    required this.onGrindSizeChanged,
    required this.onBrewMinutesChanged,
    required this.onBrewSecondsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coffee and Water Amounts
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
                const SizedBox(width: AppSpacing.fieldGap),
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
            const SizedBox(height: AppSpacing.fieldGap),

            // Water Temperature and Grind Size
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
                const SizedBox(width: AppSpacing.fieldGap),
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
            const SizedBox(height: AppSpacing.fieldGap),

            // Brew Time
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
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
                const SizedBox(width: AppSpacing.fieldGap),
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
          ],
        ),
      ),
    );
  }
}
