import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

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
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          onPressed: onSkip,
          child: Text(
            l10n.notificationPermissionSkip,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          onPressed: onEnable,
          child: Text(
            l10n.notificationPermissionEnable,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
