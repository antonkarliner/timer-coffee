import 'package:flutter/material.dart';

/// A reusable row widget for displaying label-value pairs in detail screens.
///
/// This widget provides a consistent layout for displaying information with
/// a label on the left and corresponding value on the right, following the
/// design pattern used in the coffee beans detail screen.
///
/// The layout uses flex ratios (2:3) to ensure consistent alignment across
/// multiple rows and includes proper semantic labeling for accessibility.
///
/// Example usage:
/// ```dart
/// DetailItemRow(
///   label: 'Origin',
///   value: 'Ethiopia',
/// )
/// ```
class DetailItemRow extends StatelessWidget {
  /// The label text to display on the left side
  final String label;

  /// The value text to display on the right side (can be null)
  final String? value;

  /// The placeholder text to show when value is null or empty (defaults to '-')
  final String placeholder;

  /// Optional custom label text style
  final TextStyle? labelStyle;

  /// Optional custom value text style
  final TextStyle? valueStyle;

  /// Vertical padding between rows (defaults to 4.0)
  final double verticalPadding;

  /// Flex ratio for the label column (defaults to 2)
  final int labelFlex;

  /// Flex ratio for the value column (defaults to 3)
  final int valueFlex;

  const DetailItemRow({
    super.key,
    required this.label,
    this.value,
    this.placeholder = '-',
    this.labelStyle,
    this.valueStyle,
    this.verticalPadding = 4.0,
    this.labelFlex = 2,
    this.valueFlex = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = (value?.isNotEmpty == true) ? value! : placeholder;

    return Semantics(
      identifier: 'detailItem_$label',
      label: '$label: $displayValue',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: labelFlex,
              child: Text(
                label,
                style: labelStyle ??
                    theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              flex: valueFlex,
              child: Text(
                displayValue,
                style: valueStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
