import 'package:flutter/material.dart';

/// A reusable header widget for detail screen sections.
///
/// This widget provides a consistent header layout with an icon and title,
/// following the design pattern used throughout the coffee beans detail screen.
/// It supports theming and accessibility features.
///
/// Example usage:
/// ```dart
/// DetailSectionHeader(
///   icon: Icons.info_outline,
///   title: 'Basic Information',
/// )
/// ```
class DetailSectionHeader extends StatelessWidget {
  /// The icon to display at the start of the header
  final IconData icon;

  /// The title text to display next to the icon
  final String title;

  /// Optional custom icon size (defaults to 24.0)
  final double? iconSize;

  /// Optional custom icon color (defaults to theme primary color)
  final Color? iconColor;

  /// Optional custom text style (defaults to theme titleLarge with bold weight)
  final TextStyle? textStyle;

  /// How the icon aligns against the title. Defaults to center; pass
  /// [CrossAxisAlignment.start] to pin the icon to the first line when the
  /// title can wrap to multiple lines.
  final CrossAxisAlignment crossAxisAlignment;

  const DetailSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconSize,
    this.iconColor,
    this.textStyle,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: 'detailSectionHeader_$title',
      label: title,
      header: true,
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Icon(
            icon,
            color: iconColor ?? theme.colorScheme.primary,
            size: iconSize ?? 24.0,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: textStyle ??
                  theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
