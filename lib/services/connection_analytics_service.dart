import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_endpoint_resolver.dart';
import '../utils/app_logger.dart';
import 'analytics_service.dart';

/// Reports whether this session reached Supabase directly or through the reverse
/// proxy (the blocked-region path — see [SupabaseEndpointResolver]). The intent
/// is a simple direct-vs-proxy ratio, not per-connection tracking, so reports
/// are deduped to at most one per device per day. Rows are anonymous (no user
/// id); the backend table is write-only via the `log_connection_endpoint` RPC.
class ConnectionAnalyticsService {
  ConnectionAnalyticsService._();

  /// UTC day of the last report. Older versions also recorded the endpoint.
  static const _lastReportKey = 'connection_analytics_last_report';
  static bool _reportInFlight = false;

  /// Test seam: sends the event. Defaults to the `log_connection_endpoint` RPC.
  static Future<void> Function(String endpoint, String platform)
  debugSendEvent = _sendViaRpc;

  static Future<void> _sendViaRpc(String endpoint, String platform) =>
      Supabase.instance.client.rpc(
        'log_connection_endpoint',
        params: {'p_endpoint': endpoint, 'p_platform': platform},
      );

  /// Sends at most one connection event per UTC day while General Analytics
  /// is enabled. A failed send is eligible for retry on the next launch.
  static Future<void> reportConnectionType() async {
    if (_reportInFlight) return;
    _reportInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (AnalyticsService.maybeInstance?.canTrackGeneral != true) return;
      final today = _todayUtc();
      if (prefs.getString(_lastReportKey)?.split('|').first == today) return;

      final endpoint = SupabaseEndpointResolver.usingProxy ? 'proxy' : 'direct';
      await debugSendEvent(endpoint, _platform());

      // Mark sent only after the RPC succeeds, so an offline launch retries.
      await prefs.setString(_lastReportKey, today);
      AppLogger.debug('Connection analytics: reported "$endpoint"');
    } catch (e) {
      AppLogger.debug(
        'Connection analytics: report skipped (${e.runtimeType})',
      );
    } finally {
      _reportInFlight = false;
    }
  }

  /// UTC calendar day as `yyyy-mm-dd`, so the daily dedup window doesn't shift
  /// with the device timezone.
  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'other';
    }
  }
}
