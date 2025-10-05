import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../containers/section_card.dart';
import '../fields/date_field.dart';
import '../../theme/design_tokens.dart';

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
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SectionCard(
      title: loc.importantDates,
      icon: Icons.calendar_today,
      isCollapsible: false,
      semanticIdentifier: 'datesCard',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use side-by-side layout on wider screens
          final isSideBySide = constraints.maxWidth > 600;

          if (isSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildHarvestDateField(context, loc),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: _buildRoastDateField(context, loc),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHarvestDateField(context, loc),
                const SizedBox(height: AppSpacing.fieldGap),
                _buildRoastDateField(context, loc),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHarvestDateField(BuildContext context, AppLocalizations loc) {
    return DateField(
      label: loc.harvestDate,
      initialValue: widget.harvestDate?.toIso8601String(),
      onChanged: (value) {
        final date = value != null ? DateTime.parse(value) : null;
        widget.onHarvestDateChanged(date);
      },
      semanticIdentifier: 'harvestDatePickerButton',
      hintText: loc.selectHarvestDate,
    );
  }

  Widget _buildRoastDateField(BuildContext context, AppLocalizations loc) {
    return DateField(
      label: loc.roastDate,
      initialValue: widget.roastDate?.toIso8601String(),
      onChanged: (value) {
        final date = value != null ? DateTime.parse(value) : null;
        widget.onRoastDateChanged(date);
      },
      semanticIdentifier: 'roastDatePickerButton',
      hintText: loc.selectRoastDate,
    );
  }
}
