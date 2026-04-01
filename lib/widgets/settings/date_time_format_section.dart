import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

class DateTimeFormatSection extends StatelessWidget {
  const DateTimeFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DateTimeFormatService>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final deviceIs24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final now = DateTime.now();

    final previewDate = DateFormat(svc.datePattern(l10n.dateFormat)).format(now);
    final is24h = svc.use24Hour(deviceIs24h);
    final previewTime = DateFormat(is24h ? 'HH:mm' : 'hh:mm a').format(now);

    return ExpansionTile(
      title: Text(l10n.settingsDateTimeFormat),
      children: [
        // --- Date format ---
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.base,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.settingsDateFormatLabel,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        RadioGroup<DateStyle>(
          groupValue: svc.dateStyle,
          onChanged: (v) {
            if (v != null) svc.setDateStyle(v);
          },
          child: Column(
            children: [
              RadioListTile<DateStyle>(
                dense: true,
                value: DateStyle.auto,
                title: Text(l10n.settingsDateFormatAuto),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<DateStyle>(
                dense: true,
                value: DateStyle.dmy,
                title: Text(l10n.settingsDateFormatDMY),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<DateStyle>(
                dense: true,
                value: DateStyle.mdy,
                title: Text(l10n.settingsDateFormatMDY),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<DateStyle>(
                dense: true,
                value: DateStyle.ymd,
                title: Text(l10n.settingsDateFormatYMD),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // --- Time format ---
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.base,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.settingsTimeFormatLabel,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        RadioGroup<TimeStyle>(
          groupValue: svc.timeStyle,
          onChanged: (v) {
            if (v != null) svc.setTimeStyle(v);
          },
          child: Column(
            children: [
              RadioListTile<TimeStyle>(
                dense: true,
                value: TimeStyle.auto,
                title: Text(l10n.settingsDateFormatAuto),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<TimeStyle>(
                dense: true,
                value: TimeStyle.h12,
                title: Text(l10n.settingsTimeFormat12h),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<TimeStyle>(
                dense: true,
                value: TimeStyle.h24,
                title: Text(l10n.settingsTimeFormat24h),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        // --- Live preview ---
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.preview_outlined,
                  size: AppIconSize.small,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$previewDate  $previewTime',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
