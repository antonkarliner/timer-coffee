import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/snow_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/app_switch_list_tile.dart';
import '../../widgets/settings/settings_list.dart';

/// Appearance settings: theme, app icon (mobile, when the icon API is
/// available) and the seasonal snow effect.
@RoutePage()
class SettingsAppearanceScreen extends StatefulWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  State<SettingsAppearanceScreen> createState() =>
      _SettingsAppearanceScreenState();
}

class _SettingsAppearanceScreenState extends State<SettingsAppearanceScreen> {
  late final SettingsController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = SettingsController();
    _iconController.initIconApi();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _changeTheme(ThemeMode mode) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final previous = themeProvider.themeMode.name;
    themeProvider.setThemeMode(mode);
    SettingsAnalytics.settingChanged(
      key: SettingKey.theme,
      value: mode.name,
      previous: previous,
      source: SettingSource.settings,
    );
  }

  void _setSnowEffect(bool enabled) {
    final snowProvider =
        Provider.of<SnowEffectProvider>(context, listen: false);
    final previous = snowProvider.isSnowing;
    snowProvider.setSnowEffect(enabled);
    SettingsAnalytics.settingChanged(
      key: SettingKey.snowEffect,
      value: SettingsAnalytics.onOff(enabled),
      previous: SettingsAnalytics.onOff(previous),
      source: SettingSource.settings,
    );
  }

  Future<void> _handleIconSelected(String iconName) async {
    final l10n = AppLocalizations.of(context)!;
    final previous =
        _iconController.localIconState == 'Legacy' ? 'legacy' : 'default';
    final success = await _iconController.setIcon(iconName);
    if (!mounted) return;
    if (success) {
      SettingsAnalytics.settingChanged(
        key: SettingKey.appIcon,
        value: iconName.toLowerCase(),
        previous: previous,
        source: SettingSource.settings,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.iconChangeFailed(iconName))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final snowProvider = context.watch<SnowEffectProvider>();

    return SettingsPageScaffold(
      title: l10n.settingsAppearanceTitle,
      children: [
        SettingsChoiceRow<ThemeMode>(
          identifier: 'settingsThemeTile',
          title: l10n.settingstheme,
          sheetTitle: l10n.settingstheme,
          options: [
            SettingsChoiceOption(
              value: ThemeMode.light,
              label: l10n.settingsthemelight,
              identifier: 'themeLightListTile',
            ),
            SettingsChoiceOption(
              value: ThemeMode.dark,
              label: l10n.settingsthemedark,
              identifier: 'themeDarkListTile',
            ),
            SettingsChoiceOption(
              value: ThemeMode.system,
              label: l10n.settingsthemesystem,
              identifier: 'themeSystemListTile',
            ),
          ],
          current: themeProvider.themeMode,
          onChanged: _changeTheme,
        ),
        // App icon lives in an always-present slot so the widget type at this
        // tree position stays stable while the icon API loads.
        ListenableBuilder(
          listenable: _iconController,
          builder: (context, _) => _appIconSection(context, l10n),
        ),
        Semantics(
          identifier: 'settingsSnowSwitch',
          container: true,
          child: AppSwitchListTile(
            title: l10n.snow,
            value: snowProvider.isSnowing,
            onChanged: _setSnowEffect,
          ),
        ),
      ],
    );
  }

  Widget _appIconSection(BuildContext context, AppLocalizations l10n) {
    if (kIsWeb || !_iconController.iconApiAvailable) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.settingsAppIcon),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.base,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _appIconTile(
                context,
                iconName: 'Default',
                label: l10n.settingsAppIconDefault,
              ),
              _appIconTile(
                context,
                iconName: 'Legacy',
                label: l10n.settingsAppIconLegacy,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appIconTile(
    BuildContext context, {
    required String iconName,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = iconName == 'Default'
        ? _iconController.isDefaultIcon
        : _iconController.localIconState == 'Legacy';

    return Semantics(
      identifier:
          iconName == 'Default' ? 'appIconDefaultTile' : 'appIconLegacyTile',
      selected: isSelected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _handleIconSelected(iconName),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? AppStroke.focus : AppStroke.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _assetFor(iconName, theme.brightness == Brightness.dark),
                width: AppIconSize.large,
                height: AppIconSize.large,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTextStyles.caption),
              // Check slot is always present so both tiles keep their height.
              SizedBox(
                height: AppIconSize.small,
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: AppIconSize.small,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same asset and platform/dark-mode logic as `app_icon_selector.dart`.
  String _assetFor(String iconName, bool isDark) {
    if (iconName == 'Default') {
      return defaultTargetPlatform == TargetPlatform.android
          ? 'assets/icons/timer-coffee-icon-android.png'
          : isDark
              ? 'assets/icons/timer-coffee-icon-new-dark.png'
              : 'assets/icons/timer-coffee-icon-new-light.png';
    }
    return defaultTargetPlatform == TargetPlatform.iOS && isDark
        ? 'assets/icons/ic_launcher_legacy_dark.png'
        : 'assets/icons/ic_launcher_legacy.png';
  }
}
