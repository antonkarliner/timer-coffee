import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

/// A slim, always-visible strip at the top of the My Beans screen that shows
/// the total tracked "amount left" (grams) across the user's beans.
///
/// When a filter or search is active, the value is the sum for the beans
/// currently in scope and is shown as "`filtered` of `grand total`" so a
/// subtotal is never mistaken for everything the user owns. Beans without a
/// tracked weight simply contribute nothing to the sum.
///
/// The strip hides itself entirely when there is nothing tracked
/// (grand total of 0), which also covers the empty-state screen.
class BeansTotalSummary extends StatelessWidget {
  /// Sum of tracked grams for the beans currently in scope (after filters/search).
  final double scopedGrams;

  /// Sum of tracked grams across all non-deleted beans, ignoring filters/search.
  final double grandTotalGrams;

  /// Whether a filter or search is currently narrowing the list.
  final bool hasActiveFilters;

  const BeansTotalSummary({
    super.key,
    required this.scopedGrams,
    required this.grandTotalGrams,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    // Nothing tracked at all: don't clutter the screen with "0 g".
    if (grandTotalGrams <= 0) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final unit = loc.unitGramsShort;

    final label =
        hasActiveFilters ? loc.beansFilteredLabel : loc.beansTotalLeftLabel;
    final valueText = hasActiveFilters
        ? loc.beansAmountOfTotal(
            _formatGrams(scopedGrams, unit),
            _formatGrams(grandTotalGrams, unit),
          )
        : _formatGrams(grandTotalGrams, unit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Coffeico.bag_with_bean,
            size: AppIconSize.small,
            color: colorScheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              valueText,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    hasActiveFilters ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats grams without trailing ".0" for whole numbers (e.g. "842 g"),
  /// otherwise keeps a single decimal (e.g. "842.5 g").
  String _formatGrams(double grams, String unit) {
    final isWhole = (grams - grams.roundToDouble()).abs() < 0.05;
    final numStr = isWhole ? grams.round().toString() : grams.toStringAsFixed(1);
    return '$numStr $unit';
  }
}
