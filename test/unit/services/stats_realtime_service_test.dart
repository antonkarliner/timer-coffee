import 'package:coffee_timer/services/stats_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatsRealtimeEvent.tryParse', () {
    test('parses a valid record and converts milliliters to liters', () {
      final event = StatsRealtimeEvent.tryParse({
        'recipe_id': 'recipe-1',
        'created_at': '2024-06-15T10:30:00.000Z',
        'water_amount': 325,
      });

      expect(event, isNotNull);
      expect(event!.recipeId, 'recipe-1');
      expect(event.createdAt, DateTime.utc(2024, 6, 15, 10, 30));
      expect(event.liters, 0.325);
    });

    test('rejects missing or malformed payload fields', () {
      expect(StatsRealtimeEvent.tryParse({}), isNull);
      expect(
        StatsRealtimeEvent.tryParse({
          'recipe_id': 'recipe-1',
          'created_at': 'not-a-date',
          'water_amount': 300,
        }),
        isNull,
      );
      expect(
        StatsRealtimeEvent.tryParse({
          'recipe_id': 'recipe-1',
          'created_at': '2024-06-15T10:30:00.000Z',
          'water_amount': '300',
        }),
        isNull,
      );
    });
  });
}
