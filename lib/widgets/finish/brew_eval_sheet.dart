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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/user_stat_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/diary_tags.dart';
import '../brew_diary/diary_field_editors.dart';
import '../fields/labeled_field.dart';

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

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _tasteBalance = widget.initialTasteBalance;
    _tags = widget.initialTags;
    _tagSuggestions =
        widget.tagSuggestionsFuture ??
        context.read<UserStatProvider>().fetchAllDistinctTags();
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    super.dispose();
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
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
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
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}
