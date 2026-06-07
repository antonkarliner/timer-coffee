import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the direct-vs-proxy endpoint resolution, its caching, and the
/// self-heal hooks (`forceProxy`/`invalidate`) without touching the network —
/// the probe HTTP client is injected via `debugClientFactory`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final direct = SupabaseEndpointResolver.directUrl;
  const proxy = SupabaseEndpointResolver.proxyUrl;

  http.Client reachable() => MockClient((_) async => http.Response('', 401));
  http.Client blocked() =>
      MockClient((_) async => throw http.ClientException('blocked'));
  http.Client noProbe() =>
      MockClient((_) async => throw StateError('probe must not run'));

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SupabaseEndpointResolver.debugClientFactory = http.Client.new);

  test('reachable direct endpoint resolves to direct and is then cached', () async {
    SupabaseEndpointResolver.debugClientFactory = reachable;
    expect(await SupabaseEndpointResolver.resolve(), direct);

    // Subsequent resolve must serve from cache without probing.
    SupabaseEndpointResolver.debugClientFactory = noProbe;
    expect(await SupabaseEndpointResolver.resolve(), direct);
  });

  test('blocked direct endpoint falls back to proxy and is then cached', () async {
    SupabaseEndpointResolver.debugClientFactory = blocked;
    expect(await SupabaseEndpointResolver.resolve(), proxy);

    SupabaseEndpointResolver.debugClientFactory = noProbe;
    expect(await SupabaseEndpointResolver.resolve(), proxy);
  });

  test('forceProxy pins the proxy for subsequent resolves', () async {
    await SupabaseEndpointResolver.forceProxy();

    SupabaseEndpointResolver.debugClientFactory = noProbe;
    expect(await SupabaseEndpointResolver.resolve(), proxy);
  });

  test('invalidate forces a re-probe of a cached decision', () async {
    SupabaseEndpointResolver.debugClientFactory = reachable;
    expect(await SupabaseEndpointResolver.resolve(), direct);

    await SupabaseEndpointResolver.invalidate();

    SupabaseEndpointResolver.debugClientFactory = blocked;
    expect(await SupabaseEndpointResolver.resolve(), proxy);
  });

  group('storage URL helpers', () {
    final directStorage = '$direct/storage/v1/object/public/bucket/a.webp';
    final proxyStorage = '$proxy/storage/v1/object/public/bucket/a.webp';

    test('canonicalize rewrites proxy host to direct (for persistence)', () {
      expect(
          SupabaseEndpointResolver.canonicalizeStorageUrl(proxyStorage), directStorage);
    });

    test('canonicalize is a no-op for already-direct and foreign URLs', () {
      expect(
          SupabaseEndpointResolver.canonicalizeStorageUrl(directStorage), directStorage);
      const external = 'https://example.com/logo.png';
      expect(SupabaseEndpointResolver.canonicalizeStorageUrl(external), external);
      expect(SupabaseEndpointResolver.canonicalizeStorageUrl(''), '');
    });

    test('localize rewrites direct host to proxy only when on proxy', () async {
      // Force the session onto the proxy.
      SupabaseEndpointResolver.debugClientFactory = blocked;
      await SupabaseEndpointResolver.resolve();
      expect(SupabaseEndpointResolver.usingProxy, isTrue);

      expect(SupabaseEndpointResolver.localizeStorageUrl(directStorage), proxyStorage);
      // Foreign URLs and empty strings are untouched.
      const external = 'https://example.com/logo.png';
      expect(SupabaseEndpointResolver.localizeStorageUrl(external), external);
      expect(SupabaseEndpointResolver.localizeStorageUrl(''), '');
    });

    test('localize is a no-op on the direct path', () async {
      SupabaseEndpointResolver.debugClientFactory = reachable;
      await SupabaseEndpointResolver.resolve();
      expect(SupabaseEndpointResolver.usingProxy, isFalse);

      expect(SupabaseEndpointResolver.localizeStorageUrl(directStorage), directStorage);
    });
  });
}
