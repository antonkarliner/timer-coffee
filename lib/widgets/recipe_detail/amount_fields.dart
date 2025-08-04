import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Stateless amount fields row (coffee / water).
/// Parsing, ratio logic, and state are expected to be handled by the caller/controller.
class AmountFields extends StatelessWidget {
  final TextEditingController coffeeController;
  final TextEditingController waterController;
  final VoidCallback onCoffeeChanged;
  final VoidCallback onWaterChanged;
  final VoidCallback onCoffeeFocus;
  final VoidCallback onWaterFocus;

  const AmountFields({
    Key? key,
    required this.coffeeController,
    required this.waterController,
    required this.onCoffeeChanged,
    required this.onWaterChanged,
    required this.onCoffeeFocus,
    required this.onWaterFocus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: coffeeController,
            decoration: InputDecoration(labelText: l10n.coffeeamount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onCoffeeChanged(),
            onTap: onCoffeeFocus,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: waterController,
            decoration: InputDecoration(labelText: l10n.wateramount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onWaterChanged(),
            onTap: onWaterFocus,
          ),
        ),
      ],
    );
  }
}
