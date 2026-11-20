import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import '../fields/labeled_field.dart';
import '../fields/numeric_text_field.dart';

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
                  child: _RequiredAmountField(
                    label: l10n.recipeCreationScreenCoffeeAmountLabel,
                    initialValue: coffeeAmount,
                    onChanged: onCoffeeAmountChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: _RequiredAmountField(
                    label: l10n.recipeCreationScreenWaterAmountLabel,
                    initialValue: waterAmount,
                    onChanged: onWaterAmountChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.fieldGap),

            // Water Temperature and Grind Size
            Row(
              children: [
                Expanded(
                  child: NumericTextField(
                    label: l10n.recipeCreationScreenWaterTempLabel,
                    initialValue: waterTemp,
                    allowDecimal: true,
                    maxDecimalPlaces: 2,
                    labelInsideField: true,
                    onChanged: onWaterTempChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: LabeledField(
                    label: l10n.recipeCreationScreenGrindSizeLabel,
                    initialValue: grindSize,
                    labelInsideField: true,
                    textCapitalization: TextCapitalization.none,
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
              padding: const EdgeInsets.only(bottom: AppSpacing.fieldGap),
              child: Text(l10n.recipeCreationScreenTotalBrewTimeLabel),
            ),
            Row(
              children: [
                Expanded(
                  child: NumericTextField(
                    label: l10n.recipeCreationScreenMinutesLabel,
                    initialValue: brewMinutes.toDouble(),
                    allowDecimal: false,
                    labelInsideField: true,
                    onChanged: (value) =>
                        onBrewMinutesChanged(value?.toInt() ?? 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: NumericTextField(
                    label: l10n.recipeCreationScreenSecondsLabel,
                    initialValue: brewSeconds.toDouble(),
                    allowDecimal: false,
                    labelInsideField: true,
                    onChanged: (value) =>
                        onBrewSecondsChanged(value?.toInt() ?? 0),
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

class _RequiredAmountField extends StatelessWidget {
  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _RequiredAmountField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // NumericTextField skips its custom validator for empty input. Track the
    // nullable value here to keep the recipe's required message and label.
    return FormField<double>(
      initialValue: initialValue,
      validator: (value) =>
          value == null ? l10n.recipeCreationScreenRequiredValidator : null,
      builder: (field) => NumericTextField(
        label: label,
        initialValue: field.value,
        errorText: field.errorText,
        allowDecimal: true,
        maxDecimalPlaces: 2,
        labelInsideField: true,
        onChanged: (value) {
          // The shared field also reports selection-only controller changes.
          if (value == field.value) return;
          field.didChange(value);
          onChanged(value ?? 0);
        },
      ),
    );
  }
}
