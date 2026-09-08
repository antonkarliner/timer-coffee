// lib/widgets/campaign_support_block.dart
//
// Campaign support block rendered inside a launch popup's scrollable
// content (plan 052, Item A, Phase A3). Shared by both surfaces that
// render a launch popup — the home-screen modal (`launch_popup.dart`)
// and the finish-screen expanded card dialog (`whats_new_card.dart`) —
// so the two cannot drift apart.
//
// Callers gate the block behind `popup.isCampaignActive`, so a popup
// without an active campaign follows the exact pre-campaign code path;
// the block re-checks the flag defensively in build. The campaign's
// actual copy lives in the popup's markdown content; this block only
// adds the optional goal progress bar and the donate CTA.

import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/launch_popup_model.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import 'base_buttons.dart';

/// The in-app route pushed when the donate CTA is tapped, matching the
/// `app://donate` deep links already handled by the popup markdown.
const String kDonateRoutePath = '/donate';

/// Analytics `trigger_id` for a campaign support prompt, derived from
/// the popup id (e.g. popup 5614 → 'campaign_5614').
String campaignTriggerId(int popupId) => 'campaign_$popupId';

/// Goal progress bar + donate CTA for an active campaign popup.
class CampaignSupportBlock extends StatefulWidget {
  final LaunchPopupModel popup;

  /// Source-screen tag ('home' or 'finish') carried on this block's
  /// analytics events, reusing the hosting surface's own constant.
  final String sourceScreen;

  /// Called when the donate CTA is tapped, before navigation, so the
  /// hosting surface can suppress its `support_prompt_dismissed` event
  /// if the dialog then closes after a tap.
  final VoidCallback? onCtaTapped;

  const CampaignSupportBlock({
    super.key,
    required this.popup,
    required this.sourceScreen,
    this.onCtaTapped,
  });

  @override
  State<CampaignSupportBlock> createState() => _CampaignSupportBlockState();
}

class _CampaignSupportBlockState extends State<CampaignSupportBlock> {
  bool _shownTracked = false;

  @override
  void initState() {
    super.initState();
    // Impression tracking is render-gated, mirroring the post-frame
    // impression bookkeeping in whats_new_card.dart. The bool guard keeps
    // a rebuild of the dialog builder from double-counting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shownTracked || !mounted) return;
      _shownTracked = true;
      AnalyticsService.maybeInstance?.track(
        'support_prompt_shown',
        properties: {
          'trigger_id': campaignTriggerId(widget.popup.id),
          'source_screen': widget.sourceScreen,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Defensive re-check: callers gate on isCampaignActive too, but the
    // block must never render for an expired/inactive campaign on its own.
    if (!widget.popup.isCampaignActive) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.base),
        _buildGoalProgress(context, l10n, Theme.of(context)),
        // The trailing spacer belongs to the goal bar: render it only when
        // the bar itself renders, so the no-goal configuration leaves a
        // single 16dp gap between the markdown and the CTA instead of a
        // stacked 16 + 8 (plan 054, Item D).
        if (_showsGoalProgress) const SizedBox(height: AppSpacing.sm),
        AppElevatedButton(
          label: l10n.campaignSupportCta,
          onPressed: () {
            AnalyticsService.maybeInstance?.track(
              'support_prompt_tapped',
              properties: {
                'trigger_id': campaignTriggerId(widget.popup.id),
                'source_screen': widget.sourceScreen,
              },
            );
            widget.onCtaTapped?.call();
            final router = context.router;
            Navigator.of(context).pop();
            // In-app deep link, the same mechanism the popup markdown
            // uses for `app://` hrefs — not url_launcher, and `/donate`
            // is an in-app route so no flushNow().
            router.pushPath(kDonateRoutePath);
          },
        ),
        // Debug-only operator diagnostics: kDebugMode is false and tree-shaken
        // in release builds. Hardcoded English is intentional; this is not UI.
        if (kDebugMode) const SizedBox(height: AppSpacing.xs),
        if (kDebugMode)
          Text(
            'campaign: hook=${widget.popup.hookType} '
            'goal=${widget.popup.goalAmountUsd} '
            'progress=${widget.popup.progressAmountUsd} '
            'ends=${widget.popup.campaignEndsAt?.toIso8601String()}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  /// Whether the goal progress bar renders: both amounts present and a
  /// positive goal. Single source of truth for both the bar (in
  /// [_buildGoalProgress]) and its trailing spacer (in [build]) so the
  /// two can no longer drift apart (plan 054, Item D).
  bool get _showsGoalProgress {
    final goal = widget.popup.goalAmountUsd;
    final progress = widget.popup.progressAmountUsd;
    return goal != null && goal > 0 && progress != null;
  }

  /// Optional goal progress bar. Rendered only when [_showsGoalProgress]
  /// is true; the fraction is clamped to 0.0–1.0 so over-funding renders
  /// a full bar and negatives an empty one, and the label always shows
  /// whole dollars (never a raw float). The displayed raised amount is
  /// floored at zero, and once it meets or passes the goal the label
  /// switches to the goal-reached message (plan 054, Item A).
  /// The bar is deliberately monochrome (primary fill on an
  /// outlineVariant track) because the block sits inside the launch popup,
  /// where the app's accent orange reads as a system colour.
  Widget _buildGoalProgress(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (!_showsGoalProgress) {
      return const SizedBox.shrink();
    }

    final goal = widget.popup.goalAmountUsd!;
    final progress = widget.popup.progressAmountUsd!;
    final fraction = (progress / goal).clamp(0.0, 1.0).toDouble();
    final displayProgress = math.max(progress, 0.0);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              progress >= goal
                  ? l10n.campaignGoalReached(currency.format(displayProgress))
                  : l10n.campaignGoalProgress(
                      currency.format(displayProgress),
                      currency.format(goal),
                    ),
              style: theme.textTheme.labelMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: fraction,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ],
    );
  }
}
