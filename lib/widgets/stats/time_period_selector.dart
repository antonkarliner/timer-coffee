import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/controllers/stats_controller.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';

class StatsTimePeriodSelector extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<StatsController>();
    final userStatProvider =
        Provider.of<UserStatProvider>(context, listen: false);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Theme.of(context).cardColor,
              elevation: 4,
            ),
          ),
          child: DropdownButton<TimePeriod>(
            isExpanded: true,
            underline: Container(),
            dropdownColor: Theme.of(context).cardColor,
            value: controller.selectedPeriod,
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (TimePeriod? newValue) async {
              if (newValue == null) return;
              if (newValue == TimePeriod.custom) {
                await _pickCustomRange(context, controller, userStatProvider);
              } else {
                controller.selectPeriod(userStatProvider, newValue);
                onChanged?.call();
              }
            },
            items: <TimePeriod>[
              TimePeriod.today,
              TimePeriod.thisWeek,
              TimePeriod.thisMonth,
              TimePeriod.custom
            ].map<DropdownMenuItem<TimePeriod>>((TimePeriod value) {
              return DropdownMenuItem<TimePeriod>(
                value: value,
                child: Text(controller.labelForPeriod(l10n, value)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
