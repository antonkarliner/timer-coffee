import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Transport interface for the roaster-stock backend, so the roaster profile
/// stock section can be tested with a hand-written fake instead of a real
/// Supabase client.
abstract class RoasterStockClient {
  /// Reads a roaster's current in-stock beans via RPC `get_roaster_stock`.
  /// Public RPC — works signed out. Returns null when the RPC returned null.
  Future<RoasterStockResult?> fetchRoasterStock(String slug, {int limit = 30});

  /// Logs a click on a stock product link (RPC `log_referred_click`) with
  /// the `roaster_profile` surface. No-op without a user: the RPC raises for
  /// sessions without one.
  Future<void> logReferredClick(String stockId);
}

/// Thin wrapper around Supabase, mirroring `SupabaseBeanRecommendationClient`.
class SupabaseRoasterStockClient implements RoasterStockClient {
  SupabaseRoasterStockClient(this.supabase);

  final SupabaseClient supabase;

  @override
  Future<RoasterStockResult?> fetchRoasterStock(String slug,
      {int limit = 30}) async {
    final data = await supabase.rpc(
      'get_roaster_stock',
      params: {'p_slug': slug, 'p_limit': limit},
    );
    return RoasterStockResult.fromJson(data);
  }

  @override
  Future<void> logReferredClick(String stockId) async {
    if (supabase.auth.currentUser == null) return;
    await supabase.rpc(
      'log_referred_click',
      params: {'p_stock_id': stockId, 'p_surface': 'roaster_profile'},
    );
  }
}
