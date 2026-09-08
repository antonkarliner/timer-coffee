import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Compact arrow action that advances from the recipe setup to the timer.
///
/// Icon-only by design: the accessible name ("Preparation") is provided via
/// [Semantics.label], and the stable `recipeDetailNextButton` identifier keeps
/// screenshot automation working.
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
        child: FloatingActionButton(
          onPressed: onPressed,
          child: icon ?? const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
