import 'dart:convert';
import 'dart:io';

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

    for (final arbFile in arbFiles) {
      final fileName = arbFile.uri.pathSegments.last;
      final catalog = _readArb(arbFile);
      final targetKeys = _messageKeys(catalog);

      expect(
        targetKeys.difference(sourceKeys),
        isEmpty,
        reason: '$fileName contains message keys absent from app_en.arb',
      );
      expect(
        sourceKeys.difference(targetKeys),
        isEmpty,
        reason: '$fileName is missing message keys from app_en.arb',
      );

      for (final key in sourceKeys) {
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
