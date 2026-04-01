import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

import '../app_switch_list_tile.dart';

/// Optional notification toggles: morning reminder, weekly summary, bean
/// freshness. Returns a list of widgets for spreading into a parent.
class NotificationToggles extends StatelessWidget {
  const NotificationToggles({
    super.key,
    required this.morningReminderEnabled,
    required this.morningReminderTime,
    required this.weeklySummaryEnabled,
    required this.beanFreshnessEnabled,
    required this.onMorningChanged,
    required this.onWeeklyChanged,
    required this.onBeanFreshnessChanged,
    required this.onPickMorningTime,
  });

  final bool morningReminderEnabled;
  final TimeOfDay morningReminderTime;
  final bool weeklySummaryEnabled;
  final bool beanFreshnessEnabled;
  final ValueChanged<bool> onMorningChanged;
  final ValueChanged<bool> onWeeklyChanged;
  final ValueChanged<bool> onBeanFreshnessChanged;
  final VoidCallback onPickMorningTime;

  /// Builds the list of toggle widgets. Use this to spread into a parent
  /// widget's children list.
  List<Widget> buildToggles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      AppSwitchListTile(
        title: l10n.settingsMorningReminder,
        subtitle: l10n.settingsMorningReminderSubtitle,
        value: morningReminderEnabled,
        onChanged: onMorningChanged,
      ),
      if (morningReminderEnabled)
        ListTile(
          contentPadding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.base,
          ),
          title: Text(l10n.settingsMorningReminderTime),
          trailing: Text(
            morningReminderTime.format(context),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: onPickMorningTime,
        ),
      AppSwitchListTile(
        title: l10n.settingsWeeklySummary,
        subtitle: l10n.settingsWeeklySummarySubtitle,
        value: weeklySummaryEnabled,
        onChanged: onWeeklyChanged,
      ),
      AppSwitchListTile(
        title: l10n.settingsBeanFreshness,
        subtitle: l10n.settingsBeanFreshnessSubtitle,
        value: beanFreshnessEnabled,
        onChanged: onBeanFreshnessChanged,
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
