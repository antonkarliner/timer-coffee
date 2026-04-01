import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

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
    final platform = Theme.of(context).platform;
    final notificationMessage = kIsWeb
        ? l10n.notificationPermissionDialogMessage
        : switch (platform) {
            TargetPlatform.iOS =>
              l10n.notificationPermissionDialogMessageIos,
            TargetPlatform.android =>
              l10n.notificationPermissionDialogMessageAndroid,
            _ => l10n.notificationPermissionDialogMessage,
          };

    return AlertDialog(
      title: Text(l10n.notificationPermissionDialogTitle),
      content: Text(notificationMessage),
      actions: [
        AppTextButton(
          label: l10n.notificationPermissionSkip,
          onPressed: onSkip,
          isFullWidth: false,
          height: AppButton.heightMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        AppElevatedButton(
          label: l10n.notificationPermissionEnable,
          onPressed: onEnable,
          isFullWidth: false,
          height: AppButton.heightMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ],
    );
  }
}
