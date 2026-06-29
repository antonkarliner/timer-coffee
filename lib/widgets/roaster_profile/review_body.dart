// lib/widgets/roaster_profile/review_body.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bean_review_model.dart';
import '../../providers/bean_review_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../theme/design_tokens.dart';
import '../../utils/icon_utils.dart';
import '../base_buttons.dart';
import 'flavor_notes_picker.dart';
import 'star_rating.dart';
import 'taste_profile_sliders.dart';

/// The shared content body of a bean review: star rating, review text,
/// brew method, would-buy-again chip, flavor tags, and taste profile sliders.
///
/// Used by [ReviewCard] (roaster profile page) and the "Your Review" section
/// on the bean detail screen. Does not include card chrome, reviewer identity,
/// roaster reply, or edit/delete actions — those stay in the parent.
class ReviewBody extends StatefulWidget {
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
  State<ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<ReviewBody> {
  bool _translating = false;
  bool _showTranslation = true;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final review = widget.review;

    final hasChips = review.brewingMethodName != null ||
        review.brewingMethodId != null ||
        review.wouldBuyAgain != null ||
        (review.flavorTags != null && review.flavorTags!.isNotEmpty);

    final readerLocale = context
        .watch<RecipeProvider>()
        .currentLocale
        .languageCode
        .toLowerCase();
    final hasReviewText =
        review.reviewText != null && review.reviewText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarRating(value: review.rating),

        if (hasReviewText) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(review.reviewText!, style: AppTextStyles.body),
          _buildTranslationSection(context, l10n, colorScheme, readerLocale),
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
                      widget.brewMethodNameOverride ??
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

  Widget _buildTranslationSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    String readerLocale,
  ) {
    final review = widget.review;
    final detected = review.detectedSourceLocale?.toLowerCase();
    final reader = readerLocale.toLowerCase();

    // Read translation cache reactively so batch translations populate this card.
    final translation = context.select<BeanReviewProvider, ReviewTranslation?>(
      (p) => p.cachedTranslation(
        reviewId: review.id,
        targetLocale: readerLocale,
      ),
    );

    // Hide all translation UI when source is known to match reader locale.
    final sameLanguage =
        (detected != null && detected == reader) || (translation?.sameLanguage == true);
    if (sameLanguage) return const SizedBox.shrink();

    if (translation != null && translation.translatedText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextButton(
              label: _showTranslation ? l10n.showOriginal : l10n.translateReview,
              icon: Icons.translate,
              onPressed: () =>
                  setState(() => _showTranslation = !_showTranslation),
              isFullWidth: false,
            ),
            if (_showTranslation) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(translation.translatedText!,
                    style: AppTextStyles.body),
              ),
            ],
          ],
        ),
      );
    }

    // No translation cached yet — show the Translate button.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_translating)
            const SizedBox(
              width: AppIconSize.small,
              height: AppIconSize.small,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            AppTextButton(
              label: l10n.translateReview,
              icon: Icons.translate,
              onPressed: () => _onTranslatePressed(readerLocale),
              isFullWidth: false,
            ),
          if (_failed) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.translationFailed,
              style: AppTextStyles.caption.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onTranslatePressed(String readerLocale) async {
    setState(() {
      _translating = true;
      _failed = false;
    });
    final provider = context.read<BeanReviewProvider>();
    final result = await provider.fetchTranslation(
      reviewId: widget.review.id,
      targetLocale: readerLocale,
    );
    if (!mounted) return;
    setState(() {
      _translating = false;
      _showTranslation = true;
      _failed = result == null;
    });
  }
}
