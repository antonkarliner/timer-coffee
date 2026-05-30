import 'package:flutter/material.dart';

/// Small secondary label used under settings section titles.
class SettingsSectionSubtitle extends StatelessWidget {
  const SettingsSectionSubtitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.2,
      ),
    );
  }
}
