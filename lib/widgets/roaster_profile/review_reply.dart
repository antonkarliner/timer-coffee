// lib/widgets/roaster_profile/review_reply.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bean_review_model.dart';
import '../../providers/bean_review_provider.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import '../../widgets/base_buttons.dart';

/// Shows the roaster's reply to a review inline.
/// If [isRoasterAdmin] is true an edit/reply action is shown.
class ReviewReply extends StatefulWidget {
  final BeanReviewModel review;
  final bool isRoasterAdmin;

  const ReviewReply({
    super.key,
    required this.review,
    this.isRoasterAdmin = false,
  });

  @override
  State<ReviewReply> createState() => _ReviewReplyState();
}

class _ReviewReplyState extends State<ReviewReply> {
  bool _isEditing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.review.replyText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReply(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider =
        Provider.of<BeanReviewProvider>(context, listen: false);
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final ok = await provider.submitReply(
      reviewId: widget.review.id,
      replyText: text,
    );
    if (!context.mounted) return;

    if (ok) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.replySubmitted)),
      );
    } else {
      AppLogger.error('Failed to submit reply');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final hasReply = widget.review.hasReply;

    if (!hasReply && !widget.isRoasterAdmin) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: AppIconSize.small,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.roasterResponse,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (widget.isRoasterAdmin)
                AppTextButton(
                  label: hasReply ? l10n.editReply : l10n.replyToReview,
                  onPressed: () =>
                      setState(() => _isEditing = !_isEditing),
                  height: AppButton.heightSmall,
                  padding: AppButton.paddingSmall,
                  isFullWidth: false,
                ),
            ],
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.replyToReview,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppElevatedButton(
              label: l10n.submitReviewButton,
              onPressed: () => _submitReply(context),
              height: AppButton.heightSmall,
              isFullWidth: false,
            ),
          ] else if (hasReply) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(widget.review.replyText!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}
