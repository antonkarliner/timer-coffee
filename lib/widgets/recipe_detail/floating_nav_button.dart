import 'package:flutter/material.dart';

class FloatingNavButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? icon;

  const FloatingNavButton({
    super.key,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'recipeDetailNextButton',
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
