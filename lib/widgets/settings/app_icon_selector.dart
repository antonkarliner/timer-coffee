import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// App icon selector — shows Default and Legacy icon options.
class AppIconSelector extends StatelessWidget {
  const AppIconSelector({
    super.key,
    required this.isDefaultIcon,
    required this.localIconState,
    required this.onIconSelected,
  });

  final bool isDefaultIcon;
  final String? localIconState;
  final void Function(String iconName) onIconSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Image preview(String asset) =>
        Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain);

    final defaultAsset = Platform.isIOS && isDark
        ? 'assets/icons/timer-coffee-icon-new-dark.png'
        : 'assets/icons/timer-coffee-icon-new-light.png';

    final legacyAsset = Platform.isIOS && isDark
        ? 'assets/icons/ic_launcher_legacy_dark.png'
        : 'assets/icons/ic_launcher_legacy.png';

    return ExpansionTile(
      title: Text(l10n.settingsAppIcon),
      children: [
        ListTile(
          leading: preview(defaultAsset),
          title: Text(l10n.settingsAppIconDefault),
          trailing: isDefaultIcon ? const Icon(Icons.check) : null,
          onTap: () => onIconSelected('Default'),
        ),
        ListTile(
          leading: preview(legacyAsset),
          title: Text(l10n.settingsAppIconLegacy),
          trailing: localIconState == 'Legacy' ? const Icon(Icons.check) : null,
          onTap: () => onIconSelected('Legacy'),
        ),
      ],
    );
  }
}
