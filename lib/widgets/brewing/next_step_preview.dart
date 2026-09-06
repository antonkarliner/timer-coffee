import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// Full-width preview of the next brewing step, shown above the bottom
/// control area of the timer screen.
///
/// Presentation only: [label] and [description] must already be localized by
/// the caller. The description wraps to at most two lines and truncates with
/// an ellipsis, and its height is intrinsic, so larger text scales wrap
/// instead of clipping.
class NextStepPreview extends StatelessWidget {
  final String label;
  final String description;

  const NextStepPreview({
    super.key,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: secondaryColor, fontSize: 18)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: TextStyle(color: secondaryColor, fontSize: 22, height: 1.3),
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Explicit localized "paused" state label shown under the timer ring while
/// the brew is paused — the floating button only changes its icon.
class BrewPausedLabel extends StatelessWidget {
  final String label;

  const BrewPausedLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'brewPausedIndicator',
      child: Text(
        label,
        style: AppTextStyles.fieldLabel.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
