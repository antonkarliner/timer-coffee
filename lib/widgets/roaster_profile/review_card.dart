// lib/widgets/roaster_profile/review_card.dart

import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bean_review_model.dart';
import '../../providers/bean_review_provider.dart';
import '../../services/date_time_format_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/base_buttons.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'review_body.dart';
import 'review_reply.dart';
import 'star_rating.dart';

/// An expandable card showing a single bean review.
///
/// Collapsed: bean icon + name + star rating.
/// Expanded: full review text + taste profile + roaster reply.
/// The review author sees edit/delete actions.
class ReviewCard extends StatefulWidget {
  final BeanReviewModel review;
  final bool isRoasterAdmin;
  final VoidCallback? onEdit;
  final bool initiallyExpanded;

  const ReviewCard({
    super.key,
    required this.review,
    this.isRoasterAdmin = false,
    this.onEdit,
    this.initiallyExpanded = false,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _isAuthor =>
      Supabase.instance.client.auth.currentUser?.id == widget.review.userId;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        title: l10n.confirmDeleteReviewTitle,
        content: l10n.confirmDeleteReviewMessage,
        confirmLabel: l10n.deleteReview,
        cancelLabel: l10n.cancel,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await Provider.of<BeanReviewProvider>(context, listen: false).deleteReview(
      reviewId: widget.review.id,
      roasterProfileId: widget.review.roasterProfileId,
      coffeeBeansUuid: widget.review.coffeeBeansUuid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fmtSvc = Provider.of<DateTimeFormatService>(context, listen: false);
    final review = widget.review;

    final hasOrigin =
        review.beanOrigin != null && review.beanOrigin!.isNotEmpty;
    final roastDateLine = review.beanRoastDate != null
        ? '${l10n.roastDate}: ${DateFormat(fmtSvc.datePattern(l10n.dateFormat)).format(review.beanRoastDate!)}'
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsed header
              Row(
                children: [
                  Icon(
                    Coffeico.bag_with_bean,
                    size: AppIconSize.medium,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.beanName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasOrigin)
                          Text(
                            review.beanOrigin!,
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (roastDateLine != null)
                          Text(
                            roastDateLine,
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  StarRating(value: review.rating, starSize: AppIconSize.small),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colorScheme.onSurface.withOpacity(0.5),
                    size: AppIconSize.medium,
                  ),
                ],
              ),

              // Expanded content
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),

                // Reviewer info
                if (review.reviewerDisplayName != null) ...[
                  Text(
                    review.reviewerDisplayName!,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],

                ReviewBody(review: review),

                // Roaster reply
                ReviewReply(
                  review: review,
                  isRoasterAdmin: widget.isRoasterAdmin,
                ),

                // Author actions
                if (_isAuthor) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: AppSpacing.xs,
                    overflowSpacing: AppSpacing.xs,
                    children: [
                      AppTextButton(
                        label: l10n.editReview,
                        onPressed: widget.onEdit,
                        isFullWidth: false,
                      ),
                      AppTextButton(
                        label: l10n.deleteReview,
                        onPressed: () => _confirmDelete(context),
                        foregroundColor: colorScheme.error,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
