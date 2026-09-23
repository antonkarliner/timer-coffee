// lib/widgets/finish/layout_try_card.dart
//
// Finish-screen "second chance" card for users who swiped the one-time
// layout picker away without choosing (plan 067 Phase 4). Occupies the same
// single-card slot as the review-nudge / whats-new / coffee-fact cards,
// ranked between them — see `finish_slot_resolver.dart`
// ([FinishSlotCandidateId.layoutTry] for why it sits above whats-new).
//
// The card is intentionally dumb / dependency-injected so it is
// widget-testable without provider scaffolding, mirroring
// `bean_review_nudge_card.dart` and `whats_new_card.dart`: the caller
// supplies the [budgetService], the prefs-backed [promptService], the
// [advancedFeatures] toggle, and the install's experiment [arm].
//
// Impression bookkeeping is render-gated, like both sibling cards: only
// this card's own first frame marks the finish card shown (its one and only
// impression — it shows at most once, ever), burns the budget entry, and
// emits `layout_choice_shown`. A candidate that wins the slot but never
// paints must not burn that impression.
//
// Nothing here starts a brew — accepting flips the layout for the NEXT one.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../services/advanced_features_service.dart';
import '../../services/analytics_service.dart';
import '../../services/engagement_budget_service.dart';
import '../../services/finish_slot_resolver.dart' show kLayoutTryAskId;
import '../../services/layout_choice_prompt_service.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';

class LayoutTryCard extends StatefulWidget {
  final EngagementBudgetService budgetService;

  final LayoutChoicePromptService promptService;

  final AdvancedFeaturesService advancedFeatures;

  /// Experiment arm on this install (`'pour'` / `'classic'`, or `'none'`
  /// when unassigned) — tagged on the `layout_choice_*` events so the
  /// finish-card entry point splits by arm exactly like the picker's.
  final String arm;

  const LayoutTryCard({
    super.key,
    required this.budgetService,
    required this.promptService,
    required this.advancedFeatures,
    required this.arm,
  });

  @override
  State<LayoutTryCard> createState() => _LayoutTryCardState();
}

class _LayoutTryCardState extends State<LayoutTryCard> {
  bool _impressionRecorded = false;
  bool _accepted = false;
  bool _declined = false;

  @override
  void initState() {
    super.initState();
    // Impression bookkeeping is render-gated (see the class doc): only this
    // card's own first frame marks the card shown / records the ask, never
    // the upstream slot decision.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordImpression());
  }

  Future<void> _recordImpression() async {
    if (_impressionRecorded) return;
    _impressionRecorded = true;

    // One shot, ever — after this the card can never be offered again.
    await widget.promptService.markFinishCardShown();

    // Records the ask under the exact same surface/askId
    // FinishSlotResolver gates on, so the budget log and the gate stay in
    // agreement (mirrors BeanReviewNudgeCard / WhatsNewCard).
    await widget.budgetService.recordAsk(
      surface: EngagementSurface.finishSlot,
      askId: kLayoutTryAskId,
    );

    AnalyticsService.maybeInstance?.track(
      'layout_choice_shown',
      properties: {
        'trigger': 'finish_card',
        // Eligibility (`finishCardEligible`) requires !pourEnabled, so the
        // layout this offer starts from is always the classic one.
        'current_layout': 'classic',
        'arm': widget.arm,
      },
    );
  }

  Future<void> _accept() async {
    // Flips the flag synchronously so the buttons swap for the accepted
    // confirmation on the very next frame — a second tap is impossible
    // because the buttons are gone.
    setState(() => _accepted = true);
    // Sets the layout, persists it, and logs `beta_feature_toggled` itself.
    await widget.advancedFeatures.setPourLayoutEnabled(
      true,
      source: 'finish_card',
    );
    AnalyticsService.maybeInstance?.track(
      'layout_choice_made',
      properties: {
        'trigger': 'finish_card',
        'choice': 'pour',
        'previous': 'classic',
        'arm': widget.arm,
      },
    );
  }

  void _decline() {
    AnalyticsService.maybeInstance?.track(
      'layout_choice_made',
      properties: {
        'trigger': 'finish_card',
        'choice': 'dismissed',
        'previous': 'classic',
        'arm': widget.arm,
      },
    );
    setState(() => _declined = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // The outer shape never changes with state (Semantics > Padding >
    // AnimatedSize are always present); only AnimatedSize's child swaps, so
    // declining animates the card down to nothing without remounting this
    // State — the one-shot impression above can't double-fire.
    return Semantics(
      identifier: 'layoutTryCard',
      child: Padding(
        // Horizontal-only: when the card collapses, no vertical padding
        // keeps the slot at zero height.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _declined
              ? const SizedBox.shrink()
              : Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: _accepted
                        ? _buildAccepted(context, l10n, theme)
                        : _buildOffer(context, l10n, theme),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOffer(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.layoutTryCardTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.layoutTryCardBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppElevatedButton(
                key: const Key('layoutTryAcceptButton'),
                label: l10n.layoutTryCardAccept,
                onPressed: _accept,
                height: AppButton.heightSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppTextButton(
              key: const Key('layoutTryDeclineButton'),
              label: l10n.layoutTryCardDecline,
              onPressed: _decline,
              isFullWidth: false,
              height: AppButton.heightSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccepted(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Symbols.check_circle,
          color: theme.colorScheme.primary,
          size: AppIconSize.large,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.layoutTryCardAccepted,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
