import 'dart:convert';

import 'package:coffee_timer/services/region_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [RegionService.getGeoLocation] feeds push-token and popup targeting
/// (plan 076 §2/§3): it must report only IP-derived values, take the region
/// code from the backend, and never fall back to a locale guess.
void main() {
  late List<Uri> requests;

  /// [geoip] / [countryIs]: response body, or null for a server error.
  RegionService serviceWith({
    Map<String, Object?>? geoip,
    Map<String, Object?>? countryIs,
    required void Function(http.Client) bindCountryIs,
  }) {
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.path.endsWith('/functions/v1/geoip')) {
        return geoip == null
            ? http.Response('fail', 500)
            : http.Response(
                jsonEncode(geoip),
                200,
                headers: {'content-type': 'application/json'},
              );
      }
      if (request.url.host == 'api.country.is') {
        return countryIs == null
            ? http.Response('fail', 500)
            : http.Response(jsonEncode(countryIs), 200);
      }
      return http.Response('unexpected', 404);
    });
    bindCountryIs(client);
    return RegionService(
      SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: client,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    );
  }

  /// Runs [body] with package:http's top-level functions (used for the
  /// country.is fallback) routed to the same mock client.
  Future<T> run<T>(
    Future<T> Function(RegionService service) body, {
    Map<String, Object?>? geoip,
    Map<String, Object?>? countryIs,
  }) {
    late http.Client bound;
    final service = serviceWith(
      geoip: geoip,
      countryIs: countryIs,
      bindCountryIs: (c) => bound = c,
    );
    return http.runWithClient(() => body(service), () => bound);
  }

  setUp(() {
    requests = [];
    SharedPreferences.setMockInitialValues({});
  });

  test('takes country and region from geoip, normalised', () async {
    final geo = await run(
      (s) => s.getGeoLocation(),
      geoip: {'country': 'de', 'region': 'eu'},
    );
    expect(geo?.country, 'DE');
    expect(geo?.region, 'EU');
  });

  test('WW from geoip means the region is unknown', () async {
    final geo = await run(
      (s) => s.getGeoLocation(),
      geoip: {'country': 'KZ', 'region': 'WW'},
    );
    expect(geo?.country, 'KZ');
    expect(geo?.region, isNull);
  });

  test('falls back to country.is for the country only', () async {
    final geo = await run(
      (s) => s.getGeoLocation(),
      countryIs: {'country': 'BR', 'ip': '203.0.113.1'},
    );
    expect(geo?.country, 'BR');
    expect(geo?.region, isNull);
  });

  test('never guesses from the locale when every lookup fails', () async {
    final geo = await run((s) => s.getGeoLocation());
    expect(geo, isNull);
    expect(await RegionService.getCachedGeoLocation(), isNull);
  });

  test('rejects a malformed country code', () async {
    final geo = await run(
      (s) => s.getGeoLocation(),
      geoip: {'country': '', 'region': 'EU'},
      countryIs: {'country': 'X1'},
    );
    expect(geo, isNull);
  });

  test('concurrent callers share one lookup', () async {
    final results = await run(
      (s) => Future.wait([s.getGeoLocation(), s.getGeoLocation()]),
      geoip: {'country': 'DE', 'region': 'EU'},
    );
    expect(results.map((g) => g?.country), ['DE', 'DE']);
    expect(requests.where((u) => u.path.endsWith('/geoip')), hasLength(1));
  });

  test('serves a fresh cache without a network call', () async {
    await run(
      (s) => s.getGeoLocation(),
      geoip: {'country': 'JP', 'region': 'AS'},
    );
    requests.clear();

    final geo = await run((s) => s.getGeoLocation());
    expect(geo?.country, 'JP');
    expect(geo?.region, 'AS');
    expect(requests, isEmpty);
  });

  test('refreshes a stale cache, keeping it if the refresh fails', () async {
    final staleAt = DateTime.now()
        .subtract(const Duration(hours: 25))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'geo_country_code': 'FR',
      'geo_region_code': 'EU',
      'geo_cached_at': staleAt,
    });

    final kept = await run((s) => s.getGeoLocation());
    expect(requests, isNotEmpty);
    expect(kept?.country, 'FR');

    final moved = await run(
      (s) => s.getGeoLocation(),
      geoip: {'country': 'US', 'region': 'NA'},
    );
    expect(moved?.country, 'US');
    expect(moved?.region, 'NA');
    final cached = await RegionService.getCachedGeoLocation();
    expect(cached?.country, 'US');
  });

  test('a refresh without a region clears the cached one', () async {
    SharedPreferences.setMockInitialValues({
      'geo_country_code': 'DE',
      'geo_region_code': 'EU',
      'geo_cached_at': 0,
    });
    await run((s) => s.getGeoLocation(), countryIs: {'country': 'AR'});

    final cached = await RegionService.getCachedGeoLocation();
    expect(cached?.country, 'AR');
    expect(cached?.region, isNull);
  });

  test('getCachedGeoLocation ignores age and the locale-guess cache', () async {
    SharedPreferences.setMockInitialValues({
      // getCountryCode's cache can hold a locale guess; it must not leak in.
      'country_code_cache': 'DE',
      'country_code_cached_at': DateTime.now().millisecondsSinceEpoch,
    });
    expect(await RegionService.getCachedGeoLocation(), isNull);

    SharedPreferences.setMockInitialValues({
      'geo_country_code': 'GB',
      'geo_region_code': 'EU',
      'geo_cached_at': 0,
    });
    final cached = await RegionService.getCachedGeoLocation();
    expect(cached?.country, 'GB');
    expect(cached?.region, 'EU');
  });
}
