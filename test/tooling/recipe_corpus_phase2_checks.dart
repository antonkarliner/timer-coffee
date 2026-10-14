import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'recipe_corpus_accuracy.dart';
import 'recipe_corpus_label_page.dart';
import 'recipe_corpus_sample.dart';

Map<String, dynamic> syntheticCorpusRow(
  int id,
  List<String> src, {
  List<String>? cor,
  String locale = 'en',
}) => {
  'id': id,
  'src': src,
  'cor': cor ?? src,
  'coffee': 15,
  'water': 250,
  'operator': false,
  'locale': locale,
  'created_at': '2026-06-01T00:00:00Z',
};
void check(bool condition) {
  if (!condition) throw StateError('Synthetic corpus check failed.');
}

/// Standalone checks also called by the Flutter test wrapper. No private input.
void runPhase2Checks() {
  final rows = [
    syntheticCorpusRow(1, ['Weigh coffee 20g water', 'Add 30g', 'Pour 300g water']),
    syntheticCorpusRow(
      2,
      ['Prepare filter', 'Add 5 g/s'],
      cor: ['Prepare filter', 'Add (0.2 x <final_water_amount>)g'],
    ),
    syntheticCorpusRow(
      3,
      ['Prepare filter', 'Add one cup'],
      cor: ['Prepare filter', 'Add (0.2 x <final_water_amount>)g'],
    ),
    syntheticCorpusRow(4, ['Add 15g coffee', 'Vierte 60g'], locale: 'es'),
    syntheticCorpusRow(5, ['Prepare filter', 'Add 80g'], locale: 'fr'),
    {
      ...syntheticCorpusRow(6, ['Add 15g coffee']),
      'operator': true,
    },
    {
      ...syntheticCorpusRow(7, ['Add 15g coffee']),
      'coffee': 0,
    },
    {
      ...syntheticCorpusRow(8, ['Add 15g coffee']),
      'cor': <String>[],
    },
  ];
  final sample = buildLabelingSample(rows);
  check(
    sample.items.map((i) => i.identity).toSet().length == sample.items.length,
  );
  check(sample.stratumCounts['ai_more'] == 2);
  check(sample.items.singleWhere((i) => i.diagnosticsId == 3).findMissed);
  check(
    sample.items.any(
      (i) => i.strata.contains('ambiguous') && i.strata.contains('suspect'),
    ),
  );
  check(sample.items.any((i) => i.strata.contains('lang_other')));
  check(sample.items.any((i) => i.strata.contains('random_es')));
  check(sample.items.every((i) => i.diagnosticsId < 6));
  check(
    jsonEncode(sample.items.map((i) => i.identity).toList()) ==
        jsonEncode(
          buildLabelingSample(
            rows.reversed.toList(),
          ).items.map((i) => i.identity).toList(),
        ),
  );
  final large = [
    for (var i = 0; i < 300; i++)
      syntheticCorpusRow(i, [
        'Prepare filter',
        'Add 80g',
      ], locale: ['en', 'es', 'fr', 'ja', 'de'][i % 5]),
  ];
  check(buildLabelingSample(large, target: 100).items.length == 100);
  check(
    buildLabelingSample(rows, target: 0).items.every(
      (i) => i.strata.contains('ai_more') || i.strata.contains('ambiguous'),
    ),
  );
  final page = buildLabelingPage(sample, rows);
  for (final forbidden in [
    'http://',
    'https://',
    '<script src',
    'fetch(',
    'XMLHttpRequest',
    'sendBeacon',
  ]) {
    check(!page.contains(forbidden));
  }
  final embedded =
      jsonDecode(page.split('const items=')[1].split(';\nconst storageKey')[0])
          as List;
  check(embedded.length == sample.items.length);
  check(
    page.contains('localStorage.setItem(storageKey,serializeLabels(labels))'),
  );
  check(page.contains('new Blob([serializeLabels(labels)]'));
  final whitelist = page
      .split('function labelRecord(r){return ')[1]
      .split(';')[0];
  check(!whitelist.contains('text') && !whitelist.contains('context'));
  for (final field in [
    'diagnostics_id',
    'step_index',
    'char_start',
    'char_end',
    'label',
  ]) {
    check(whitelist.contains('$field:r.$field'));
  }
  final hostile = [
    syntheticCorpusRow(99, [
      '<script> https://example.invalid/a </script>',
      'Add 80g',
    ]),
  ];
  check(
    !buildLabelingPage(
      buildLabelingSample(hostile),
      hostile,
    ).contains('https://'),
  );
  var refused = false;
  try {
    labelingPageOutput('$corpusRepository/private-page.html');
  } catch (_) {
    refused = true;
  }
  check(refused);
  final scratch = Directory.systemTemp.createTempSync('corpus-synthetic-');
  try {
    check(
      labelingPageOutput(
        '${scratch.path}/page.html',
      ).path.endsWith('page.html'),
    );
    Link('${scratch.path}/repo').createSync(corpusRepository);
    refused = false;
    try {
      labelingPageOutput('${scratch.path}/repo/private-page.html');
    } catch (_) {
      refused = true;
    }
    check(refused);
    Link(
      '${scratch.path}/dangling.html',
    ).createSync('$corpusRepository/nonexistent-private-page.html');
    refused = false;
    try {
      labelingPageOutput('${scratch.path}/dangling.html');
    } catch (_) {
      refused = true;
    }
    check(refused);
  } finally {
    scratch.deleteSync(recursive: true);
  }
  final accuracyRows = [
    syntheticCorpusRow(10, ['Add 15g coffee', 'Pour 60g water', 'Add one cup']),
  ];
  Map<String, dynamic> label(
    int row,
    int step,
    int start,
    int end,
    String name,
  ) => {
    'diagnostics_id': row,
    'step_index': step,
    'char_start': start,
    'char_end': end,
    'label': name,
  };
  final accuracy = computeLabelAccuracy(accuracyRows, [
    label(10, 0, 4, 7, 'coffee'),
    label(10, 1, 5, 8, 'fixed'),
    label(10, 2, 4, 11, 'water'),
    label(100, 0, 0, 1, 'water'),
  ]);
  check(
    accuracy.orphan == 1 &&
        accuracy.scopes['overall']!['labelled'] == 3 &&
        accuracy.scopes['overall']!['correct'] == 1,
  );
  check(
    accuracy.confusion['coffee:coffee'] == 1 &&
        accuracy.confusion['fixed:water'] == 1 &&
        accuracy.confusion['water:missed'] == 1,
  );
  check(formatLabelAccuracy(accuracy).contains('METRIC '));
  for (final text in [
    'Pour 60-90g water; add 15g coffee',
    'Add ۶۰ گرم آب',
    'coffee 60-90g water',
  ]) {
    final trace = RecipeExpressionService.explainStepConversion(
      text,
      kind: RecipeStepKind.brew,
      coffeeAmount: 15,
      waterAmount: 250,
    );
    final spans = trace
        .map((a) => text.substring(a.originalStart, a.originalEnd))
        .toList();
    check(
      jsonEncode(spans) ==
          jsonEncode(
            text.startsWith('Pour')
                ? ['60-90g', '15g']
                : text.startsWith('Add')
                ? ['۶۰ گرم']
                : ['60-90g', '90g'],
          ),
    );
  }
}

void main() {
  runPhase2Checks();
  // ignore: avoid_print
  print('Synthetic Phase 2 checks passed.');
}
