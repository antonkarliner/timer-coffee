import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/network_timeouts.dart';
import '../utils/app_logger.dart';
import 'region_service.dart';

/// Reads the newest launch popup this viewer should see (plan 076 §3).
///
/// Goes through `get_launch_popup`, which applies a popup's audience
/// (language, country/region, platform) and `visible_from`. If that call
/// fails, it falls back to the direct table read, which RLS limits to
/// untargeted popups: a failure costs targeting, never the popup itself.
class LaunchPopupFetcher {
  LaunchPopupFetcher(
    this._client, {
    Duration budget = NetworkTimeouts.handshake,
    Duration rpcTimeout = const Duration(seconds: 3),
  }) : _budget = budget,
       _rpcTimeout = rpcTimeout;

  final SupabaseClient _client;

  /// Covers the RPC and the fallback together, so a failing RPC doesn't make
  /// launch wait longer than the single direct read used to.
  final Duration _budget;
  final Duration _rpcTimeout;

  /// The fields [LaunchPopupModel.fromMap] reads, for both paths.
  static const columns =
      'id, content, locale, created_at, platform, hook_type, '
      'goal_amount_usd, progress_amount_usd, campaign_ends_at, title';

  /// The popup row, or null when none applies. [geo] is passed as the
  /// viewer's country/region; null means unknown, which a country- or
  /// region-targeted popup excludes. Throws only if the fallback fails too.
  Future<Map<String, dynamic>?> fetch({
    required String locale,
    required String platform,
    GeoLocation? geo,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      // Read as a list, not maybeSingle(): an empty result must stay a plain
      // "no popup", never an error that triggers the fallback.
      final rows = await _client
          .rpc(
            'get_launch_popup',
            params: {
              'p_locale': locale,
              'p_platform': platform,
              'p_country': geo?.country,
              'p_region': geo?.region,
            },
          )
          .select(columns)
          .timeout(_rpcTimeout);
      return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
    } catch (e) {
      AppLogger.warning(
        'get_launch_popup failed, reading untargeted popups instead: '
        '${AppLogger.sanitize(e)}',
      );
    }

    final remaining = _budget - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('Launch popup budget spent', _budget);
    }
    return _client
        .from('launch_popup')
        .select(columns)
        .eq('locale', locale)
        .or('platform.eq.$platform,platform.eq.all')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle()
        .timeout(remaining);
  }
}
