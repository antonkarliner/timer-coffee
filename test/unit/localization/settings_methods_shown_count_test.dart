import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plural contract for `settingsMethodsShownCount` ("12 of 30 methods"), the
/// Settings root row summary. Guards the known failure modes: a locale's
/// branch dropping a placeholder (ru/uk/hr: `one` also covers 21, 31, 101),
/// a literal number instead of `{total}`/`{shown}`, or an English copy
/// instead of a translation.
void main() {
  const codes = ['en', 'ru', 'uk', 'pl', 'hr', 'ar', 'de', 'ja'];
  const pairs = [(0, 1), (1, 2), (2, 5), (12, 21), (30, 101)];

  test('every output contains both numbers as digits', () {
    for (final code in codes) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final (shown, total) in pairs) {
        final output = l10n.settingsMethodsShownCount(shown, total);
        expect(
          output.contains(shown.toString()),
          isTrue,
          reason: '$code shown=$shown total=$total must contain '
              '"$shown" but rendered "$output"',
        );
        expect(
          output.contains(total.toString()),
          isTrue,
          reason: '$code shown=$shown total=$total must contain '
              '"$total" but rendered "$output"',
        );
      }
    }
  });

  test('label-form locales stay grammatical at the risky totals', () {
    // In ru/uk/hr the `one` branch also covers 21, 31, 101 — the label form
    // sidesteps noun agreement entirely, so the digits are the contract.
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.settingsMethodsShownCount(0, 1), 'Методы: 0 из 1');
    expect(ru.settingsMethodsShownCount(12, 21), 'Методы: 12 из 21');
    expect(ru.settingsMethodsShownCount(30, 101), 'Методы: 30 из 101');

    final uk = lookupAppLocalizations(const Locale('uk'));
    expect(uk.settingsMethodsShownCount(0, 1), 'Методи: 0 із 1');
    expect(uk.settingsMethodsShownCount(12, 21), 'Методи: 12 із 21');
    expect(uk.settingsMethodsShownCount(30, 101), 'Методи: 30 із 101');

    final pl = lookupAppLocalizations(const Locale('pl'));
    expect(pl.settingsMethodsShownCount(0, 1), 'Metody: 0 z 1');
    expect(pl.settingsMethodsShownCount(12, 21), 'Metody: 12 z 21');

    final hr = lookupAppLocalizations(const Locale('hr'));
    expect(hr.settingsMethodsShownCount(0, 1), 'Metode: 0 od 1');
    expect(hr.settingsMethodsShownCount(12, 21), 'Metode: 12 od 21');

    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(ar.settingsMethodsShownCount(0, 1), 'الطرق: 0 من 1');
    expect(ar.settingsMethodsShownCount(12, 21), 'الطرق: 12 من 21');
    expect(ar.settingsMethodsShownCount(30, 101), 'الطرق: 30 من 101');
  });

  test('natural-form locales agree with the total', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.settingsMethodsShownCount(0, 1), '0 of 1 method');
    expect(en.settingsMethodsShownCount(1, 2), '1 of 2 methods');
    expect(en.settingsMethodsShownCount(2, 5), '2 of 5 methods');
    expect(en.settingsMethodsShownCount(12, 21), '12 of 21 methods');
    expect(en.settingsMethodsShownCount(30, 101), '30 of 101 methods');

    final de = lookupAppLocalizations(const Locale('de'));
    expect(de.settingsMethodsShownCount(0, 1), '0 von 1 Methode');
    expect(de.settingsMethodsShownCount(1, 2), '1 von 2 Methoden');
    expect(de.settingsMethodsShownCount(12, 21), '12 von 21 Methoden');

    final ja = lookupAppLocalizations(const Locale('ja'));
    expect(ja.settingsMethodsShownCount(0, 1), '抽出方法: 0 / 1');
    expect(ja.settingsMethodsShownCount(12, 21), '抽出方法: 12 / 21');
  });
}
