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
    return FloatingActionButton(
      onPressed: onPressed,
      child: icon ?? const Icon(Icons.arrow_forward),
    );
  }
}
