import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/controllers/stats_controller.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

class StatsTimePeriodSelector extends StatelessWidget {
  // Match _ModeSwitch in extraction_calculator_screen.dart.
  static const double _height = 44;
  static const double _borderWidth = 1.5;

  static const _periods = [
    TimePeriod.today,
    TimePeriod.thisWeek,
    TimePeriod.thisMonth,
    TimePeriod.custom,
  ];

  final VoidCallback? onChanged;

  const StatsTimePeriodSelector({super.key, this.onChanged});

  Future<void> _pickCustomRange(
    BuildContext context,
    StatsController controller,
    UserStatProvider userStatProvider,
  ) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: [controller.customStartDate, controller.customEndDate],
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.length == 2) {
      final start = results[0] ?? DateTime.now();
      final end = results[1] ?? DateTime.now();
      controller.setCustomRange(userStatProvider, start, end);
      onChanged?.call();
    }
  }

  String? _rangeLabel(
    BuildContext context,
    AppLocalizations l10n,
    StatsController controller,
  ) {
    if (controller.selectedPeriod != TimePeriod.custom) return null;
    if (controller.calendarMonth != null) {
      return controller.labelForPeriod(l10n, TimePeriod.custom);
    }

    final start = controller.customStartDate;
    final end = controller.customEndDate;
    if (start == null || end == null) return null;
    final formatService = Provider.of<DateTimeFormatService>(context);
    final format = DateFormat(
      formatService.datePattern(l10n.dateFormat),
      l10n.localeName,
    );
    final formattedStart = format.format(start);
    return DateUtils.isSameDay(start, end)
        ? formattedStart
        : '$formattedStart – ${format.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<StatsController>();
    final userStatProvider = context.read<UserStatProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final rangeLabel = _rangeLabel(context, l10n, controller);

    void selectPeriod(TimePeriod value) {
      if (value == TimePeriod.custom) {
        unawaited(_pickCustomRange(context, controller, userStatProvider));
      } else if (value != controller.selectedPeriod) {
        controller.selectPeriod(userStatProvider, value);
        onChanged?.call();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'statsPeriodSelector',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - 2 * _borderWidth) / _periods.length;
              return AnimatedToggleSwitch<TimePeriod>.rolling(
                current: controller.selectedPeriod,
                values: _periods,
                onChanged: selectPeriod,
                onTap: (details) {
                  // The switch skips onChanged for the current segment.
                  if (details.tapped?.value == TimePeriod.custom &&
                      controller.selectedPeriod == TimePeriod.custom) {
                    selectPeriod(TimePeriod.custom);
                  }
                },
                height: _height,
                borderWidth: _borderWidth,
                indicatorSize: Size.fromWidth(itemWidth),
                style: ToggleStyle(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  borderColor: colorScheme.outline,
                  indicatorColor: colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  indicatorBorderRadius: BorderRadius.circular(AppRadius.small),
                ),
                iconBuilder: (value, foreground) {
                  final (id, label) = switch (value) {
                    TimePeriod.today => ('today', l10n.statsPeriodToday),
                    TimePeriod.thisWeek => ('week', l10n.statsPeriodWeek),
                    TimePeriod.thisMonth => ('month', l10n.statsPeriodMonth),
                    TimePeriod.custom => ('range', l10n.statsPeriodRange),
                  };
                  final text = Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                  // The rolling indicator paints a second copy of its label.
                  return foreground
                      ? ExcludeSemantics(child: text)
                      : Semantics(
                          identifier: 'statsPeriod_$id',
                          selected: value == controller.selectedPeriod,
                          button: true,
                          onTap: () => selectPeriod(value),
                          child: text,
                        );
                },
              );
            },
          ),
        ),
        if (rangeLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            rangeLabel,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
