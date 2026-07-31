import 'dart:convert';
import 'dart:io';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _allowedEmptyValues = <String, Set<String>>{
  'app_fa.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_fi.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_fr.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_it.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_pl.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_ru.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_tr.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
  'app_uk.arb': {
    'yearlyStats25ShareRoastersSuffix',
    'yearlyStats25ShareOriginsSuffix',
  },
};

void main() {
  test('all locale catalogs match English and contain intentional values', () {
    final arbFiles =
        Directory('lib/l10n')
            .listSync()
            .whereType<File>()
            .where((file) => RegExp(r'app_[a-z]+\.arb$').hasMatch(file.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(arbFiles, isNotEmpty);

    final sourceCatalog = _readArb(File('lib/l10n/app_en.arb'));
    final sourceKeys = _messageKeys(sourceCatalog);
    final observedEmptyValues = <String>{};

    // Key-set mismatches are accumulated across every locale and reported in
    // one failure, rather than thrown per file. A new key is almost always
    // missing from *all* 21 locales at once, and failing on the first file
    // turned that into 21 fix-rerun cycles. `flutter analyze` never catches
    // this, so the message here is the only thing pointing at the fix.
    final missingByFile = <String, Set<String>>{};
    final unknownByFile = <String, Set<String>>{};

    for (final arbFile in arbFiles) {
      final fileName = arbFile.uri.pathSegments.last;
      final catalog = _readArb(arbFile);
      final targetKeys = _messageKeys(catalog);

      final unknown = targetKeys.difference(sourceKeys);
      if (unknown.isNotEmpty) unknownByFile[fileName] = unknown;
      final missing = sourceKeys.difference(targetKeys);
      if (missing.isNotEmpty) missingByFile[fileName] = missing;

      for (final key in sourceKeys) {
        if (!targetKeys.contains(key)) continue;
        final value = catalog[key];
        expect(value, isA<String>(), reason: '$fileName:$key must be a string');
        if ((value! as String).trim().isNotEmpty) continue;

        observedEmptyValues.add('$fileName:$key');
        expect(
          _allowedEmptyValues[fileName] ?? const <String>{},
          contains(key),
          reason: '$fileName:$key is unexpectedly empty',
        );
      }
    }

    expect(
      missingByFile,
      isEmpty,
      reason: _keySetFailure(
        'Message keys present in app_en.arb but MISSING from these locale '
        'files. Add each key (an English placeholder is acceptable; real '
        'translation can follow) to every file listed:',
        missingByFile,
      ),
    );
    expect(
      unknownByFile,
      isEmpty,
      reason: _keySetFailure(
        'Message keys present in these locale files but ABSENT from '
        'app_en.arb. Either add them to the English template or remove them:',
        unknownByFile,
      ),
    );

    final configuredEmptyValues = {
      for (final entry in _allowedEmptyValues.entries)
        for (final key in entry.value) '${entry.key}:$key',
    };
    expect(observedEmptyValues, configuredEmptyValues);
  });

  test('generated localization inventory reports no untranslated messages', () {
    final untranslated = jsonDecode(
      File('untranslated.txt').readAsStringSync(),
    );
    expect(untranslated, isA<Map<String, dynamic>>());
    expect(untranslated, isEmpty);
  });

  test('audited Brew Diary copy and plural edges stay domain-specific', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final ja = lookupAppLocalizations(const Locale('ja'));
    final ar = lookupAppLocalizations(const Locale('ar'));
    final ru = lookupAppLocalizations(const Locale('ru'));

    expect(de.journeyCompareTitle, 'Brühvorgänge vergleichen');
    expect(ja.journeySelectTwo, '2件の抽出記録を選択');
    expect(ar.diaryGroupBrewCount(0), 'لا توجد تحضيرات');
    expect(ar.diaryGroupBrewCount(2), 'تحضيران');
    expect(ar.journeyEvaluatedBrewCount(3), '3 تحضيرات مقيّمة');
    expect(ru.diaryGroupBrewCount(1), '1 заваривание');
    expect(ru.diaryGroupBrewCount(2), '2 заваривания');
    expect(ru.diaryGroupBrewCount(5), '5 завариваний');
    expect(ru.journeyEvaluatedCount(1, 2), 'Оценено: 1 из 2');
    expect(ar.journeyBetterTaste, 'نتيجة مذاق أفضل');
    expect(ru.journeyBetterTaste, 'Лучший вкусовой результат');
  });
}

Map<String, dynamic> _readArb(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  expect(
    decoded,
    isA<Map<String, dynamic>>(),
    reason: '${file.path} is invalid',
  );
  return Map<String, dynamic>.from(decoded as Map);
}

Set<String> _messageKeys(Map<String, dynamic> catalog) {
  return catalog.keys.where((key) => !key.startsWith('@')).toSet();
}

/// Formats an aggregated key-set mismatch so the failure names every affected
/// (file, key) pair at once. Grouped by key when a key is missing from many
/// files — the common case for a newly added string — so the reader sees
/// "this one key, these 21 files" instead of 21 near-identical lines.
String _keySetFailure(String headline, Map<String, Set<String>> byFile) {
  if (byFile.isEmpty) return headline;

  final filesByKey = <String, List<String>>{};
  for (final entry in byFile.entries) {
    for (final key in entry.value) {
      filesByKey.putIfAbsent(key, () => <String>[]).add(entry.key);
    }
  }

  final buffer = StringBuffer(headline);
  final keys = filesByKey.keys.toList()..sort();
  for (final key in keys) {
    final files = filesByKey[key]!..sort();
    buffer.write('\n  $key -> ${files.length} file(s): ${files.join(', ')}');
  }
  return buffer.toString();
}
