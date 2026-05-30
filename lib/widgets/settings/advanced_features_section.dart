import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../../services/advanced_features_service.dart';
import '../../services/analytics_service.dart';
import '../app_switch_list_tile.dart';
import 'settings_section_subtitle.dart';

/// Advanced / beta feature toggles. Currently exposes manual step control on
/// the brewing screen. Add future beta toggles as additional children.
class AdvancedFeaturesSection extends StatefulWidget {
  const AdvancedFeaturesSection({super.key});

  @override
  State<AdvancedFeaturesSection> createState() =>
      _AdvancedFeaturesSectionState();
}

class _AdvancedFeaturesSectionState extends State<AdvancedFeaturesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<AdvancedFeaturesService>(
      builder: (context, advanced, _) {
        return Semantics(
          identifier: 'advancedFeaturesExpansionTile',
          child: ExpansionTile(
            title: Text(loc.advancedFeatures),
            subtitle: SettingsSectionSubtitle(loc.advancedFeaturesSubtitle),
            onExpansionChanged: (expanded) {
              setState(() => _expanded = expanded);
            },
            children: [
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      loc.advancedFeaturesDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              AppSwitchListTile(
                title: loc.manualStepControl,
                subtitle: loc.manualStepControlDescription,
                value: advanced.manualStepControlEnabled,
                onChanged: (value) {
                  advanced.setManualStepControlEnabled(value);
                  AnalyticsService.instance.track(
                    'beta_feature_toggled',
                    properties: {
                      'feature': 'manual_step_control',
                      'enabled': value,
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
