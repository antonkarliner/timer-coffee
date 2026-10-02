import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'settings_list.dart';

/// Optional notification rows: morning reminder, its time value row, weekly
/// summary, bean freshness and (when [beanReviewNudgeEnabled] /
/// [onBeanReviewNudgeChanged] are supplied) bean review. Returns a list of
/// Settings rows for spreading into a parent.
///
/// The two bean-review parameters are optional so screens that predate the
/// fourth switch (the current Settings root) keep rendering the original
/// three; the dedicated notifications page passes both and gets all four.
class NotificationToggles extends StatelessWidget {
  const NotificationToggles({
    super.key,
    required this.morningReminderEnabled,
    required this.morningReminderTime,
    required this.use24HourFormat,
    required this.weeklySummaryEnabled,
    required this.beanFreshnessEnabled,
    required this.onMorningChanged,
    required this.onWeeklyChanged,
    required this.onBeanFreshnessChanged,
    required this.onPickMorningTime,
    this.beanReviewNudgeEnabled,
    this.onBeanReviewNudgeChanged,
  });

  final bool morningReminderEnabled;
  final TimeOfDay morningReminderTime;

  /// Resolved by the caller through `DateTimeFormatService.use24Hour`, per
  /// CLAUDE.md "Date/Time Formatting"; this widget has no provider lookup so
  /// it stays pumpable in tests.
  final bool use24HourFormat;

  final bool weeklySummaryEnabled;
  final bool beanFreshnessEnabled;

  /// Nullable — the fourth switch renders only when both this and
  /// [onBeanReviewNudgeChanged] are non-null.
  final bool? beanReviewNudgeEnabled;
  final ValueChanged<bool>? onBeanReviewNudgeChanged;

  final ValueChanged<bool> onMorningChanged;
  final ValueChanged<bool> onWeeklyChanged;
  final ValueChanged<bool> onBeanFreshnessChanged;
  final VoidCallback onPickMorningTime;

  /// Builds the list of rows. Use this to spread into a parent
  /// widget's children list.
  ///
  /// The morning-time row sits in an always-present slot (see
  /// `settings_list.dart` rule 7) so the widget type at that tree position
  /// stays stable when the morning reminder is switched off.
  List<Widget> buildToggles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showBeanReview = beanReviewNudgeEnabled != null &&
        onBeanReviewNudgeChanged != null;
    return [
      SettingsSwitchRow(
        identifier: 'settingsMorningReminderSwitch',
        title: l10n.settingsMorningReminder,
        subtitle: l10n.settingsMorningReminderSubtitle,
        value: morningReminderEnabled,
        onChanged: onMorningChanged,
      ),
      MorningTimeSlot(
        visible: morningReminderEnabled,
        label: l10n.settingsMorningReminderTime,
        formattedTime:
            DateFormat(
              use24HourFormat ? 'HH:mm' : 'hh:mm a',
              Localizations.localeOf(context).toString(),
            ).format(
              DateTime(
                2000,
                1,
                1,
                morningReminderTime.hour,
                morningReminderTime.minute,
              ),
            ),
        onTap: onPickMorningTime,
      ),
      SettingsSwitchRow(
        identifier: 'settingsWeeklySummarySwitch',
        title: l10n.settingsWeeklySummary,
        subtitle: l10n.settingsWeeklySummarySubtitle,
        value: weeklySummaryEnabled,
        onChanged: onWeeklyChanged,
      ),
      SettingsSwitchRow(
        identifier: 'settingsBeanFreshnessSwitch',
        title: l10n.settingsBeanFreshness,
        subtitle: l10n.settingsBeanFreshnessSubtitle,
        value: beanFreshnessEnabled,
        onChanged: onBeanFreshnessChanged,
      ),
      if (showBeanReview)
        SettingsSwitchRow(
          identifier: 'settingsBeanReviewNudgeSwitch',
          title: l10n.settingsBeanReviewNudge,
          subtitle: l10n.settingsBeanReviewNudgeSubtitle,
          value: beanReviewNudgeEnabled!,
          onChanged: onBeanReviewNudgeChanged,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buildToggles(context),
    );
  }
}

/// Always-present slot for the morning-reminder time row. Renders
/// [SizedBox.shrink] when the morning reminder is off so the widget type at
/// this tree position never changes (a type change would recreate the child
/// element and re-run `initState`).
@visibleForTesting
class MorningTimeSlot extends StatelessWidget {
  const MorningTimeSlot({
    super.key,
    required this.visible,
    required this.label,
    required this.formattedTime,
    required this.onTap,
  });

  final bool visible;
  final String label;
  final String formattedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return SettingsValueRow(
      identifier: 'settingsMorningReminderTimeRow',
      title: label,
      value: formattedTime,
      onTap: onTap,
    );
  }
}
