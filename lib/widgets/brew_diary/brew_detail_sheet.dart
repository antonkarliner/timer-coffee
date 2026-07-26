import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/extraction_calculator_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/diary_tags.dart';
import 'package:coffee_timer/utils/grind_suggestions.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/utils/temperature_format.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/add_coffee_beans_widget.dart';
import 'package:coffee_timer/widgets/confirm_delete_dialog.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:coffee_timer/widgets/fields/chip_input.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

/// Allowed values for [BrewDetailSheet.analyticsSource] /
/// [showBrewDetailSheet]'s `analyticsSource` — where the sheet was opened
/// from, per plan 029's `diary_entry_opened` event spec.
const _kValidDiaryEntryOpenSources = {'card', 'group_card', 'deep_link'};

/// Maps the DB `entry_source` column to the analytics enum used across all
/// diary events: `0`/timer → `timer`, `1` → `manual`, `NULL`/anything else
/// → `legacy`.
String diaryEntrySourceLabel(int? entrySource) => switch (entrySource) {
  0 => 'timer',
  1 => 'manual',
  _ => 'legacy',
};

/// Applies the typed calculator result without re-querying the diary row.
@visibleForTesting
DiaryEntry applyExtractionCalculatorResult(
  DiaryEntry entry,
  ExtractionCalculatorResult result,
) => entry.copyWith(
  tdsPercent: result.tdsPercent,
  extractionYieldPercent: result.extractionYieldPercent,
);

Future<bool?> showBrewDetailSheet(
  BuildContext context, {
  required DiaryEntry entry,
  Future<Map<String, String?>>? logoUrls,
  ValueChanged<double?>? onRatingChanged,
  ValueChanged<DiaryEntry>? onEntryChanged,
  ValueChanged<DiaryEntry>? onOpenBeanJourney,
  String analyticsSource = 'card',
}) {
  assert(
    _kValidDiaryEntryOpenSources.contains(analyticsSource),
    'Unknown analyticsSource "$analyticsSource"',
  );
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BrewDetailSheet(
      entry: entry,
      logoUrls: logoUrls,
      onRatingChanged: onRatingChanged,
      onEntryChanged: onEntryChanged,
      onOpenBeanJourney: onOpenBeanJourney,
      analyticsSource: analyticsSource,
    ),
  );
}

enum BrewRatingEditStatus { saved, cancelled }

@immutable
class BrewRatingEditResult {
  const BrewRatingEditResult.saved(this.rating)
    : status = BrewRatingEditStatus.saved;

  const BrewRatingEditResult.cancelled()
    : status = BrewRatingEditStatus.cancelled,
      rating = null;

  final BrewRatingEditStatus status;
  final double? rating;

  bool get wasSaved => status == BrewRatingEditStatus.saved;
}

/// Opens the diary's existing focused rating editor for a single attempt.
Future<BrewRatingEditResult> showBrewRatingEditor(
  BuildContext context, {
  required DiaryEntry entry,
}) async {
  final result = await showDialog<_NullableValue<double>>(
    context: context,
    builder: (_) => _RatingDialog(
      initialRating: entry.rating,
      onSave: (value) => context.read<UserStatProvider>().updateDiaryRating(
        statUuid: entry.statUuid,
        rating: value,
      ),
    ),
  );
  return result == null
      ? const BrewRatingEditResult.cancelled()
      : BrewRatingEditResult.saved(result.value);
}

class BrewDetailSheet extends StatefulWidget {
  const BrewDetailSheet({
    super.key,
    required this.entry,
    this.logoUrls,
    this.onRatingChanged,
    this.onEntryChanged,
    this.onOpenBeanJourney,
    this.analyticsSource = 'card',
  });

  final DiaryEntry entry;
  final Future<Map<String, String?>>? logoUrls;
  final ValueChanged<double?>? onRatingChanged;
  final ValueChanged<DiaryEntry>? onEntryChanged;
  final ValueChanged<DiaryEntry>? onOpenBeanJourney;

  /// Where the sheet was opened from — one of `card`, `group_card`,
  /// `deep_link`. Reported once via the `diary_entry_opened` analytics
  /// event fired from `initState`.
  final String analyticsSource;

  @override
  State<BrewDetailSheet> createState() => _BrewDetailSheetState();
}

class _BrewDetailSheetState extends State<BrewDetailSheet> {
  late DiaryEntry _entry;
  Future<Map<String, String?>>? _logoUrls;
  bool _savingBean = false;
  bool _savingBookmark = false;
  // Lives for the sheet's lifetime (not the tag dialog's): the dialog's exit
  // transition still renders the input after showDialog completes, so the
  // controller cannot be disposed per-edit. Cleared on each dialog open;
  // read at save time so typed-but-unsubmitted text survives a Save tap.
  final _pendingTagController = TextEditingController();

  bool get _manual => _entry.entrySource == 1;

  void _replaceEntry(DiaryEntry updated) {
    if (!mounted) return;
    setState(() => _entry = updated);
    widget.onEntryChanged?.call(updated);
  }

  @override
  void dispose() {
    _pendingTagController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _logoUrls = widget.logoUrls;
    AnalyticsService.maybeInstance?.track(
      'diary_entry_opened',
      properties: {
        'source': widget.analyticsSource,
        'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        'has_extraction': _entry.extractionYieldPercent != null,
        'has_taste': _entry.tasteBalance != null,
        'has_tags': _entry.tagList.isNotEmpty,
        'has_notes': _entry.notes?.trim().isNotEmpty ?? false,
        'has_rating': _entry.rating != null,
      },
    );
  }

  Future<bool> _updateBeanAssociation(
    String? nextBeanUuid, {
    bool showFailure = true,
  }) async {
    if (_savingBean) return false;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final beansProvider = context.read<CoffeeBeansProvider>();
    final databaseProvider = context.read<DatabaseProvider>();
    final statsProvider = context.read<UserStatProvider>();
    setState(() => _savingBean = true);

    try {
      await statsProvider.updateDiaryBean(
        statUuid: _entry.statUuid,
        nextBeanUuid: nextBeanUuid,
      );
      final bean = nextBeanUuid == null
          ? null
          : await beansProvider.fetchCoffeeBeansByUuid(nextBeanUuid);
      if (nextBeanUuid != null && bean == null) {
        throw StateError('Selected coffee beans are unavailable');
      }
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'bean',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      if (!mounted) return true;
      final updated = _entry.copyWith(
        coffeeBeansUuid: nextBeanUuid,
        beanName: bean?.name,
        roaster: bean?.roaster,
        origin: bean?.origin,
      );
      setState(() {
        _entry = updated;
        _logoUrls = bean == null
            ? null
            : databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
        _savingBean = false;
      });
      widget.onEntryChanged?.call(updated);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _savingBean = false);
        if (showFailure) {
          messenger.showSnackBar(
            SnackBar(content: Text(loc.unexpectedErrorOccurred)),
          );
        }
      }
      return false;
    }
  }

  Future<void> _openBeanSelector() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AddCoffeeBeansWidget(
        onSelect: (selectedBeanUuid) async {
          final saved = await _updateBeanAssociation(
            selectedBeanUuid,
            showFailure: false,
          );
          if (!saved) throw StateError('Bean association failed');
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  Future<void> _editAmounts() async {
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (_) => _AmountDialog(
        coffeeAmount: _entry.coffeeAmount,
        waterAmount: _entry.waterAmount,
        onSave: (value) => context.read<UserStatProvider>().updateDiaryAmounts(
          statUuid: _entry.statUuid,
          coffeeAmount: value.$1,
          waterAmount: value.$2,
        ),
      ),
    );
    if (result != null) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'amounts',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      final amountsChanged =
          result.$1 != _entry.coffeeAmount || result.$2 != _entry.waterAmount;
      _replaceEntry(
        _entry.copyWith(
          coffeeAmount: result.$1,
          waterAmount: result.$2,
          tdsPercent: amountsChanged ? null : _entry.tdsPercent,
          extractionYieldPercent: amountsChanged
              ? null
              : _entry.extractionYieldPercent,
        ),
      );
    }
  }

  Future<void> _editGrind() async {
    final suggestions = mergedGrindSizeSuggestions(
      brewHistoryGrinds: context.read<UserStatProvider>()
          .fetchAllDistinctGrindSizes(),
      beanGrinds: context.read<CoffeeBeansProvider>()
          .fetchAllDistinctGrindSizes(),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _FocusedEditDialog<String>(
        title: AppLocalizations.of(context)!.brewDiaryEditGrind,
        initialValue: _entry.grindSize ?? '',
        bodyBuilder: (context, value, onChanged, error) => DropdownSearchField(
          key: const Key('focusedGrindInput'),
          label: AppLocalizations.of(context)!.grindsize,
          initialValue: value,
          errorText: error,
          onSearch: (query) async {
            final options = await suggestions;
            final normalized = query.toLowerCase();
            return options
                .where((option) => option.toLowerCase().contains(normalized))
                .toList();
          },
          onChanged: onChanged,
        ),
        onSave: (value) => context
            .read<UserStatProvider>()
            .updateDiaryGrindSize(statUuid: _entry.statUuid, grindSize: value),
      ),
    );
    if (result != null) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'grind',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      _replaceEntry(_entry.copyWith(grindSize: result));
    }
  }

  Future<void> _editTemperature() async {
    final result = await showDialog<_NullableValue<double>>(
      context: context,
      builder: (_) => _FocusedEditDialog<_NullableValue<double>>(
        title: AppLocalizations.of(context)!.brewDiaryEditTemperature,
        initialValue: _NullableValue(_entry.storedWaterTemp),
        clearValue: const _NullableValue(null),
        bodyBuilder: (context, value, onChanged, error) => NumericTextField(
          key: const Key('focusedTemperatureInput'),
          label: AppLocalizations.of(context)!.watertemp,
          initialValue: value.value,
          allowDecimal: true,
          helperText:
              error ??
              formatTemperatureInputHelper(value.value) ??
              (_entry.waterTempIsDerived
                  ? '~${formatTemperatureDual(_entry.waterTemp)}'
                  : null),
          onChanged: (next) {
            if (next != value.value) onChanged(_NullableValue(next));
          },
        ),
        onSave: (value) =>
            context.read<UserStatProvider>().updateDiaryWaterTemperature(
              statUuid: _entry.statUuid,
              waterTemp: value.value,
            ),
      ),
    );
    if (result != null) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'temperature',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      _replaceEntry(
        _entry.copyWith(waterTemp: result.value, waterTempIsDerived: false),
      );
    }
  }

  Future<void> _editTaste() async {
    final result = await showDialog<_NullableValue<int>>(
      context: context,
      builder: (_) => _FocusedEditDialog<_NullableValue<int>>(
        title: AppLocalizations.of(context)!.brewDiaryEditTaste,
        initialValue: _NullableValue(_entry.tasteBalance),
        clearValue: const _NullableValue(null),
        bodyBuilder: (context, value, onChanged, error) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TasteEditor(
              value: value.value,
              labels: [
                AppLocalizations.of(context)!.tasteSour,
                AppLocalizations.of(context)!.tasteBalanced,
                AppLocalizations.of(context)!.tasteBitter,
              ],
              onChanged: (next) => onChanged(_NullableValue(next)),
            ),
            if (error != null) _InlineError(error),
          ],
        ),
        onSave: (value) =>
            context.read<UserStatProvider>().updateDiaryTasteBalance(
              statUuid: _entry.statUuid,
              tasteBalance: value.value,
            ),
      ),
    );
    if (result != null) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'taste',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      _replaceEntry(_entry.copyWith(tasteBalance: result.value));
    }
  }

  Future<void> _editNotes() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _FocusedEditDialog<String>(
        title: AppLocalizations.of(context)!.brewDiaryEditNotes,
        initialValue: _entry.notes ?? '',
        bodyBuilder: (context, value, onChanged, error) => LabeledField(
          key: const Key('focusedNotesInput'),
          label: AppLocalizations.of(context)!.notes,
          initialValue: value,
          errorText: error,
          isMultiline: true,
          minLines: 3,
          maxLines: 6,
          onChanged: onChanged,
        ),
        onSave: (value) => context.read<UserStatProvider>().updateDiaryNotes(
          statUuid: _entry.statUuid,
          notes: value,
        ),
      ),
    );
    if (result != null) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'notes',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      _replaceEntry(_entry.copyWith(notes: result));
    }
  }

  Future<void> _editTags() async {
    final suggestions = context.read<UserStatProvider>().fetchAllDistinctTags();
    _pendingTagController.clear();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FocusedEditDialog<List<String>>(
        title: AppLocalizations.of(context)!.brewDiaryEditTags,
        initialValue: _entry.tagList,
        saveLabel: AppLocalizations.of(context)!.done,
        bodyBuilder: (context, value, onChanged, error) => _TagsFieldEditor(
          initialValues: value,
          suggestionsFuture: suggestions,
          errorText: error,
          onChanged: onChanged,
          textController: _pendingTagController,
        ),
        onSave: (value) => context.read<UserStatProvider>().updateDiaryTags(
          statUuid: _entry.statUuid,
          tags: diaryTagsToStorage(
            diaryTagsWithPending(value, _pendingTagController.text),
          ),
        ),
      ),
    );
    if (result != null) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'tags',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      _replaceEntry(
        _entry.copyWith(
          tags: diaryTagsToStorage(
            diaryTagsWithPending(result, _pendingTagController.text),
          ),
        ),
      );
    }
  }

  Future<void> _editRating() async {
    final result = await showBrewRatingEditor(context, entry: _entry);
    if (result.wasSaved) {
      AnalyticsService.maybeInstance?.track(
        'diary_entry_edited',
        properties: {
          'field': 'rating',
          'entry_source': diaryEntrySourceLabel(_entry.entrySource),
        },
      );
      _replaceEntry(_entry.copyWith(rating: result.rating));
      widget.onRatingChanged?.call(result.rating);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_savingBookmark) return;
    final nextValue = !_entry.isMarked;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingBookmark = true);
    try {
      await context.read<UserStatProvider>().updateUserStat(
        statUuid: _entry.statUuid,
        isMarked: nextValue,
      );
      AnalyticsService.maybeInstance?.track(
        'diary_bookmark_toggled',
        properties: {'bookmarked': nextValue, 'source': 'sheet'},
      );
      if (!mounted) return;
      final updated = _entry.copyWith(isMarked: nextValue);
      setState(() {
        _entry = updated;
        _savingBookmark = false;
      });
      widget.onEntryChanged?.call(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingBookmark = false);
      messenger.showSnackBar(
        SnackBar(content: Text(loc.unexpectedErrorOccurred)),
      );
    }
  }

  Future<void> _delete() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: loc.confirmDeleteTitle,
        content: loc.confirmDeleteMessage,
        confirmLabel: loc.delete,
        cancelLabel: loc.cancel,
      ),
    );
    if (confirmed != true || !mounted) return;

    // Captured before the awaits: the weight return and the stat deletion
    // must both complete even if the sheet is dismissed mid-flight —
    // otherwise the bean weight is refunded but the stat survives.
    final messenger = ScaffoldMessenger.of(context);
    final coffeeBeansProvider = context.read<CoffeeBeansProvider>();
    final userStatProvider = context.read<UserStatProvider>();
    if (_entry.coffeeBeansUuid != null) {
      final newWeight = await coffeeBeansProvider
          .updateBeanWeightAfterBrewModification(
            _entry.coffeeBeansUuid!,
            _entry.coffeeAmount,
          );
      if (newWeight != null && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              loc.beansWeightAddedBack(
                _entry.coffeeAmount.toString(),
                _entry.beanName ?? '',
                newWeight.toStringAsFixed(1),
                loc.unitGramsShort,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    await userStatProvider.deleteUserStat(_entry.statUuid);
    AnalyticsService.maybeInstance?.track(
      'diary_entry_deleted',
      properties: {'entry_source': diaryEntrySourceLabel(_entry.entrySource)},
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bookmarkLabel = _entry.isMarked
        ? loc.diaryRemoveBookmark
        : loc.diaryMarkBookmark;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Icon(
                  getIconByBrewingMethod(_entry.brewingMethodId).icon,
                  size: AppIconSize.medium,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entry.recipeName,
                      key: const Key('brewDetailRecipeName'),
                      style: AppTextStyles.headline,
                    ),
                    Text(
                      _entry.methodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Semantics(
                identifier: 'detailBookmarkToggle_${_entry.statUuid}',
                container: true,
                label: bookmarkLabel,
                button: true,
                enabled: !_savingBookmark,
                toggled: _entry.isMarked,
                onTap: _savingBookmark ? null : _toggleBookmark,
                child: ExcludeSemantics(
                  child: IconButton(
                    tooltip: bookmarkLabel,
                    onPressed: _savingBookmark ? null : _toggleBookmark,
                    icon: Icon(
                      _entry.isMarked ? Icons.bookmark : Icons.bookmark_outline,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('brewDetailMenuButton'),
                tooltip: loc.delete,
                icon: const Icon(Icons.more_vert),
                position: PopupMenuPosition.under,
                offset: const Offset(0, AppSpacing.xs),
                elevation: AppButton.elevation,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                onSelected: (value) {
                  if (value == 'delete') _delete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    key: const Key('deleteBrewMenuItem'),
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          loc.delete,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _BeanBlock(
            entry: _entry,
            logoUrls: _logoUrls,
            isSaving: _savingBean,
            onSelect: _openBeanSelector,
            onOpenJourney: widget.onOpenBeanJourney,
            onRemove: () async {
              await _updateBeanAssociation(null);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFacts(loc),
          const SizedBox(height: AppSpacing.sm),
          _RatingButton(
            rating: _entry.rating,
            label: loc.rating,
            notRatedLabel: loc.brewDiaryNotRated,
            onTap: _editRating,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: loc.notes,
            icon: Icons.note_outlined,
            isCollapsible: false,
            trailing: _EditButton(
              key: const Key('editNotesButton'),
              label: loc.brewDiaryEditNotes,
              onPressed: _editNotes,
            ),
            child: Text(
              _entry.notes?.trim().isNotEmpty == true
                  ? _entry.notes!
                  : loc.notProvided,
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: loc.diaryTags,
            icon: Icons.local_offer_outlined,
            isCollapsible: false,
            trailing: _EditButton(
              key: const Key('editTagsButton'),
              label: loc.brewDiaryEditTags,
              onPressed: _editTags,
            ),
            child: _entry.tagList.isEmpty
                ? Text(loc.notProvided, style: AppTextStyles.body)
                : Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _entry.tagList
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: AppTextButton(
              label: loc.brewAgain,
              icon: Icons.replay,
              isFullWidth: false,
              onPressed: () {
                AnalyticsService.maybeInstance?.track(
                  'diary_brew_again_tapped',
                  properties: {
                    'source': 'sheet',
                    'recipe_id': _entry.recipeId,
                    'brewing_method_id': _entry.brewingMethodId,
                    'has_grind_prefill':
                        _entry.grindSize?.trim().isNotEmpty ?? false,
                    'has_temp_prefill': _entry.storedWaterTemp != null,
                  },
                );
                context.router.push(
                  RecipeDetailRoute(
                    brewingMethodId: _entry.brewingMethodId,
                    recipeId: _entry.recipeId,
                    prefillCoffeeAmount: _entry.coffeeAmount,
                    prefillWaterAmount: _entry.waterAmount,
                    prefillGrindSize: _entry.grindSize,
                    prefillWaterTemp: _entry.storedWaterTemp,
                    prefillCoffeeBeansUuid: _entry.coffeeBeansUuid,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacts(AppLocalizations loc) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      children: [
        _FactCell(
          label: loc.brewDiaryDoseWater,
          value:
              '${_amount(_entry.coffeeAmount)} g → ${_amount(_entry.waterAmount)} g',
          editLabel: loc.brewDiaryEditAmounts,
          onEdit: _manual ? _editAmounts : null,
          editKey: const Key('editAmountsButton'),
        ),
        _FactCell(
          label: loc.brewDiaryRatioComputed,
          value: _entry.ratio ?? '—',
        ),
        _FactCell(
          label: loc.grindsize,
          value: _entry.grindSize ?? '—',
          editLabel: loc.brewDiaryEditGrind,
          onEdit: _editGrind,
          editKey: const Key('editGrindButton'),
        ),
        _FactCell(
          label: loc.watertemp,
          value: _waterTempDisplay(),
          editLabel: loc.brewDiaryEditTemperature,
          onEdit: _editTemperature,
          editKey: const Key('editTemperatureButton'),
        ),
        _FactCell(
          label: loc.brewDiaryExtraction,
          value: _entry.extractionYieldPercent == null
              ? loc.brewDiaryCalculate
              : '${_entry.extractionYieldPercent!.toStringAsFixed(1)}% ↗',
          onTap: () async {
            AnalyticsService.maybeInstance?.track(
              'diary_extraction_opened',
              properties: {
                'mode': _entry.extractionYieldPercent != null
                    ? 'view'
                    : 'calculate',
              },
            );
            final result = await context.router
                .push<ExtractionCalculatorResult>(
                  ExtractionCalculatorRoute(statUuid: _entry.statUuid),
                );
            if (result != null && mounted) {
              _replaceEntry(applyExtractionCalculatorResult(_entry, result));
            }
          },
        ),
        _FactCell(
          label: loc.brewDiaryTasted,
          value: switch (_entry.tasteBalance) {
            -1 => loc.tasteSour,
            0 => loc.tasteBalanced,
            1 => loc.tasteBitter,
            _ => '—',
          },
          editLabel: loc.brewDiaryEditTaste,
          onEdit: _editTaste,
          editKey: const Key('editTasteButton'),
        ),
      ],
    );
  }

  String _waterTempDisplay() {
    final formatted = formatTemperatureDual(_entry.waterTemp);
    if (formatted == null) return '—';
    return _entry.waterTempIsDerived ? '~$formatted' : formatted;
  }

  static String _amount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _BeanBlock extends StatelessWidget {
  const _BeanBlock({
    required this.entry,
    required this.isSaving,
    required this.onSelect,
    required this.onRemove,
    this.onOpenJourney,
    this.logoUrls,
  });
  final DiaryEntry entry;
  final Future<Map<String, String?>>? logoUrls;
  final bool isSaving;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final ValueChanged<DiaryEntry>? onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isLinked = entry.coffeeBeansUuid != null && entry.beanName != null;
    if (!isLinked) {
      return SectionCard(
        key: const Key('unlinkedBeanBlock'),
        title: loc.selectCoffeeBeans,
        isCollapsible: false,
        child: AppElevatedButton(
          key: const Key('addDiaryBeanButton'),
          label: loc.addCoffeeBeans,
          icon: Icons.add,
          isLoading: isSaving,
          onPressed: isSaving ? null : onSelect,
        ),
      );
    }

    final subtitle = [entry.roaster, entry.origin]
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return Card(
      key: const Key('linkedBeanBlock'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            key: const Key('beanSummaryButton'),
            onTap: isSaving || onOpenJourney == null
                ? null
                : () => onOpenJourney!(entry),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  FutureBuilder<Map<String, String?>>(
                    future: logoUrls,
                    builder: (context, snapshot) => Container(
                      width: AppSpacing.xxl + AppSpacing.lg,
                      height: AppSpacing.xxl,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: RoasterLogo(
                        originalUrl: snapshot.data?['original'],
                        mirrorUrl: snapshot.data?['mirror'],
                        width: AppSpacing.xxl + AppSpacing.lg,
                        height: AppSpacing.xxl,
                        borderRadius: AppRadius.small,
                        forceFit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.beanName!,
                          style: AppTextStyles.fieldLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.chevron_right, size: AppIconSize.medium),
                ],
              ),
            ),
          ),
          Divider(
            height: AppStroke.border,
            thickness: AppStroke.border,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    key: const Key('changeDiaryBeanButton'),
                    label: loc.edit,
                    icon: Icons.swap_horiz,
                    height: AppButton.heightSmall,
                    padding: AppButton.paddingSmall,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : onSelect,
                  ),
                ),
                IconButton(
                  key: const Key('removeDiaryBeanButton'),
                  tooltip: loc.removeFromEntry,
                  color: Theme.of(context).colorScheme.error,
                  onPressed: isSaving ? null : onRemove,
                  icon: const Icon(Icons.link_off),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({
    required this.label,
    required this.value,
    this.onTap,
    this.onEdit,
    this.editLabel,
    this.editKey,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String? editLabel;
  final Key? editKey;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.caption)),
              if (onEdit != null)
                _EditButton(
                  key: editKey,
                  label: editLabel!,
                  onPressed: onEdit!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    return onTap == null
        ? child
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: child,
          );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    icon: const Icon(Icons.edit_outlined),
  );
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.label,
    required this.notRatedLabel,
    required this.onTap,
  });

  final double? rating;
  final String label;
  final String notRatedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: ${rating?.toStringAsFixed(1) ?? notRatedLabel}',
    child: InkWell(
      key: const Key('editRatingButton'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.fieldLabel)),
            ..._ratingIcons(rating),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    ),
  );

  static List<Widget> _ratingIcons(double? rating) {
    final value = rating ?? 0;
    return [
      for (var index = 1; index <= 5; index++)
        Icon(
          value >= index
              ? Icons.star
              : value >= index - 0.5
              ? Icons.star_half
              : Icons.star_border,
          size: AppIconSize.medium,
        ),
    ];
  }
}

class _NullableValue<T> {
  const _NullableValue(this.value);
  final T? value;
}

typedef _FocusedBodyBuilder<T> =
    Widget Function(
      BuildContext context,
      T value,
      ValueChanged<T> onChanged,
      String? error,
    );

class _FocusedEditDialog<T> extends StatefulWidget {
  const _FocusedEditDialog({
    required this.title,
    required this.initialValue,
    required this.bodyBuilder,
    required this.onSave,
    this.clearValue,
    this.saveLabel,
  });

  final String title;
  final T initialValue;
  final _FocusedBodyBuilder<T> bodyBuilder;
  final Future<void> Function(T value) onSave;
  final T? clearValue;

  /// Confirm-button label override. Defaults to [AppLocalizations.save].
  /// Used by the tags dialog, which reads "Done" since editing tags is a
  /// multi-add workflow rather than a single-value save.
  final String? saveLabel;

  @override
  State<_FocusedEditDialog<T>> createState() => _FocusedEditDialogState<T>();
}

class _FocusedEditDialogState<T> extends State<_FocusedEditDialog<T>> {
  late T _value;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_value);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppLocalizations.of(context)!.brewDiarySaveFailed;
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final compactButtonPadding = AppButton.paddingSmall;
    final cancelButton = AppTextButton(
      key: const Key('focusedCancelButton'),
      label: loc.cancel,
      isFullWidth: widget.clearValue != null,
      padding: compactButtonPadding,
      onPressed: _saving ? null : () => Navigator.of(context).pop(),
    );
    final saveButton = AppElevatedButton(
      key: const Key('focusedSaveButton'),
      label: widget.saveLabel ?? loc.save,
      isFullWidth: widget.clearValue != null,
      padding: compactButtonPadding,
      isLoading: _saving,
      onPressed: _saving ? null : _save,
    );

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      title: Text(widget.title, style: AppTextStyles.title),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.bodyBuilder(
            context,
            _value,
            (value) => setState(() {
              _value = value;
              _error = null;
            }),
            _error,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.clearValue == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cancelButton,
                const SizedBox(width: AppSpacing.sm),
                saveButton,
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    key: const Key('focusedClearButton'),
                    label: loc.fieldClearButtonTooltip,
                    padding: compactButtonPadding,
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _value = widget.clearValue as T;
                            _error = null;
                          }),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: cancelButton),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: saveButton),
              ],
            ),
        ],
      ),
    );
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.coffeeAmount,
    required this.waterAmount,
    required this.onSave,
  });

  final double coffeeAmount;
  final double waterAmount;
  final Future<void> Function((double, double)) onSave;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late double _coffeeAmount = widget.coffeeAmount;
  late double _waterAmount = widget.waterAmount;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _FocusedEditDialog<(double, double)>(
      title: loc.brewDiaryEditAmounts,
      initialValue: (_coffeeAmount, _waterAmount),
      bodyBuilder: (context, value, onChanged, error) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NumericTextField(
            key: const Key('focusedCoffeeAmountInput'),
            label: loc.coffeeamount,
            initialValue: value.$1,
            allowDecimal: true,
            onChanged: (next) {
              _coffeeAmount = next ?? value.$1;
              onChanged((_coffeeAmount, _waterAmount));
            },
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          NumericTextField(
            key: const Key('focusedWaterAmountInput'),
            label: loc.wateramount,
            initialValue: value.$2,
            allowDecimal: true,
            helperText: error,
            onChanged: (next) {
              _waterAmount = next ?? value.$2;
              onChanged((_coffeeAmount, _waterAmount));
            },
          ),
        ],
      ),
      onSave: widget.onSave,
    );
  }
}

class _RatingDialog extends StatelessWidget {
  const _RatingDialog({required this.initialRating, required this.onSave});

  final double? initialRating;
  final Future<void> Function(double? value) onSave;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _FocusedEditDialog<_NullableValue<double>>(
      title: loc.brewDiaryRateThisBrew,
      initialValue: _NullableValue(initialRating),
      clearValue: const _NullableValue(null),
      bodyBuilder: (context, value, onChanged, error) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyedSubtree(
            key: const Key('focusedRatingBar'),
            child: RatingBar.builder(
              initialRating: value.value ?? 0,
              minRating: 0.5,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: AppIconSize.large,
              itemBuilder: (context, index) => Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.primary,
              ),
              onRatingUpdate: (rating) => onChanged(_NullableValue(rating)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.value?.toStringAsFixed(1) ?? loc.brewDiaryNotRated,
            key: const Key('focusedRatingLabel'),
            style: AppTextStyles.body,
          ),
          if (error != null) _InlineError(error),
        ],
      ),
      onSave: (value) => onSave(value.value),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Text(
      message,
      style: AppTextStyles.caption.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

class _TasteEditor extends StatelessWidget {
  const _TasteEditor({
    required this.value,
    required this.labels,
    required this.onChanged,
  });
  final int? value;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ChoiceChip(
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ),
              label: Text(
                labels[index],
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: value == index - 1
                      ? AppSemanticColors.taste(
                          index - 1,
                          brightness,
                        ).foreground
                      : null,
                ),
              ),
              selected: value == index - 1,
              selectedColor: AppSemanticColors.taste(
                index - 1,
                brightness,
              ).background,
              onSelected: (_) => onChanged(index - 1),
            ),
          ),
        ],
      ],
    );
  }
}

class _TagsFieldEditor extends StatelessWidget {
  const _TagsFieldEditor({
    required this.initialValues,
    required this.suggestionsFuture,
    required this.onChanged,
    this.errorText,
    this.textController,
  });

  final List<String> initialValues;
  final Future<List<String>> suggestionsFuture;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<List<String>>(
      future: suggestionsFuture,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];
        return ChipInput(
          key: const Key('focusedTagsInput'),
          label: loc.diaryTags,
          hintText: loc.diaryTagsHint,
          initialValues: initialValues,
          suggestions: suggestions,
          quickPicks: suggestions,
          maxChips: diaryTagsMaxCount,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          capitalizeChipLabels: false,
          errorText: errorText,
          onChanged: onChanged,
          controller: textController,
        );
      },
    );
  }
}
