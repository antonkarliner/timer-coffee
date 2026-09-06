import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';

/// Compact inline review surface shown after a successful AI label scan.
///
/// Replaces the old sequential success dialogs (the CollectedDataDialog
/// popup followed by the automatic cover-photo prompt): the populated form
/// itself is the review, so this section only
/// - tells the user the scanned details are ready to review,
/// - surfaces the ambiguous roast-date attention near the top, with an
///   action that scrolls to the DatesCard where the field-level
///   confirmation lives, and
/// - offers an optional, explicit cover-photo choice from the reviewed
///   scan photos.
///
/// Deliberately monochrome (onSurface/onSurfaceVariant/outlineVariant):
/// this is a review aid, not a warning panel.
class ScanReviewSection extends StatelessWidget {
  /// Whether a scan result is present. When false the section renders as a
  /// zero-size placeholder so callers can keep it in a fixed layout slot —
  /// its appearance after a scan must never shift the form cards below it
  /// (a child-index change would remount them).
  final bool visible;

  /// The roast date exactly as printed on the scanned label, or null when
  /// unavailable. Shown verbatim in the attention row; never reinterpreted.
  final String? roastDateRawText;

  /// Whether the server flagged the scanned roast date as ambiguous.
  final bool roastDateNeedsConfirmation;

  /// Scrolls to the DatesCard, where the field-level roast-date
  /// confirmation lives. The attention row is only rendered when non-null.
  final VoidCallback? onReviewRoastDate;

  /// Scanned photos offered for an explicit cover choice, or null when the
  /// chooser must not be shown (a cover already exists, the user dismissed
  /// the choice for this scan, or no scan photos were kept).
  final List<XFile>? coverCandidates;

  /// Called when the user taps a scan-photo thumbnail to use it as cover.
  final ValueChanged<XFile>? onCoverSelected;

  /// Called when the user explicitly declines the cover choice.
  final VoidCallback? onCoverChoiceDismissed;

  /// Bottom gap between this card and the next form card when visible.
  /// Matches the caller's inter-card spacing (16 narrow / 24 wide).
  final double trailingSpacing;

  const ScanReviewSection({
    super.key,
    required this.visible,
    required this.roastDateRawText,
    required this.roastDateNeedsConfirmation,
    required this.onReviewRoastDate,
    required this.coverCandidates,
    required this.onCoverSelected,
    required this.onCoverChoiceDismissed,
    required this.trailingSpacing,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final showRoastDateAttention =
        roastDateNeedsConfirmation && onReviewRoastDate != null;
    final showCoverChooser =
        coverCandidates != null &&
        coverCandidates!.isNotEmpty &&
        onCoverSelected != null &&
        onCoverChoiceDismissed != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Semantics(
            identifier: 'scanReviewSection',
            container: true,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: AppIconSize.small,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          loc.collectedInformation,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  if (showRoastDateAttention) ...[
                    const SizedBox(height: AppSpacing.base),
                    _buildRoastDateAttention(context, loc, colorScheme),
                  ],
                  if (showCoverChooser) ...[
                    const SizedBox(height: AppSpacing.base),
                    Divider(
                      height: 1,
                      thickness: AppStroke.border,
                      color: colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _buildCoverChooser(context, loc, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: trailingSpacing),
      ],
    );
  }

  /// Ambiguous roast-date attention near the top of the form. Shows the raw
  /// printed date verbatim (or the not-found wording) and an action that
  /// scrolls to the existing DatesCard — the field-level confirmation and
  /// its date picker stay exactly where they are.
  Widget _buildRoastDateAttention(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final rawText = roastDateRawText;
    final hasRawText = rawText != null && rawText.trim().isNotEmpty;

    return Semantics(
      identifier: 'scanReviewRoastDateAttention',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: AppIconSize.small,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              hasRawText
                  ? loc.roastDateConfirmPrompt(rawText)
                  : loc.roastDateNotFound,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              softWrap: true,
            ),
          ),
          AppTextButton(
            label: loc.edit,
            onPressed: onReviewRoastDate,
            foregroundColor: colorScheme.onSurface,
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  /// Optional cover choice from the reviewed scan photos. Purely explicit:
  /// nothing is selected or uploaded until the user taps a thumbnail, and
  /// the choice can be declined.
  Widget _buildCoverChooser(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    return Semantics(
      identifier: 'scanCoverChooser',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.beanCoverPhotoSavePromptBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            softWrap: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final image in coverCandidates!)
                Semantics(
                  identifier: 'scanCoverCandidate',
                  button: true,
                  label: loc.beanCoverPhotoSavePromptTitle,
                  onTap: () => onCoverSelected?.call(image),
                  excludeSemantics: true,
                  child: _buildCoverThumbnail(context, image),
                ),
            ],
          ),
          AppTextButton(
            label: loc.no,
            onPressed: onCoverChoiceDismissed,
            foregroundColor: colorScheme.onSurface,
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverThumbnail(BuildContext context, XFile image) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onCoverSelected?.call(image),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: AppStroke.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Image.file(
            File(image.path),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: Icon(Icons.broken_image, size: AppIconSize.small),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
