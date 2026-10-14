import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'recipe_corpus_metrics.dart';

Map<String, dynamic> _row(
  List<String> src, {
  List<String>? cor,
  String locale = 'en-US',
  String created = '2026-06-01 10:00:00+00',
  bool operator = false,
  double? coffee = 15,
}) => {
  'created_at': created,
  'operator': operator,
  'coffee': coffee,
  'water': 250,
  'method': 'v60',
  'locale': locale,
  'src': src,
  'cor': cor ?? src,
};

List<Map<String, dynamic>> _syntheticRows() => [
  _row(['Add 15g coffee', 'Add 60g', 'Add 250ml']),
  _row(
    ['Weigh coffee 20g water', 'Vierte 60-90g agua', 'Vierte 250ML agua'],
    locale: 'es-ES',
    cor: [
      'Weigh coffee (0.08 x <final_water_amount>)g water',
      'Vierte 60-90g agua',
      'Vierte 250ML agua',
    ],
  ),
  _row(
    ['Prepare filter', 'Pour 5 g/s'],
    cor: ['Prepare filter', 'Wait'],
    created: '2026-08-14 23:59:59+00',
  ),
  _row(['Add 250ml water'], operator: true),
  _row(['Add 250ml water'], coffee: null),
  _row(['Prepare filter', 'Pour 250ml water'], cor: ['Prepare filter']),
];

void main() {
  test('counts only eligible synthetic rows, by language and kind', () {
    final m = computeCorpusMetrics(_syntheticRows());
    expect(m.rowsUsed, 3);
    expect(m.count('skippedRows', key: 'operator'), 1);
    expect(m.count('skippedRows', key: 'invalidAmounts'), 1);
    expect(m.count('skippedRows', key: 'stepCountMismatch'), 1);
    expect(m.count('steps'), 8);
    expect(m.count('steps', kind: 'preparation'), 3);
    expect(m.count('steps', kind: 'brew'), 5);
    expect(m.count('rows', kind: 'brew'), 3);
    expect(m.count('rows', scope: 'lang:es'), 1);
    expect(m.count('amounts'), 7);
    expect(m.count('amounts', kind: 'preparation'), 2);
    expect(m.count('amounts', scope: 'lang:es', kind: 'brew'), 2);
    // 'Add 15g coffee', 'Add 250ml' and 'Vierte 250ML agua' equal a recipe
    // total, so the exact-total rule decides them before any keyword.
    expect(m.count('reason', key: 'exactTotalCoffee'), 1);
    expect(m.count('reason', key: 'exactTotalWater'), 2);
    expect(m.count('reason', key: 'coffeeKeyword'), 0);
    expect(m.count('reason', key: 'brewDefaultWater'), 1);
    expect(m.count('reason', key: 'waterKeyword'), 1);
    // plan 080 D4: preparation ambiguity now comes from a keyword tie
    expect(m.count('reason', key: 'keywordTie'), 1);
    expect(m.count('reason', key: 'skippedRateContext'), 1);
    expect(m.count('ranges'), 1);
    expect(m.count('literal'), 2);
    expect(m.count('unit', key: 'g'), 5);
    expect(m.count('unit', key: 'ml'), 2);
    expect(m.count('unit', scope: 'lang:es', key: 'g'), 2);
    expect(m.count('blockingReviews'), 1);
    expect(m.count('blockingReviews', scope: 'lang:es'), 1);
    expect(m.count('totalLike', kind: 'brew'), 2);
    expect(m.count('cumulativeRecipes'), 2);
    expect(m.count('aiMore'), 1);
    expect(m.count('aiMore', scope: 'lang:es', kind: 'preparation'), 1);
    // plan 080 D4: preparation ambiguity now comes from a keyword tie
    expect(m.count('aiMoreSourceReason', key: 'keywordTie'), 1);
    expect(m.count('aiFewer'), 0);
  });

  test('AI cutoff is strict and fewer expressions are counted', () {
    final rows = [
      _row(
        ['Add 15g coffee'],
        cor: ['Wait'],
        created: '2026-08-14 23:59:59+00',
      ),
      _row(
        ['Weigh coffee 20g water'],
        cor: ['Weigh coffee (0.08 × <FINAL_WATER_AMOUNT>)g water'],
        created: '2026-08-15 00:00:00+00',
      ),
    ];
    final m = computeCorpusMetrics(rows);
    expect(m.count('aiFewer'), 1);
    expect(m.count('aiMore'), 0);
    // plan 080 D4: preparation ambiguity now comes from a keyword tie
    expect(m.count('aiMoreSourceReason', key: 'keywordTie'), 0);
  });

  test('total-like tolerance and cumulative monotonicity', () {
    final m = computeCorpusMetrics([
      _row(['Weigh 249g water', 'Add 247.5g', 'Add 250g']),
      _row(['Prepare filter', 'Add 250g', 'Add 250g']),
      _row(['Prepare filter', 'Add 250g']),
      _row(['Prepare filter', 'Add 60g', 'Add 244g']),
      {
        ..._row(['Prepare filter', 'Add 1.49g', 'Add 2g']),
        'water': 2,
      },
    ]);
    expect(m.count('totalLike', kind: 'preparation'), 1);
    expect(m.count('totalLike', kind: 'brew'), 6);
    expect(m.count('cumulativeRecipes'), 2);
  });

  test('format is deterministic JSON containing aggregate fields only', () {
    final rows = _syntheticRows();
    final output = formatMetrics(computeCorpusMetrics(rows));
    expect(output, formatMetrics(computeCorpusMetrics(rows.reversed.toList())));
    for (final line in output.split('\n')) {
      expect(line.startsWith('METRIC '), isTrue);
      final record = jsonDecode(line.substring(7)) as Map<String, dynamic>;
      expect(
        record.keys,
        everyElement(isIn(['scope', 'kind', 'name', 'key', 'value'])),
      );
      expect(record['value'], isA<int>());
    }
    expect(output.contains('Vierte'), isFalse);
    expect(output.contains('Weigh'), isFalse);
    expect(output.contains('v60'), isFalse);
  });

  test('empty corpus and non-positive amounts emit zero totals', () {
    expect(computeCorpusMetrics([]).rowsUsed, 0);
    final m = computeCorpusMetrics([
      _row(['Weigh 20g'], coffee: 0),
      _row(['Weigh 20g'], coffee: -1),
    ]);
    expect(m.rowsUsed, 0);
    expect(m.count('skippedRows', key: 'invalidAmounts'), 2);
  });
}
