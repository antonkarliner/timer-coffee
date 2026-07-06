import 'package:supabase_flutter/supabase_flutter.dart';

class StatsRealtimeEvent {
  final String recipeId;
  final DateTime createdAt;
  final double liters;

  const StatsRealtimeEvent({
    required this.recipeId,
    required this.createdAt,
    required this.liters,
  });

  static StatsRealtimeEvent? tryParse(Map<String, dynamic> record) {
    final recipeId = record['recipe_id'];
    final createdAtRaw = record['created_at'];
    final water = record['water_amount'];
    if (recipeId == null || createdAtRaw == null || water is! num) return null;

    final createdAt = DateTime.tryParse(createdAtRaw.toString());
    if (createdAt == null) return null;

    return StatsRealtimeEvent(
      recipeId: recipeId.toString(),
      createdAt: createdAt,
      liters: water.toDouble() / 1000.0,
    );
  }
}

/// Lightweight realtime service for Stats feature.
/// Emits recipeId, createdAt, and liters brewed on each insert to public.global_stats.
class StatsRealtimeService {
  RealtimeChannel? _channel;

  void start({
    required void Function({
      required String recipeId,
      required DateTime createdAt,
      required double liters,
    })
    onEvent,
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
          final event = StatsRealtimeEvent.tryParse(payload.newRecord);
          if (event == null) return;

          onEvent(
            recipeId: event.recipeId,
            createdAt: event.createdAt,
            liters: event.liters,
          );
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
