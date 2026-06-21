import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_endpoint_resolver.dart';
import '../utils/app_logger.dart';

/// Reports whether this session reached Supabase directly or through the reverse
/// proxy (the blocked-region path — see [SupabaseEndpointResolver]). The intent
/// is a simple direct-vs-proxy ratio, not per-connection tracking, so reports
/// are deduped to at most one per device per day. Rows are anonymous (no user
/// id); the backend table is write-only via the `log_connection_endpoint` RPC.
class ConnectionAnalyticsService {
  ConnectionAnalyticsService._();

  /// SharedPreferences key holding the last report as `"yyyy-mm-dd|endpoint"`.
  static const _lastReportKey = 'connection_analytics_last_report';

  /// Test seam: sends the event. Defaults to the `log_connection_endpoint` RPC.
  static Future<void> Function(String endpoint, String platform) debugSendEvent =
      _sendViaRpc;

  static Future<void> _sendViaRpc(String endpoint, String platform) =>
      Supabase.instance.client.rpc(
        'log_connection_endpoint',
        params: {'p_endpoint': endpoint, 'p_platform': platform},
      );

  /// Sends one connection event if none has been sent today (or if the endpoint
  /// changed since the last report — e.g. the user travelled into a blocked
  /// region between launches). Fully fire-and-forget: any failure is swallowed
  /// and the report is not marked sent, so it retries on the next launch.
  static Future<void> reportConnectionType() async {
    try {
      final endpoint = SupabaseEndpointResolver.usingProxy ? 'proxy' : 'direct';
      final today = _todayUtc();
      final marker = '$today|$endpoint';

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastReportKey) == marker) {
        // Already reported this endpoint today — nothing to do.
        return;
      }

      await debugSendEvent(endpoint, _platform());

      // Mark sent only after the RPC succeeds, so an offline launch retries.
      await prefs.setString(_lastReportKey, marker);
      AppLogger.debug('Connection analytics: reported "$endpoint"');
    } catch (e) {
      AppLogger.debug('Connection analytics: report skipped (${e.runtimeType})');
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
