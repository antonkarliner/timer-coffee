import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/network_timeouts.dart';
import '../utils/app_logger.dart';
import '../utils/persistent_ttl_cache.dart';

/// Shared cached lookup of a roaster's directory bundle (logo assets +
/// profile ref) by free-text roaster name, via the merged
/// `get_roaster_bundle_by_name` RPC. One network round trip serves every
/// consumer (logo widgets, profile navigation, notification scheduler).
typedef RoasterBundleLoader =
    Future<Map<String, String?>?> Function(String roasterName);

class RoasterDirectoryService {
  RoasterDirectoryService._()
    : _bundleLoader = _loadBundleFromSupabase,
      _persistentCache = PersistentTtlCache('roaster_bundle_');

  @visibleForTesting
  RoasterDirectoryService.forTesting({
    required RoasterBundleLoader bundleLoader,
    required PersistentTtlCache persistentCache,
  }) : _bundleLoader = bundleLoader,
       _persistentCache = persistentCache;

  static final instance = RoasterDirectoryService._();

  static const _foundTtl = Duration(days: 7);
  static const _negativeTtl = Duration(minutes: 5);

  final RoasterBundleLoader _bundleLoader;
  final PersistentTtlCache _persistentCache;
  final Map<String, Map<String, String?>> _memoryCache = {};
  final Map<String, Future<Map<String, String?>?>> _inFlight = {};
  final Set<Future<void>> _persistentWrites = {};
  int _cacheGeneration = 0;
  Future<void>? _clearInFlight;

  /// Changes whenever an explicit cache clear invalidates consumer caches.
  int get cacheGeneration => _cacheGeneration;

  String _normalize(String roasterName) =>
      removeDiacritics(roasterName.trim()).toLowerCase();

  /// Returns the bundle for [roasterName], or null when the roaster has no
  /// active directory profile (a cacheable negative). Throws on network
  /// failure with no cached fallback — callers decide their own degraded
  /// behavior and nothing is cached for errors.
  Future<Map<String, String?>?> fetchBundle(String roasterName) {
    final clearing = _clearInFlight;
    if (clearing != null) {
      return clearing.then((_) => fetchBundle(roasterName));
    }
    final key = _normalize(roasterName);
    if (_memoryCache.containsKey(key)) {
      return Future.value(_memoryCache[key]);
    }
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;
    final generation = _cacheGeneration;
    late final Future<Map<String, String?>?> future;
    future = _fetchBundle(key, roasterName, generation).whenComplete(() {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    });
    _inFlight[key] = future;
    return future;
  }

  /// Clears persistent and in-memory directory data. Lookups started before
  /// this call may still complete for their original callers, but cannot
  /// repopulate the invalidated caches.
  Future<void> clearCache() {
    _cacheGeneration++;
    _memoryCache.clear();
    _inFlight.clear();
    final previousClear = _clearInFlight;
    final activeWrites = _persistentWrites.toList(growable: false);
    late final Future<void> clearFuture;
    clearFuture = (previousClear ?? Future<void>.value())
        .then((_) => Future.wait(activeWrites.map(_ignoreWriteError)))
        .then((_) => _persistentCache.clear())
        .whenComplete(() {
          if (identical(_clearInFlight, clearFuture)) {
            _clearInFlight = null;
          }
        });
    _clearInFlight = clearFuture;
    return clearFuture;
  }

  /// Whether a positive in-memory bundle exists for [roasterName]. Synchronous
  /// companion to [fetchBundle] for callers that want to render cached data in
  /// their first frame.
  bool isCached(String roasterName) =>
      _memoryCache.containsKey(_normalize(roasterName));

  /// The positive in-memory bundle for [roasterName], or null when no positive
  /// bundle is cached.
  Map<String, String?>? peekBundle(String roasterName) =>
      _memoryCache[_normalize(roasterName)];

  Future<Map<String, String?>?> _fetchBundle(
    String key,
    String roasterName,
    int generation,
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
        if (bundle != null && generation == _cacheGeneration) {
          _memoryCache[key] = bundle;
        }
        return bundle;
      }
    }

    try {
      final bundle = await _bundleLoader(
        roasterName.trim(),
      ).timeout(NetworkTimeouts.handshake);
      if (bundle == null) {
        AppLogger.debug('Roaster bundle: no directory profile, caching miss');
        if (generation == _cacheGeneration) {
          _memoryCache.remove(key);
          await _writePersistent(key, {'found': false}, generation: generation);
        }
        return null;
      }
      if (generation == _cacheGeneration) {
        _memoryCache[key] = bundle;
        await _writePersistent(key, {
          'found': true,
          ...bundle,
        }, generation: generation);
      }
      return bundle;
    } catch (error) {
      AppLogger.error(
        'Roaster bundle lookup failed',
        errorObject: AppLogger.sanitize(error),
      );
      // Stale-if-error: an expired positive entry beats nothing. Errors are
      // never cached so the next call retries.
      final stale = await _persistentCache.read(key, allowStale: true);
      if (stale?['found'] == true) {
        final bundle = _bundleFromStored(stale!);
        if (generation == _cacheGeneration) {
          _memoryCache[key] = bundle;
        }
        return bundle;
      }
      rethrow;
    }
  }

  Future<void> _writePersistent(
    String key,
    Map<String, dynamic> data, {
    required int generation,
  }) async {
    if (generation != _cacheGeneration) return;
    late final Future<void> write;
    write = _persistentCache.write(key, data).whenComplete(() {
      _persistentWrites.remove(write);
    });
    _persistentWrites.add(write);
    await write;
  }

  Future<void> _ignoreWriteError(Future<void> write) async {
    try {
      await write;
    } catch (_) {
      // The original lookup reports its own cache-write failure. A clear must
      // still remove any other entries that can be invalidated safely.
    }
  }

  static Future<Map<String, String?>?> _loadBundleFromSupabase(
    String roasterName,
  ) async {
    // No .maybeSingle(): on POST RPCs it requests
    // application/vnd.pgrst.object+json, so an unknown roaster (0 rows)
    // comes back as HTTP 406/PGRST116 that postgrest-dart 2.6.0 fails to
    // map to null. Fetching the row set keeps "not found" a plain empty
    // list instead of an exception.
    final response = await Supabase.instance.client.rpc(
      'get_roaster_bundle_by_name',
      params: {'p_roaster_name': roasterName},
    );
    final rows = response as List<dynamic>;
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return <String, String?>{
      'profile_id': row['profile_id'] as String?,
      'slug': row['slug'] as String?,
      'roaster_logo_url': row['roaster_logo_url'] as String?,
      'roaster_logo_mirror_url': row['roaster_logo_mirror_url'] as String?,
      'dominant_color_hex': row['dominant_color_hex'] as String?,
    };
  }

  Map<String, String?> _bundleFromStored(Map<String, dynamic> stored) => {
    'profile_id': stored['profile_id'] as String?,
    'slug': stored['slug'] as String?,
    'roaster_logo_url': stored['roaster_logo_url'] as String?,
    'roaster_logo_mirror_url': stored['roaster_logo_mirror_url'] as String?,
    'dominant_color_hex': stored['dominant_color_hex'] as String?,
  };
}
