import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'recipe_corpus_metrics.dart';
import 'recipe_corpus_accuracy.dart';

void main() {
  final path = Platform.environment['RECIPE_CORPUS_JSON'];
  var exists = false;
  if (path != null && path.isNotEmpty) {
    try {
      exists = File(path).existsSync();
    } catch (_) {
      // Never expose a supplied path through an exception message.
    }
  }
  test(
    'replays the recipe corpus as aggregates',
    () {
      late CorpusMetrics metrics;
      late String output;
      try {
        final decoded = jsonDecode(File(path!).readAsStringSync()) as List;
        final rows = decoded
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        metrics = computeCorpusMetrics(rows);
        output = formatMetrics(metrics);
        final labelsPath = Platform.environment['RECIPE_CORPUS_LABELS'];
        if (labelsPath != null && labelsPath.isNotEmpty) {
          final decodedLabels =
              jsonDecode(File(labelsPath).readAsStringSync()) as List;
          final labels = decodedLabels
              .map((label) => Map<String, dynamic>.from(label as Map))
              .toList();
          final accuracy = computeLabelAccuracy(rows, labels);
          output += '\n${formatLabelAccuracy(accuracy)}';
          // Optional per-label outcomes (ids, offsets and an enum; no text) for
          // diffing two converter versions label by label.
          final outcomesPath =
              Platform.environment['RECIPE_CORPUS_OUTCOMES_OUT'];
          if (outcomesPath != null && outcomesPath.isNotEmpty) {
            File(outcomesPath).writeAsStringSync(jsonEncode(accuracy.outcomes));
          }
        }
      } catch (_) {
        // JSON/typing/conversion exceptions can contain private input. Replace
        // them completely; never log the caught error or its stack trace.
        throw TestFailure('Corpus loading or processing failed.');
      }
      expect(metrics.rowsUsed, greaterThan(0));
      // ignore: avoid_print
      print(output);
    },
    skip: path == null || path.isEmpty
        ? 'RECIPE_CORPUS_JSON is unset.'
        : !exists
        ? 'Recipe corpus file is unavailable.'
        : false,
  );
}
