import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../../services/analytics_service.dart';
import '../app_switch_list_tile.dart';
import 'data_export_section.dart';
import 'settings_section_subtitle.dart';

/// Analytics/privacy settings section with three toggles (brews, beans, general)
/// plus the self-serve data export entry point.
///
/// Uses [Consumer<AnalyticsService>] internally — fully self-contained.
class AnalyticsPrivacySection extends StatelessWidget {
  const AnalyticsPrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<AnalyticsService>(
      builder: (context, analytics, _) {
        return Semantics(
          identifier: 'analyticsPrivacyExpansionTile',
          child: ExpansionTile(
            title: Text(loc.settingsAnalyticsTitle),
            subtitle: SettingsSectionSubtitle(loc.settingsAnalyticsSubtitle),
            children: [
              AppSwitchListTile(
                title: loc.settingsAnalyticsBrews,
                value: analytics.brewsEnabled,
                onChanged: (value) => analytics.setBrewsEnabled(value),
              ),
              AppSwitchListTile(
                title: loc.settingsAnalyticsBeans,
                value: analytics.beansEnabled,
                onChanged: (value) => analytics.setBeansEnabled(value),
              ),
              AppSwitchListTile(
                title: loc.settingsAnalyticsGeneral,
                value: analytics.generalEnabled,
                onChanged: (value) => analytics.setGeneralEnabled(value),
              ),
              const DataExportSection(),
            ],
          ),
        );
      },
    );
  }
}
