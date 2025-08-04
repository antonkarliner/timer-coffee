import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class DatesCard extends StatefulWidget {
  final DateTime? harvestDate;
  final DateTime? roastDate;
  final ValueChanged<DateTime?> onHarvestDateChanged;
  final ValueChanged<DateTime?> onRoastDateChanged;

  const DatesCard({
    super.key,
    required this.harvestDate,
    required this.roastDate,
    required this.onHarvestDateChanged,
    required this.onRoastDateChanged,
  });

  @override
  State<DatesCard> createState() => _DatesCardState();
}

class _DatesCardState extends State<DatesCard> {
  DateTime? _harvestDate;
  DateTime? _roastDate;

  @override
  void initState() {
    super.initState();
    _harvestDate = widget.harvestDate;
    _roastDate = widget.roastDate;
  }

  @override
  void didUpdateWidget(covariant DatesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.harvestDate != widget.harvestDate) {
      _harvestDate = widget.harvestDate;
    }
    if (oldWidget.roastDate != widget.roastDate) {
      _roastDate = widget.roastDate;
    }
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initial,
    required ValueChanged<DateTime?> onChanged,
  }) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(),
      dialogSize: const Size(325, 400),
      value: [initial],
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.isNotEmpty) {
      onChanged(results[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = loc.localeName;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.importantDates,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Harvest
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.harvestDate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        identifier: 'harvestDatePickerButton',
                        label: loc.selectHarvestDate,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _pickDate(
                              context: context,
                              initial: _harvestDate,
                              onChanged: (d) {
                                setState(() {
                                  _harvestDate = d;
                                });
                                widget.onHarvestDateChanged(d);
                              },
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _harvestDate != null
                                ? DateFormat.yMd(localeName)
                                    .format(_harvestDate!)
                                : loc.selectDate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Roast
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.roastDate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        identifier: 'roastDatePickerButton',
                        label: loc.selectRoastDate,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _pickDate(
                              context: context,
                              initial: _roastDate,
                              onChanged: (d) {
                                setState(() {
                                  _roastDate = d;
                                });
                                widget.onRoastDateChanged(d);
                              },
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _roastDate != null
                                ? DateFormat.yMd(localeName).format(_roastDate!)
                                : loc.selectDate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
