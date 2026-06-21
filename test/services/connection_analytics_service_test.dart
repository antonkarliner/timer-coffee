import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:coffee_timer/services/connection_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the daily dedup and fail-safe behavior of the connection telemetry
/// without touching Supabase — the event sender is injected via [debugSendEvent]
/// and the endpoint is driven through the resolver's probe seam.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Captured (endpoint, platform) pairs for each send the service attempts.
  late List<List<String>> sent;

  http.Client reachable() => MockClient((_) async => http.Response('', 401));
  http.Client blocked() =>
      MockClient((_) async => throw http.ClientException('blocked'));

  Future<void> useDirect() async {
    await SupabaseEndpointResolver.invalidate();
    SupabaseEndpointResolver.debugClientFactory = reachable;
    await SupabaseEndpointResolver.resolve();
  }

  Future<void> useProxy() async {
    await SupabaseEndpointResolver.invalidate();
    SupabaseEndpointResolver.debugClientFactory = blocked;
    await SupabaseEndpointResolver.resolve();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent = [];
    ConnectionAnalyticsService.debugSendEvent = (endpoint, platform) async {
      sent.add([endpoint, platform]);
    };
  });

  tearDown(() {
    SupabaseEndpointResolver.debugClientFactory = http.Client.new;
  });

  test('reports the resolved endpoint on first launch of the day', () async {
    await useDirect();
    await ConnectionAnalyticsService.reportConnectionType();

    expect(sent, hasLength(1));
    expect(sent.first.first, 'direct');
  });

  test('does not report twice for the same endpoint on the same day', () async {
    await useProxy();
    await ConnectionAnalyticsService.reportConnectionType();
    await ConnectionAnalyticsService.reportConnectionType();

    expect(sent, hasLength(1));
    expect(sent.first.first, 'proxy');
  });

  test('reports again when the endpoint changes within the same day', () async {
    await useDirect();
    await ConnectionAnalyticsService.reportConnectionType();

    // User moves behind a block between launches.
    await useProxy();
    await ConnectionAnalyticsService.reportConnectionType();

    expect(sent.map((e) => e.first), ['direct', 'proxy']);
  });

  test('a failed send is not marked, so the next launch retries', () async {
    await useDirect();
    var attempts = 0;
    ConnectionAnalyticsService.debugSendEvent = (endpoint, platform) async {
      attempts++;
      throw StateError('offline');
    };

    await ConnectionAnalyticsService.reportConnectionType();
    await ConnectionAnalyticsService.reportConnectionType();

    // Both launches attempted the send because the first never persisted a marker.
    expect(attempts, 2);
  });
}
