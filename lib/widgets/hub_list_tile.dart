import 'package:flutter/material.dart';

/// The More tab's row, also used by the For you taste-profile entry to match.
class HubListTile extends StatelessWidget {
  const HubListTile({
    super.key,
    required this.identifier,
    required this.label,
    required this.title,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.subtitle,
    this.isCompact = false,
  });

  final String identifier;
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: identifier,
      label: label,
      child: ListTile(
        dense: isCompact,
        visualDensity: isCompact ? VisualDensity.compact : null,
        leading: iconWidget ?? Icon(icon),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
