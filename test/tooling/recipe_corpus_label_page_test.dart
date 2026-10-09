import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'recipe_corpus_label_page.dart';
import 'recipe_corpus_sample.dart';

void main() {
  final input = Platform.environment['RECIPE_CORPUS_JSON'];
  final output = Platform.environment['RECIPE_CORPUS_PAGE_OUT'];
  test(
    'writes the offline labelling page outside the repository',
    () {
      late LabelingSample sample;
      try {
        // Validate before loading private input or constructing the document.
        final destination = labelingPageOutput(output!);
        final decoded = jsonDecode(File(input!).readAsStringSync()) as List;
        final rows = decoded
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        sample = buildLabelingSample(rows);
        destination.writeAsStringSync(buildLabelingPage(sample, rows));
      } catch (_) {
        throw TestFailure('Corpus loading, processing or page output failed.');
      }
      for (final entry in sample.stratumCounts.entries) {
        // ignore: avoid_print
        print('SAMPLE ${entry.key} ${entry.value}');
      }
      // ignore: avoid_print
      print('SAMPLE total ${sample.items.length}');
    },
    skip: input == null || input.isEmpty || output == null || output.isEmpty
        ? 'RECIPE_CORPUS_JSON or RECIPE_CORPUS_PAGE_OUT is unset.'
        : false,
  );
}
