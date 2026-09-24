final RegExp _numberUnitWhitespace = RegExp(
  r'(\d)[ \t]+(?=[\p{L}°%])',
  unicode: true,
);

/// Keeps a number and its unit together when Flutter breaks text into lines.
///
/// Flutter's line breaker honours U+00A0, so the pair wraps as one unit.
///
/// Display-only: apply it where a string is handed to a `Text`, never to a
/// step description that is stored, sent to a Live Activity, or parsed by
/// `RecipeExpressionService` — its amount regexes expect ordinary spaces.
String keepNumbersWithUnits(String text) => text.replaceAllMapped(
  _numberUnitWhitespace,
  (match) => '${match[1]}\u00A0',
);
