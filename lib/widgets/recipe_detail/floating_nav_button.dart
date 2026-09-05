import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

class FloatingNavButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? icon;

  const FloatingNavButton({super.key, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.preparation;
    return Semantics(
      identifier: 'recipeDetailNextButton',
      label: label,
      button: true,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          // The parent positions this action at the trailing edge of the screen.
          // Bound long translations so they wrap rather than leave the viewport.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - AppSpacing.xl,
          ),
          child: AppElevatedButton(
            label: label,
            onPressed: onPressed,
            iconWidget: icon ?? const Icon(Icons.arrow_forward),
            isFullWidth: false,
            height: AppButton.heightLarge,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
