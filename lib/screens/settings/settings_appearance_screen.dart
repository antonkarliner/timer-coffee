import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/snow_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/base_buttons.dart';
import '../../widgets/brewing/layout_preview_cards.dart';
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
  static const Duration _analyticsFlushTimeout = Duration(seconds: 2);

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
    final messenger = ScaffoldMessenger.of(context);
    final previous = _iconController.localIconState == 'Legacy'
        ? 'legacy'
        : 'default';
    final value = iconName.toLowerCase();
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      // The Android switch restarts the app process, so confirm before
      // anything else; cancel or dismissal must be a full no-op.
      final confirmed = await showAppIconSwitchConfirmation(
        context: context,
        l10n: l10n,
      );
      if (!mounted || !confirmed) return;
      // A failed Android switch may still be reported so buffered events survive.
      SettingsAnalytics.settingChanged(
        key: SettingKey.appIcon,
        value: value,
        previous: previous,
        source: SettingSource.settings,
      );
      try {
        await AnalyticsService.maybeInstance?.flushNow().timeout(
          _analyticsFlushTimeout,
        );
      } catch (_) {}
    }

    final success = await _iconController.setIcon(iconName);
    if (!mounted) return;
    if (success) {
      if (!isAndroid) {
        SettingsAnalytics.settingChanged(
          key: SettingKey.appIcon,
          value: value,
          previous: previous,
          source: SettingSource.settings,
        );
      }
    } else {
      messenger.showSnackBar(
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
        // No header: a single-row section would only repeat the row's title.
        SettingsSection(
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
                  subtitle: l10n.settingsAutoMatchesDevice,
                  identifier: 'themeSystemListTile',
                ),
              ],
              current: themeProvider.themeMode,
              onChanged: _changeTheme,
            ),
          ],
        ),
        // App icon lives in an always-present slot so the widget type at this
        // tree position stays stable while the icon API loads.
        ListenableBuilder(
          listenable: _iconController,
          builder: (context, _) => _appIconSection(context, l10n),
        ),
        SettingsSection(
          children: [
            SettingsSwitchRow(
              identifier: 'settingsSnowSwitch',
              title: l10n.snow,
              value: snowProvider.isSnowing,
              onChanged: _setSnowEffect,
            ),
          ],
        ),
      ],
    );
  }

  Widget _appIconSection(BuildContext context, AppLocalizations l10n) {
    if (kIsWeb || !_iconController.iconApiAvailable) {
      return const SizedBox.shrink();
    }

    return SettingsSection(
      header: l10n.settingsAppIcon,
      children: [
        AppIconPreviewGrid(
          options: appIconPreviewOptions(l10n),
          selectedId: _selectedIconId,
          isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
          isDark: Theme.of(context).brightness == Brightness.dark,
          onSelected: _handleIconSelected,
        ),
      ],
    );
  }

  /// The icon the grid highlights, or the empty string when the stored state
  /// names neither icon (then no cell is selected, as before).
  String get _selectedIconId {
    if (_iconController.isDefaultIcon) return 'Default';
    return _iconController.localIconState == 'Legacy' ? 'Legacy' : '';
  }
}

/// Android-only confirmation before switching the app icon, which closes the
/// app. Returns whether the user confirmed; cancel and dismissal return
/// false. Exposed so the tests can drive it — they cannot reach an Android
/// device.
@visibleForTesting
Future<bool> showAppIconSwitchConfirmation({
  required BuildContext context,
  required AppLocalizations l10n,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(l10n.settingsAppIconRestartTitle),
      content: Text(l10n.settingsAppIconRestartBody),
      actions: [
        AppTextButton(
          label: l10n.cancel,
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppElevatedButton(
          label: l10n.settingsAppIconRestartConfirm,
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// One option of the Appearance page's app-icon grid. Plan 057 extends it
/// with groups and a lock state when supporter icons ship.
class AppIconOption {
  const AppIconOption({
    required this.id,
    required this.label,
    required this.previewAsset,
    required this.identifier,
  });

  /// The name [SettingsController.setIcon] takes: `'Default'` or `'Legacy'`.
  final String id;

  /// The localized name shown under the preview.
  final String label;

  /// Resolves the full-bleed preview art for the current theme and platform.
  final String Function({required bool isDark, required bool isAndroid})
      previewAsset;

  /// Semantics identifier of the grid cell.
  final String identifier;
}

/// The Appearance page's app-icon options (default and legacy) with their
/// preview-asset rules.
List<AppIconOption> appIconPreviewOptions(AppLocalizations l10n) => [
      AppIconOption(
        id: 'Default',
        label: l10n.settingsAppIconDefault,
        // Android shows its adaptive icon; anything else picks the dark or
        // light rendering to match the current theme.
        previewAsset: ({required bool isDark, required bool isAndroid}) =>
            isAndroid
                ? 'assets/icons/previews/default_android.png'
                : isDark
                    ? 'assets/icons/previews/default_dark.png'
                    : 'assets/icons/previews/default_light.png',
        identifier: 'appIconDefaultTile',
      ),
      AppIconOption(
        id: 'Legacy',
        label: l10n.settingsAppIconLegacy,
        // The dark rendering exists for iOS only; Android always shows the
        // light one.
        previewAsset: ({required bool isDark, required bool isAndroid}) =>
            !isAndroid && isDark
                ? 'assets/icons/previews/legacy_dark.png'
                : 'assets/icons/previews/legacy_light.png',
        identifier: 'appIconLegacyTile',
      ),
    ];

/// The corner radius of an iOS home-screen icon as a fraction of its size —
/// Apple's squircle proportion. Derived from each shape's own size so the
/// selection ring keeps the icon's silhouette.
const double _iosIconCornerRatio = 0.2237;

/// The Appearance page's app-icon grid: equal quarter-width cells laid out
/// like a phone's home screen, four start-aligned columns with an
/// [AppSpacing.sm] gutter, each a masked icon preview with its name under it.
/// The selected cell carries a 2 pt primary ring outside the icon and a
/// [SelectionCheckBadge] at the icon's top end; unselected cells have no box
/// at all, only the hairline edge that keeps the white Default icon visible
/// on the white page.
///
/// Public (but test-only) so the tests can pump it directly — the icon API
/// is unavailable there.
@visibleForTesting
class AppIconPreviewGrid extends StatelessWidget {
  const AppIconPreviewGrid({
    super.key,
    required this.options,
    required this.selectedId,
    required this.isAndroid,
    required this.isDark,
    required this.onSelected,
  });

  final List<AppIconOption> options;

  /// The id of the selected icon, or the empty string for none.
  final String selectedId;

  /// True on Android: the preview uses the adaptive round mask, everything
  /// else the iOS squircle.
  final bool isAndroid;
  final bool isDark;
  final ValueChanged<String> onSelected;

  static const int _columns = 4;
  static const double _gutter = AppSpacing.sm;

  /// Icon plus the ring's gap and stroke: the reserved box around the icon,
  /// identical whether or not the cell is selected.
  static const double _iconAreaSize =
      AppIconSize.appIconPreview + 2 * (AppSpacing.xs + AppStroke.focus);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 16 pt page inset like the rows, on both sides.
        final cellWidth =
            (constraints.maxWidth - AppSpacing.base * 2 - (_columns - 1) * _gutter) /
                _columns;
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.base,
          ),
          child: Wrap(
            spacing: _gutter,
            runSpacing: _gutter,
            children: [
              for (final option in options) _cell(context, option, cellWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(BuildContext context, AppIconOption option, double cellWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = option.id == selectedId;

    return Semantics(
      identifier: option.identifier,
      button: true,
      selected: isSelected,
      label: option.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Tapping the selected icon does nothing.
        onTap: isSelected ? null : () => onSelected(option.id),
        child: SizedBox(
          width: cellWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _iconAreaSize,
                height: _iconAreaSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: _iconAreaSize,
                        height: _iconAreaSize,
                        decoration: ShapeDecoration(
                          shape: _maskShape(
                            _iconAreaSize,
                            BorderSide(
                              color: colorScheme.primary,
                              width: AppStroke.focus,
                            ),
                          ),
                        ),
                      ),
                    _iconPreview(context, option),
                    // On the ring's corner rather than the icon's, so the
                    // badge covers the corner the mask already cuts away
                    // instead of the artwork.
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: isSelected
                          ? const SelectionCheckBadge()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // The cell's Semantics node already carries the label.
              ExcludeSemantics(
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The 60 pt preview: the full-bleed art under the platform mask with a
  /// hairline edge in outlineVariant.
  Widget _iconPreview(BuildContext context, AppIconOption option) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = AppIconSize.appIconPreview;
    final preview = Image.asset(
      option.previewAsset(isDark: isDark, isAndroid: isAndroid),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: _maskShape(
            size,
            BorderSide(
              color: colorScheme.outlineVariant,
              width: AppStroke.border,
            ),
          ),
        ),
        child: isAndroid
            ? ClipOval(child: preview)
            : ClipRSuperellipse(
                borderRadius:
                    BorderRadius.circular(size * _iosIconCornerRatio),
                child: preview,
              ),
      ),
    );
  }

  /// The icon's silhouette: a circle on Android, Apple's squircle
  /// ([RoundedSuperellipseBorder] at the home-screen corner proportion)
  /// everywhere else. [side] draws the selection ring or the hairline edge.
  ShapeBorder _maskShape(double size, BorderSide side) => isAndroid
      ? CircleBorder(side: side)
      : RoundedSuperellipseBorder(
          side: side,
          borderRadius: BorderRadius.circular(size * _iosIconCornerRatio),
        );
}
