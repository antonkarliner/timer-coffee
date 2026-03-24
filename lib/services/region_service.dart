import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

/// Lightweight region detector.
/// Order of attempts: cached value -> Supabase Edge Function `geoip` -> country.is -> locale heuristic.
class RegionService {
  static const _cacheKey = 'giftbox_region_code';
  static const _cacheTsKey = 'giftbox_region_cached_at';
  static const _countryCodeKey = 'country_code_cache';
  static const _countryCodeTsKey = 'country_code_cached_at';
  static const _cacheTtlHours = 24;

  final SupabaseClient _supabaseClient;

  RegionService(this._supabaseClient);

  Future<String?> detectRegion({required String localeCode}) async {
    final cached = await _getCached();
    if (cached != null) return cached;

    final fromEdge = await _tryEdgeFunction();
    if (fromEdge != null) {
      await _cache(fromEdge);
      return fromEdge;
    }

    final fromCountryIs = await _tryCountryIs();
    if (fromCountryIs != null) {
      await _cache(fromCountryIs);
      return fromCountryIs;
    }

    final fallback = _mapLocaleToRegion(localeCode);
    if (fallback != null) {
      await _cache(fallback);
    }
    return fallback;
  }

  Future<String?> _getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final ts = prefs.getInt(_cacheTsKey);
    if (cached != null && ts != null) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt).inHours < _cacheTtlHours) {
        return cached;
      }
    }
    return null;
  }

  Future<void> _cache(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, region);
    await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _tryEdgeFunction() async {
    try {
      final res = await _supabaseClient.functions.invoke('geoip');
      final data = res.data as Map?;
      final region = data?['region']?.toString();
      if (region != null && region.isNotEmpty) return region;
    } catch (e) {
      AppLogger.debug('geoip edge function failed: ${AppLogger.sanitize(e)}');
    }
    return null;
  }

  Future<String?> _tryCountryIs() async {
    try {
      final resp = await http
          .get(Uri.parse('https://api.country.is/'))
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final country = data['country']?.toString();
        if (country != null) {
          return _mapCountryToRegion(country);
        }
      }
    } catch (e) {
      AppLogger.debug('country.is lookup failed: ${AppLogger.sanitize(e)}');
    }
    return null;
  }

  String? _mapLocaleToRegion(String localeCode) {
    // Simple heuristic; adjust as needed.
    final lc = localeCode.toLowerCase();
    if (lc.startsWith('en-us') || lc.startsWith('en-ca')) return 'NA';
    if (lc.startsWith('en-gb') || lc.startsWith('de') || lc.startsWith('fr') || lc.startsWith('es') || lc.startsWith('it')) {
      return 'EU';
    }
    if (lc.startsWith('ja') || lc.startsWith('zh') || lc.startsWith('ko')) return 'ASIA';
    return 'WW';
  }

  // ---------------------------------------------------------------------------
  // Country code detection (ISO 3166-1 alpha-2)
  // ---------------------------------------------------------------------------

  /// Returns the user's ISO 3166-1 alpha-2 country code (e.g. "FR"), cached
  /// for 24 hours. Falls back through: geoip edge function → country.is API →
  /// locale heuristic. Returns null if all methods fail.
  Future<String?> getCountryCode({required String localeCode}) async {
    final cached = await _getCachedCountryCode();
    if (cached != null) return cached;

    final fromEdge = await _tryEdgeFunctionCountry();
    if (fromEdge != null) {
      await _cacheCountryCode(fromEdge);
      return fromEdge;
    }

    final fromCountryIs = await _tryCountryIsRaw();
    if (fromCountryIs != null) {
      await _cacheCountryCode(fromCountryIs);
      return fromCountryIs;
    }

    final fallback = _mapLocaleToCountry(localeCode);
    if (fallback != null) {
      await _cacheCountryCode(fallback);
    }
    return fallback;
  }

  Future<String?> _getCachedCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_countryCodeKey);
    final ts = prefs.getInt(_countryCodeTsKey);
    if (cached != null && ts != null) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt).inHours < _cacheTtlHours) {
        return cached;
      }
    }
    return null;
  }

  Future<void> _cacheCountryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryCodeKey, code);
    await prefs.setInt(_countryCodeTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _tryEdgeFunctionCountry() async {
    try {
      final res = await _supabaseClient.functions.invoke('geoip');
      final data = res.data as Map?;
      final country = data?['country']?.toString();
      if (country != null && country.isNotEmpty) return country.toUpperCase();
    } catch (e) {
      AppLogger.debug('geoip country lookup failed: ${AppLogger.sanitize(e)}');
    }
    return null;
  }

  Future<String?> _tryCountryIsRaw() async {
    try {
      final resp = await http
          .get(Uri.parse('https://api.country.is/'))
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final country = data['country']?.toString();
        if (country != null && country.isNotEmpty) return country.toUpperCase();
      }
    } catch (e) {
      AppLogger.debug('country.is raw lookup failed: ${AppLogger.sanitize(e)}');
    }
    return null;
  }

  String? _mapLocaleToCountry(String localeCode) {
    final lc = localeCode.toLowerCase();
    if (lc.startsWith('ja')) return 'JP';
    if (lc.startsWith('zh')) return 'CN';
    if (lc.startsWith('ko')) return 'KR';
    if (lc.startsWith('de')) return 'DE';
    if (lc.startsWith('fr')) return 'FR';
    if (lc.startsWith('es')) return 'ES';
    if (lc.startsWith('it')) return 'IT';
    if (lc.startsWith('pt')) return 'BR';
    if (lc.startsWith('nl')) return 'NL';
    if (lc.startsWith('pl')) return 'PL';
    if (lc.startsWith('ru')) return 'RU';
    if (lc.startsWith('uk')) return 'UA';
    if (lc.startsWith('ar')) return 'SA';
    if (lc.startsWith('tr')) return 'TR';
    if (lc.startsWith('fi')) return 'FI';
    if (lc.startsWith('no')) return 'NO';
    if (lc.startsWith('hr')) return 'HR';
    if (lc.startsWith('ro')) return 'RO';
    if (lc.startsWith('id')) return 'ID';
    if (lc.startsWith('en-us') || lc.startsWith('en_us')) return 'US';
    if (lc.startsWith('en-gb') || lc.startsWith('en_gb')) return 'GB';
    if (lc.startsWith('en-au') || lc.startsWith('en_au')) return 'AU';
    if (lc.startsWith('en-ca') || lc.startsWith('en_ca')) return 'CA';
    return null;
  }

  String? _mapCountryToRegion(String countryCode) {
    final c = countryCode.toUpperCase();
    if (['US', 'CA', 'MX'].contains(c)) return 'NA';
    if (['GB', 'DE', 'FR', 'ES', 'IT', 'NL', 'BE', 'SE', 'NO', 'FI', 'DK', 'PL', 'PT', 'IE', 'AT', 'CH'].contains(c)) {
      return 'EU';
    }
    if (['JP', 'CN', 'HK', 'KR', 'SG', 'TH', 'VN', 'MY', 'ID', 'PH', 'IN'].contains(c)) return 'ASIA';
    if (['AU', 'NZ'].contains(c)) return 'AU';
    return 'WW';
  }
}
