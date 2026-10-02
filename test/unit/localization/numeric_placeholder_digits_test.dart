import 'dart:convert';
import 'dart:io';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;

/// Every count in a message is printed in the locale's digits, and is the
/// real count.
///
/// Three generator behaviours this guards against (plan 077 phase 13):
/// - An `int`/`num` placeholder without a `"format"` is interpolated with
///   `toString()`, so fa showed Latin digits ("11 از 30") next to dates in
///   Persian ones. With `"format": "decimalPattern"` gen-l10n formats it
///   through `NumberFormat` for the locale.
/// - gen-l10n resolves each placeholder from the locale ARB before the
///   template, so a locale redeclaring `"count": {"type": "int"}` silently
///   cancels the template's format for that language.
/// - `=1{…}` is passed to `Intl.pluralLogic` as `one:`, so a literal number in
///   it is shown for every number in CLDR `one` — 0 in fa/fr/pt, 21/31/101 in
///   hr/ru/uk. `#` is not supported at all and renders as a literal "#".
void main() {
  const counts = [0, 1, 2, 5, 21, 101, 1234];

  // Number formats other than decimalPattern, by key.
  const otherFormats = {'showAllNBrews': 'compact'};

  // Digits that are part of the sentence, not the count ("in the last
  // 1 minute").
  const literalAllowed = {
    'ja': {'mts_inSyncCelebration': '1分'},
    'ko': {'mts_inSyncCelebration': '1분'},
  };

  // Every message with a numeric placeholder; all numeric arguments get the
  // same value.
  final messages = <String, String Function(AppLocalizations, int)>{
    'showAllNBrews': (l, n) => l.showAllNBrews(n),
    'pulseBrewsCount': (l, n) => l.pulseBrewsCount(n),
    'relativeTimeMinutesAgo': (l, n) => l.relativeTimeMinutesAgo(n),
    'relativeTimeHoursAgo': (l, n) => l.relativeTimeHoursAgo(n),
    'relativeTimeHoursMinutesAgo': (l, n) =>
        l.relativeTimeHoursMinutesAgo(n, n),
    'relativeTimeDaysAgo': (l, n) => l.relativeTimeDaysAgo(n),
    'relativeTimeMonthsAgo': (l, n) => l.relativeTimeMonthsAgo(n),
    'relativeTimeYearsAgo': (l, n) => l.relativeTimeYearsAgo(n),
    'aiScanPhotosSaved': (l, n) => l.aiScanPhotosSaved(n),
    'aiScanPhotosPartiallySaved': (l, n) => l.aiScanPhotosPartiallySaved(n, n),
    'yearlyStatsStory4Text': (l, n) => l.yearlyStatsStory4Text(n),
    'yearlyStatsStory6Text': (l, n) => l.yearlyStatsStory6Text(n),
    'yearlyStatsStory8TitleLow': (l, n) => l.yearlyStatsStory8TitleLow(n),
    'yearlyStatsStory8TitleMedium': (l, n) => l.yearlyStatsStory8TitleMedium(n),
    'yearlyStatsStory8TitleHigh': (l, n) => l.yearlyStatsStory8TitleHigh(n),
    'yearlyStats25Slide3TopBadge': (l, n) => l.yearlyStats25Slide3TopBadge(n),
    'yearlyStats25BrewsCount': (l, n) => l.yearlyStats25BrewsCount(n),
    'yearlyStats25MethodRow': (l, n) => l.yearlyStats25MethodRow('X', n),
    'yearlyStats25FallbackTitle': (l, n) => l.yearlyStats25FallbackTitle(n, n),
    'yearlyStats25BrewTimeMinutes': (l, n) => l.yearlyStats25BrewTimeMinutes(n),
    'formattedRoasterCount': (l, n) => l.formattedRoasterCount(n),
    'formattedCountryCount': (l, n) => l.formattedCountryCount(n),
    'formattedBrewingMethodCount': (l, n) => l.formattedBrewingMethodCount(n),
    'notifBrewMilestoneBody': (l, n) => l.notifBrewMilestoneBody(n),
    'notifExploreRecipesBody': (l, n) => l.notifExploreRecipesBody(n),
    'notifWeeklyTitle': (l, n) => l.notifWeeklyTitle(n),
    'notifWeeklyBody': (l, n) => l.notifWeeklyBody(n),
    'settingsNotificationsSummaryOn': (l, n) =>
        l.settingsNotificationsSummaryOn(n),
    'settingsMethodsShownCount': (l, n) => l.settingsMethodsShownCount(n, n),
    'daysAgo': (l, n) => l.daysAgo(n),
    'approxBrewsLeft': (l, n) => l.approxBrewsLeft(n),
    'roasterBagsLogged': (l, n) => l.roasterBagsLogged(n),
    'reviewsCount': (l, n) => l.reviewsCount(n),
    'roasterCountryCount': (l, n) => l.roasterCountryCount(n),
    'mts_inSyncCelebration': (l, n) => l.mts_inSyncCelebration(n),
    'mts_inSyncFromCountriesWithOthers': (l, n) =>
        l.mts_inSyncFromCountriesWithOthers('X', n),
    'diarySelectedBeanCount': (l, n) => l.diarySelectedBeanCount(n),
    'diaryBeanCount': (l, n) => l.diaryBeanCount(n),
    'diaryGroupBrewCount': (l, n) => l.diaryGroupBrewCount(n),
    'diaryMonthBrews': (l, n) => l.diaryMonthBrews(n),
    'diaryMonthStreakDays': (l, n) => l.diaryMonthStreakDays(n),
    'diaryMonthActiveDays': (l, n) => l.diaryMonthActiveDays(n),
    'diaryOnThisDayTitle': (l, n) => l.diaryOnThisDayTitle(n),
    'journeyEvaluatedCount': (l, n) => l.journeyEvaluatedCount(n, n),
    'journeyEvaluatedBrewCount': (l, n) => l.journeyEvaluatedBrewCount(n),
    'journeyProgressChartLabel': (l, n) =>
        l.journeyProgressChartLabel('X', n, n),
    'liveActivityStepProgress': (l, n) => l.liveActivityStepProgress(n, n),
    'liveUpdateStepDescription': (l, n) =>
        l.liveUpdateStepDescription(n, n, 'X'),
    'dataExportIncorrectCodeAttempts': (l, n) =>
        l.dataExportIncorrectCodeAttempts(n),
    'accountEmailResendCountdown': (l, n) => l.accountEmailResendCountdown(n),
  };

  Map<String, dynamic> readArb(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  /// Numeric placeholder names per message key, from an ARB's metadata.
  Map<String, Set<String>> numericPlaceholders(Map<String, dynamic> arb) {
    final result = <String, Set<String>>{};
    for (final entry in arb.entries) {
      if (!entry.key.startsWith('@') || entry.key.startsWith('@@')) continue;
      final meta = entry.value;
      if (meta is! Map || meta['placeholders'] is! Map) continue;
      final names = <String>{
        for (final p in (meta['placeholders'] as Map).entries)
          if (p.value is Map &&
              const ['int', 'num', 'double'].contains(p.value['type']))
            p.key as String,
      };
      if (names.isNotEmpty) result[entry.key.substring(1)] = names;
    }
    return result;
  }

  final template = readArb('lib/l10n/app_en.arb');
  final templateNumeric = numericPlaceholders(template);

  test('every numeric placeholder in the template has a number format', () {
    for (final MapEntry(key: key, value: names) in templateNumeric.entries) {
      final placeholders = template['@$key']['placeholders'] as Map;
      for (final name in names) {
        expect(
          placeholders[name]['format'],
          otherFormats[key] ?? 'decimalPattern',
          reason: '$key.$name: without a format it is printed with '
              'toString(), in Latin digits in every locale',
        );
      }
    }
  });

  test('no locale ARB redeclares a numeric placeholder', () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('_en.arb'));
    for (final file in arbs) {
      final arb = readArb(file.path);
      for (final MapEntry(key: key, value: names) in templateNumeric.entries) {
        final meta = arb['@$key'];
        if (meta is! Map || meta['placeholders'] is! Map) continue;
        final redeclared =
            names.intersection((meta['placeholders'] as Map).keys.toSet());
        expect(
          redeclared,
          isEmpty,
          reason: '${file.path} @$key redeclares $redeclared, which replaces '
              "the template's placeholder (and its format) for that locale",
        );
      }
    }
  });

  test('the table below covers every numeric message in the template', () {
    expect(messages.keys.toSet(), templateNumeric.keys.toSet());
  });

  test('every locale prints the real count, in its own digits', () {
    final digitOrHash = RegExp(r'[0-9٠-٩۰-۹#]');
    final failures = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      final code = locale.languageCode;
      for (final MapEntry(key: key, value: render) in messages.entries) {
        for (final n in counts) {
          final output = render(l10n, n);
          final formatted = otherFormats[key] == 'compact'
              ? intl.NumberFormat.compact(locale: l10n.localeName).format(n)
              : intl.NumberFormat.decimalPattern(l10n.localeName).format(n);
          var rest = output.replaceAll(formatted, '');
          final allowed = literalAllowed[code]?[key];
          if (allowed != null) rest = rest.replaceAll(allowed, '');
          if (digitOrHash.hasMatch(rest)) {
            failures.add('$code $key($n) = "$output" (count is "$formatted")');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  group('fa prints Persian digits, ar counts stay on Latin ones', () {
    final fa = lookupAppLocalizations(const Locale('fa'));
    final ar = lookupAppLocalizations(const Locale('ar'));

    test('Settings summaries', () {
      expect(fa.settingsMethodsShownCount(11, 30), '۱۱ از ۳۰ روش');
      expect(fa.settingsNotificationsSummaryOn(1), 'فعال، ۱ یادآوری');
      // intl's `ar` number symbols are Latin; configureDateDigits() makes ar
      // dates Latin to match (test/unit/utils/date_digits_test.dart).
      expect(ar.settingsMethodsShownCount(11, 30), 'الطرق: 11 من 30');
    });

    test('thousands use the locale separator', () {
      expect(fa.roasterBagsLogged(1234), startsWith('۱٬۲۳۴ '));
    });

    test('fa `one` covers 0, so its branch must print the count', () {
      expect(fa.diaryMonthBrews(0), '۰ دم‌آوری');
      expect(fa.diaryMonthBrews(1), '۱ دم‌آوری');
    });

    test('fa never puts a middle dot next to its digits', () {
      // Persian zero (۰) is a dot: "فعال · ۱" reads as "۱۰". fa separates
      // summary parts with the Persian comma instead.
      expect(fa.summarySeparator, '، ');
      expect(lookupAppLocalizations(const Locale('en')).summarySeparator,
          ' · ');
      final dotted = [
        for (final entry in readArb('lib/l10n/app_fa.arb').entries)
          if (!entry.key.startsWith('@') &&
              entry.value is String &&
              (entry.value as String).contains('·'))
            entry.key,
      ];
      expect(dotted, isEmpty);
    });
  });
}
