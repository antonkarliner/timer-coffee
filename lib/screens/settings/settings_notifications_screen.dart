import 'package:app_settings/app_settings.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../database/database.dart';
import '../../l10n/app_localizations.dart';
import '../../services/date_time_format_service.dart';
import '../../services/notification_settings_service.dart';
import '../../services/onboarding_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_switch_list_tile.dart';
import '../../widgets/base_buttons.dart';
import '../../widgets/fields/time_field.dart';
import '../../widgets/settings/debug_notification_panel.dart';
import '../../widgets/settings/notification_toggles.dart';
import '../../widgets/settings/settings_list.dart';

/// Notifications settings page (Settings → Notifications).
///
/// Replicates the notification behaviour of the legacy Settings screen
/// (master toggle, permission warning, optional reminders, debug panel) on
/// the shared Settings scaffold.
///
/// On web the page renders just the scaffold: there are no notification
/// controls there (the root hides this row on web in a later phase).
@RoutePage()
class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.initNotificationSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      return SettingsPageScaffold(title: l10n.notifications, children: const []);
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        return SettingsPageScaffold(
          title: l10n.notifications,
          children: [
            _permissionBannerSlot(l10n),
            _masterSwitch(l10n),
            _remindersSlot(context, l10n),
            _debugPanelSlot(),
          ],
        );
      },
    );
  }

  /// Always-present slot for the permission warning row.
  Widget _permissionBannerSlot(AppLocalizations l10n) {
    final visible = _controller.systemPermissionDenied &&
        _controller.masterNotificationsEnabled;
    return Semantics(
      identifier: 'notificationsPermissionBanner',
      child: visible
          ? ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                size: AppIconSize.medium,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.notificationsDisabledInSystemSettings),
              trailing: AppTextButton(
                label: l10n.openSettings,
                onPressed: _openNotificationSettings,
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _masterSwitch(AppLocalizations l10n) {
    return Semantics(
      identifier: 'settingsNotificationsMasterSwitch',
      container: true,
      child: AppSwitchListTile(
        title: l10n.settingsNotificationsToggle,
        value: _controller.masterNotificationsEnabled,
        onChanged: _controller.isLoading
            ? null
            : (value) => _handleToggleNotifications(value),
      ),
    );
  }

  /// Always-present slot for the optional reminders. The header and toggle
  /// content only render while notifications are on and not loading; the
  /// slot itself never changes type (settings_list.dart rule 5).
  Widget _remindersSlot(BuildContext context, AppLocalizations l10n) {
    final visible =
        _controller.masterNotificationsEnabled && !_controller.isLoading;
    // The header goes with the rows: with notifications off it would label
    // an empty section.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visible
          ? [
              SettingsSectionHeader(
                title: l10n.settingsNotificationsRemindersHeader,
              ),
              ..._buildToggles(context),
            ]
          : const [SizedBox.shrink()],
    );
  }

  Widget _debugPanelSlot() {
    if (SettingsController.showNotifDebugPanel && !kIsWeb) {
      return const DebugNotificationPanel();
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildToggles(BuildContext context) {
    // Same singleton the NotificationService.settings getter returns; going
    // through it directly keeps the page constructible in widget tests,
    // where NotificationService.initialize() cannot run.
    final notificationSettings = NotificationSettingsService.instance;
    final fmtSvc = Provider.of<DateTimeFormatService>(context);
    final is24h = fmtSvc.use24Hour(
      MediaQuery.of(context).alwaysUse24HourFormat,
    );

    return NotificationToggles(
      morningReminderEnabled: _controller.morningReminderEnabled,
      morningReminderTime: _controller.morningReminderTime,
      use24HourFormat: is24h,
      weeklySummaryEnabled: _controller.weeklySummaryEnabled,
      beanFreshnessEnabled: _controller.beanFreshnessEnabled,
      beanReviewNudgeEnabled: _controller.beanReviewNudgeEnabled,
      onMorningChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationSettings.setMorningReminderEnabled,
      ),
      onWeeklyChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationSettings.setWeeklySummaryEnabled,
      ),
      onBeanFreshnessChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationSettings.setBeanFreshnessEnabled,
      ),
      onBeanReviewNudgeChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationSettings.setBeanReviewNudgeEnabled,
      ),
      onPickMorningTime: _pickMorningReminderTime,
    ).buildToggles(context);
  }

  // ---------------------------------------------------------------------------
  // Handlers (dialog/snackbar logic stays in the screen, like settings_screen)
  // ---------------------------------------------------------------------------

  Future<void> _handleToggleNotifications(bool enabled) async {
    final result = await _controller.toggleNotifications(enabled);
    if (result == ToggleNotificationResult.permissionDenied && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _onOptionalToggleChanged(
    bool value,
    Future<void> Function(bool) setter,
  ) async {
    // Capture everything context-bound before the await.
    final database = Provider.of<AppDatabase>(context, listen: false);
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    await _controller.onOptionalToggleChanged(
      value,
      setter,
      database: database,
      onboarding: onboarding,
      locale: locale,
    );
  }

  Future<void> _pickMorningReminderTime() async {
    // Capture everything context-bound before the await.
    final database = Provider.of<AppDatabase>(context, listen: false);
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _controller.morningReminderTime,
    );
    if (picked == null) return;
    await _controller.updateMorningReminderTime(
      picked,
      database: database,
      onboarding: onboarding,
      locale: locale,
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Text(l10n.notificationsDisabledDialogTitle),
          content: Text(l10n.notificationsDisabledDialogContent),
          actions: [
            AppTextButton(
              label: l10n.cancel,
              onPressed: () => Navigator.of(dialogContext).pop(),
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: AppButton.paddingMedium,
            ),
            AppElevatedButton(
              label: l10n.openSettings,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _openNotificationSettings();
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: AppButton.paddingMedium,
              backgroundColor: Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      AppLogger.error('Error opening notification settings', errorObject: e);
      try {
        await AppSettings.openAppSettings();
      } catch (fallbackError) {
        AppLogger.error(
          'Error opening general app settings',
          errorObject: fallbackError,
        );
      }
    }
  }
}
