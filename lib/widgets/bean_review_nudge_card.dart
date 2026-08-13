// lib/widgets/bean_review_nudge_card.dart
//
// Finish-screen card that nudges the user to review the bean they just
// brewed (plan 021). Occupies the same slot as the coffee-fact filler card
// when BeanReviewPromptService.evaluate() decides the moment is right.
//
// The card is intentionally dumb / dependency-injected so it is
// widget-testable without provider/bottom-sheet scaffolding: the caller
// supplies the resolved [bean], [trigger], and a [promptService] instance;
// the review-form opening logic can be overridden via [openReviewForm] for
// tests, defaulting to the real Provider + showReviewForm flow.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coffee_beans_model.dart';
import '../providers/roaster_profile_provider.dart';
import '../services/analytics_service.dart';
import '../services/bean_review_prompt_service.dart';
import '../services/engagement_budget_service.dart';
import '../services/finish_slot_resolver.dart' show kBeanReviewNudgeAskId;
import '../theme/design_tokens.dart';
import 'base_buttons.dart';
import 'roaster_profile/review_form.dart';

/// Signature shared by the finish-screen review entry points. [rating] may
/// preselect a 1–5 value; this card's CTA deliberately passes null so the
/// review form owns the rating interaction. Returns true if a review was
/// submitted. Overridable for tests.
typedef ReviewFormOpener =
    Future<bool> Function(BuildContext context, double? rating);

class BeanReviewNudgeCard extends StatefulWidget {
  final CoffeeBeansModel bean;

  /// 'brew_count' | 'depletion' — see [BeanReviewPromptDecision.trigger].
  final String trigger;

  final BeanReviewPromptService promptService;

  /// Injectable for tests; defaults to resolving the roaster profile id via
  /// [RoasterProfileProvider] and opening [showReviewForm].
  final ReviewFormOpener? openReviewForm;

  /// Shared per-visit impression guard (plan 039, Phase B2 — "Bean review,
  /// second delivery surface"). The finish screen shares one
  /// `_beanReviewImpressionRecorded` flag between this card and
  /// `BrewEvalSheet`'s "Rate the beans" step, since both doors can read the
  /// same [BeanReviewPromptDecision] in the same visit (a depletion trigger
  /// bypasses the global cooldown, so without this guard both doors would
  /// burn a separate impression for the same bean). Checked before this
  /// card's own first-frame recording; defaults to "never already recorded"
  /// for callers (and existing tests) that don't share a guard, preserving
  /// this card's original standalone behavior.
  final bool Function()? hasSharedImpressionRecorded;

  /// Called the instant this card wins the race to record the impression,
  /// so a sibling door sharing [hasSharedImpressionRecorded] observes the
  /// flip before it can also record. Defaults to a no-op.
  final VoidCallback? onImpressionRecorded;

  /// Plan 039 triage item 1: `EngagementBudgetService.allowAsk` is already
  /// consulted for this candidate inside `FinishSlotResolver.resolve`, but
  /// nothing ever called `recordAsk` for the `finish_slot` surface — leaving
  /// the shadow-mode evidence trail incomplete exactly where the review
  /// nudge is concerned. Wired here (not inside the resolver) so it fires
  /// only when this card actually paints, from the same post-frame
  /// impression gate that calls [BeanReviewPromptService.recordImpression]
  /// — calling it from the resolver would race the 4s `.timeout()` around
  /// slot resolution and could record asks that never rendered. Nullable
  /// and defaults to a no-op so existing callers/tests that don't inject a
  /// budget service keep working unmodified.
  final EngagementBudgetService? budgetService;

  const BeanReviewNudgeCard({
    super.key,
    required this.bean,
    required this.trigger,
    required this.promptService,
    this.openReviewForm,
    this.hasSharedImpressionRecorded,
    this.onImpressionRecorded,
    this.budgetService,
  });

  @override
  State<BeanReviewNudgeCard> createState() => _BeanReviewNudgeCardState();
}

bool _neverAlreadyRecorded() => false;

class _BeanReviewNudgeCardState extends State<BeanReviewNudgeCard> {
  bool _opening = false;
  bool _submitted = false;
  bool _impressionRecorded = false;

  @override
  void initState() {
    super.initState();
    // Impression bookkeeping is render-gated (see plan "Losing the slot"):
    // only the card's own first frame burns a per-bean impression / starts
    // the cooldown, never the eligibility decision upstream.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordImpression());
  }

  Future<void> _recordImpression() async {
    if (_impressionRecorded) return;
    if ((widget.hasSharedImpressionRecorded ?? _neverAlreadyRecorded)()) {
      return;
    }
    _impressionRecorded = true;
    widget.onImpressionRecorded?.call();
    final count = await widget.promptService.recordImpression(
      widget.bean.beansUuid,
    );
    // Plan 039 triage item 1 — records the ask under the exact same
    // surface/askId `FinishSlotResolver` gates on, so the budget log and
    // the gate stay in agreement. Render-gated (only reached once this
    // card's own first frame fires), matching `WhatsNewCard`'s equivalent
    // `recordAsk` call for the `finish_popup` surface.
    await widget.budgetService?.recordAsk(
      surface: EngagementSurface.finishSlot,
      askId: kBeanReviewNudgeAskId,
    );
    AnalyticsService.maybeInstance?.track(
      'review_nudge_card_shown',
      properties: {
        'bean_uuid': widget.bean.beansUuid,
        'trigger': widget.trigger,
        'impression_count': count,
      },
    );
  }

  Future<bool> _defaultOpenReviewForm(
    BuildContext context,
    double? rating,
  ) async {
    String? roasterProfileId;
    try {
      roasterProfileId =
          await Provider.of<RoasterProfileProvider>(context, listen: false)
              .fetchRoasterProfileIdByName(widget.bean.roaster)
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      // Null is fine — the review-submit DB trigger auto-links the profile
      // later. Never let a lookup failure block the review form.
      roasterProfileId = null;
    }
    if (!context.mounted) return false;
    return showReviewForm(
      context,
      roasterProfileId: roasterProfileId,
      roasterName: widget.bean.roaster,
      preselectedBean: widget.bean,
      initialRating: rating,
      sourceScreen: 'finish_screen',
    );
  }

  Future<void> _handleTap(double? rating) async {
    if (_opening) return;
    setState(() => _opening = true);
    final opener = widget.openReviewForm ?? _defaultOpenReviewForm;
    bool submitted = false;
    try {
      submitted = await opener(context, rating);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (!mounted) return;
    if (submitted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      identifier: 'beanReviewNudgeCard',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: _submitted
                ? _buildThanks(context, l10n, theme)
                : _buildPrompt(context, l10n, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildPrompt(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final subtitle = widget.trigger == 'depletion'
        ? l10n.finishReviewNudgeDepletedSubtitle
        : l10n.finishReviewNudgeSubtitle(widget.bean.roaster);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.finishReviewNudgeTitle(widget.bean.name),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppElevatedButton(
          key: const Key('beanReviewRateButton'),
          label: l10n.finishEvalSheetRateBeansSection,
          icon: Icons.star_outline_rounded,
          onPressed: _opening ? null : () => _handleTap(null),
          isLoading: _opening,
          isFullWidth: false,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          elevation: 0,
        ),
      ],
    );
  }

  Widget _buildThanks(
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
          size: AppIconSize.large + 8,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.finishReviewNudgeThanks,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
