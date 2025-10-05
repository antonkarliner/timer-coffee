import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class InventorySection extends StatefulWidget {
  final double? packageWeightGrams;
  final ValueChanged<double?> onPackageWeightGramsChanged;

  const InventorySection({
    super.key,
    this.packageWeightGrams,
    required this.onPackageWeightGramsChanged,
  });

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NumericTextField(
      label: '${loc.amountLeft} (${loc.unitGramsShort})',
      hintText: loc.inventoryWeightExample,
      initialValue: widget.packageWeightGrams,
      allowDecimal: true,
      maxDecimalPlaces: 2,
      min: 0.1,
      semanticIdentifier: 'amountLeftInputField',
      onChanged: (value) {
        widget.onPackageWeightGramsChanged(value);
      },
      onSubmitted: (value) {
        widget.onPackageWeightGramsChanged(value);
      },
    );
  }
}
