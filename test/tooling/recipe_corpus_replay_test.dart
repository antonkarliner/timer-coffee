import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'recipe_corpus_metrics.dart';

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
