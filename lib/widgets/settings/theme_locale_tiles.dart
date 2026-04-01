import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Theme and language selector tiles for the settings screen.
class ThemeLocaleTiles extends StatelessWidget {
  const ThemeLocaleTiles({
    super.key,
    required this.localizedThemeMode,
    required this.languageNameFuture,
    required this.onThemeTap,
    required this.onLocaleTap,
  });

  final String localizedThemeMode;
  final Future<String> languageNameFuture;
  final VoidCallback onThemeTap;
  final VoidCallback onLocaleTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          identifier: 'settingsThemeTile',
          child: ListTile(
            title: Text(l10n.settingstheme),
            trailing: Text(localizedThemeMode),
            onTap: onThemeTap,
          ),
        ),
        Semantics(
          identifier: 'settingsLangTile',
          child: ListTile(
            title: Text(l10n.settingslang),
            trailing: FutureBuilder<String>(
              future: languageNameFuture,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            onTap: onLocaleTap,
          ),
        ),
      ],
    );
  }
}
