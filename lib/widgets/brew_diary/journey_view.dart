import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/grind_value.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/utils/temperature_format.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_entry_card.dart';
import 'package:coffee_timer/widgets/brew_diary/directional_value_text.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_progress.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class JourneyView extends StatelessWidget {
  const JourneyView({
    super.key,
    required this.group,
    this.logoUrls,
    this.onBeanTap,
  });

  final DiaryGroup group;
  final Future<Map<String, String?>>? logoUrls;
  final VoidCallback? onBeanTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'journeyView_${group.key}',
      child: Scaffold(
        appBar: AppBar(
          leading: SmartBackButton(),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Coffeico.bag_with_bean, size: AppIconSize.medium),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  group.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: _BeanJourney(
          group: group,
          logoUrls: logoUrls,
          onBeanTap: onBeanTap,
        ),
      ),
    );
  }
}

class _BeanJourney extends StatefulWidget {
  const _BeanJourney({required this.group, this.logoUrls, this.onBeanTap});

  final DiaryGroup group;
  final Future<Map<String, String?>>? logoUrls;
  final VoidCallback? onBeanTap;

  @override
  State<_BeanJourney> createState() => _BeanJourneyState();
}

class _BeanJourneyState extends State<_BeanJourney> {
  late List<DiaryEntry> _entries = widget.group.entries.toList();
  final Set<String> _pendingBookmarkUuids = {};

  @override
  void didUpdateWidget(covariant _BeanJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.key != widget.group.key ||
        !identical(oldWidget.group.entries, widget.group.entries)) {
      _entries = widget.group.entries.toList();
    }
  }

  void _replaceEntry(DiaryEntry updated) {
    setState(() {
      _entries = [
        for (final entry in _entries)
          entry.statUuid == updated.statUuid ? updated : entry,
      ];
    });
  }

  void _replaceRating(String statUuid, double? rating) {
    final current = _entries.firstWhere((entry) => entry.statUuid == statUuid);
    _replaceEntry(current.copyWith(rating: rating));
  }

  Future<void> _evaluateLatest(DiaryEntry entry) async {
    final result = await showBrewRatingEditor(context, entry: entry);
    if (mounted && result.wasSaved) {
      _replaceRating(entry.statUuid, result.rating);
    }
  }

  Future<void> _toggleBookmark(DiaryEntry entry) async {
    if (_pendingBookmarkUuids.contains(entry.statUuid)) return;
    final nextValue = !entry.isMarked;
    setState(() => _pendingBookmarkUuids.add(entry.statUuid));
    try {
      await context.read<UserStatProvider>().updateUserStat(
        statUuid: entry.statUuid,
        isMarked: nextValue,
      );
      AnalyticsService.maybeInstance?.track(
        'diary_bookmark_toggled',
        properties: {'bookmarked': nextValue, 'source': 'journey'},
      );
      if (!mounted) return;
      _replaceEntry(entry.copyWith(isMarked: nextValue));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update Journey bookmark',
        errorObject: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _pendingBookmarkUuids.remove(entry.statUuid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final byMethod = [
      for (final method in buildJourneyMethodSeries(_entries))
        method.entries.reversed.toList(growable: false),
    ];
    final best = _bestEntry(_entries);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        _JourneyHeader(
          group: widget.group,
          entries: _entries,
          logoUrls: widget.logoUrls,
          onBeanTap: widget.onBeanTap,
        ),
        const SizedBox(height: AppSpacing.base),
        JourneyProgress(entries: _entries, onEvaluateLatest: _evaluateLatest),
        for (final series in byMethod) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            key: ValueKey(
              'journeyMethodHeader_${series.first.brewingMethodId}',
            ),
            children: [
              Icon(
                getIconByBrewingMethod(series.first.brewingMethodId).icon,
                size: AppIconSize.small,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  series.first.methodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionHeader,
                ),
              ),
              if (series.length >= 2)
                AppTextButton(
                  key: ValueKey(
                    'journeyCompare_${series.first.brewingMethodId}',
                  ),
                  label: loc.journeyCompare,
                  icon: Icons.compare_arrows,
                  isFullWidth: false,
                  height: AppButton.heightSmall,
                  padding: AppButton.paddingSmall,
                  onPressed: () => _showCompareSheet(context, series),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < series.length; index++) ...[
            _JourneyEntryCard(
              entry: series[index],
              logoUrls: widget.logoUrls,
              isBest: identical(series[index], best),
              onEntryChanged: _replaceEntry,
              onBookmarkToggle: () => _toggleBookmark(series[index]),
              bookmarkTogglePending: _pendingBookmarkUuids.contains(
                series[index].statUuid,
              ),
            ),
            if (index < series.length - 1)
              _DeltaRow(previous: series[index + 1], current: series[index]),
          ],
        ],
      ],
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.group,
    required this.entries,
    this.logoUrls,
    this.onBeanTap,
  });

  final DiaryGroup group;
  final List<DiaryEntry> entries;
  final Future<Map<String, String?>>? logoUrls;
  final VoidCallback? onBeanTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final roaster = group.roaster?.trim().isNotEmpty == true
        ? group.roaster!.trim()
        : group.subtitle?.trim();
    final origin = entries.first.origin?.trim();
    final methodCount = entries
        .map((entry) => entry.brewingMethodId)
        .toSet()
        .length;
    final evaluatedCount = entries
        .where((entry) => entry.rating != null)
        .length;
    final summaryParts = [
      loc.diaryGroupBrewCount(entries.length),
      loc.formattedBrewingMethodCount(methodCount),
      loc.journeyEvaluatedBrewCount(evaluatedCount),
    ];
    final summaryLabel = summaryParts.join(', ');
    final labelParts = [
      group.title,
      if (roaster?.isNotEmpty ?? false) roaster!,
      if (origin?.isNotEmpty ?? false) '${loc.origin}: $origin',
      summaryLabel,
    ];

    return Semantics(
      identifier: 'journeyBeanHeader_${group.key}',
      label: labelParts.join(', '),
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              onBeanTap ??
              () =>
                  context.router.push(CoffeeBeansDetailRoute(uuid: group.key)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                _JourneyLogo(logoUrls: logoUrls),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionHeader,
                      ),
                      if (roaster?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          roaster!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body,
                        ),
                      ],
                      if (origin?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${loc.origin}: $origin',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      _JourneySummary(parts: summaryParts),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, size: AppIconSize.medium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          runSpacing: AppSpacing.xs,
          children: [
            for (var index = 0; index < parts.length; index++)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: AppStroke.focus,
                        height: AppStroke.focus,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(parts[index], style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneyLogo extends StatelessWidget {
  const _JourneyLogo({this.logoUrls});

  final Future<Map<String, String?>>? logoUrls;

  static const _width = AppSpacing.xxl + AppSpacing.lg;
  static const _height = AppSpacing.xxl + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('journeyBeanLogoSlot'),
      width: _width,
      height: _height,
      child: Center(
        child: logoUrls == null
            ? const Icon(Coffeico.bean, size: AppIconSize.large)
            : FutureBuilder<Map<String, String?>>(
                future: logoUrls,
                builder: (context, snapshot) {
                  final original = snapshot.data?['original'];
                  final mirror = snapshot.data?['mirror'];
                  if (original == null && mirror == null) {
                    return const Icon(Coffeico.bean, size: AppIconSize.large);
                  }
                  return RoasterLogo(
                    originalUrl: original,
                    mirrorUrl: mirror,
                    width: _width,
                    height: _height,
                    borderRadius: AppRadius.small,
                    forceFit: BoxFit.contain,
                  );
                },
              ),
      ),
    );
  }
}

class _JourneyEntryCard extends StatelessWidget {
  const _JourneyEntryCard({
    required this.entry,
    required this.onBookmarkToggle,
    required this.bookmarkTogglePending,
    this.logoUrls,
    this.isBest = false,
    this.onEntryChanged,
  });

  final DiaryEntry entry;
  final VoidCallback onBookmarkToggle;
  final bool bookmarkTogglePending;
  final Future<Map<String, String?>>? logoUrls;
  final bool isBest;
  final ValueChanged<DiaryEntry>? onEntryChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final formatService = context.watch<DateTimeFormatService>();
    final use24Hour = formatService.use24Hour(
      MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat(
      formatService.datePattern(loc.dateFormat),
      locale,
    );
    final timeFormat = DateFormat(use24Hour ? 'HH:mm' : 'hh:mm a', locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BrewEntryCard(
        entry: entry,
        formattedDate: dateFormat.format(entry.createdAt.toLocal()),
        formattedTime: timeFormat.format(entry.createdAt.toLocal()),
        logoUrls: logoUrls,
        tasteLabels: [loc.tasteSour, loc.tasteBalanced, loc.tasteBitter],
        onTap: () async {
          final changed = await showBrewDetailSheet(
            context,
            entry: entry,
            logoUrls: logoUrls,
            onEntryChanged: onEntryChanged,
            onOpenBeanJourney: (_) => Navigator.of(context).pop(),
            analyticsSource: 'group_card',
          );
          if (changed == true && context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
        onBookmarkToggle: onBookmarkToggle,
        bookmarkTogglePending: bookmarkTogglePending,
        onBrewAgain: () {
          AnalyticsService.maybeInstance?.track(
            'diary_brew_again_tapped',
            properties: {
              'source': 'journey',
              'recipe_id': entry.recipeId,
              'brewing_method_id': entry.brewingMethodId,
              'has_grind_prefill': entry.grindSize?.trim().isNotEmpty ?? false,
              'has_temp_prefill': entry.storedWaterTemp != null,
            },
          );
          context.router.push(
            RecipeDetailRoute(
              brewingMethodId: entry.brewingMethodId,
              recipeId: entry.recipeId,
              prefillCoffeeAmount: entry.coffeeAmount,
              prefillWaterAmount: entry.waterAmount,
              prefillGrindSize: entry.grindSize,
              prefillWaterTemp: entry.storedWaterTemp,
              prefillCoffeeBeansUuid: entry.coffeeBeansUuid,
            ),
          );
        },
        isBestCup: isBest,
        showBeanIdentity: false,
        semanticsIdentifierPrefix: 'journeyAttempt',
        bookmarkSemanticsIdentifierPrefix: 'journeyBookmark',
      ),
    );
  }
}

String _keepTemperatureUnitTogether(String value) =>
    value.replaceAll(' °C', '\u00A0°C').replaceAll(' °F', '\u00A0°F');

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({required this.previous, required this.current});

  final DiaryEntry previous;
  final DiaryEntry current;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final deltas = <String>[];
    _addNumericDelta(
      deltas,
      loc.coffeeamount,
      previous.coffeeAmount,
      current.coffeeAmount,
    );
    _addNumericDelta(
      deltas,
      loc.wateramount,
      previous.waterAmount,
      current.waterAmount,
    );
    _addRatioDelta(deltas, loc, previous, current);

    final previousGrind = previous.grindSize?.trim();
    final currentGrind = current.grindSize?.trim();
    if (previousGrind != null && currentGrind != null) {
      if (previousGrind == currentGrind) {
        deltas.add(loc.journeyHeld(loc.grindsize));
      } else {
        final before = parseGrindSetting(previousGrind);
        final after = parseGrindSetting(currentGrind);
        deltas.add(
          before != null &&
                  after != null &&
                  before.contextKey == after.contextKey
              ? '${loc.grindsize} ${_signed(after.value - before.value)}'
              : '$previousGrind → $currentGrind',
        );
      }
    }

    if (previous.waterTemp != null && current.waterTemp != null) {
      if (previous.waterTemp == current.waterTemp) {
        final bothDerived =
            previous.waterTempIsDerived && current.waterTempIsDerived;
        if (!bothDerived) deltas.add(loc.journeyHeld(loc.watertemp));
      } else {
        final delta = current.waterTemp! - previous.waterTemp!;
        final derived =
            previous.waterTempIsDerived || current.waterTempIsDerived;
        deltas.add('${loc.watertemp} ${derived ? '~' : ''}${_signed(delta)}°');
      }
    } else if (previous.waterTemp != null || current.waterTemp != null) {
      final hasCurrent = current.waterTemp != null;
      final derived = hasCurrent
          ? current.waterTempIsDerived
          : previous.waterTempIsDerived;
      final formatted = formatTemperatureDual(
        hasCurrent ? current.waterTemp : previous.waterTemp,
      )!;
      final value = derived ? '~$formatted' : formatted;
      deltas.add(hasCurrent ? '— → $value' : '$value → —');
    }
    if (deltas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [for (final delta in deltas) _FactChip(label: delta)],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final neutral = AppSemanticColors.neutralChip(Theme.of(context).brightness);
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(color: neutral.foreground),
      backgroundColor: neutral.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    );
  }
}

/// Builds a stable, human-readable label per entry ("recipe name · date"),
/// keyed by `statUuid`. Falls back to appending the time when two entries in
/// the same series would otherwise produce an identical label.
Map<String, String> _entryLabels(
  List<DiaryEntry> entries,
  AppLocalizations loc,
  DateTimeFormatService fmtSvc,
  bool use24Hour,
  String locale,
) {
  final dateFormat = DateFormat(fmtSvc.datePattern(loc.dateFormat), locale);
  final baseLabels = {
    for (final entry in entries)
      entry.statUuid:
          '${entry.recipeName} · ${dateFormat.format(entry.createdAt.toLocal())}',
  };
  final hasCollision = baseLabels.values.toSet().length != baseLabels.length;
  if (!hasCollision) return baseLabels;

  final timeFormat = DateFormat(use24Hour ? 'HH:mm' : 'hh:mm a', locale);
  return {
    for (final entry in entries)
      entry.statUuid:
          '${baseLabels[entry.statUuid]} ${timeFormat.format(entry.createdAt.toLocal())}',
  };
}

Future<void> _showCompareSheet(BuildContext context, List<DiaryEntry> entries) {
  AnalyticsService.maybeInstance?.track(
    'diary_compare_opened',
    properties: {'series_length': entries.length},
  );
  final chronological = [...entries]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  DiaryEntry? first;
  DiaryEntry? second;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final loc = AppLocalizations.of(context)!;
        final fmtSvc = Provider.of<DateTimeFormatService>(context);
        final use24Hour = fmtSvc.use24Hour(
          MediaQuery.of(context).alwaysUse24HourFormat,
        );
        final locale = Localizations.localeOf(context).toString();
        final labels = _entryLabels(
          chronological,
          loc,
          fmtSvc,
          use24Hour,
          locale,
        );
        // Scrollable: long recipe·date chip labels stack vertically, and
        // together with the comparison table the content can exceed the
        // sheet height on phones.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.journeyCompareTitle, style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.sm),
              Text(loc.journeySelectTwo, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (var index = 0; index < chronological.length; index++)
                    FilterChip(
                      label: _ComparisonEntryLabel(
                        labels[chronological[index].statUuid]!,
                      ),
                      selected:
                          identical(first, chronological[index]) ||
                          identical(second, chronological[index]),
                      onSelected: (selected) => setState(() {
                        final entry = chronological[index];
                        if (!selected) {
                          if (identical(first, entry)) first = null;
                          if (identical(second, entry)) second = null;
                        } else if (first == null) {
                          first ??= entry;
                        } else {
                          second ??= entry;
                        }
                      }),
                    ),
                ],
              ),
              if (first != null && second != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ComparisonTable(
                  first: first!,
                  second: second!,
                  firstLabel: labels[first!.statUuid]!,
                  secondLabel: labels[second!.statUuid]!,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    ),
  );
}

enum JourneyComparisonField {
  doseWater,
  ratio,
  grind,
  temperature,
  extraction,
  taste,
  rating,
}

enum JourneyComparisonSide { first, second }

/// Test-visible representation of one evidence-honest comparison row.
@immutable
class JourneyComparisonRow {
  const JourneyComparisonRow({
    required this.field,
    required this.label,
    required this.firstValue,
    required this.secondValue,
    required this.changed,
    this.bestCupSide,
    this.betterTasteSide,
    this.firstTasteBalance,
    this.secondTasteBalance,
  });

  final JourneyComparisonField field;
  final String label;
  final String firstValue;
  final String secondValue;
  final bool changed;
  final JourneyComparisonSide? bestCupSide;
  final JourneyComparisonSide? betterTasteSide;
  final int? firstTasteBalance;
  final int? secondTasteBalance;
}

List<JourneyComparisonRow> buildJourneyComparisonRows(
  DiaryEntry first,
  DiaryEntry second,
  AppLocalizations loc,
) {
  final better = _betterOf(first, second);
  final bestCupSide = identical(first, better)
      ? JourneyComparisonSide.first
      : identical(second, better)
      ? JourneyComparisonSide.second
      : null;
  final betterTasteSide = _betterTasteOf(first, second);

  JourneyComparisonRow row(
    JourneyComparisonField field,
    String label,
    String firstValue,
    String secondValue, {
    int? firstTasteBalance,
    int? secondTasteBalance,
  }) {
    final changed = firstValue != secondValue;
    return JourneyComparisonRow(
      field: field,
      label: label,
      firstValue: firstValue,
      secondValue: secondValue,
      changed: changed,
      // A higher overall rating makes this the preferred cup; it does not
      // make each changed recipe or taste value a winner in isolation.
      bestCupSide: changed && field == JourneyComparisonField.rating
          ? bestCupSide
          : null,
      betterTasteSide: changed && field == JourneyComparisonField.taste
          ? betterTasteSide
          : null,
      firstTasteBalance: firstTasteBalance,
      secondTasteBalance: secondTasteBalance,
    );
  }

  return [
    row(
      JourneyComparisonField.doseWater,
      loc.brewDiaryDoseWater,
      '${_amount(first.coffeeAmount)}\u00A0g → ${_amount(first.waterAmount)}\u00A0g',
      '${_amount(second.coffeeAmount)}\u00A0g → ${_amount(second.waterAmount)}\u00A0g',
    ),
    row(
      JourneyComparisonField.ratio,
      loc.brewDiaryRatioComputed,
      first.ratio ?? '—',
      second.ratio ?? '—',
    ),
    row(
      JourneyComparisonField.grind,
      loc.grindsize,
      first.grindSize?.trim() ?? '—',
      second.grindSize?.trim() ?? '—',
    ),
    row(
      JourneyComparisonField.temperature,
      loc.watertemp,
      _dualTemp(first),
      _dualTemp(second),
    ),
    row(
      JourneyComparisonField.extraction,
      loc.brewDiaryExtraction,
      _ey(first),
      _ey(second),
    ),
    row(
      JourneyComparisonField.taste,
      loc.brewDiaryTasted,
      _taste(loc, first),
      _taste(loc, second),
      firstTasteBalance: first.tasteBalance,
      secondTasteBalance: second.tasteBalance,
    ),
    row(
      JourneyComparisonField.rating,
      loc.rating,
      _rating(first),
      _rating(second),
    ),
  ];
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({
    required this.first,
    required this.second,
    required this.firstLabel,
    required this.secondLabel,
  });

  final DiaryEntry first;
  final DiaryEntry second;
  final String firstLabel;
  final String secondLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final rows = buildJourneyComparisonRows(first, second, loc);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CompareCell(
                      text: firstLabel,
                      label: true,
                      entryIdentity: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CompareCell(
                      text: secondLabel,
                      label: true,
                      entryIdentity: true,
                    ),
                  ),
                ],
              ),
              for (final row in rows) ...[
                const Divider(height: AppSpacing.sm),
                _CompareCell(
                  key: ValueKey('journeyComparisonLabel_${row.field.name}'),
                  text: row.label,
                  label: true,
                  wrapLabelByWord: true,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _comparisonValueCell(
                        row,
                        JourneyComparisonSide.first,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _comparisonValueCell(
                        row,
                        JourneyComparisonSide.second,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }
        return Table(
          columnWidths: const {
            0: FlexColumnWidth(1.25),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(1.1),
          },
          children: [
            TableRow(
              children: [
                const _CompareCell(text: ''),
                _CompareCell(
                  text: firstLabel,
                  label: true,
                  entryIdentity: true,
                ),
                _CompareCell(
                  text: secondLabel,
                  label: true,
                  entryIdentity: true,
                ),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  _CompareCell(
                    key: ValueKey('journeyComparisonLabel_${row.field.name}'),
                    text: row.label,
                    label: true,
                    wrapLabelByWord: true,
                  ),
                  _comparisonValueCell(row, JourneyComparisonSide.first),
                  _comparisonValueCell(row, JourneyComparisonSide.second),
                ],
              ),
          ],
        );
      },
    );
  }

  _CompareCell _comparisonValueCell(
    JourneyComparisonRow row,
    JourneyComparisonSide side,
  ) {
    final first = side == JourneyComparisonSide.first;
    return _CompareCell(
      key: ValueKey(
        'journeyComparison_${row.field.name}_${first ? 'first' : 'second'}',
      ),
      text: first ? row.firstValue : row.secondValue,
      fieldLabel: row.label,
      changed: row.changed,
      fromBestCup: row.bestCupSide == side,
      betterTasteResult: row.betterTasteSide == side,
      tasteBalance: first ? row.firstTasteBalance : row.secondTasteBalance,
      literalValue: row.field != JourneyComparisonField.taste,
    );
  }
}

class _CompareCell extends StatelessWidget {
  const _CompareCell({
    super.key,
    required this.text,
    this.label = false,
    this.fieldLabel,
    this.changed = false,
    this.fromBestCup = false,
    this.betterTasteResult = false,
    this.tasteBalance,
    this.wrapLabelByWord = false,
    this.literalValue = false,
    this.entryIdentity = false,
  });
  final String text;
  final bool label;
  final String? fieldLabel;
  final bool changed;
  final bool fromBestCup;
  final bool betterTasteResult;
  final int? tasteBalance;
  final bool wrapLabelByWord;
  final bool literalValue;
  final bool entryIdentity;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tastePair = tasteBalance == null
        ? null
        : AppSemanticColors.taste(tasteBalance!, theme.brightness);
    final background = !changed
        ? null
        : tastePair?.background ??
              (fromBestCup
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest);
    final foreground = !changed
        ? null
        : tastePair?.foreground ??
              (fromBestCup
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant);
    final borderColor = !changed ? null : theme.colorScheme.outlineVariant;
    final semanticsLabel = fieldLabel == null
        ? text
        : changed
        ? '${loc.journeyChanged(fieldLabel!)}: $text'
              '${fromBestCup ? ', ${loc.journeyBestCup}' : ''}'
              '${betterTasteResult ? ', ${loc.journeyBetterTaste}' : ''}'
        : '${fieldLabel!}: $text';

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: background == null
              ? null
              : BoxDecoration(
                  color: background,
                  border: Border.all(
                    color: borderColor!,
                    width: AppStroke.border,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: entryIdentity
                    ? _ComparisonEntryLabel(text)
                    : wrapLabelByWord
                    ? _WordAwareComparisonLabel(text: text)
                    : literalValue
                    ? DirectionalValueText(
                        text,
                        style: foreground == null
                            ? (label
                                  ? AppTextStyles.fieldLabel
                                  : AppTextStyles.caption)
                            : AppTextStyles.caption.copyWith(color: foreground),
                      )
                    : Text(
                        text,
                        style: foreground == null
                            ? (label
                                  ? AppTextStyles.fieldLabel
                                  : AppTextStyles.caption)
                            : AppTextStyles.caption.copyWith(color: foreground),
                      ),
              ),
              if (fromBestCup) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.workspace_premium_outlined,
                  size: AppIconSize.small,
                  color: foreground,
                ),
              ],
              if (betterTasteResult) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.check_circle_outline,
                  size: AppIconSize.small,
                  color: foreground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WordAwareComparisonLabel extends StatelessWidget {
  const _WordAwareComparisonLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final words = text.trim().split(RegExp(r'\s+'));
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final word in words)
          Text(word, softWrap: false, style: AppTextStyles.fieldLabel),
      ],
    );
  }
}

class _ComparisonEntryLabel extends StatelessWidget {
  const _ComparisonEntryLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final separator = label.lastIndexOf(' · ');
    final recipe = separator < 0 ? label : label.substring(0, separator);
    final date = separator < 0 ? '' : label.substring(separator + 3);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fieldLabel,
            ),
            if (date.isNotEmpty)
              DirectionalValueText(
                date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
          ],
        ),
      ),
    );
  }
}

DiaryEntry? _bestEntry(Iterable<DiaryEntry> entries) {
  final rated = entries.where((entry) => entry.rating != null).toList();
  if (rated.isEmpty) return null;
  rated.sort((a, b) {
    final rating = b.rating!.compareTo(a.rating!);
    return rating != 0 ? rating : b.createdAt.compareTo(a.createdAt);
  });
  return rated.first;
}

// Only declares a winner when both entries are rated and the ratings differ;
// otherwise there's nothing meaningful to highlight.
DiaryEntry? _betterOf(DiaryEntry first, DiaryEntry second) {
  final firstRating = first.rating;
  final secondRating = second.rating;
  if (firstRating == null ||
      secondRating == null ||
      firstRating == secondRating) {
    return null;
  }
  return firstRating > secondRating ? first : second;
}

JourneyComparisonSide? _betterTasteOf(DiaryEntry first, DiaryEntry second) {
  final firstTaste = first.tasteBalance;
  final secondTaste = second.tasteBalance;
  if (firstTaste == 0 && (secondTaste == -1 || secondTaste == 1)) {
    return JourneyComparisonSide.first;
  }
  if (secondTaste == 0 && (firstTaste == -1 || firstTaste == 1)) {
    return JourneyComparisonSide.second;
  }
  return null;
}

void _addNumericDelta(
  List<String> output,
  String label,
  double before,
  double after,
) {
  if (before == after) return;
  output.add('$label ${_signed(after - before)}');
}

void _addRatioDelta(
  List<String> output,
  AppLocalizations loc,
  DiaryEntry before,
  DiaryEntry after,
) {
  if (before.coffeeAmount <= 0 || after.coffeeAmount <= 0) return;
  final delta =
      after.waterAmount / after.coffeeAmount -
      before.waterAmount / before.coffeeAmount;
  if (delta != 0) output.add(loc.journeyRatioDelta(_signed(delta)));
}

String _signed(double value) => '${value > 0 ? '+' : ''}${_amount(value)}';
String _amount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
String _dualTemp(DiaryEntry entry) {
  final formatted = formatTemperatureDual(entry.waterTemp);
  if (formatted == null) return '—';
  final grouped = _keepTemperatureUnitTogether(formatted);
  return entry.waterTempIsDerived ? '~$grouped' : grouped;
}

String _ey(DiaryEntry entry) => entry.extractionYieldPercent == null
    ? '—'
    : '${entry.extractionYieldPercent!.toStringAsFixed(1)}%';
String _rating(DiaryEntry entry) =>
    entry.rating == null ? '—' : '★${entry.rating!.toStringAsFixed(1)}';
String _taste(AppLocalizations loc, DiaryEntry entry) =>
    switch (entry.tasteBalance) {
      -1 => loc.tasteSour,
      0 => loc.tasteBalanced,
      1 => loc.tasteBitter,
      _ => '—',
    };
