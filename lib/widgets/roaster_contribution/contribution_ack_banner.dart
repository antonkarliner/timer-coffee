import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../app_router.gr.dart';
import '../../l10n/app_localizations.dart';
import '../../services/roaster_contribution_service.dart';
import '../../theme/design_tokens.dart';

/// A main-screen banner thanking the user for a roaster contribution that is
/// now live in the database (plan 062), shown in the home screen's banner slot
/// above the tab content so it reaches every tab. Renders
/// nothing until a fetch confirms there is an unacknowledged contribution to
/// thank for; self-contained — drop it above the tab content and it fetches,
/// marks the acknowledgement on first display (one-ask, so it never returns),
/// and the whole banner links to the roaster's page.
class RoasterContributionAckBanner extends StatefulWidget {
  final RoasterContributionAcknowledgementFetcher? fetchAcknowledgement;

  const RoasterContributionAckBanner({super.key, this.fetchAcknowledgement});

  @override
  State<RoasterContributionAckBanner> createState() =>
      _RoasterContributionAckBannerState();
}

class _RoasterContributionAckBannerState
    extends State<RoasterContributionAckBanner> {
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
    // One-ask: acknowledge on first display so it never reappears. The banner
    // stays visible; hiding is the user's choice (dismiss or tap through).
    if (acknowledgement != null && !_markedAcknowledged) {
      _markedAcknowledged = true;
      RoasterContributionService.instance.markAcknowledged(
        acknowledgement.contributionId,
      );
    }
  }

  Future<void> _onOpenRoaster() async {
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
    // Already marked acknowledged on first display; just hide the banner.
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

    // Same Material/InkWell shape as the home screen's other banners (see
    // _GiftBoxBanner there), but with token-built paddings and radii, and no
    // per-child buttons: the whole banner is the tap target.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: _onOpenRoaster,
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.fromBorderSide(
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_outlined, size: AppIconSize.medium),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.roasterContributionAckTitle(
                            acknowledgement.roasterName,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.roasterContributionAckBody,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    label: l10n.roasterContributionAckDismiss,
                    button: true,
                    // Padded hit area so the 16px glyph keeps a reasonable
                    // tap target.
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onDismiss,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Icon(Icons.close, size: AppIconSize.small),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
