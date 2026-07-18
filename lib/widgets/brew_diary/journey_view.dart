import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/grind_value.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/utils/temperature_format.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_progress.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class JourneyView extends StatelessWidget {
  const JourneyView({super.key, required this.group, this.logoUrls});

  final DiaryGroup group;
  final Future<Map<String, String?>>? logoUrls;

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
        body: _BeanJourney(group: group, logoUrls: logoUrls),
      ),
    );
  }
}

class _BeanJourney extends StatefulWidget {
  const _BeanJourney({required this.group, this.logoUrls});

  final DiaryGroup group;
  final Future<Map<String, String?>>? logoUrls;

  @override
  State<_BeanJourney> createState() => _BeanJourneyState();
}

class _BeanJourneyState extends State<_BeanJourney> {
  late List<DiaryEntry> _entries = widget.group.entries.toList();

  @override
  void didUpdateWidget(covariant _BeanJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.key != widget.group.key ||
        !identical(oldWidget.group.entries, widget.group.entries)) {
      _entries = widget.group.entries.toList();
    }
  }

  void _replaceRating(String statUuid, double? rating) {
    setState(() {
      _entries = [
        for (final entry in _entries)
          entry.statUuid == statUuid ? entry.copyWith(rating: rating) : entry,
      ];
    });
  }

  Future<void> _evaluateLatest(DiaryEntry entry) async {
    final result = await showBrewRatingEditor(context, entry: entry);
    if (mounted && result.wasSaved) {
      _replaceRating(entry.statUuid, result.rating);
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
              onRatingChanged: (rating) =>
                  _replaceRating(series[index].statUuid, rating),
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
  });

  final DiaryGroup group;
  final List<DiaryEntry> entries;
  final Future<Map<String, String?>>? logoUrls;

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
          onTap: () =>
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
    this.logoUrls,
    this.isBest = false,
    this.onRatingChanged,
  });

  final DiaryEntry entry;
  final Future<Map<String, String?>>? logoUrls;
  final bool isBest;
  final ValueChanged<double?>? onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final formatService = context.watch<DateTimeFormatService>();
    final use24Hour = formatService.use24Hour(
      MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final dateTimeFormat = DateFormat(
      '${formatService.datePattern(loc.dateFormat)} '
      '${use24Hour ? 'HH:mm' : 'hh:mm a'}',
      Localizations.localeOf(context).toString(),
    );
    return Semantics(
      identifier: 'journeyAttempt_${entry.statUuid}',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final changed = await showBrewDetailSheet(
              context,
              entry: entry,
              logoUrls: logoUrls,
              onRatingChanged: onRatingChanged,
              onOpenBeanJourney: (_) => Navigator.of(context).pop(),
              analyticsSource: 'group_card',
            );
            if (changed == true && context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.recipeName,
                        style: AppTextStyles.sectionHeader,
                      ),
                    ),
                    if (entry.isMarked) ...[
                      Semantics(
                        identifier: 'journeyBookmark_${entry.statUuid}',
                        label: loc.diaryBookmarked,
                        child: Icon(
                          Icons.bookmark,
                          size: AppIconSize.small,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    if (isBest)
                      _FactChip(
                        label: loc.journeyBestCup,
                        icon: Icons.push_pin,
                        emphasized: true,
                      ),
                  ],
                ),
                Text(
                  dateTimeFormat.format(entry.createdAt.toLocal()),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _FactChip(
                      label:
                          '${_amount(entry.coffeeAmount)} g → ${_amount(entry.waterAmount)} g',
                    ),
                    if (entry.ratio case final ratio?) _FactChip(label: ratio),
                    if (entry.grindSize?.trim().isNotEmpty ?? false)
                      _FactChip(label: entry.grindSize!.trim()),
                    if (formatTemperatureDual(entry.waterTemp) case final temp?)
                      _FactChip(
                        label: entry.waterTempIsDerived ? '~$temp' : temp,
                      ),
                    if (entry.extractionYieldPercent case final ey?)
                      _FactChip(
                        label: entry.tdsPercent == null
                            ? '${ey.toStringAsFixed(1)}% EY'
                            : loc.extractionCalcDiaryLine(
                                ey.toStringAsFixed(1),
                                entry.tdsPercent!.toStringAsFixed(2),
                              ),
                      )
                    else if (entry.tdsPercent case final tds?)
                      _FactChip(label: 'TDS ${tds.toStringAsFixed(2)}%'),
                    if (entry.tasteBalance case final taste?)
                      _TasteChip(taste: taste),
                    if (entry.rating case final rating?)
                      _FactChip(label: '★${rating.toStringAsFixed(1)}'),
                    if (entry.rating == null)
                      _FactChip(label: loc.brewDiaryNotRated),
                    ..._tagChips(entry.tagList),
                  ],
                ),
                if (entry.notes?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    entry.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppTextButton(
                    label: loc.brewAgain,
                    icon: Icons.replay,
                    isFullWidth: false,
                    height: AppButton.heightSmall,
                    padding: AppButton.paddingSmall,
                    onPressed: () {
                      AnalyticsService.maybeInstance?.track(
                        'diary_brew_again_tapped',
                        properties: {
                          'source': 'journey',
                          'recipe_id': entry.recipeId,
                          'brewing_method_id': entry.brewingMethodId,
                          'has_grind_prefill':
                              entry.grindSize?.trim().isNotEmpty ?? false,
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  const _FactChip({required this.label, this.icon, this.emphasized = false});

  final String label;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neutral = AppSemanticColors.neutralChip(theme.brightness);
    final foreground = emphasized
        ? theme.colorScheme.onPrimaryContainer
        : neutral.foreground;
    return Chip(
      avatar: icon == null
          ? null
          : Icon(icon, size: AppIconSize.small, color: foreground),
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(color: foreground),
      backgroundColor: emphasized
          ? theme.colorScheme.primaryContainer
          : neutral.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    );
  }
}

List<Widget> _tagChips(List<String> tags) {
  if (tags.isEmpty) return const [];
  final visible = tags.take(3).toList();
  final overflow = tags.length - visible.length;
  return [
    for (final tag in visible) _FactChip(label: '#$tag'),
    if (overflow > 0) _FactChip(label: '+$overflow'),
  ];
}

class _TasteChip extends StatelessWidget {
  const _TasteChip({required this.taste});

  final int taste;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = AppSemanticColors.taste(taste, Theme.of(context).brightness);
    final label = switch (taste) {
      -1 => loc.tasteSour,
      0 => loc.tasteBalanced,
      _ => loc.tasteBitter,
    };
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(color: colors.foreground),
      backgroundColor: colors.background,
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
                      label: Text(labels[chronological[index].statUuid]!),
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
    final better = _betterOf(first, second);
    final rows = <(String, String, String)>[
      (
        loc.brewDiaryDoseWater,
        '${_amount(first.coffeeAmount)} → ${_amount(first.waterAmount)} g',
        '${_amount(second.coffeeAmount)} → ${_amount(second.waterAmount)} g',
      ),
      (loc.brewDiaryRatioComputed, first.ratio ?? '—', second.ratio ?? '—'),
      (loc.grindsize, first.grindSize ?? '—', second.grindSize ?? '—'),
      (loc.watertemp, _dualTemp(first), _dualTemp(second)),
      (loc.brewDiaryExtraction, _ey(first), _ey(second)),
      (loc.brewDiaryTasted, _taste(loc, first), _taste(loc, second)),
      (loc.rating, _rating(first), _rating(second)),
    ];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          children: [
            const _CompareCell(text: ''),
            _CompareCell(text: firstLabel, label: true, maxLines: 2),
            _CompareCell(text: secondLabel, label: true, maxLines: 2),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _CompareCell(text: row.$1, label: true),
              _CompareCell(text: row.$2, highlighted: identical(first, better)),
              _CompareCell(
                text: row.$3,
                highlighted: identical(second, better),
              ),
            ],
          ),
      ],
    );
  }
}

class _CompareCell extends StatelessWidget {
  const _CompareCell({
    required this.text,
    this.label = false,
    this.highlighted = false,
    this.maxLines,
  });
  final String text;
  final bool label;
  final bool highlighted;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final pair = AppSemanticColors.taste(0, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: highlighted ? pair.background : null,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: highlighted
            ? AppTextStyles.caption.copyWith(color: pair.foreground)
            : (label ? AppTextStyles.fieldLabel : AppTextStyles.caption),
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
  return entry.waterTempIsDerived ? '~$formatted' : formatted;
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
