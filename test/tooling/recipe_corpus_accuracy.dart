import 'dart:convert';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'recipe_corpus_sample.dart';

const corpusLabels = [
  'coffee',
  'water',
  'fixed',
  'cumulative_target_water',
  'not_an_amount',
];

class LabelAccuracy {
  final Map<String, Map<String, int>> scopes = {};
  final Map<String, int> confusion = {};

  /// Outcome per label, keyed `diagnostics_id:step_index:char_start:char_end`.
  /// Ids and enum values only, so before/after runs can be diffed per label.
  final Map<String, String> outcomes = {};
  int orphan = 0;
  void add(String scope, bool correct) {
    final counts = scopes.putIfAbsent(
      scope,
      () => {'labelled': 0, 'correct': 0},
    );
    counts['labelled'] = counts['labelled']! + 1;
    if (correct) counts['correct'] = counts['correct']! + 1;
  }
}

/// Match the largest original-span overlap, preferring the narrower observation
/// on a tie (a literal range can be revisited by the single-amount pass).
LabelAccuracy computeLabelAccuracy(
  List<Map<String, dynamic>> rows,
  List<Map<String, dynamic>> labels,
) {
  final result = LabelAccuracy();
  final eligible = {
    for (final row in rows.where(corpusRowEligible)) row['id']: row,
  };
  result.scopes['overall'] = {'labelled': 0, 'correct': 0};
  for (final label in labels) {
    final name = label['label'] as String;
    final start = label['char_start'] as int, end = label['char_end'] as int;
    if (!corpusLabels.contains(name) || start < 0 || end <= start) {
      throw const FormatException('Invalid label.');
    }
    final row = eligible[label['diagnostics_id']];
    final index = label['step_index'] as int;
    if (row == null || index < 0 || index >= (row['src'] as List).length) {
      result.orphan++;
      continue;
    }
    final text = (row['src'] as List)[index] as String;
    if (end > text.length) throw const FormatException('Invalid label.');
    final kind = index == 0 ? RecipeStepKind.preparation : RecipeStepKind.brew;
    final amounts = RecipeExpressionService.explainStepConversion(
      text,
      kind: kind,
      coffeeAmount: (row['coffee'] as num).toDouble(),
      waterAmount: (row['water'] as num).toDouble(),
    );
    final overlaps =
        amounts
            .where((a) => a.originalStart < end && start < a.originalEnd)
            .toList()
          ..sort((a, b) {
            int overlap(RecipeAmountResolution a) =>
                (a.originalEnd < end ? a.originalEnd : end) -
                (a.originalStart > start ? a.originalStart : start);
            final size = overlap(b).compareTo(overlap(a));
            return size != 0
                ? size
                : (a.originalEnd - a.originalStart).compareTo(
                    b.originalEnd - b.originalStart,
                  );
          });
    final matched = overlaps.isEmpty ? null : overlaps.first;
    final outcome = matched == null ? 'missed' : corpusOutcome(matched);
    final expected = switch (name) {
      'coffee' => 'coffee',
      'water' || 'cumulative_target_water' => 'water',
      _ => 'literal',
    };
    final key = '$name:$outcome';
    result.confusion[key] = (result.confusion[key] ?? 0) + 1;
    result.outcomes['${label['diagnostics_id']}:$index:$start:$end'] = outcome;
    for (final scope in [
      'overall',
      'lang:${corpusLanguage(row)}',
      'kind:${kind.name}',
      'reason:${matched?.reason.name ?? 'missed'}',
    ]) {
      result.add(scope, outcome == expected);
    }
  }
  return result;
}

String formatLabelAccuracy(LabelAccuracy result) {
  String line(String scope, String name, num value, [String? key]) =>
      'METRIC ${jsonEncode({'scope': scope, 'kind': 'all', 'name': name, 'key': ?key, 'value': value})}';
  return [
    line('overall', 'orphan', result.orphan),
    for (final label in corpusLabels)
      for (final outcome in ['coffee', 'water', 'literal', 'missed'])
        line(
          'overall',
          'confusion',
          result.confusion['$label:$outcome'] ?? 0,
          '$label:$outcome',
        ),
    for (final scope in (result.scopes.keys.toList()..sort())) ...[
      line(scope, 'labelled', result.scopes[scope]!['labelled']!),
      line(scope, 'correct', result.scopes[scope]!['correct']!),
      line(
        scope,
        'accuracy',
        result.scopes[scope]!['labelled'] == 0
            ? 0
            : result.scopes[scope]!['correct']! /
                  result.scopes[scope]!['labelled']!,
      ),
    ],
  ].join('\n');
}
