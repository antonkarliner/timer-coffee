import 'dart:math';

import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';

/// Text-free identity and converter metadata for one labelling task.
class LabelingItem {
  final int diagnosticsId, stepIndex;
  final int? originalStart, originalEnd;
  final String? outcome, reason;
  final String language, stepKind;
  final List<String> strata;
  const LabelingItem({
    required this.diagnosticsId,
    required this.stepIndex,
    this.originalStart,
    this.originalEnd,
    this.outcome,
    this.reason,
    required this.language,
    required this.stepKind,
    required this.strata,
  });
  bool get findMissed => originalStart == null;
  String get identity =>
      '$diagnosticsId:$stepIndex:$originalStart:$originalEnd';
}

class LabelingSample {
  final List<LabelingItem> items;
  final Map<String, int> stratumCounts;
  LabelingSample(List<LabelingItem> items)
    : items = List.unmodifiable(items),
      stratumCounts = Map.unmodifiable({
        for (final name in corpusStrata)
          name: items.where((item) => item.strata.contains(name)).length,
      });
}

const corpusStrata = [
  'ai_more',
  'ambiguous',
  'suspect',
  'lang_other',
  'random_en',
  'random_es',
];

/// Matches Phase 1 eligibility; malformed input is handled by the entrypoint.
bool corpusRowEligible(Map<String, dynamic> row) {
  if (row['operator'] == true) return false;
  final coffee = row['coffee'] as num?;
  final water = row['water'] as num?;
  return coffee != null &&
      water != null &&
      coffee.isFinite &&
      water.isFinite &&
      coffee > 0 &&
      water > 0 &&
      (row['src'] as List).length == (row['cor'] as List).length;
}

String corpusLanguage(Map<String, dynamic> row) {
  final primary = (row['locale'] as String? ?? '')
      .toLowerCase()
      .split(RegExp('[-_]'))
      .first;
  return RegExp(r'^[a-z]{2,3}$').hasMatch(primary) ? primary : 'und';
}

List<BrewStepModel> corpusSteps(List<String> descriptions) => [
  for (var i = 0; i < descriptions.length; i++)
    BrewStepModel(
      id: 'corpus-step-$i',
      order: i + 1,
      description: descriptions[i],
      time: Duration.zero,
    ),
];
String corpusOutcome(RecipeAmountResolution amount) =>
    amount.placeholder == RecipeExpressionService.finalCoffeeAmount
    ? 'coffee'
    : amount.placeholder == RecipeExpressionService.finalWaterAmount
    ? 'water'
    : 'literal';

/// Mandatory strata are complete. Optional candidates are randomly capped per
/// language, assigned to their first qualifying stratum, then apportioned using
/// largest remainders. Counts include every qualifying stratum, so may overlap.
LabelingSample buildLabelingSample(
  List<Map<String, dynamic>> rows, {
  int seed = 80,
  int target = 400,
}) {
  final candidates = <String, LabelingItem>{};
  final expression = RegExp(r'(?:x|×)\s*<final_', caseSensitive: false);
  final ordered = rows.where(corpusRowEligible).toList()
    ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
  for (final row in ordered) {
    final coffee = (row['coffee'] as num).toDouble(),
        water = (row['water'] as num).toDouble();
    final src = (row['src'] as List).cast<String>();
    final source = RecipeExpressionService.processStepsForSavingDetailed(
      corpusSteps(src),
      coffee,
      water,
    );
    final created = DateTime.tryParse(row['created_at'] as String? ?? '');
    final ai =
        created != null && created.toUtc().isBefore(DateTime.utc(2026, 8, 15))
        ? RecipeExpressionService.processStepsForSavingDetailed(
            corpusSteps((row['cor'] as List).cast<String>()),
            coffee,
            water,
          )
        : null;
    final language = corpusLanguage(row);
    for (var i = 0; i < src.length; i++) {
      final kind = i == 0 ? RecipeStepKind.preparation : RecipeStepKind.brew;
      final amounts = RecipeExpressionService.explainStepConversion(
        src[i],
        kind: kind,
        coffeeAmount: coffee,
        waterAmount: water,
      );
      final more =
          ai != null &&
          expression.allMatches(ai.steps[i].description).length >
              expression.allMatches(source.steps[i].description).length;
      if (more && amounts.isEmpty) {
        final item = LabelingItem(
          diagnosticsId: row['id'] as int,
          stepIndex: i,
          language: language,
          stepKind: kind.name,
          strata: const ['ai_more'],
        );
        candidates[item.identity] = item;
      }
      for (final a in amounts) {
        final strata = <String>[
          if (more) 'ai_more',
          if (a.reason == RecipeAmountResolutionReason.keywordTie ||
              a.reason == RecipeAmountResolutionReason.preparationAmbiguous ||
              source.stepResults[i].hasBlockingIssues)
            'ambiguous',
          if (i == 0 ||
              a.value > 1.02 * water ||
              (a.reason == RecipeAmountResolutionReason.brewDefaultWater &&
                  a.value <= 3 * coffee))
            'suspect',
          if (language != 'en' && language != 'es') 'lang_other',
          if (language == 'en') 'random_en',
          if (language == 'es') 'random_es',
        ];
        final item = LabelingItem(
          diagnosticsId: row['id'] as int,
          stepIndex: i,
          originalStart: a.originalStart,
          originalEnd: a.originalEnd,
          outcome: corpusOutcome(a),
          reason: a.reason.name,
          language: language,
          stepKind: kind.name,
          strata: List.unmodifiable(strata),
        );
        candidates.putIfAbsent(item.identity, () => item);
      }
    }
  }
  final rng = Random(seed);
  final all = candidates.values.toList();
  final randomEligible = <String>{};
  for (final language
      in (all.map((i) => i.language).toSet().toList()..sort())) {
    final group =
        all.where((i) => !i.findMissed && i.language == language).toList()
          ..shuffle(rng);
    randomEligible.addAll(
      group
          .take(language == 'en' || language == 'es' ? 80 : 40)
          .map((i) => i.identity),
    );
  }
  final selected = all
      .where(
        (i) => i.strata.contains('ai_more') || i.strata.contains('ambiguous'),
      )
      .toList();
  final buckets = <List<LabelingItem>>[[], [], [], []];
  for (final item in all.where((i) => !selected.contains(i))) {
    if (item.strata.contains('suspect')) {
      buckets[0].add(item);
    } else if (randomEligible.contains(item.identity)) {
      buckets[item.strata.contains('lang_other')
              ? 1
              : item.language == 'en'
              ? 2
              : 3]
          .add(item);
    }
  }
  final available = buckets.fold<int>(0, (n, b) => n + b.length);
  final budget = min(max(0, target - selected.length), available);
  if (available > 0) {
    final quotas = buckets.map((b) => budget * b.length / available).toList();
    final sizes = quotas.map((q) => q.floor()).toList();
    final priority = [0, 1, 2, 3]
      ..sort((a, b) => (quotas[b] - sizes[b]).compareTo(quotas[a] - sizes[a]));
    var remaining = budget - sizes.fold<int>(0, (a, b) => a + b);
    for (final index in priority) {
      if (remaining-- > 0) sizes[index]++;
    }
    for (var i = 0; i < buckets.length; i++) {
      buckets[i].shuffle(rng);
      selected.addAll(buckets[i].take(sizes[i]));
    }
  }
  selected.sort((a, b) {
    final priority = corpusStrata
        .indexOf(a.strata.first)
        .compareTo(corpusStrata.indexOf(b.strata.first));
    return priority != 0 ? priority : a.identity.compareTo(b.identity);
  });
  return LabelingSample(selected);
}
