import 'dart:convert';
import 'package:flutter/material.dart';

/// Lightweight model for Gift Box offers pulled directly from Supabase.
/// No Drift tables are used; the data is kept in-memory per fetch.
class GiftOffer {
  final String id;
  final String partnerName;
  final String? discountLabel; // legacy fallback
  final String? discountText;
  final String? cta;
  final double? discountMinPercent;
  final double? discountMaxPercent;
  final String? promoCode;
  final List<String> regions;
  final String? description;
  final String? termsAndConditions;
  final String? websiteUrl;
  final String? imageUrl;
  final String? festiveColor;
  final DateTime? validFrom;
  final DateTime? validTo;
  final int? priority;
  final DateTime? updatedAt;

  /// The locale that successfully matched localization content for this offer.
  final Locale localeUsed;

  GiftOffer({
    required this.id,
    required this.partnerName,
    required this.localeUsed,
    this.discountLabel,
    this.discountText,
    this.cta,
    this.discountMinPercent,
    this.discountMaxPercent,
    this.promoCode,
    this.regions = const [],
    this.description,
    this.termsAndConditions,
    this.websiteUrl,
    this.imageUrl,
    this.festiveColor,
    this.validFrom,
    this.validTo,
    this.priority,
    this.updatedAt,
  });

  /// Builds from Supabase row with `localizations` JSONB column shaped like
  /// `{ "en": {"title": "...", "description": "...", "terms": "...", "cta": "..."}, ... }`.
  factory GiftOffer.fromMap(Map<String, dynamic> json, Locale requestedLocale) {
    final dynamic rawLocalizations = json['localizations'];
    Map<String, dynamic> localizations = {};
    if (rawLocalizations is Map) {
      localizations = rawLocalizations.cast<String, dynamic>();
    } else if (rawLocalizations is String) {
      try {
        final decoded = jsonDecode(rawLocalizations);
        if (decoded is Map) {
          localizations = decoded.cast<String, dynamic>();
        }
      } catch (_) {
        // ignore decode errors and keep empty map
      }
    }
    final normalizedRequested = _normalizeLocale(requestedLocale);

    // Fallback chain: full locale (e.g., en-US), language code (en), then en
    Map<String, dynamic>? pickLocalization() {
      if (localizations.containsKey(normalizedRequested)) {
        return (localizations[normalizedRequested] as Map?)
            ?.cast<String, dynamic>();
      }
      final lang = requestedLocale.languageCode;
      if (localizations.containsKey(lang)) {
        return (localizations[lang] as Map?)?.cast<String, dynamic>();
      }
      if (localizations.containsKey('en')) {
        return (localizations['en'] as Map?)?.cast<String, dynamic>();
      }
      return null;
    }

    final localized = pickLocalization();
    final localeUsed = Locale(
        localized != null && localizations.containsKey(normalizedRequested)
            ? normalizedRequested
            : localized != null &&
                    localizations.containsKey(requestedLocale.languageCode)
                ? requestedLocale.languageCode
                : 'en');

    return GiftOffer(
      id: json['id'].toString(),
      // Always use canonical partner_name from backend; do not localize title.
      partnerName: json['partner_name']?.toString() ?? '',
      discountLabel: json['discount_label']?.toString(),
      // Prefer localized discount_text inside the locale object; fall back to top-level column if present.
      // Final fallback to English localization, then empty string to ensure non-null values.
      discountText: (localized?['discount_text'] as String?) ??
          json['discount_text']?.toString() ??
          (localizations['en']?['discount_text'] as String?) ??
          '',
      // Prefer localized CTA; fall back to top-level, then English localization, then empty string.
      cta: (localized?['cta'] as String?) ??
          json['cta']?.toString() ??
          (localizations['en']?['cta'] as String?) ??
          '',
      discountMinPercent: _tryDouble(json['discount_min_percent']),
      discountMaxPercent: _tryDouble(json['discount_max_percent']),
      promoCode: json['promo_code']?.toString(),
      regions: (json['regions'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      // Improved fallback chain: localized → top-level → English localization → empty string
      description: (localized?['description'] as String?) ??
          json['description']?.toString() ??
          (localizations['en']?['description'] as String?) ??
          '',
      termsAndConditions: (localized?['termsandconditions'] as String?) ??
          json['termsandconditions']?.toString() ??
          (localizations['en']?['termsandconditions'] as String?) ??
          '',
      websiteUrl: json['website_url']?.toString(),
      imageUrl: json['image_url']?.toString(),
      festiveColor: json['festive_color']?.toString(),
      validFrom: json['valid_from'] != null
          ? DateTime.tryParse(json['valid_from'].toString())
          : null,
      validTo: json['valid_to'] != null
          ? DateTime.tryParse(json['valid_to'].toString())
          : null,
      priority: json['priority'] as int?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      localeUsed: localeUsed,
    );
  }

  static double? _tryDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _normalizeLocale(Locale locale) {
    if (locale.countryCode == null || locale.countryCode!.isEmpty)
      return locale.languageCode;
    return '${locale.languageCode}-${locale.countryCode}'.toLowerCase();
  }
}
