import 'package:flutter/material.dart';

/// A reusable chip widget for displaying quick statistics with icon, label, and value.
///
/// This widget provides a compact, visually appealing way to display key statistics
/// in a rounded container with an icon, label, and value arranged vertically.
/// It follows the design pattern used in the coffee beans detail screen hero header.
///
/// The chip adapts to the current theme and provides proper contrast in both
/// light and dark modes with a semi-transparent surface background.
///
/// Example usage:
/// ```dart
/// QuickStatChip(
///   icon: Icons.calendar_today,
///   label: 'Roast Date',
///   value: 'Jan 15, 2024',
/// )
/// ```
class QuickStatChip extends StatelessWidget {
  /// The icon to display at the top of the chip
  final IconData icon;

  /// The label text to display below the icon
  final String label;

  /// The value text to display at the bottom
  final String value;

  /// Optional custom icon size (defaults to 20.0)
  final double? iconSize;

  /// Optional custom icon color (defaults to theme primary color)
  final Color? iconColor;

  /// Optional custom label text style
  final TextStyle? labelStyle;

  /// Optional custom value text style
  final TextStyle? valueStyle;

  /// Optional custom background color (defaults to theme surface with opacity)
  final Color? backgroundColor;

  /// Optional custom border radius (defaults to 8.0)
  final double borderRadius;

  /// Optional custom padding (defaults to symmetric horizontal: 12, vertical: 8)
  final EdgeInsetsGeometry? padding;

  const QuickStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconSize,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: 'quickStat_$label',
      label: '$label: $value',
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor ?? theme.colorScheme.surface.withOpacity(0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize ?? 20.0,
              color: iconColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: labelStyle ?? theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
