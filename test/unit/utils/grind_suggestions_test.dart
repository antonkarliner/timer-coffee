import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/utils/grind_suggestions.dart';

void main() {
  group('mergeGrindSuggestionLists', () {
    test('brew-history values precede bean values', () {
      final merged = mergeGrindSuggestionLists(['24 clicks'], ['Medium-fine']);
      expect(merged, ['24 clicks', 'Medium-fine']);
    });

    test('a value present in both appears once, keeping brew-history casing', () {
      final merged = mergeGrindSuggestionLists(['Medium-Fine'], ['medium-fine']);
      expect(merged, ['Medium-Fine']);
    });

    test('case-insensitive dedupe collapses Medium-Fine and medium-fine', () {
      final merged = mergeGrindSuggestionLists(
        ['Medium-Fine'],
        ['medium-fine', 'Coarse'],
      );
      expect(merged, ['Medium-Fine', 'Coarse']);
    });

    test('whitespace is trimmed and dedupes against the trimmed form', () {
      final merged = mergeGrindSuggestionLists(['  24 clicks  '], ['24 clicks']);
      expect(merged, ['24 clicks']);
    });

    test('empty and whitespace-only strings are dropped', () {
      final merged = mergeGrindSuggestionLists(
        ['', '   ', '24 clicks'],
        ['  ', 'Fine'],
      );
      expect(merged, ['24 clicks', 'Fine']);
    });

    test('both inputs empty returns an empty list', () {
      final merged = mergeGrindSuggestionLists([], []);
      expect(merged, isEmpty);
    });

    test('only brew-history has values', () {
      final merged = mergeGrindSuggestionLists(['24 clicks', 'Fine'], []);
      expect(merged, ['24 clicks', 'Fine']);
    });

    test('only bean values has values', () {
      final merged = mergeGrindSuggestionLists([], ['24 clicks', 'Fine']);
      expect(merged, ['24 clicks', 'Fine']);
    });

    test('order within each source is preserved', () {
      final merged = mergeGrindSuggestionLists(
        ['C', 'A', 'B'],
        ['Z', 'X', 'Y'],
      );
      expect(merged, ['C', 'A', 'B', 'Z', 'X', 'Y']);
    });

    test('duplicate values within the same source keep only the first', () {
      final merged = mergeGrindSuggestionLists(
        ['24 clicks', '24 CLICKS'],
        [],
      );
      expect(merged, ['24 clicks']);
    });
  });

  group('mergedGrindSizeSuggestions', () {
    test('returns the same result as the sync version', () async {
      final brewHistory = ['24 clicks', 'Medium-Fine'];
      final beans = ['medium-fine', 'Coarse'];

      final asyncResult = await mergedGrindSizeSuggestions(
        brewHistoryGrinds: Future.value(brewHistory),
        beanGrinds: Future.value(beans),
      );
      final syncResult = mergeGrindSuggestionLists(brewHistory, beans);

      expect(asyncResult, syncResult);
    });

    test('awaits both futures concurrently and merges empty inputs', () async {
      final result = await mergedGrindSizeSuggestions(
        brewHistoryGrinds: Future.value(<String>[]),
        beanGrinds: Future.value(<String>[]),
      );
      expect(result, isEmpty);
    });
  });
}
