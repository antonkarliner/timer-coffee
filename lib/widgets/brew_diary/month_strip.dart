import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime diaryMonth(DateTime date) => DateTime(date.year, date.month);

int _civilDateOrdinal(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

class DiaryMonthBounds {
  const DiaryMonthBounds({
    required this.earliestMonth,
    required this.currentMonth,
  });

  final DateTime earliestMonth;
  final DateTime currentMonth;

  factory DiaryMonthBounds.fromEntries(
    List<DiaryEntry> entries, {
    DateTime? now,
  }) {
    final currentMonth = diaryMonth((now ?? DateTime.now()).toLocal());
    if (entries.isEmpty) {
      return DiaryMonthBounds(
        earliestMonth: currentMonth,
        currentMonth: currentMonth,
      );
    }

    var earliest = entries.first.createdAt.toLocal();
    for (final entry in entries.skip(1)) {
      final createdAt = entry.createdAt.toLocal();
      if (createdAt.isBefore(earliest)) earliest = createdAt;
    }
    return DiaryMonthBounds(
      earliestMonth: diaryMonth(earliest),
      currentMonth: currentMonth,
    );
  }

  DateTime clamp(DateTime month) {
    final normalized = diaryMonth(month);
    if (normalized.isBefore(earliestMonth)) return earliestMonth;
    if (normalized.isAfter(currentMonth)) return currentMonth;
    return normalized;
  }
}

class DiaryMonthSummary {
  const DiaryMonthSummary({
    required this.month,
    required this.dayCounts,
    required this.brewCount,
    required this.averageRating,
    required this.longestStreak,
    required this.activeDays,
  });

  final DateTime month;
  final Map<DateTime, int> dayCounts;
  final int brewCount;
  final double? averageRating;
  final int longestStreak;
  final int activeDays;

  /// Builds the almanac entirely from the diary's already-loaded full history.
  ///
  /// This deliberately mirrors the diary grouping's in-memory approach: the screen
  /// already has every non-deleted brew, so another DAO round-trip would only
  /// duplicate work. If the timeline becomes paginated, this summary must move
  /// to a DAO aggregate so months are not computed from an incomplete window.
  factory DiaryMonthSummary.fromEntries(
    List<DiaryEntry> entries,
    DateTime displayedMonth,
  ) {
    final month = diaryMonth(displayedMonth);
    final dayCounts = <DateTime, int>{};
    final ratings = <double>[];
    var brewCount = 0;

    for (final entry in entries) {
      final createdAt = entry.createdAt.toLocal();
      if (createdAt.year != month.year || createdAt.month != month.month) {
        continue;
      }
      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      dayCounts.update(day, (count) => count + 1, ifAbsent: () => 1);
      brewCount++;
      if (entry.rating != null) ratings.add(entry.rating!);
    }

    final activeDates = dayCounts.keys.toList()..sort();
    var longestStreak = 0;
    var currentStreak = 0;
    int? previousDayOrdinal;
    for (final day in activeDates) {
      // A streak is a run of consecutive local calendar days within the
      // displayed month where every day has at least one brew.
      final dayOrdinal = _civilDateOrdinal(day);
      if (previousDayOrdinal != null && dayOrdinal == previousDayOrdinal + 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > longestStreak) longestStreak = currentStreak;
      previousDayOrdinal = dayOrdinal;
    }

    return DiaryMonthSummary(
      month: month,
      dayCounts: Map.unmodifiable(dayCounts),
      brewCount: brewCount,
      averageRating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      longestStreak: longestStreak,
      activeDays: dayCounts.length,
    );
  }
}

class MonthStrip extends StatelessWidget {
  const MonthStrip({
    super.key,
    required this.entries,
    required this.displayedMonth,
    required this.expanded,
    required this.onDisplayedMonthChanged,
    required this.onExpandedChanged,
    required this.onDayTap,
  });

  final List<DiaryEntry> entries;
  final DateTime displayedMonth;
  final bool expanded;
  final ValueChanged<DateTime> onDisplayedMonthChanged;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<DateTime> onDayTap;

  void _changeMonth(int offset) {
    final bounds = DiaryMonthBounds.fromEntries(entries);
    AnalyticsService.maybeInstance?.track(
      'diary_month_strip_used',
      properties: {'action': 'month_change'},
    );
    onDisplayedMonthChanged(
      bounds.clamp(
        DateTime(displayedMonth.year, displayedMonth.month + offset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final bounds = DiaryMonthBounds.fromEntries(entries);
    final controlledMonth = bounds.clamp(displayedMonth);
    final summary = DiaryMonthSummary.fromEntries(entries, controlledMonth);
    final monthName = DateFormat.yMMMM(locale).format(controlledMonth);
    final averageRating = summary.averageRating == null
        ? null
        : NumberFormat('0.0', locale).format(summary.averageRating);
    final summarySegments = [
      loc.diaryMonthBrews(summary.brewCount),
      if (averageRating != null) '★$averageRating',
      loc.diaryMonthStreakDays(summary.longestStreak),
    ];

    return Semantics(
      identifier: 'diaryMonthStrip',
      container: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppStroke.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label:
                  '$monthName, ${summarySegments.join(', ')}. '
                  '${expanded ? loc.diaryMonthStripCollapse : loc.diaryMonthStripExpand}',
              child: InkWell(
                onTap: () {
                  final newExpanded = !expanded;
                  if (newExpanded) {
                    AnalyticsService.maybeInstance?.track(
                      'diary_month_strip_used',
                      properties: {'action': 'expand'},
                    );
                  }
                  onExpandedChanged(newExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(monthName, style: AppTextStyles.fieldLabel),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                summarySegments.join(' · '),
                                style: AppTextStyles.caption.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ExcludeSemantics(
                        child: Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          size: AppIconSize.medium,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded) ...[
              Divider(
                height: AppStroke.border,
                thickness: AppStroke.border,
                color: theme.colorScheme.outlineVariant,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: loc.diaryPreviousMonth,
                          onPressed:
                              controlledMonth.isAfter(bounds.earliestMonth)
                              ? () => _changeMonth(-1)
                              : null,
                          icon: const Icon(
                            Icons.chevron_left,
                            size: AppIconSize.medium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            monthName,
                            style: AppTextStyles.sectionHeader,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          tooltip: loc.diaryNextMonth,
                          onPressed:
                              controlledMonth.isBefore(bounds.currentMonth)
                              ? () => _changeMonth(1)
                              : null,
                          icon: const Icon(
                            Icons.chevron_right,
                            size: AppIconSize.medium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MonthHeatmap(
                      summary: summary,
                      locale: locale,
                      onDayTap: onDayTap,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Column(
                      key: const Key('monthStatsGrid'),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MonthStat(
                                key: const Key('monthStatBrews'),
                                label: loc.diaryMonthBrews(summary.brewCount),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _MonthStat(
                                key: const Key('monthStatRating'),
                                label: '★${averageRating ?? '—'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: _MonthStat(
                                key: const Key('monthStatStreak'),
                                label: loc.diaryMonthStreakDays(
                                  summary.longestStreak,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _MonthStat(
                                key: const Key('monthStatActiveDays'),
                                label: loc.diaryMonthActiveDays(
                                  summary.activeDays,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppTextButton(
                        label: '${loc.diaryFullStats} →',
                        isFullWidth: false,
                        height: AppButton.heightSmall,
                        padding: AppButton.paddingSmall,
                        onPressed: () {
                          AnalyticsService.maybeInstance?.track(
                            'diary_month_strip_used',
                            properties: {'action': 'full_stats'},
                          );
                          context.router.push(
                            StatsRoute(
                              initialYear: controlledMonth.year,
                              initialMonth: controlledMonth.month,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthHeatmap extends StatelessWidget {
  const _MonthHeatmap({
    required this.summary,
    required this.locale,
    required this.onDayTap,
  });

  final DiaryMonthSummary summary;
  final String locale;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final firstDay = summary.month;
    final leadingEmptyDays = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final cellCount = ((leadingEmptyDays + daysInMonth + 6) ~/ 7) * 7;
    final weekdayFormat = DateFormat.E(locale);
    final weekdayLabels = List.generate(
      DateTime.daysPerWeek,
      (index) => weekdayFormat.format(DateTime(2024, 1, 1 + index)),
    );

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.badge.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DateTime.daysPerWeek,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingEmptyDays + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(firstDay.year, firstDay.month, dayNumber);
            final count = summary.dayCounts[day] ?? 0;
            final isInteractive = count > 0;
            final opacity = switch (count) {
              0 => 0.0,
              1 => 0.22,
              2 => 0.36,
              3 => 0.5,
              _ => 0.68,
            };
            final background = count == 0
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  )
                : theme.colorScheme.primary.withValues(alpha: opacity);
            final foreground = count >= 3
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface;

            return Semantics(
              button: isInteractive,
              label: '$dayNumber, ${loc.diaryMonthBrews(count)}',
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.small),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: isInteractive
                      ? () {
                          AnalyticsService.maybeInstance?.track(
                            'diary_month_strip_used',
                            properties: {'action': 'day_tap'},
                          );
                          onDayTap(day);
                        }
                      : null,
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        '$dayNumber',
                        style: AppTextStyles.badge.copyWith(color: foreground),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: AppSpacing.xxl + AppSpacing.base,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
