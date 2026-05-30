import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// A reusable row widget for displaying label-value pairs in detail screens.
///
/// This widget provides a consistent layout for displaying information with
/// a label on the left and corresponding value on the right, following the
/// design pattern used in the coffee beans detail screen.
///
/// The layout uses equal flex columns with a small gap to keep label and
/// value clearly separated and to give long compound labels (e.g. Russian
/// "Происхождения", "Разновидность") enough room to wrap on word boundaries
/// instead of mid-character.
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

  /// Optional secondary text shown below the value in a muted style
  final String? valueSubtitle;

  const DetailItemRow({
    super.key,
    required this.label,
    this.value,
    this.placeholder = '-',
    this.labelStyle,
    this.valueStyle,
    this.verticalPadding = 4.0,
    this.labelFlex = 1,
    this.valueFlex = 1,
    this.valueSubtitle,
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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: valueFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayValue,
                    style: valueStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  if (valueSubtitle != null)
                    Text(
                      valueSubtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
