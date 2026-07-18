import 'dart:collection';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_progress_chart.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:flutter/material.dart';

export 'package:coffee_timer/widgets/brew_diary/journey_progress_chart.dart'
    show
        JourneyChartConnection,
        JourneyChartData,
        JourneyChartPoint,
        JourneyRatingLabelPlacement,
        JourneyProgressPainter;

typedef EvaluateLatestCallback = Future<void> Function(DiaryEntry entry);

/// A deterministically ordered, method-local series used by journey progress.
@immutable
class JourneyMethodSeries {
  JourneyMethodSeries({
    required this.methodId,
    required this.methodName,
    required List<DiaryEntry> entries,
  }) : entries = UnmodifiableListView(entries);

  final String methodId;
  final String methodName;
  final UnmodifiableListView<DiaryEntry> entries;

  DiaryEntry get latestEntry => entries.last;
  int get evaluatedCount =>
      entries.where((entry) => entry.rating != null).length;
}

/// Groups a bean's attempts by method without mutating the caller's list.
///
/// Entries inside each method are chronological. Methods are newest-first,
/// then ordered by their display name and stable method ID.
List<JourneyMethodSeries> buildJourneyMethodSeries(
  Iterable<DiaryEntry> source,
) {
  final byMethod = <String, List<DiaryEntry>>{};
  for (final entry in source) {
    byMethod.putIfAbsent(entry.brewingMethodId, () => []).add(entry);
  }

  final result =
      byMethod.entries.map((group) {
        final entries = group.value.toList()
          ..sort((a, b) {
            final byDate = a.createdAt.compareTo(b.createdAt);
            if (byDate != 0) return byDate;
            return a.statUuid.compareTo(b.statUuid);
          });
        final latest = entries.last;
        final name = latest.methodName.trim();
        return JourneyMethodSeries(
          methodId: group.key,
          methodName: name.isEmpty ? group.key : name,
          entries: entries,
        );
      }).toList()..sort((a, b) {
        final byLatest = b.latestEntry.createdAt.compareTo(
          a.latestEntry.createdAt,
        );
        if (byLatest != 0) return byLatest;
        final byFoldedName = a.methodName.toLowerCase().compareTo(
          b.methodName.toLowerCase(),
        );
        if (byFoldedName != 0) return byFoldedName;
        final byName = a.methodName.compareTo(b.methodName);
        if (byName != 0) return byName;
        return a.methodId.compareTo(b.methodId);
      });

  return UnmodifiableListView(result);
}

class JourneyProgress extends StatefulWidget {
  const JourneyProgress({
    super.key,
    required this.entries,
    required this.onEvaluateLatest,
  });

  final List<DiaryEntry> entries;
  final EvaluateLatestCallback onEvaluateLatest;

  @override
  State<JourneyProgress> createState() => _JourneyProgressState();
}

class _JourneyProgressState extends State<JourneyProgress> {
  final ScrollController _chartScrollController = ScrollController();
  late List<JourneyMethodSeries> _series;
  String? _selectedMethodId;
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _series = buildJourneyMethodSeries(widget.entries);
    _selectedMethodId = _series.firstOrNull?.methodId;
    _scrollChartToNewest();
  }

  @override
  void didUpdateWidget(covariant JourneyProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _series = buildJourneyMethodSeries(widget.entries);
    if (!_series.any((series) => series.methodId == _selectedMethodId)) {
      _selectedMethodId = _series.firstOrNull?.methodId;
    }
    _scrollChartToNewest();
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  JourneyMethodSeries? get _selectedSeries {
    if (_series.isEmpty) return null;
    return _series.firstWhere(
      (series) => series.methodId == _selectedMethodId,
      orElse: () => _series.first,
    );
  }

  void _scrollChartToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chartScrollController.hasClients) return;
      _chartScrollController.jumpTo(
        _chartScrollController.position.maxScrollExtent,
      );
    });
  }

  void _selectMethod(String methodId) {
    if (methodId == _selectedMethodId) return;
    setState(() => _selectedMethodId = methodId);
    _scrollChartToNewest();
  }

  Future<void> _evaluateLatest() async {
    final latest = _selectedSeries?.latestEntry;
    if (latest == null || _isEvaluating) return;
    setState(() => _isEvaluating = true);
    try {
      await widget.onEvaluateLatest(latest);
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final evaluatedCount = widget.entries
        .where((entry) => entry.rating != null)
        .length;
    final selected = _selectedSeries;

    return SectionCard(
      title: loc.journeyProgress,
      subtitle: loc.journeyEvaluatedCount(
        evaluatedCount,
        widget.entries.length,
      ),
      icon: Icons.insights_outlined,
      initiallyExpanded: true,
      semanticIdentifier: 'journeyProgressSection',
      mergeHeaderSemantics: true,
      child: selected == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MethodSelector(
                  series: _series,
                  selectedMethodId: selected.methodId,
                  onSelected: _selectMethod,
                ),
                const SizedBox(height: AppSpacing.base),
                JourneyProgressChart(
                  key: ValueKey('journeyProgressChart_${selected.methodId}'),
                  methodName: selected.methodName,
                  entries: selected.entries.toList(growable: false),
                  scrollController: _chartScrollController,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppTextButton(
                    key: const ValueKey('journeyEvaluateLatest'),
                    label: selected.latestEntry.rating == null
                        ? loc.journeyEvaluateLatest
                        : loc.journeyEditLatestRating,
                    icon: selected.latestEntry.rating == null
                        ? Icons.star_outline
                        : Icons.edit_outlined,
                    isLoading: _isEvaluating,
                    isFullWidth: false,
                    onPressed: _evaluateLatest,
                  ),
                ),
              ],
            ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({
    required this.series,
    required this.selectedMethodId,
    required this.onSelected,
  });

  final List<JourneyMethodSeries> series;
  final String selectedMethodId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selected = series.firstWhere(
      (method) => method.methodId == selectedMethodId,
    );
    final hasMenu = series.length > 1;
    final row = _MethodSelectorRow(series: selected, showAffordance: hasMenu);
    final decoration = BoxDecoration(
      border: Border.all(
        color: theme.colorScheme.outlineVariant,
        width: AppStroke.border,
      ),
      borderRadius: BorderRadius.circular(AppRadius.field),
      color: theme.colorScheme.surfaceContainerLow,
    );

    Widget selector;
    if (hasMenu) {
      selector = PopupMenuButton<String>(
        key: const ValueKey('journeyMethodSelector'),
        tooltip: loc.journeyMethodSelectorLabel,
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final method in series)
            PopupMenuItem<String>(
              key: ValueKey('journeyMethodOption_${method.methodId}'),
              value: method.methodId,
              height: AppButton.heightLarge + AppSpacing.sm,
              child: _MethodSelectorRow(
                series: method,
                showAffordance: false,
                isSelected: method.methodId == selectedMethodId,
              ),
            ),
        ],
        child: row,
      );
    } else {
      selector = KeyedSubtree(
        key: const ValueKey('journeyMethodSelectorSingle'),
        child: row,
      );
    }

    return Semantics(
      label: loc.journeyMethodSelectorLabel,
      button: hasMenu,
      child: DecoratedBox(
        decoration: decoration,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppButton.heightMedium),
          child: selector,
        ),
      ),
    );
  }
}

class _MethodSelectorRow extends StatelessWidget {
  const _MethodSelectorRow({
    required this.series,
    required this.showAffordance,
    this.isSelected = false,
  });

  final JourneyMethodSeries series;
  final bool showAffordance;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconTheme.merge(
            data: IconThemeData(
              color: colorScheme.primary,
              size: AppIconSize.medium,
            ),
            child: getIconByBrewingMethod(series.methodId),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.methodName,
                  key: ValueKey('journeyMethodName_${series.methodId}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.fieldLabel,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${loc.diaryGroupBrewCount(series.entries.length)} · '
                  '${loc.journeyEvaluatedBrewCount(series.evaluatedCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (showAffordance) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.expand_more,
              size: AppIconSize.medium,
              color: colorScheme.onSurfaceVariant,
            ),
          ] else if (isSelected) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.check,
              size: AppIconSize.medium,
              color: colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
