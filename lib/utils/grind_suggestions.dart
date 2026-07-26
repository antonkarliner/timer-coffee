// Merges grind-size suggestions from brew history and bean records.
//
// Kept separate from `grind_value.dart` (which parses a single grind
// string), since this file is about combining and deduplicating whole
// suggestion lists from two sources.

/// Awaits both suggestion sources concurrently and merges them.
///
/// Brew-history values are listed first, since what the user has actually
/// brewed with is the more relevant suggestion; bean values not already
/// present follow. See [mergeGrindSuggestionLists] for the merge semantics.
Future<List<String>> mergedGrindSizeSuggestions({
  required Future<List<String>> brewHistoryGrinds,
  required Future<List<String>> beanGrinds,
}) async {
  final results = await Future.wait([brewHistoryGrinds, beanGrinds]);
  return mergeGrindSuggestionLists(results[0], results[1]);
}

/// Pure, synchronous merge of two grind-size suggestion lists.
///
/// Brew-history values come first, then bean values not already present.
/// Deduplication is case-insensitive on the trimmed value, keeping the
/// first occurrence's original (trimmed) casing. Entries that are empty
/// after trimming are dropped. Order within each source is otherwise
/// preserved, and results are neither sorted nor ranked by frequency.
List<String> mergeGrindSuggestionLists(
  List<String> brewHistory,
  List<String> beans,
) {
  final seen = <String>{};
  final merged = <String>[];

  void addAll(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) {
        merged.add(trimmed);
      }
    }
  }

  addAll(brewHistory);
  addAll(beans);

  return merged;
}
