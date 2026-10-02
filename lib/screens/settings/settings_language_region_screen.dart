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
import '../../widgets/settings/settings_list.dart';

/// Language & region settings: app language, date format and time format,
/// with today's date and the current time shown in the chosen formats.
@RoutePage()
class SettingsLanguageRegionScreen extends StatefulWidget {
  const SettingsLanguageRegionScreen({super.key});

  /// Test seam for "now": the section footer and the sheet examples format
  /// the same instant, and a minute boundary between the widget's build and
  /// a test's expectation would otherwise flake exact-match assertions.
  /// Lives on the public widget (not the private State) so tests can pin it.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

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

  /// Sheet subtitle for a date-format option: Automatic says where the
  /// format comes from (the app language), every option shows today's date
  /// in that format as its example.
  String _dateOptionSubtitle(
    DateStyle style,
    AppLocalizations l10n,
    String locale,
    DateTime now,
  ) {
    final example = DateFormat(
      _datePatternFor(style, l10n.dateFormat),
      locale,
    ).format(now);
    return style == DateStyle.auto
        ? '${l10n.settingsAutoMatchesLanguage}${l10n.summarySeparator}$example'
        : example;
  }

  /// Sheet subtitle for a time-format option: Automatic says where the
  /// format comes from (the device setting), every option shows the current
  /// time in that format as its example.
  String _timeOptionSubtitle(
    TimeStyle style,
    AppLocalizations l10n,
    String locale,
    DateTime now,
    bool deviceIs24h,
  ) {
    final example = DateFormat(
      _timePatternFor(style, deviceIs24h),
      locale,
    ).format(now);
    return style == TimeStyle.auto
        ? '${l10n.settingsAutoMatchesDevice}${l10n.summarySeparator}$example'
        : example;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recipeProvider = context.watch<RecipeProvider>();
    final fmtService = context.watch<DateTimeFormatService>();
    final deviceIs24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final now = SettingsLanguageRegionScreen.now();
    // Give every DateFormat the app locale: Intl.defaultLocale is never set
    // in this app, so without it month names and AM/PM stay English in every
    // language.
    final locale = Localizations.localeOf(context).toString();

    final previewDate =
        DateFormat(fmtService.datePattern(l10n.dateFormat), locale).format(now);
    final is24h = fmtService.use24Hour(deviceIs24h);
    final previewTime =
        DateFormat(is24h ? 'HH:mm' : 'hh:mm a', locale).format(now);

    return SettingsPageScaffold(
      title: l10n.settingsLanguageRegionTitle,
      children: [
        // Section 1 — Language: a single row, so no section header. Shown
        // only once the supported locales have loaded, in an always-present
        // slot so the tree shape stays stable.
        SettingsSection(
          children: [
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
                    for (final localeModel in locales)
                      SettingsChoiceOption(
                        value: localeModel.locale,
                        label: localeModel.localeName,
                        identifier: 'locale${localeModel.locale}ListTile',
                      ),
                  ],
                  current: recipeProvider.currentLocale.languageCode,
                  onChanged: _setLocale,
                );
              },
            ),
          ],
        ),
        // Section 2 — Date & time: the two format rows, with today's date and
        // the current time in the chosen formats as the section footer (it
        // replaces the old grey preview box).
        SettingsSection(
          header: l10n.settingsDateTimeFormat,
          footer: l10n.settingsDateTimeToday(previewDate, previewTime),
          children: [
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
                    subtitle: _dateOptionSubtitle(style, l10n, locale, now),
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
                    subtitle: _timeOptionSubtitle(
                      style,
                      l10n,
                      locale,
                      now,
                      deviceIs24h,
                    ),
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
          ],
        ),
      ],
    );
  }
}
