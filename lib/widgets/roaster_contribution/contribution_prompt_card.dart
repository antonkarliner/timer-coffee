import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/local_notification_scheduler_service.dart';
import '../../services/roaster_contribution_service.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';
import '../coffee_bean_details/detail_section_header.dart';
import 'contribution_sheet.dart';

typedef RoasterContributionEligibilityChecker =
    Future<RoasterContributionEligibility> Function(String roaster);

/// A dismissible in-app card that invites the user to contribute a website for a
/// roaster that is not yet in the Timer.Coffee database. Renders nothing until an
/// eligibility check confirms the roaster is a *pending* candidate the user has
/// not been prompted about. Self-contained — drop it into any screen that knows
/// a bean's free-text [roaster] string; it checks eligibility itself and marks
/// the prompt shown so it appears at most once per roaster (plan 011).
class RoasterContributionPromptCard extends StatefulWidget {
  final String roaster;
  final bool profileLookupCompleted;
  final bool isKnownRoaster;
  final RoasterContributionEligibilityChecker? eligibilityChecker;

  const RoasterContributionPromptCard({
    super.key,
    required this.roaster,
    this.profileLookupCompleted = true,
    this.isKnownRoaster = false,
    this.eligibilityChecker,
  });

  @override
  State<RoasterContributionPromptCard> createState() =>
      _RoasterContributionPromptCardState();
}

class _RoasterContributionPromptCardState
    extends State<RoasterContributionPromptCard> {
  RoasterContributionEligibility _eligibility =
      RoasterContributionEligibility.ineligible;
  bool _resolved = false;
  bool _hidden = false;
  bool _checkStarted = false;
  bool _routeInspectionScheduled = false;
  Animation<double>? _routeAnimation;

  bool get _canCheckEligibility =>
      widget.profileLookupCompleted && !widget.isKnownRoaster;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRouteInspection();
  }

  @override
  void didUpdateWidget(covariant RoasterContributionPromptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRouteInspection();
  }

  void _scheduleRouteInspection() {
    if (!_canCheckEligibility || _checkStarted || _routeInspectionScheduled) {
      return;
    }
    _routeInspectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeInspectionScheduled = false;
      if (!mounted || !_canCheckEligibility) return;
      _scheduleCheckAfterRouteTransition();
    });
  }

  void _scheduleCheckAfterRouteTransition() {
    if (_checkStarted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      _startCheck();
      return;
    }
    if (identical(_routeAnimation, animation)) return;
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _routeAnimation = animation;
    animation.addStatusListener(_onRouteAnimationStatus);
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _routeAnimation = null;
    _startCheck();
  }

  void _startCheck() {
    if (_checkStarted || !_canCheckEligibility) return;
    _checkStarted = true;
    _check();
  }

  Future<void> _check() async {
    final checker =
        widget.eligibilityChecker ??
        RoasterContributionService.instance.checkEligibility;
    final eligibility = await checker(widget.roaster);
    if (!mounted) return;
    setState(() {
      _eligibility = eligibility;
      _resolved = true;
    });
    final clusterId = eligibility.clusterId;
    if (eligibility.eligible && clusterId != null) {
      // One-ask: mark shown so it never reappears on a later screen load.
      RoasterContributionService.instance.markPromptShown(clusterId);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    super.dispose();
  }

  Future<void> _onAdd() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final submitted = await showRoasterContributionSheet(
      context,
      roaster: widget.roaster,
      clusterId: _eligibility.clusterId,
    );
    if (!mounted) return;
    if (submitted) {
      final clusterId = _eligibility.clusterId;
      if (clusterId != null) {
        // Resolving via the card cancels the parallel notification nudge.
        LocalNotificationSchedulerService.instance.cancelRoasterContribNudge(
          clusterId,
          reason: 'submitted',
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.roasterContributionSuccess)),
      );
      setState(() => _hidden = true);
    }
  }

  void _onDismiss() {
    final clusterId = _eligibility.clusterId;
    if (clusterId != null) {
      RoasterContributionService.instance.dismiss(clusterId);
      // Dismissing the card also cancels the parallel notification nudge.
      LocalNotificationSchedulerService.instance.cancelRoasterContribNudge(
        clusterId,
        reason: 'dismissed',
      );
    }
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canCheckEligibility ||
        !_resolved ||
        _hidden ||
        !_eligibility.eligible) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Header matches the other detail-screen cards: shared component,
            // hub roasters icon + titleLarge font. Top-align the icon so it
            // pins to the first line when this (longer) title wraps.
            DetailSectionHeader(
              icon: Icons.store_outlined,
              title: l10n.roasterContributionCardTitle(widget.roaster),
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.roasterContributionCardBody, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.base),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppTextButton(
                  label: l10n.roasterContributionCardDismiss,
                  onPressed: _onDismiss,
                  isFullWidth: false,
                  height: AppButton.heightMedium,
                  padding: AppButton.paddingMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppElevatedButton(
                  label: l10n.roasterContributionCardAdd,
                  onPressed: _onAdd,
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
