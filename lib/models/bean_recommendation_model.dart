/// Plan 017 Phase 4: data layer for the "For You" bean recommendations.
///
/// Plain immutable models, no code generation. The backend contract may
/// evolve — any field can go missing or change type — so all parsing is
/// defensive: nothing here throws, and items without a usable `stock_id`,
/// `bean_name` or `roaster_name` are skipped instead of surfaced.
library;

/// Status returned by the `recommend-beans` edge function.
enum BeanRecommendationStatus {
  ok,
  insufficientHistory,
  noSupply,

  /// Anything else: unparseable payload, HTTP error (e.g. 429 rate limit),
  /// or a transport failure.
  unknown;

  /// Maps the wire value (`ok` | `insufficient_history` | `no_supply`);
  /// anything else becomes [unknown]. Never throws.
  static BeanRecommendationStatus fromWire(Object? raw) {
    switch (raw) {
      case 'ok':
        return BeanRecommendationStatus.ok;
      case 'insufficient_history':
        return BeanRecommendationStatus.insufficientHistory;
      case 'no_supply':
        return BeanRecommendationStatus.noSupply;
      default:
        return BeanRecommendationStatus.unknown;
    }
  }
}

/// One recommended bean, as returned by RPC `get_my_recommendations`.
class BeanRecommendation {
  final String stockId;
  final String? roasterProfileId;
  final String? roasterSlug;
  final String roasterName;
  final String? roasterLogoUrl;
  final String? roasterLogoMirrorUrl;
  final String? dominantColorHex;
  final String beanName;
  final String? imageUrl;
  final List<String> originCountryCodes;
  final String? processFamily;
  final String? roastLevel;
  final List<String> flavorFamilies;
  final double? priceAmount;
  final String? currency;
  final String? productUrl;

  /// One-sentence explanation of why this bean was picked.
  final String? reason;

  /// Raw `mode` from the server: `your_roaster` or `near_you`.
  final String? mode;

  const BeanRecommendation({
    required this.stockId,
    this.roasterProfileId,
    this.roasterSlug,
    required this.roasterName,
    this.roasterLogoUrl,
    this.roasterLogoMirrorUrl,
    this.dominantColorHex,
    required this.beanName,
    this.imageUrl,
    this.originCountryCodes = const [],
    this.processFamily,
    this.roastLevel,
    this.flavorFamilies = const [],
    this.priceAmount,
    this.currency,
    this.productUrl,
    this.reason,
    this.mode,
  });

  /// Parses one item of the RPC payload. Returns null when [json] is not a
  /// JSON object, or when it lacks a usable `stock_id`, `bean_name` or
  /// `roaster_name` — the caller must skip such items. Never throws.
  static BeanRecommendation? fromJson(Object? json) {
    if (json is! Map) return null;
    final stockId = _nonEmptyString(json['stock_id']);
    final beanName = _nonEmptyString(json['bean_name']);
    final roasterName = _nonEmptyString(json['roaster_name']);
    if (stockId == null || beanName == null || roasterName == null) {
      return null;
    }
    return BeanRecommendation(
      stockId: stockId,
      roasterProfileId: _stringOrNull(json['roaster_profile_id']),
      roasterSlug: _stringOrNull(json['roaster_slug']),
      roasterName: roasterName,
      roasterLogoUrl: _stringOrNull(json['roaster_logo_url']),
      roasterLogoMirrorUrl: _stringOrNull(json['roaster_logo_mirror_url']),
      dominantColorHex: _stringOrNull(json['dominant_color_hex']),
      beanName: beanName,
      imageUrl: _stringOrNull(json['image_url']),
      originCountryCodes: _stringList(json['origin_country_codes']),
      processFamily: _stringOrNull(json['process_family']),
      roastLevel: _stringOrNull(json['roast_level']),
      flavorFamilies: _stringList(json['flavor_families']),
      priceAmount: _doubleOrNull(json['price_amount']),
      currency: _stringOrNull(json['currency']),
      productUrl: _stringOrNull(json['product_url']),
      reason: _stringOrNull(json['reason']),
      mode: _stringOrNull(json['mode']),
    );
  }

  static String? _nonEmptyString(Object? value) {
    final v = value is String ? value.trim() : null;
    return (v == null || v.isEmpty) ? null : v;
  }

  static String? _stringOrNull(Object? value) => value is String ? value : null;

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static double? _doubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// The full answer of RPC `get_my_recommendations`.
class RecommendationResult {
  final bool hasRecommendations;
  final DateTime? generatedAt;
  final bool stale;
  final List<BeanRecommendation> items;

  const RecommendationResult({
    required this.hasRecommendations,
    this.generatedAt,
    this.stale = false,
    this.items = const [],
  });

  /// Parses the RPC payload. Returns null when [json] is not a JSON object
  /// (e.g. the RPC returned null because there is no session). Unusable
  /// items are skipped. Never throws.
  static RecommendationResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final dynamic rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .map(BeanRecommendation.fromJson)
              .whereType<BeanRecommendation>()
              .toList(growable: false)
        : const <BeanRecommendation>[];
    final dynamic generatedAt = json['generated_at'];
    return RecommendationResult(
      hasRecommendations: json['has_recommendations'] is bool
          ? json['has_recommendations'] as bool
          : false,
      generatedAt: generatedAt is String
          ? DateTime.tryParse(generatedAt)
          : null,
      stale: json['stale'] is bool ? json['stale'] as bool : false,
      items: items,
    );
  }
}

/// One in-stock bean of a roaster, as returned by RPC `get_roaster_stock`.
class RoasterStockItem {
  final String stockId;
  final String beanName;
  final String? imageUrl;
  final List<String> originCountryCodes;
  final String? processFamily;
  final String? roastLevel;
  final List<String> flavorFamilies;
  final bool isDecaf;
  final double? priceAmount;
  final String? currency;
  final String? productUrl;
  final DateTime? firstSeenAt;

  const RoasterStockItem({
    required this.stockId,
    required this.beanName,
    this.imageUrl,
    this.originCountryCodes = const [],
    this.processFamily,
    this.roastLevel,
    this.flavorFamilies = const [],
    this.isDecaf = false,
    this.priceAmount,
    this.currency,
    this.productUrl,
    this.firstSeenAt,
  });

  /// Parses one item of the RPC payload. Returns null when [json] is not a
  /// JSON object, or when it lacks a usable `stock_id` or `bean_name` — the
  /// caller must skip such items. Never throws.
  static RoasterStockItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final stockId = _nonEmptyString(json['stock_id']);
    final beanName = _nonEmptyString(json['bean_name']);
    if (stockId == null || beanName == null) return null;
    return RoasterStockItem(
      stockId: stockId,
      beanName: beanName,
      imageUrl: _stringOrNull(json['image_url']),
      originCountryCodes: _stringList(json['origin_country_codes']),
      processFamily: _stringOrNull(json['process_family']),
      roastLevel: _stringOrNull(json['roast_level']),
      flavorFamilies: _stringList(json['flavor_families']),
      isDecaf: json['is_decaf'] is bool ? json['is_decaf'] as bool : false,
      priceAmount: _doubleOrNull(json['price_amount']),
      currency: _stringOrNull(json['currency']),
      productUrl: _stringOrNull(json['product_url']),
      firstSeenAt: json['first_seen_at'] is String
          ? DateTime.tryParse(json['first_seen_at'] as String)
          : null,
    );
  }

  static String? _nonEmptyString(Object? value) {
    final v = value is String ? value.trim() : null;
    return (v == null || v.isEmpty) ? null : v;
  }

  static String? _stringOrNull(Object? value) => value is String ? value : null;

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static double? _doubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// The full answer of RPC `get_roaster_stock`: `{ "total": 10, "items": [...] }`.
class RoasterStockResult {
  /// Total in-stock items server-side. Informational: [items] is what the
  /// section can actually show (already capped by the fetch limit).
  final int total;
  final List<RoasterStockItem> items;

  const RoasterStockResult({this.total = 0, this.items = const []});

  /// Parses the RPC payload. Returns an empty result when [json] is not a
  /// JSON object (e.g. the RPC returned null). Unusable items are skipped.
  /// Never throws.
  static RoasterStockResult fromJson(Object? json) {
    if (json is! Map) return const RoasterStockResult();
    final dynamic rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .map(RoasterStockItem.fromJson)
              .whereType<RoasterStockItem>()
              .toList(growable: false)
        : const <RoasterStockItem>[];
    final dynamic total = json['total'];
    return RoasterStockResult(
      total: total is num ? total.toInt() : 0,
      items: items,
    );
  }
}

/// Plan 086: one of the four taste dimensions the user can adjust.
enum TasteDimension {
  origin('origin'),
  process('process'),
  roast('roast'),
  flavor('flavor');

  const TasteDimension(this.wire);

  /// Value used by RPCs `get_my_taste_profile` / `set_my_taste_preference`.
  final String wire;

  static TasteDimension? fromWire(Object? raw) {
    for (final d in values) {
      if (d.wire == raw) return d;
    }
    return null;
  }

  /// Normalises a value the way `set_my_taste_preference` does: origins are
  /// upper-case ISO alpha-2 codes, everything else lower-case.
  String normalize(String value) {
    final trimmed = value.trim();
    return this == TasteDimension.origin
        ? trimmed.toUpperCase()
        : trimmed.toLowerCase();
  }
}

/// Plan 086: a stored More / Less / Never adjustment.
enum TastePreference {
  more('more'),
  less('less'),
  never('never');

  const TastePreference(this.wire);

  final String wire;

  static TastePreference? fromWire(Object? raw) {
    for (final p in values) {
      if (p.wire == raw) return p;
    }
    return null;
  }
}

/// One entry of a computed taste distribution, e.g. `ET` at 0.43.
class TasteShare {
  final String value;

  /// Share of this value in the user's history, 0..1.
  final double share;

  const TasteShare({required this.value, required this.share});
}

/// One stored adjustment.
class TasteAdjustment {
  final TasteDimension dimension;
  final String value;
  final TastePreference preference;

  const TasteAdjustment({
    required this.dimension,
    required this.value,
    required this.preference,
  });
}

/// Plan 086: the answer of RPC `get_my_taste_profile` — the computed history
/// (before adjustments), counts, and the user's stored adjustments.
class TasteProfile {
  /// Top values per dimension, sorted by share descending. Every dimension
  /// is present (possibly empty).
  final Map<TasteDimension, List<TasteShare>> distributions;
  final int beanCount;
  final int brewCount;

  /// Same threshold as `recommend-beans`: enough history to suggest beans.
  final bool enoughHistory;
  final List<TasteAdjustment> preferences;

  const TasteProfile({
    this.distributions = const {},
    this.beanCount = 0,
    this.brewCount = 0,
    this.enoughHistory = false,
    this.preferences = const [],
  });

  List<TasteShare> sharesFor(TasteDimension dimension) =>
      distributions[dimension] ?? const [];

  /// The stored adjustment for [value] in [dimension], or null.
  TastePreference? preferenceFor(TasteDimension dimension, String value) {
    final key = dimension.normalize(value);
    for (final p in preferences) {
      if (p.dimension == dimension && p.value == key) return p.preference;
    }
    return null;
  }

  /// Values the user marked Never in [dimension].
  Set<String> neverValues(TasteDimension dimension) => {
    for (final p in preferences)
      if (p.dimension == dimension && p.preference == TastePreference.never)
        p.value,
  };

  /// Copy with one adjustment set ([preference] non-null) or cleared (null).
  TasteProfile withPreference(
    TasteDimension dimension,
    String value,
    TastePreference? preference,
  ) {
    final key = dimension.normalize(value);
    final next = [
      for (final p in preferences)
        if (!(p.dimension == dimension && p.value == key)) p,
      if (preference != null)
        TasteAdjustment(
          dimension: dimension,
          value: key,
          preference: preference,
        ),
    ];
    return TasteProfile(
      distributions: distributions,
      beanCount: beanCount,
      brewCount: brewCount,
      enoughHistory: enoughHistory,
      preferences: List.unmodifiable(next),
    );
  }

  /// Parses the RPC payload. Returns null when [json] is not a JSON object
  /// (the RPC returns null without a session). Unusable entries are skipped.
  /// Never throws.
  static TasteProfile? fromJson(Object? json) {
    if (json is! Map) return null;
    final distributions = <TasteDimension, List<TasteShare>>{};
    for (final dimension in TasteDimension.values) {
      final raw = json[dimension.wire];
      final shares = <TasteShare>[];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is! Map) continue;
          final value = entry['value'];
          final share = entry['share'];
          final parsedShare = share is num
              ? share.toDouble()
              : (share is String ? double.tryParse(share) : null);
          if (value is! String || value.trim().isEmpty || parsedShare == null) {
            continue;
          }
          shares.add(
            TasteShare(value: dimension.normalize(value), share: parsedShare),
          );
        }
      }
      shares.sort((a, b) => b.share.compareTo(a.share));
      distributions[dimension] = List.unmodifiable(shares);
    }
    final preferences = <TasteAdjustment>[];
    final rawPrefs = json['preferences'];
    if (rawPrefs is List) {
      for (final entry in rawPrefs) {
        if (entry is! Map) continue;
        final dimension = TasteDimension.fromWire(entry['dimension']);
        final preference = TastePreference.fromWire(entry['preference']);
        final value = entry['value'];
        if (dimension == null ||
            preference == null ||
            value is! String ||
            value.trim().isEmpty) {
          continue;
        }
        preferences.add(
          TasteAdjustment(
            dimension: dimension,
            value: dimension.normalize(value),
            preference: preference,
          ),
        );
      }
    }
    int count(Object? raw) => raw is num ? raw.toInt() : 0;
    return TasteProfile(
      distributions: Map.unmodifiable(distributions),
      beanCount: count(json['bean_count']),
      brewCount: count(json['brew_count']),
      enoughHistory: json['enough_history'] == true,
      preferences: List.unmodifiable(preferences),
    );
  }
}
