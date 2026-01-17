import 'package:flutter/material.dart';

class DeleteButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDisabled;
  final double iconSize;
  final String? tooltip;

  const DeleteButton({
    super.key,
    required this.onPressed,
    this.isDisabled = false,
    this.iconSize = 24.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: Icon(
        Icons.remove_circle_outline,
        size: iconSize,
        color: isDisabled
            ? theme.colorScheme.onSurface.withOpacity(0.3)
            : Colors.red,
      ),
      onPressed: isDisabled ? null : onPressed,
      tooltip: tooltip ?? 'Delete',
    );
  }
}
