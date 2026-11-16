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
      hasRecommendations:
          json['has_recommendations'] is bool
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
