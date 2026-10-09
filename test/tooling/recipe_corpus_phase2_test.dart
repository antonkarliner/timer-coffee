import 'package:flutter_test/flutter_test.dart';
import 'recipe_corpus_phase2_checks.dart';

void main() {
  test(
    'synthetic sample, offline page, path guard, accuracy and original offsets',
    runPhase2Checks,
  );
}
