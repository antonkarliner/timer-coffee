import 'dart:convert';
import 'dart:math' as math;

import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';

typedef CorpusMetricKey = ({
  String scope,
  String kind,
  String name,
  String key,
});

/// Aggregate counters only: never retains descriptions, recipe names or IDs.
class CorpusMetrics {
  final Map<CorpusMetricKey, int> counts;

  CorpusMetrics._(Map<CorpusMetricKey, int> counts)
    : counts = Map.unmodifiable(counts);

  int count(
    String name, {
    String scope = 'overall',
    String kind = 'all',
    String key = '',
  }) => counts[(scope: scope, kind: kind, name: name, key: key)] ?? 0;

  int get rowsUsed => count('rows');
}

final _scalingExpression = RegExp(r'(?:x|×)\s*<final_', caseSensitive: false);
final _cutoff = DateTime.utc(2026, 8, 15);

/// Counts converter amount observations (ranges use their upper bound).
/// An unchanged range may be revisited as a single amount by the converter.
/// Such a visit is retained because its second decision can differ.
/// Kind-specific rows count reviews containing at least one step of that kind.
/// Cumulative style requires at least two water-resolved brew amounts, in source
/// order, strictly increasing, with the final amount within 2% of the water total.
/// AI reason histograms describe the source step, rather than the AI rewrite.
CorpusMetrics computeCorpusMetrics(List<Map<String, dynamic>> rows) {
  final counts = <CorpusMetricKey, int>{};
  void add(
    String scope,
    String kind,
    String name, [
    String key = '',
    int n = 1,
  ]) {
    final metric = (scope: scope, kind: kind, name: name, key: key);
    counts[metric] = (counts[metric] ?? 0) + n;
  }

  // Always emit the principal totals, including for an empty/all-skipped file.
  for (final name in [
    'rows',
    'steps',
    'amounts',
    'ranges',
    'literal',
    'blockingReviews',
    'totalLike',
    'cumulativeRecipes',
    'aiMore',
    'aiFewer',
  ]) {
    add('overall', 'all', name, '', 0);
  }
  for (final key in ['operator', 'invalidAmounts', 'stepCountMismatch']) {
    add('overall', 'all', 'skippedRows', key, 0);
  }

  for (final row in rows) {
    if (row['operator'] == true) {
      add('overall', 'all', 'skippedRows', 'operator');
      continue;
    }
    final coffee = (row['coffee'] as num?)?.toDouble();
    final water = (row['water'] as num?)?.toDouble();
    if (coffee == null ||
        water == null ||
        !coffee.isFinite ||
        !water.isFinite ||
        coffee <= 0 ||
        water <= 0) {
      add('overall', 'all', 'skippedRows', 'invalidAmounts');
      continue;
    }
    final src = (row['src'] as List).cast<String>();
    final cor = (row['cor'] as List).cast<String>();
    if (src.length != cor.length) {
      add('overall', 'all', 'skippedRows', 'stepCountMismatch');
      continue;
    }
    // Restrict emitted locale labels to language codes, never arbitrary input.
    final primary = (row['locale'] as String? ?? '')
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    final language = RegExp(r'^[a-z]{2,3}$').hasMatch(primary)
        ? primary
        : 'und';
    final scopes = ['overall', 'lang:$language'];
    final source = RecipeExpressionService.processStepsForSavingDetailed(
      _steps(src),
      coffee,
      water,
    );
    final created = DateTime.tryParse(row['created_at'] as String? ?? '');
    final compareAi = created != null && created.toUtc().isBefore(_cutoff);
    final corrected = compareAi
        ? RecipeExpressionService.processStepsForSavingDetailed(
            _steps(cor),
            coffee,
            water,
          )
        : null;
    for (final scope in scopes) {
      add(scope, 'all', 'rows');
      if (source.hasBlockingIssues) add(scope, 'all', 'blockingReviews');
      if (src.isNotEmpty) add(scope, 'preparation', 'rows');
      if (src.length > 1) add(scope, 'brew', 'rows');
    }

    final brewWater = <double>[];
    for (var index = 0; index < src.length; index++) {
      final kind = index == 0
          ? RecipeStepKind.preparation
          : RecipeStepKind.brew;
      final amounts = RecipeExpressionService.explainStepConversion(
        src[index],
        kind: kind,
        coffeeAmount: coffee,
        waterAmount: water,
      );
      final more =
          corrected != null &&
          _scalingExpression
                  .allMatches(corrected.steps[index].description)
                  .length >
              _scalingExpression
                  .allMatches(source.steps[index].description)
                  .length;
      final fewer =
          corrected != null &&
          _scalingExpression
                  .allMatches(corrected.steps[index].description)
                  .length <
              _scalingExpression
                  .allMatches(source.steps[index].description)
                  .length;
      for (final amount in amounts) {
        if (kind == RecipeStepKind.brew &&
            amount.placeholder == RecipeExpressionService.finalWaterAmount) {
          brewWater.add(amount.value);
        }
      }
      for (final scope in scopes) {
        for (final kindName in ['all', kind.name]) {
          add(scope, kindName, 'steps');
          add(scope, kindName, 'amounts', '', amounts.length);
          if (more) add(scope, kindName, 'aiMore');
          if (fewer) add(scope, kindName, 'aiFewer');
          for (final amount in amounts) {
            add(scope, kindName, 'reason', amount.reason.name);
            if (amount.isRange) add(scope, kindName, 'ranges');
            if (amount.placeholder == null) add(scope, kindName, 'literal');
            if ((amount.value - water).abs() <= math.max(0.5, water * 0.01)) {
              add(scope, kindName, 'totalLike');
            }
            if (more) {
              add(scope, kindName, 'aiMoreSourceReason', amount.reason.name);
            }
          }
        }
        for (final amount in amounts) {
          add(scope, 'all', 'unit', amount.unit.toLowerCase());
        }
      }
    }
    if (brewWater.length >= 2 &&
        Iterable.generate(
          brewWater.length - 1,
        ).every((i) => brewWater[i + 1] > brewWater[i]) &&
        (brewWater.last - water).abs() <= water * 0.02) {
      for (final scope in scopes) {
        add(scope, 'all', 'cumulativeRecipes');
      }
    }
  }
  return CorpusMetrics._(counts);
}

List<BrewStepModel> _steps(List<String> descriptions) => [
  for (var i = 0; i < descriptions.length; i++)
    BrewStepModel(
      id: 'corpus-step-$i',
      order: i + 1,
      description: descriptions[i],
      time: Duration.zero,
    ),
];

/// Deterministic compact JSON lines containing only aggregate counters/labels.
String formatMetrics(CorpusMetrics metrics) {
  final keys = metrics.counts.keys.toList()
    ..sort((a, b) {
      for (final comparison in [
        a.scope.compareTo(b.scope),
        a.kind.compareTo(b.kind),
        a.name.compareTo(b.name),
        a.key.compareTo(b.key),
      ]) {
        if (comparison != 0) return comparison;
      }
      return 0;
    });
  return keys
      .map(
        (metric) =>
            'METRIC ${jsonEncode({'scope': metric.scope, 'kind': metric.kind, 'name': metric.name, if (metric.key.isNotEmpty) 'key': metric.key, 'value': metrics.counts[metric]})}',
      )
      .join('\n');
}
