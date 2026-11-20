import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Amount fields row (coffee / water).
/// Parsing, ratio logic, and state are expected to be handled by the caller/controller.
class AmountFields extends StatefulWidget {
  final TextEditingController coffeeController;
  final TextEditingController waterController;
  final VoidCallback onCoffeeChanged;
  final VoidCallback onWaterChanged;
  final VoidCallback onCoffeeFocus;
  final VoidCallback onWaterFocus;

  const AmountFields({
    super.key,
    required this.coffeeController,
    required this.waterController,
    required this.onCoffeeChanged,
    required this.onWaterChanged,
    required this.onCoffeeFocus,
    required this.onWaterFocus,
  });

  @override
  State<AmountFields> createState() => _AmountFieldsState();
}

class _AmountFieldsState extends State<AmountFields> {
  final FocusNode _coffeeFocusNode = FocusNode();
  final FocusNode _waterFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _coffeeFocusNode.addListener(_onCoffeeFocusChanged);
    _waterFocusNode.addListener(_onWaterFocusChanged);
  }

  @override
  void dispose() {
    _coffeeFocusNode.dispose();
    _waterFocusNode.dispose();
    super.dispose();
  }

  void _onCoffeeFocusChanged() {
    if (_coffeeFocusNode.hasFocus) widget.onCoffeeFocus();
  }

  void _onWaterFocusChanged() {
    if (_waterFocusNode.hasFocus) widget.onWaterFocus();
  }

  LabeledField _buildAmountField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onChanged,
  }) {
    // LabeledField reports controller notifications as well as input changes.
    // Forward one callback per user text edit so ratio updates can write either
    // controller without triggering another calculation.
    var hasUserEdit = false;
    return LabeledField(
      label: label,
      labelInsideField: true,
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textCapitalization: TextCapitalization.none,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          hasUserEdit = oldValue.text != newValue.text;
          return newValue;
        }),
      ],
      onChanged: (_) {
        if (!hasUserEdit) return;
        hasUserEdit = false;
        onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildAmountField(
            label: l10n.coffeeamount,
            controller: widget.coffeeController,
            focusNode: _coffeeFocusNode,
            onChanged: widget.onCoffeeChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: _buildAmountField(
            label: l10n.wateramount,
            controller: widget.waterController,
            focusNode: _waterFocusNode,
            onChanged: widget.onWaterChanged,
          ),
        ),
      ],
    );
  }
}
