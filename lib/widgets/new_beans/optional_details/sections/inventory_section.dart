import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/new_beans/section_header.dart';
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
  late final TextEditingController _packageWeightController;

  String _formatDouble(double val) {
    return (val % 1 == 0) ? val.toInt().toString() : val.toString();
  }

  @override
  void initState() {
    super.initState();
    _packageWeightController = TextEditingController(
      text: widget.packageWeightGrams == null
          ? ''
          : _formatDouble(widget.packageWeightGrams!),
    );
  }

  @override
  void didUpdateWidget(covariant InventorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller when external value actually changed
    if (oldWidget.packageWeightGrams != widget.packageWeightGrams) {
      String newText;
      if (widget.packageWeightGrams == null) {
        newText = '';
      } else {
        newText = _formatDouble(widget.packageWeightGrams!);
      }
      if (_packageWeightController.text != newText) {
        _packageWeightController.value =
            _packageWeightController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
          composing: TextRange.empty,
        );
      }
    }
  }

  @override
  void dispose() {
    _packageWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: Icons.inventory, title: loc.inventory),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'amountLeftInputField',
          label: loc.enterAmountLeft,
          child: TextFormField(
            controller: _packageWeightController,
            decoration: InputDecoration(
              labelText: loc.amountLeft,
              hintText: 'e.g., 250.5',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                widget.onPackageWeightGramsChanged(parsed);
              }
            },
            onEditingComplete: () {
              // Validate on editing complete to avoid flashing during typing
              final text = _packageWeightController.text;
              if (text.isNotEmpty) {
                final double? num = double.tryParse(text);
                if (num != null && num < 0.1) {
                  // Show validation error only when editing is complete
                  _packageWeightController.clear();
                  widget.onPackageWeightGramsChanged(null);
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
