import 'package:diacritic/diacritic.dart';

/// Normalizes a free-text roaster string for alias-aware matching that is both
/// case- and accent-insensitive. Mirrors the server-side normalization used by
/// `resolve_roaster_profile_for_review` / `resolve_coffee_roaster_id`, i.e.
/// `lower(unaccent(trim(...)))`, so client-side review eligibility agrees with
/// how the backend links reviews and counts bags.
String normalizeRoasterName(String input) =>
    removeDiacritics(input.trim()).toLowerCase();
