import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import '../../theme/design_tokens.dart';

class SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppElevatedButton(
      label: label,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      height: AppButton.heightLarge,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );
  }
}
