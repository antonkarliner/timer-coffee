import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../../services/collections_preferences_service.dart';
import '../app_switch_list_tile.dart';
import 'settings_section_subtitle.dart';

/// Home screen settings, currently focused on Collections visibility.
class CollectionsSection extends StatelessWidget {
  const CollectionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Consumer<CollectionsPreferencesService>(
      builder: (context, prefs, _) {
        return Semantics(
          identifier: 'homeScreenSettingsExpansionTile',
          child: ExpansionTile(
            title: Text(loc.settingsHomeScreenTitle),
            subtitle: SettingsSectionSubtitle(loc.settingsHomeScreenSubtitle),
            children: [
              AppSwitchListTile(
                title: loc.collectionsShowOnHomeTitle,
                subtitle: loc.collectionsShowOnHomeDescription,
                value: !prefs.dismissed,
                onChanged: (value) => prefs.setDismissed(!value),
              ),
            ],
          ),
        );
      },
    );
  }
}
