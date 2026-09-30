import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../models/supported_locale_model.dart';
import '../../providers/recipe_provider.dart';
import '../../services/date_time_format_service.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/settings/settings_list.dart';

/// Language & region settings: app language, date format and time format,
/// with a live preview of the current choices.
@RoutePage()
class SettingsLanguageRegionScreen extends StatefulWidget {
  const SettingsLanguageRegionScreen({super.key});

  @override
  State<SettingsLanguageRegionScreen> createState() =>
      _SettingsLanguageRegionScreenState();
}

class _SettingsLanguageRegionScreenState
    extends State<SettingsLanguageRegionScreen> {
  Future<List<SupportedLocaleModel>>? _supportedLocales;

  @override
  void initState() {
    super.initState();
    _supportedLocales =
        Provider.of<RecipeProvider>(context, listen: false)
            .fetchAllSupportedLocales();
  }

  /// Persists the language and applies it. The MaterialApp listens to
  /// [RecipeProvider.currentLocale], so this page re-renders in the new
  /// language without a route replace.
  Future<void> _setLocale(String code) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final previous = recipeProvider.currentLocale.languageCode;
    if (code == previous) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    if (!mounted) return;
    await recipeProvider.setLocale(Locale(code));
    SettingsAnalytics.settingChanged(
      key: SettingKey.language,
      value: code,
      previous: previous,
      source: SettingSource.settings,
    );
  }

  void _changeDateStyle(DateStyle style) {
    final fmtService =
        Provider.of<DateTimeFormatService>(context, listen: false);
    final previous = fmtService.dateStyle.name;
    fmtService.setDateStyle(style);
    SettingsAnalytics.settingChanged(
      key: SettingKey.dateFormat,
      value: style.name,
      previous: previous,
      source: SettingSource.settings,
    );
  }

  void _changeTimeStyle(TimeStyle style) {
    final fmtService =
        Provider.of<DateTimeFormatService>(context, listen: false);
    final previous = fmtService.timeStyle.name;
    fmtService.setTimeStyle(style);
    SettingsAnalytics.settingChanged(
      key: SettingKey.timeFormat,
      value: style.name,
      previous: previous,
      source: SettingSource.settings,
    );
  }

  /// Pattern per style, mirroring `DateTimeFormatService.datePattern`; kept
  /// local so the service does not grow preview-only API.
  String _datePatternFor(DateStyle style, String localeDefault) {
    switch (style) {
      case DateStyle.auto:
        return localeDefault;
      case DateStyle.dmy:
        return 'dd/MM/yyyy';
      case DateStyle.mdy:
        return 'MM/dd/yyyy';
      case DateStyle.ymd:
        return 'yyyy-MM-dd';
    }
  }

  /// Time pattern per style; `auto` resolves through the device setting.
  String _timePatternFor(TimeStyle style, bool deviceIs24h) {
    switch (style) {
      case TimeStyle.auto:
        return deviceIs24h ? 'HH:mm' : 'hh:mm a';
      case TimeStyle.h12:
        return 'hh:mm a';
      case TimeStyle.h24:
        return 'HH:mm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recipeProvider = context.watch<RecipeProvider>();
    final fmtService = context.watch<DateTimeFormatService>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deviceIs24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final now = DateTime.now();

    final previewDate =
        DateFormat(fmtService.datePattern(l10n.dateFormat)).format(now);
    final is24h = fmtService.use24Hour(deviceIs24h);
    final previewTime = DateFormat(is24h ? 'HH:mm' : 'hh:mm a').format(now);

    return SettingsPageScaffold(
      title: l10n.settingsLanguageRegionTitle,
      children: [
        // Language — shown only once the supported locales have loaded, in an
        // always-present slot so the tree shape stays stable.
        FutureBuilder<List<SupportedLocaleModel>>(
          future: _supportedLocales,
          builder: (context, snapshot) {
            final locales = snapshot.data;
            if (locales == null || locales.isEmpty) {
              return const SizedBox.shrink();
            }
            return SettingsChoiceRow<String>(
              identifier: 'settingsLangTile',
              title: l10n.settingslang,
              sheetTitle: l10n.settingslang,
              options: [
                for (final locale in locales)
                  SettingsChoiceOption(
                    value: locale.locale,
                    label: locale.localeName,
                    identifier: 'locale${locale.locale}ListTile',
                  ),
              ],
              current: recipeProvider.currentLocale.languageCode,
              onChanged: _setLocale,
            );
          },
        ),
        SettingsSectionHeader(title: l10n.settingsDateTimeFormat),
        SettingsChoiceRow<DateStyle>(
          identifier: 'settingsDateFormatTile',
          title: l10n.settingsDateFormatLabel,
          sheetTitle: l10n.settingsDateFormatLabel,
          options: [
            for (final style in DateStyle.values)
              SettingsChoiceOption(
                value: style,
                label: switch (style) {
                  DateStyle.auto => l10n.settingsDateFormatAuto,
                  DateStyle.dmy => l10n.settingsDateFormatDMY,
                  DateStyle.mdy => l10n.settingsDateFormatMDY,
                  DateStyle.ymd => l10n.settingsDateFormatYMD,
                },
                subtitle:
                    DateFormat(_datePatternFor(style, l10n.dateFormat))
                        .format(now),
                identifier: 'dateFormat${switch (style) {
                  DateStyle.auto => 'Auto',
                  DateStyle.dmy => 'Dmy',
                  DateStyle.mdy => 'Mdy',
                  DateStyle.ymd => 'Ymd',
                }}ListTile',
              ),
          ],
          current: fmtService.dateStyle,
          onChanged: _changeDateStyle,
        ),
        SettingsChoiceRow<TimeStyle>(
          identifier: 'settingsTimeFormatTile',
          title: l10n.settingsTimeFormatLabel,
          sheetTitle: l10n.settingsTimeFormatLabel,
          options: [
            for (final style in TimeStyle.values)
              SettingsChoiceOption(
                value: style,
                label: switch (style) {
                  TimeStyle.auto => l10n.settingsDateFormatAuto,
                  TimeStyle.h12 => l10n.settingsTimeFormat12h,
                  TimeStyle.h24 => l10n.settingsTimeFormat24h,
                },
                subtitle:
                    DateFormat(_timePatternFor(style, deviceIs24h)).format(now),
                identifier: 'timeFormat${switch (style) {
                  TimeStyle.auto => 'Auto',
                  TimeStyle.h12 => '12h',
                  TimeStyle.h24 => '24h',
                }}ListTile',
              ),
          ],
          current: fmtService.timeStyle,
          onChanged: _changeTimeStyle,
        ),
        // Live preview — today's date and time in the current choices.
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.preview_outlined,
                  size: AppIconSize.small,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$previewDate  $previewTime',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
