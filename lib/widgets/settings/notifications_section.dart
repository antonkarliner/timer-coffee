import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../app_switch_list_tile.dart';
import '../base_buttons.dart';
import '../../theme/design_tokens.dart';

/// Notifications settings expansion tile with master toggle and permission
/// warning. Child toggles are passed in via [notificationToggles].
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({
    super.key,
    required this.isLoading,
    required this.masterNotificationsEnabled,
    required this.systemPermissionDenied,
    required this.statusText,
    required this.onMasterToggled,
    required this.onOpenNotificationSettings,
    this.notificationToggles = const [],
    this.controller,
  });

  final bool isLoading;
  final bool masterNotificationsEnabled;
  final bool systemPermissionDenied;
  final String statusText;
  final ValueChanged<bool> onMasterToggled;
  final VoidCallback onOpenNotificationSettings;
  final List<Widget> notificationToggles;
  final ExpansibleController? controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      identifier: 'settingsNotificationsExpansionTile',
      child: ExpansionTile(
        controller: controller,
        title: Text(l10n.notifications),
        subtitle: isLoading
            ? const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            : Text(statusText),
        children: [
          AppSwitchListTile(
            title: l10n.settingsNotificationsToggle,
            value: masterNotificationsEnabled,
            onChanged: isLoading ? null : (v) => onMasterToggled(v),
          ),
          if (systemPermissionDenied && masterNotificationsEnabled)
            ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              title: Text(l10n.notificationsDisabledInSystemSettings),
              trailing: AppTextButton(
                label: l10n.openSettings,
                onPressed: onOpenNotificationSettings,
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ),
          if (masterNotificationsEnabled && !isLoading)
            ...notificationToggles,
        ],
      ),
    );
  }
}
