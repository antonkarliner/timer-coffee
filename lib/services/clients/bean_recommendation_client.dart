import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Transport interface for the bean-recommendations backend, so
/// [RecommendationProvider] can be unit-tested with a hand-written fake
/// instead of a real Supabase client.
abstract class BeanRecommendationClient {
  /// Reads the user's current picks via RPC `get_my_recommendations`.
  /// Returns null when the RPC returned null (no session).
  Future<RecommendationResult?> fetch({String? locale});

  /// Invokes the `recommend-beans` edge function (can take 10–20 seconds).
  /// It returns no picks; read them with [fetch] afterwards. Throws on
  /// transport or HTTP errors (incl. HTTP 429 rate limiting) — callers are
  /// expected to treat any exception as "nothing new came back".
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  });

  /// Records a dismissal in `bean_recommendation_feedback`. Duplicate
  /// inserts are ignored, so repeated dismissals never fail.
  Future<void> dismiss(String stockId);

  /// Logs a click on a recommendation link (RPC `log_referred_click`).
  /// [surface] is one of `for_you_card`, `roaster_profile`, `bean_detail`.
  Future<void> logReferredClick(String stockId, String surface);

  /// Opt-out: deletes the user's stored picks and dismissals.
  Future<void> deleteMine();
}

/// Thin wrapper around Supabase, mirroring `BeansLabelParserClient`.
class SupabaseBeanRecommendationClient implements BeanRecommendationClient {
  SupabaseBeanRecommendationClient(this.supabase);

  final SupabaseClient supabase;

  @override
  Future<RecommendationResult?> fetch({String? locale}) async {
    final data = await supabase.rpc(
      'get_my_recommendations',
      params: {'p_locale': locale},
    );
    return RecommendationResult.fromJson(data);
  }

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async {
    final response = await supabase.functions.invoke(
      'recommend-beans',
      body: {
        'locale': locale,
        'country_code': countryCode,
        'force_refresh': forceRefresh,
      },
    );
    final data = response.data;
    if (data is Map) {
      return BeanRecommendationStatus.fromWire(data['status']);
    }
    return BeanRecommendationStatus.unknown;
  }

  @override
  Future<void> dismiss(String stockId) async {
    // `ignoreDuplicates` (without an explicit conflict target) turns this
    // into `ON CONFLICT DO NOTHING`, so a repeated dismissal is a harmless
    // no-op regardless of which unique constraint catches it.
    await supabase
        .from('bean_recommendation_feedback')
        .upsert({'stock_id': stockId, 'action': 'dismissed'},
            ignoreDuplicates: true);
  }

  @override
  Future<void> logReferredClick(String stockId, String surface) async {
    await supabase.rpc(
      'log_referred_click',
      params: {'p_stock_id': stockId, 'p_surface': surface},
    );
  }

  @override
  Future<void> deleteMine() async {
    await supabase.rpc('delete_my_recommendations');
  }
}
