/// Storage/list conversion for brew diary custom tags.
///
/// Tags are stored on `user_stats.tags` as a single nullable comma-separated
/// string, exactly like `coffee_beans.tasting_notes` — joined with
/// [diaryTagSeparator]. This is the single place that converts between that
/// storage string and a display-ready `List<String>`.
library;

/// The separator used to join/split the stored tags string.
const String diaryTagSeparator = ', ';

/// Maximum number of tags a diary entry may carry.
const int diaryTagsMaxCount = 10;

/// Maximum length, in characters, of a single normalized tag.
const int diaryTagsMaxLength = 30;

/// Parses a stored tags string into a list of trimmed, non-empty tags.
///
/// Returns an empty list for null/blank input.
List<String> diaryTagsFromStorage(String? stored) {
  if (stored == null || stored.trim().isEmpty) return const [];
  return stored
      .split(diaryTagSeparator)
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}

/// Normalizes raw tag input so every write path is safe by construction.
///
/// The comma is the storage separator, so it is stripped from every tag.
/// Each tag is trimmed, internal whitespace runs are collapsed to a single
/// space, commas are removed, and the result is truncated to
/// [diaryTagsMaxLength] characters (then re-trimmed); tags that end up empty
/// are dropped. Tags are deduplicated case-insensitively, keeping the
/// first-seen casing and order, and the list is capped at [diaryTagsMaxCount]
/// entries.
List<String> normalizeDiaryTags(Iterable<String> raw) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final tag in raw) {
    if (normalized.length >= diaryTagsMaxCount) break;
    var cleaned = tag
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(',', '');
    if (cleaned.length > diaryTagsMaxLength) {
      cleaned = cleaned.substring(0, diaryTagsMaxLength);
    }
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) continue;
    if (seen.add(cleaned.toLowerCase())) {
      normalized.add(cleaned);
    }
  }
  return normalized;
}

/// Returns [tags] plus the not-yet-committed [pendingText] from a tag input
/// field, so saving never silently drops text the user typed but did not
/// submit as a chip. Normalization (dedupe, caps) happens later in
/// [diaryTagsToStorage].
List<String> diaryTagsWithPending(List<String> tags, String pendingText) {
  final pending = pendingText.trim();
  return pending.isEmpty ? tags : [...tags, pending];
}

/// Joins a list of tags into the storage string format.
///
/// Normalizes [tags] first (see [normalizeDiaryTags]), so every write path
/// is safe by construction. Returns null for an empty (or empty-after-
/// normalization) list.
String? diaryTagsToStorage(List<String> tags) {
  final normalized = normalizeDiaryTags(tags);
  if (normalized.isEmpty) return null;
  return normalized.join(diaryTagSeparator);
}
