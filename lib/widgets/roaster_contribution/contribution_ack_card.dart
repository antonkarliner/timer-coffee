import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../app_router.gr.dart';
import '../../l10n/app_localizations.dart';
import '../../services/roaster_contribution_service.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';
import '../coffee_bean_details/detail_section_header.dart';

typedef RoasterContributionAcknowledgementFetcher =
    Future<RoasterContributionAcknowledgement?> Function();

/// A hub card thanking the user for a roaster contribution that is now live in
/// the database (plan 062). Renders nothing until a fetch confirms there is an
/// unacknowledged contribution to thank for; self-contained — drop it at the
/// top of the hub list and it fetches, marks the acknowledgement on first
/// display (one-ask, so it never returns), and links to the roaster's page.
class RoasterContributionAckCard extends StatefulWidget {
  final RoasterContributionAcknowledgementFetcher? fetchAcknowledgement;

  const RoasterContributionAckCard({super.key, this.fetchAcknowledgement});

  @override
  State<RoasterContributionAckCard> createState() =>
      _RoasterContributionAckCardState();
}

class _RoasterContributionAckCardState
    extends State<RoasterContributionAckCard> {
  RoasterContributionAcknowledgement? _acknowledgement;
  bool _resolved = false;
  bool _hidden = false;
  bool _markedAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final fetcher =
        widget.fetchAcknowledgement ??
        RoasterContributionService.instance.fetchPendingAcknowledgement;
    final acknowledgement = await fetcher();
    if (!mounted) return;
    setState(() {
      _acknowledgement = acknowledgement;
      _resolved = true;
    });
    // One-ask: acknowledge on first display so it never reappears. The card
    // stays visible; hiding is the user's choice (dismiss or tap through).
    if (acknowledgement != null && !_markedAcknowledged) {
      _markedAcknowledged = true;
      RoasterContributionService.instance.markAcknowledged(
        acknowledgement.contributionId,
      );
    }
  }

  Future<void> _onSeePage() async {
    final acknowledgement = _acknowledgement;
    if (acknowledgement == null) return;
    RoasterContributionService.instance.trackAcknowledgementTapped(
      acknowledgement.contributionId,
    );
    await context.router.push(RoasterProfileRoute(slug: acknowledgement.slug));
    if (!mounted) return;
    setState(() => _hidden = true);
  }

  void _onDismiss() {
    // Already marked acknowledged on first display; just hide the card.
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved || _hidden || _acknowledgement == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final acknowledgement = _acknowledgement!;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: AppSpacing.base),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Same header component as the sibling prompt card. Deliberately an
            // icon, not the roaster's logo: these logos are arbitrary
            // third-party artwork and many are pale wordmarks drawn for dark
            // backgrounds, which render as an invisible smudge on this card's
            // light surface (verified on device with Coffee Gems, whose
            // dominant_color_hex is #FEF6E5 — the logo's own cream, so it
            // cannot serve as a contrasting backdrop either).
            DetailSectionHeader(
              icon: Icons.store_outlined,
              title: l10n.roasterContributionAckTitle(
                acknowledgement.roasterName,
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.roasterContributionAckBody, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.base),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppTextButton(
                  label: l10n.roasterContributionAckDismiss,
                  onPressed: _onDismiss,
                  isFullWidth: false,
                  height: AppButton.heightMedium,
                  padding: AppButton.paddingMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppElevatedButton(
                  label: l10n.roasterContributionAckAction,
                  onPressed: _onSeePage,
                  isFullWidth: false,
                  height: AppButton.heightMedium,
                  padding: AppButton.paddingMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
