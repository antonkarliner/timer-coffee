import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../env/env.dart';
import '../utils/app_logger.dart';

/// Resolves which Supabase endpoint the app should talk to: the direct Supabase
/// URL, or a transparent reverse proxy for networks where Supabase (its Cloudflare
/// edge) is blocked — primarily Russia.
///
/// At startup the app probes the direct endpoint; if the probe times out (as it
/// does under Russian DPI, where the connection black-holes rather than failing
/// fast) it falls back to the proxy. The decision is cached so subsequent launches
/// skip the probe. Caching is asymmetric and self-healing:
///   - a `proxy` decision is cached for 7 days (the proxy works everywhere);
///   - a `direct` decision is cached for only 24h, so a user who travels into a
///     blocked region re-probes within a day even absent the runtime self-heal;
///   - [forceProxy] lets the app pin the proxy immediately (called from the launch
///     auth path when a direct connection fails — see `lib/main.dart`).
///
/// The proxy is a stateless reverse proxy hosted outside Russia (see the project
/// proxy plan). Nothing about the host is baked in here beyond its hostname; the
/// VPS behind it is swapped via DNS, not an app release.
class SupabaseEndpointResolver {
  SupabaseEndpointResolver._();

  static const _cacheKey = 'supabase_endpoint_v1';
  static const _cacheTsKey = 'supabase_endpoint_ts_v1';

  static const Duration _proxyTtl = Duration(days: 7);
  static const Duration _directTtl = Duration(hours: 24);
  static const Duration _probeTimeout = Duration(seconds: 3);

  /// Reverse proxy that fronts Supabase from outside Russia. Not a secret.
  static const String proxyUrl = 'https://api.timer.coffee';

  /// Direct Supabase URL (obfuscated, injected at build time via envied).
  static String get directUrl => Env.supaUrl;

  /// Test seam: factory for the HTTP client used by the reachability probe.
  static http.Client Function() debugClientFactory = http.Client.new;

  /// The endpoint this session actually resolved to. Set by [resolve]; read
  /// synchronously (e.g. from widget builds) via [usingProxy] and the storage
  /// URL helpers below.
  static String _activeEndpoint = directUrl;

  /// Whether this session is routing through the proxy (blocked-region path).
  static bool get usingProxy => _activeEndpoint == proxyUrl;

  /// Rewrites a stored Supabase storage URL to this session's active endpoint so
  /// blocked-region users load images through the proxy. No-op on the direct path
  /// and for non-Supabase URLs. Safe for signed URLs — the signature covers the
  /// path and token, not the host.
  static String localizeStorageUrl(String url) {
    if (url.isEmpty || !usingProxy) return url;
    if (!url.startsWith('$directUrl/')) return url;
    return url.replaceFirst(directUrl, proxyUrl);
  }

  /// Forces a Supabase storage URL back to the canonical direct host before it is
  /// persisted to shared backend data, so proxy hostnames never leak into rows
  /// other users read. No-op for URLs not on the proxy host.
  static String canonicalizeStorageUrl(String url) {
    if (url.isEmpty || !url.startsWith('$proxyUrl/')) return url;
    return url.replaceFirst(proxyUrl, directUrl);
  }

  /// Returns the Supabase base URL to initialize the client with.
  static Future<String> resolve() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    final ts = prefs.getInt(_cacheTsKey) ?? 0;
    if (cached != null) {
      final ttl = cached == proxyUrl ? _proxyTtl : _directTtl;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age >= 0 && age < ttl.inMilliseconds) {
        AppLogger.info(
          'Supabase endpoint: using cached "${_label(cached)}" '
          '(age ${Duration(milliseconds: age).inMinutes}m of ${ttl.inHours}h TTL)',
        );
        _activeEndpoint = cached;
        return cached;
      }
      AppLogger.debug(
        'Supabase endpoint: cached "${_label(cached)}" is stale, re-probing',
      );
    } else {
      AppLogger.debug('Supabase endpoint: no cached decision, probing direct');
    }

    final url = await _probe();
    await _persist(prefs, url);
    _activeEndpoint = url;
    AppLogger.info('Supabase endpoint: resolved to "${_label(url)}"');
    return url;
  }

  /// Pins the proxy as the resolved endpoint for subsequent launches. Used by the
  /// runtime self-heal when a direct connection fails at launch.
  static Future<void> forceProxy() async {
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, proxyUrl);
    AppLogger.warning(
      'Supabase endpoint: pinned to "proxy" (self-heal after direct failure)',
    );
  }

  /// Clears the cache freshness so the next [resolve] re-probes. Call on app
  /// version change if such a hook exists.
  static Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTsKey);
    AppLogger.debug('Supabase endpoint: cache invalidated, will re-probe');
  }

  static Future<String> _probe() async {
    final client = debugClientFactory();
    final sw = Stopwatch()..start();
    try {
      // Any HTTP response (even a 401 from PostgREST) proves the direct endpoint
      // is reachable. Under DPI the request hangs and the timeout fires instead.
      final resp = await client
          .head(Uri.parse('$directUrl/rest/v1/'))
          .timeout(_probeTimeout);
      AppLogger.debug(
        'Supabase endpoint: direct probe reachable '
        '(HTTP ${resp.statusCode}, ${sw.elapsedMilliseconds}ms)',
      );
      return directUrl;
    } catch (e) {
      AppLogger.warning(
        'Supabase endpoint: direct probe failed after ${sw.elapsedMilliseconds}ms '
        '(timeout ${_probeTimeout.inSeconds}s); falling back to proxy',
        errorObject: e,
      );
      return proxyUrl;
    } finally {
      client.close();
    }
  }

  /// Short, non-sensitive label for logs. Avoids logging the full direct URL,
  /// whose project ref would be redacted by the sanitizer anyway.
  static String _label(String url) => url == proxyUrl ? 'proxy' : 'direct';

  static Future<void> _persist(SharedPreferences prefs, String url) async {
    await prefs.setString(_cacheKey, url);
    await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);
  }
}
