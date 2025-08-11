import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight realtime service for Stats feature.
/// Emits recipeId, createdAt, and liters brewed on each insert to public.global_stats.
class StatsRealtimeService {
  RealtimeChannel? _channel;

  void start({
    required void Function({
      required String recipeId,
      required DateTime createdAt,
      required double liters,
    }) onEvent,
  }) {
    // Ensure only one active channel
    stop();

    final client = Supabase.instance.client;
    _channel = client.channel('public:global_stats')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'global_stats',
        callback: (payload) {
          final record = payload.newRecord;
          if (record == null) return;

          final recipeId = record['recipe_id']?.toString();
          final createdAtRaw = record['created_at'];
          final water = record['water_amount'];

          if (recipeId == null || createdAtRaw == null || water == null) return;

          final createdAt = DateTime.tryParse(createdAtRaw.toString());
          if (createdAt == null) return;

          // Convert to liters to match UI expectations
          final liters = (water as num).toDouble() / 1000.0;

          onEvent(recipeId: recipeId, createdAt: createdAt, liters: liters);
        },
      ).subscribe();
  }

  void stop() {
    try {
      if (_channel != null) {
        // In this project other screens call removeAllChannels();
        // Stay consistent and aggressively clean up.
        Supabase.instance.client.removeAllChannels();
      }
    } catch (_) {
      // no-op
    } finally {
      _channel = null;
    }
  }

  void dispose() {
    stop();
  }
}
