import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Custom dialog for requesting notification permissions on first finish screen
///
/// This dialog provides a user-friendly way to request notification permissions
/// instead of showing the system dialog immediately.
class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const NotificationPermissionDialog({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.notificationPermissionDialogTitle),
      content: Text(l10n.notificationPermissionDialogMessage),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: Text(l10n.notificationPermissionSkip),
        ),
        ElevatedButton(
          onPressed: onEnable,
          child: Text(l10n.notificationPermissionEnable),
        ),
      ],
    );
  }
}
