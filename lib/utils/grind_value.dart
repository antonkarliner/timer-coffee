class ParsedGrindValue {
  const ParsedGrindValue({required this.value, required this.contextKey});

  final double value;
  final String contextKey;
}

/// Parses a non-negative leading number and its normalized free-text context.
///
/// Context comparison is deliberately conservative: meaningful tokens such as
/// a grinder name or `clicks` are retained, while case, whitespace, and
/// parentheses are normalized.
ParsedGrindValue? parseGrindSetting(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)').firstMatch(raw);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!.replaceFirst(',', '.'));
  if (value == null) return null;
  final contextKey = raw
      .substring(match.end)
      .toLowerCase()
      .replaceAll(RegExp(r'[()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return ParsedGrindValue(value: value, contextKey: contextKey);
}

/// Compatibility wrapper for callers that only need the leading number.
double? parseGrindValue(String? raw) => parseGrindSetting(raw)?.value;
