// lib/widgets/roaster_profile/aggregate_rating.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import 'star_rating.dart';

/// Displays the aggregate rating for a roaster: average stars + review count.
class AggregateRating extends StatelessWidget {
  final double? avgRating;
  final int reviewCount;

  const AggregateRating({
    super.key,
    required this.avgRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (reviewCount == 0) {
      return Text(
        l10n.noReviewsYet,
        style: AppTextStyles.body.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    return Row(
      children: [
        StarRating(
          value: avgRating ?? 0,
          starSize: AppIconSize.medium,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          avgRating != null ? avgRating!.toStringAsFixed(1) : '—',
          style: AppTextStyles.title.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.reviewsCount(reviewCount),
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
