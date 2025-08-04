import 'package:flutter/material.dart';

class FloatingNavButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? icon;

  const FloatingNavButton({
    Key? key,
    required this.onPressed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: icon ?? const Icon(Icons.arrow_forward),
    );
  }
}
