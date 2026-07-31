// lib/widgets/finish/brew_eval_sheet.dart
//
// Compact bottom sheet opened from the finish screen's star row (plan 039,
// "Item B — Brew evaluation CTA", Phase B1). Lets the user refine the rating
// they just tapped and capture taste balance, notes, and tags for the brew
// they just finished — the same four diary fields `BrewDetailSheet` edits,
// but scoped to a single compact sheet with no bean/recipe/extraction/delete
// sections (those stay diary-only). Takes a bare [statUuid] and plain
// initial values rather than a `DiaryEntry`, because the finish screen never
// builds one.
//
// Each field instant-saves through the same narrow `UserStatProvider`
// helpers `BrewDetailSheet` uses (`updateDiaryRating` and friends), and
// emits its own `diary_entry_edited {field, entry_source,
// source: 'finish_eval_sheet'}` per successful save — the provider helpers
// emit nothing themselves. Does NOT fire `diary_entry_opened`: that event's
// `analyticsSource` assert enumerates diary-origin values only, and this
// sheet is not a diary entry open.
//
// Notes are the one field that isn't a discrete tap/chip interaction, so a
// short debounce coalesces keystrokes into a single write + analytics event
// per pause, instead of one of each per character.
//
// Plan 039 Phase B2 adds an optional, conditional "Rate the beans" step
// after the taste/notes/tags fields: a second door into the bean-review
// flow, alongside the always-independent `BeanReviewNudgeCard` slot card
// (decision D9 — both doors stay). This sheet never calls
// `BeanReviewPromptService.evaluate()` itself — it receives an already
// -computed `BeanReviewPromptDecision` from the finish screen (which
// resolves it exactly once, via `FinishSlotResolver`) so a depletion-
// triggered bean can't have both doors burn a separate impression in the
// same visit. Whichever door actually renders records the impression,
// gated by the shared `hasBeanReviewImpressionRecorded` /
// `onBeanReviewImpressionRecorded` pair also threaded into
// `BeanReviewNudgeCard` — see `finish_screen.dart`'s
// `_beanReviewImpressionRecorded` field.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/roaster_profile_provider.dart';
import '../../providers/user_stat_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/bean_review_prompt_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/diary_tags.dart';
import '../base_buttons.dart';
import '../bean_review_nudge_card.dart' show ReviewFormOpener;
import '../brew_diary/diary_field_editors.dart';
import '../fields/labeled_field.dart';
import '../roaster_profile/review_form.dart';
import '../roaster_profile/star_rating.dart';

/// Signature used by [BrewEvalSheet] to report each successful field save.
/// Defaults to `AnalyticsService.maybeInstance?.track`; overridable so tests
/// can assert without a live [AnalyticsService].
typedef BrewEvalAnalyticsTrack =
    void Function(String event, Map<String, Object?> properties);

/// Opens [BrewEvalSheet] as a modal bottom sheet, mirroring
/// `showBrewDetailSheet`'s presentation (scroll-controlled, safe-area
/// aware).
Future<void> showBrewEvalSheet(
  BuildContext context, {
  required String statUuid,
  required String entrySource,
  double? initialRating,
  int? initialTasteBalance,
  String? initialNotes,
  List<String> initialTags = const [],
  ValueChanged<double>? onRatingChanged,
  BeanReviewPromptDecision? reviewDecision,
  BeanReviewPromptService? reviewPromptService,
  bool Function()? hasBeanReviewImpressionRecorded,
  VoidCallback? onBeanReviewImpressionRecorded,
  ReviewFormOpener? openBeanReviewForm,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BrewEvalSheet(
      statUuid: statUuid,
      entrySource: entrySource,
      initialRating: initialRating,
      initialTasteBalance: initialTasteBalance,
      initialNotes: initialNotes,
      initialTags: initialTags,
      onRatingChanged: onRatingChanged,
      reviewDecision: reviewDecision,
      reviewPromptService: reviewPromptService,
      hasBeanReviewImpressionRecorded: hasBeanReviewImpressionRecorded,
      onBeanReviewImpressionRecorded: onBeanReviewImpressionRecorded,
      openBeanReviewForm: openBeanReviewForm,
    ),
  );
}

class BrewEvalSheet extends StatefulWidget {
  const BrewEvalSheet({
    super.key,
    required this.statUuid,
    required this.entrySource,
    this.initialRating,
    this.initialTasteBalance,
    this.initialNotes,
    this.initialTags = const [],
    this.onRatingChanged,
    this.tagSuggestionsFuture,
    this.trackEvent,
    this.reviewDecision,
    this.reviewPromptService,
    this.hasBeanReviewImpressionRecorded,
    this.onBeanReviewImpressionRecorded,
    this.openBeanReviewForm,
  });

  /// The `user_stats.stat_uuid` row this sheet writes to. Must already
  /// exist — every write goes through a narrow `UserStatProvider` helper
  /// that fetches the row by uuid first.
  final String statUuid;

  /// `timer` | `manual` | `legacy` — the `entry_source` analytics
  /// dimension, matching `diaryEntrySourceLabel` in `brew_detail_sheet.dart`.
  /// The finish screen always passes `timer` (its brews are always
  /// `entrySource: 0`).
  final String entrySource;

  final double? initialRating;

  /// Called after each successful in-sheet rating save, so the opening
  /// surface can keep its own rating display in sync.
  final ValueChanged<double>? onRatingChanged;
  final int? initialTasteBalance;
  final String? initialNotes;
  final List<String> initialTags;

  /// The finish screen's once-per-visit bean-review decision (plan 039
  /// Phase B2), hoisted from `FinishSlotResolver.lastReviewDecision`. This
  /// sheet never calls `BeanReviewPromptService.evaluate()` itself — a
  /// `null` or `show == false` decision simply means the "Rate the beans"
  /// step is omitted.
  final BeanReviewPromptDecision? reviewDecision;

  /// The `BeanReviewPromptService` instance that produced [reviewDecision]
  /// (`FinishSlotResolver.lastPromptService`), reused here so
  /// `recordImpression` writes through the same prefs-backed service rather
  /// than constructing a second instance.
  final BeanReviewPromptService? reviewPromptService;

  /// Shared per-visit impression guard — mirrors the same-named parameters
  /// on `BeanReviewNudgeCard`. Checked before this sheet's own first-frame
  /// recording so the card and the sheet never double-count the same bean
  /// in the same visit.
  final bool Function()? hasBeanReviewImpressionRecorded;

  /// Called the instant this sheet's "Rate the beans" step wins the race to
  /// record the impression.
  final VoidCallback? onBeanReviewImpressionRecorded;

  /// Injectable for tests; defaults to resolving the roaster profile id via
  /// [RoasterProfileProvider] and opening [showReviewForm].
  final ReviewFormOpener? openBeanReviewForm;

  /// Tag autocomplete source. Defaults to
  /// `UserStatProvider.fetchAllDistinctTags()`; overridable for tests.
  final Future<List<String>>? tagSuggestionsFuture;

  /// Overridable analytics sink for tests. Defaults to
  /// `AnalyticsService.maybeInstance?.track`.
  final BrewEvalAnalyticsTrack? trackEvent;

  @override
  State<BrewEvalSheet> createState() => _BrewEvalSheetState();
}

class _BrewEvalSheetState extends State<BrewEvalSheet> {
  static const Duration _notesDebounceDelay = Duration(milliseconds: 600);

  late double? _rating;
  late int? _tasteBalance;
  late List<String> _tags;
  late Future<List<String>> _tagSuggestions;
  Timer? _notesDebounce;

  // "Rate the beans" step (plan 039 Phase B2). Computed once in initState
  // from the injected decision + the shared guard's value *at open time* —
  // stable for the sheet's lifetime, matching the card's own render-once
  // semantics (see class doc).
  late final bool _showBeanReviewStep = _computeShowBeanReviewStep();
  bool _beanReviewOpening = false;
  bool _beanReviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _tasteBalance = widget.initialTasteBalance;
    _tags = widget.initialTags;
    _tagSuggestions =
        widget.tagSuggestionsFuture ??
        context.read<UserStatProvider>().fetchAllDistinctTags();
    if (_showBeanReviewStep) {
      // Render-gated, mirroring `BeanReviewNudgeCard._recordImpression`:
      // only the step's own first frame burns the shared per-visit
      // impression, never the eligibility decision upstream.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _recordBeanReviewImpression(),
      );
    }
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    super.dispose();
  }

  bool _computeShowBeanReviewStep() {
    final decision = widget.reviewDecision;
    if (decision == null ||
        !decision.show ||
        decision.bean == null ||
        decision.trigger == null ||
        widget.reviewPromptService == null) {
      return false;
    }
    return !(widget.hasBeanReviewImpressionRecorded?.call() ?? false);
  }

  Future<void> _recordBeanReviewImpression() async {
    // Re-check the shared guard: it may have flipped between initState and
    // this post-frame callback if the slot card's own post-frame callback
    // ran first in the same frame batch.
    if (widget.hasBeanReviewImpressionRecorded?.call() ?? false) return;
    widget.onBeanReviewImpressionRecorded?.call();
    final decision = widget.reviewDecision;
    final promptService = widget.reviewPromptService;
    final bean = decision?.bean;
    if (bean == null || promptService == null) return;
    final count = await promptService.recordImpression(bean.beansUuid);
    _trackEvent('review_nudge_card_shown', {
      'bean_uuid': bean.beansUuid,
      'trigger': decision!.trigger,
      'impression_count': count,
      'surface': 'finish_eval_sheet',
    });
  }

  void _track(String field) {
    _trackEvent('diary_entry_edited', {
      'field': field,
      'entry_source': widget.entrySource,
      'source': 'finish_eval_sheet',
    });
  }

  void _trackEvent(String event, Map<String, Object?> properties) {
    final track = widget.trackEvent ?? _defaultTrack;
    track(event, properties);
  }

  void _defaultTrack(String event, Map<String, Object?> properties) {
    AnalyticsService.maybeInstance?.track(event, properties: properties);
  }

  Future<void> _saveRating(double value) async {
    setState(() => _rating = value);
    await context.read<UserStatProvider>().updateDiaryRating(
      statUuid: widget.statUuid,
      rating: value,
    );
    _track('rating');
    // Push the new value back to whoever opened the sheet (the finish
    // screen's star row) so its own display stays in sync. Fired per save
    // rather than on close, so a swipe-dismiss can't strand a stale row.
    widget.onRatingChanged?.call(value);
  }

  Future<void> _saveTaste(int value) async {
    setState(() => _tasteBalance = value);
    await context.read<UserStatProvider>().updateDiaryTasteBalance(
      statUuid: widget.statUuid,
      tasteBalance: value,
    );
    _track('taste');
  }

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(_notesDebounceDelay, () => _saveNotes(value));
  }

  Future<void> _saveNotes(String value) async {
    await context.read<UserStatProvider>().updateDiaryNotes(
      statUuid: widget.statUuid,
      notes: value,
    );
    _track('notes');
  }

  Future<void> _saveTags(List<String> value) async {
    setState(() => _tags = value);
    await context.read<UserStatProvider>().updateDiaryTags(
      statUuid: widget.statUuid,
      tags: diaryTagsToStorage(value),
    );
    _track('tags');
  }

  Future<bool> _defaultOpenBeanReviewForm(
    BuildContext context,
    double? rating,
  ) async {
    final bean = widget.reviewDecision?.bean;
    if (bean == null) return false;
    String? roasterProfileId;
    try {
      roasterProfileId = await Provider.of<RoasterProfileProvider>(
        context,
        listen: false,
      ).fetchRoasterProfileIdByName(bean.roaster).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
    } catch (_) {
      // Null is fine — the review-submit DB trigger auto-links the profile
      // later. Never let a lookup failure block the review form.
      roasterProfileId = null;
    }
    // This sheet is itself presented via `showModalBottomSheet`, so
    // `showReviewForm` below nests a second modal route on top of it. Its
    // context stays mounted for the inner sheet's whole lifetime — opening
    // the inner sheet doesn't pop this one, it only pushes above it — so no
    // `mounted` guard is dropping a write here, only avoiding stale-context
    // errors if the outer sheet was independently dismissed mid-lookup.
    if (!context.mounted) return false;
    return showReviewForm(
      context,
      roasterProfileId: roasterProfileId,
      roasterName: bean.roaster,
      preselectedBean: bean,
      initialRating: rating,
      sourceScreen: 'finish_eval_sheet',
    );
  }

  Future<void> _handleBeanReviewTap(double? rating) async {
    if (_beanReviewOpening) return;
    setState(() => _beanReviewOpening = true);
    final opener = widget.openBeanReviewForm ?? _defaultOpenBeanReviewForm;
    bool submitted = false;
    try {
      submitted = await opener(context, rating);
    } finally {
      if (mounted) setState(() => _beanReviewOpening = false);
    }
    if (!mounted) return;
    if (submitted) setState(() => _beanReviewSubmitted = true);
  }

  Widget _buildBeanReviewStep(AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            loc.finishEvalSheetRateBeansSection,
            style: AppTextStyles.sectionHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          _beanReviewSubmitted
              ? _buildBeanReviewThanks(loc, theme)
              : _buildBeanReviewPrompt(loc, theme),
        ],
      ),
    );
  }

  Widget _buildBeanReviewPrompt(AppLocalizations loc, ThemeData theme) {
    final decision = widget.reviewDecision!;
    final bean = decision.bean!;
    final subtitle = decision.trigger == 'depletion'
        ? loc.finishReviewNudgeDepletedSubtitle
        : loc.finishReviewNudgeSubtitle(bean.roaster);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.finishReviewNudgeTitle(bean.name),
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
        Center(
          child: IgnorePointer(
            ignoring: _beanReviewOpening,
            child: Opacity(
              opacity: _beanReviewOpening ? 0.6 : 1.0,
              child: StarRating(
                value: 0,
                interactive: true,
                starSize: AppIconSize.large,
                onChanged: (rating) => _handleBeanReviewTap(rating),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextButton(
          label: loc.finishReviewNudgeWriteButton,
          onPressed: _beanReviewOpening ? null : () => _handleBeanReviewTap(null),
          isFullWidth: false,
        ),
      ],
    );
  }

  Widget _buildBeanReviewThanks(AppLocalizations loc, ThemeData theme) {
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
          loc.finishReviewNudgeThanks,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          right: AppSpacing.base,
          top: AppSpacing.base,
          bottom: AppSpacing.base + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.finishEvalSheetTitle,
                      style: AppTextStyles.sectionHeader,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: KeyedSubtree(
                  key: const Key('evalSheetRatingBar'),
                  child: RatingBar.builder(
                    initialRating: _rating ?? 0,
                    minRating: 0.5,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: AppIconSize.large,
                    itemBuilder: (context, index) =>
                        Icon(Icons.star, color: theme.colorScheme.primary),
                    onRatingUpdate: (value) => _saveRating(value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                loc.tasteFeedbackPrompt,
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DiaryTasteEditor(
                value: _tasteBalance,
                labels: [loc.tasteSour, loc.tasteBalanced, loc.tasteBitter],
                onChanged: _saveTaste,
              ),
              const SizedBox(height: AppSpacing.base),
              LabeledField(
                key: const Key('evalSheetNotesInput'),
                label: loc.notes,
                initialValue: widget.initialNotes,
                isMultiline: true,
                minLines: 2,
                maxLines: 4,
                onChanged: _onNotesChanged,
              ),
              const SizedBox(height: AppSpacing.base),
              DiaryTagsFieldEditor(
                initialValues: _tags,
                suggestionsFuture: _tagSuggestions,
                onChanged: _saveTags,
              ),
              if (_showBeanReviewStep)
                Semantics(
                  identifier: 'evalSheetBeanReviewStep',
                  child: _buildBeanReviewStep(loc, theme),
                ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}
