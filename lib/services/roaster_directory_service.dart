import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/network_timeouts.dart';
import '../utils/app_logger.dart';
import '../utils/persistent_ttl_cache.dart';

/// Shared cached lookup of a roaster's directory bundle (logo assets +
/// profile ref) by free-text roaster name, via the merged
/// `get_roaster_bundle_by_name` RPC. One network round trip serves every
/// consumer (logo widgets, profile navigation, notification scheduler).
class RoasterDirectoryService {
  RoasterDirectoryService._();
  static final instance = RoasterDirectoryService._();

  static const _foundTtl = Duration(days: 7);
  static const _negativeTtl = Duration(hours: 24);

  final Map<String, Map<String, String?>?> _memoryCache = {};
  final Map<String, Future<Map<String, String?>?>> _inFlight = {};
  final PersistentTtlCache _persistentCache =
      PersistentTtlCache('roaster_bundle_');

  String _normalize(String roasterName) =>
      removeDiacritics(roasterName.trim()).toLowerCase();

  /// Returns the bundle for [roasterName], or null when the roaster has no
  /// active directory profile (a cacheable negative). Throws on network
  /// failure with no cached fallback — callers decide their own degraded
  /// behavior and nothing is cached for errors.
  Future<Map<String, String?>?> fetchBundle(String roasterName) {
    final key = _normalize(roasterName);
    if (_memoryCache.containsKey(key)) {
      return Future.value(_memoryCache[key]);
    }
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;
    final future = _fetchBundle(key, roasterName).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  /// Whether an in-memory result (positive or negative) exists for
  /// [roasterName]. Synchronous companion to [fetchBundle] for callers that
  /// want to render cached data in their first frame.
  bool isCached(String roasterName) =>
      _memoryCache.containsKey(_normalize(roasterName));

  /// The in-memory bundle for [roasterName]: the cached map, null for a
  /// cached negative, or null when nothing is cached (disambiguate with
  /// [isCached]).
  Map<String, String?>? peekBundle(String roasterName) =>
      _memoryCache[_normalize(roasterName)];

  Future<Map<String, String?>?> _fetchBundle(
    String key,
    String roasterName,
  ) async {
    final persisted = await _persistentCache.read(key);
    if (persisted != null) {
      final found = persisted['found'] == true;
      final fresh = await _persistentCache.read(
        key,
        maxAge: found ? _foundTtl : _negativeTtl,
      );
      if (fresh != null) {
        final bundle = found ? _bundleFromStored(fresh) : null;
        _memoryCache[key] = bundle;
        return bundle;
      }
    }

    try {
      final response = await Supabase.instance.client
          .rpc(
            'get_roaster_bundle_by_name',
            params: {'p_roaster_name': roasterName.trim()},
          )
          .maybeSingle()
          .timeout(NetworkTimeouts.handshake);
      if (response == null) {
        _memoryCache[key] = null;
        await _persistentCache.write(key, {'found': false});
        return null;
      }
      final bundle = <String, String?>{
        'profile_id': response['profile_id'] as String?,
        'slug': response['slug'] as String?,
        'roaster_logo_url': response['roaster_logo_url'] as String?,
        'roaster_logo_mirror_url':
            response['roaster_logo_mirror_url'] as String?,
        'dominant_color_hex': response['dominant_color_hex'] as String?,
      };
      _memoryCache[key] = bundle;
      await _persistentCache.write(key, {'found': true, ...bundle});
      return bundle;
    } catch (error) {
      AppLogger.error(
        'Roaster bundle lookup failed',
        errorObject: AppLogger.sanitize(error),
      );
      // Stale-if-error: an expired entry beats nothing. Errors are never
      // cached so the next call retries.
      final stale = await _persistentCache.read(key, allowStale: true);
      if (stale != null) {
        final bundle = stale['found'] == true ? _bundleFromStored(stale) : null;
        _memoryCache[key] = bundle;
        return bundle;
      }
      rethrow;
    }
  }

  Map<String, String?> _bundleFromStored(Map<String, dynamic> stored) => {
        'profile_id': stored['profile_id'] as String?,
        'slug': stored['slug'] as String?,
        'roaster_logo_url': stored['roaster_logo_url'] as String?,
        'roaster_logo_mirror_url':
            stored['roaster_logo_mirror_url'] as String?,
        'dominant_color_hex': stored['dominant_color_hex'] as String?,
      };
}
