import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;

/// Plural contract for `recipeCreationAiReviewChangesSummary` ("The AI
/// review changed {count} step(s)."), the AI review sheet intro line.
/// Guards the known failure mode where a locale's `one` branch ignores
/// `{count}` (ru/uk/hr: `one` also covers 21, 31, 101) or misses CLDR
/// categories.
void main() {
  // Every supported locale; the sheet is shown in all of them.
  final codes = AppLocalizations.supportedLocales
      .map((locale) => locale.languageCode)
      .toSet()
      .toList();
  const counts = [1, 2, 5, 21, 101];

  test('every locale renders the digits of its count', () {
    expect(codes.length, 22);
    for (final code in codes) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final count in counts) {
        // Arabic `one`/`two` match exactly 1 and 2, so they spell the count
        // out ("خطوة واحدة" / "خطوتين") instead of printing a digit.
        if (code == 'ar' && count <= 2) continue;
        final output = l10n.recipeCreationAiReviewChangesSummary(count);
        // The generated code formats the count with decimalPattern, which
        // uses native digits for some locales (fa: ۱, ar: Western). Compare
        // against the same formatter so this test catches a swallowed
        // {count} in a plural branch, not a digit-script difference.
        final expectedDigits = intl.NumberFormat.decimalPattern(
          code,
        ).format(count);
        expect(
          output.contains(expectedDigits),
          isTrue,
          reason: '$code@$count must contain "$expectedDigits" '
              'but rendered "$output"',
        );
      }
    }
  });

  test('en singular and plural', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.recipeCreationAiReviewChangesSummary(1),
        'The AI review changed 1 step.');
    expect(en.recipeCreationAiReviewChangesSummary(2),
        'The AI review changed 2 steps.');
  });

  test('ru plural forms at the risky counts', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.recipeCreationAiReviewChangesSummary(1),
        'ИИ-проверка изменила 1 шаг.');
    expect(ru.recipeCreationAiReviewChangesSummary(2),
        'ИИ-проверка изменила 2 шага.');
    expect(ru.recipeCreationAiReviewChangesSummary(5),
        'ИИ-проверка изменила 5 шагов.');
    // `one` also covers 21 — it must still print the real count.
    expect(ru.recipeCreationAiReviewChangesSummary(21),
        'ИИ-проверка изменила 21 шаг.');
    expect(ru.recipeCreationAiReviewChangesSummary(101),
        'ИИ-проверка изменила 101 шаг.');
  });

  test('ar supplies its CLDR categories', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(ar.recipeCreationAiReviewChangesSummary(1),
        contains('خطوة واحدة'));
    expect(ar.recipeCreationAiReviewChangesSummary(2),
        contains('خطوتين'));
    expect(ar.recipeCreationAiReviewChangesSummary(5), contains('خطوات'));
    expect(ar.recipeCreationAiReviewChangesSummary(21), contains('21'));
  });

  test('pl and hr categories at the risky counts', () {
    final pl = lookupAppLocalizations(const Locale('pl'));
    expect(pl.recipeCreationAiReviewChangesSummary(1), contains('krok.'));
    expect(pl.recipeCreationAiReviewChangesSummary(2), contains('kroki.'));
    expect(pl.recipeCreationAiReviewChangesSummary(5), contains('kroków.'));
    expect(pl.recipeCreationAiReviewChangesSummary(21), contains('21'));

    final hr = lookupAppLocalizations(const Locale('hr'));
    expect(hr.recipeCreationAiReviewChangesSummary(21), contains('21'));
    expect(hr.recipeCreationAiReviewChangesSummary(5), contains('koraka.'));
  });
}
