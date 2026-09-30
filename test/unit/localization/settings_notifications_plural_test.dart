import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plural contract for `settingsNotificationsSummaryOn` ("On · N reminders"),
/// the Settings root row summary. Guards the known failure mode where a
/// locale's `one` branch ignores `{count}` (ru/uk/hr: `one` also covers 21,
/// 31, 101) or misses CLDR categories.
void main() {
  const codes = ['en', 'ru', 'uk', 'hr', 'pl', 'ar'];
  const counts = [0, 1, 2, 5, 21, 101];

  test('every output contains the digits of its count (except 0)', () {
    for (final code in codes) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final count in counts) {
        final output = l10n.settingsNotificationsSummaryOn(count);
        expect(
          output,
          isNot(contains('null')),
          reason: '$code@$count rendered "$output"',
        );
        if (count == 0) continue;
        final digits = count.toString();
        expect(
          output.contains(digits),
          isTrue,
          reason: '$code@$count must contain "$digits" but rendered "$output"',
        );
      }
    }
  });

  test('ru plural forms at the risky counts', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.settingsNotificationsSummaryOn(0), 'Вкл');
    expect(ru.settingsNotificationsSummaryOn(1), 'Вкл · 1 напоминание');
    expect(ru.settingsNotificationsSummaryOn(2), 'Вкл · 2 напоминания');
    expect(ru.settingsNotificationsSummaryOn(5), 'Вкл · 5 напоминаний');
    // `one` also covers 21 — it must still print the real count.
    expect(ru.settingsNotificationsSummaryOn(21), 'Вкл · 21 напоминание');
    expect(ru.settingsNotificationsSummaryOn(101), 'Вкл · 101 напоминание');
  });

  test('uk and hr also read "21 …" in their one branch', () {
    final uk = lookupAppLocalizations(const Locale('uk'));
    expect(uk.settingsNotificationsSummaryOn(21), contains('21'));
    final hr = lookupAppLocalizations(const Locale('hr'));
    expect(hr.settingsNotificationsSummaryOn(21), contains('21'));
  });

  test('pl and ar supply their CLDR categories', () {
    final pl = lookupAppLocalizations(const Locale('pl'));
    expect(pl.settingsNotificationsSummaryOn(0), 'Włączone');
    expect(pl.settingsNotificationsSummaryOn(1), contains('1 przypomnienie'));
    expect(pl.settingsNotificationsSummaryOn(2), contains('2 przypomnienia'));
    expect(pl.settingsNotificationsSummaryOn(5), contains('5 przypomnień'));
    expect(pl.settingsNotificationsSummaryOn(21), contains('21'));

    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(ar.settingsNotificationsSummaryOn(0), 'مفعّل');
    // Non-zero branches use digit forms so the count is always visible.
    expect(ar.settingsNotificationsSummaryOn(1), 'مفعّل · 1 تذكير');
    expect(ar.settingsNotificationsSummaryOn(2), 'مفعّل · 2 تذكيران');
    expect(ar.settingsNotificationsSummaryOn(5), 'مفعّل · 5 تذكيرات');
    expect(ar.settingsNotificationsSummaryOn(21), 'مفعّل · 21 تذكيرًا');
    expect(ar.settingsNotificationsSummaryOn(101), 'مفعّل · 101 تذكير');
  });
}
