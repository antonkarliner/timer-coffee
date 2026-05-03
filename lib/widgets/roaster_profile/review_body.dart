// lib/widgets/roaster_profile/review_body.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bean_review_model.dart';
import '../../theme/design_tokens.dart';
import '../../utils/icon_utils.dart';
import 'flavor_notes_picker.dart';
import 'star_rating.dart';
import 'taste_profile_sliders.dart';

/// The shared content body of a bean review: star rating, review text,
/// brew method, would-buy-again chip, flavor tags, and taste profile sliders.
///
/// Used by [ReviewCard] (roaster profile page) and the "Your Review" section
/// on the bean detail screen. Does not include card chrome, reviewer identity,
/// roaster reply, or edit/delete actions — those stay in the parent.
class ReviewBody extends StatelessWidget {
  final BeanReviewModel review;

  /// Override for the brewing method display name. Used by the bean detail
  /// screen when the name must be resolved from the local DB and is not
  /// present on the review object itself.
  final String? brewMethodNameOverride;

  const ReviewBody({
    super.key,
    required this.review,
    this.brewMethodNameOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final hasChips = review.brewingMethodName != null ||
        review.brewingMethodId != null ||
        review.wouldBuyAgain != null ||
        (review.flavorTags != null && review.flavorTags!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarRating(value: review.rating),

        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(review.reviewText!, style: AppTextStyles.body),
        ],

        if (hasChips) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.xs,
            children: [
              if (review.brewingMethodName != null ||
                  review.brewingMethodId != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme.merge(
                      data: const IconThemeData(size: AppIconSize.small),
                      child: getIconByBrewingMethod(review.brewingMethodId),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      brewMethodNameOverride ??
                          review.brewingMethodName ??
                          review.brewingMethodId!,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              if (review.wouldBuyAgain != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.wouldBuyAgain!
                          ? Icons.thumb_up_outlined
                          : Icons.thumb_down_outlined,
                      size: AppIconSize.small,
                      color: review.wouldBuyAgain!
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      review.wouldBuyAgain!
                          ? 'Would buy again'
                          : 'Would not buy again',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
            ],
          ),
          if (review.flavorTags != null && review.flavorTags!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: sortedFlavorTagsWithColors(
                review.flavorTags!,
                l10n,
              ).map((entry) {
                final displayColor =
                    adaptFlavorColor(entry.color, Theme.of(context).brightness);
                final fg = flavorTagOnColor(displayColor);
                return Chip(
                  label: Text(
                    entry.tag,
                    style: AppTextStyles.caption.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: displayColor,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 0,
                  ),
                );
              }).toList(),
            ),
          ],
        ],

        if (review.hasTasteProfile || review.fruitiness != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TasteProfileSliders(
            sweetness: review.sweetness,
            acidity: review.acidity,
            fruitiness: review.fruitiness,
            body: review.body,
            bitterness: review.bitterness,
            aftertaste: review.aftertaste,
            readOnly: true,
          ),
        ],
      ],
    );
  }
}
