import 'dart:io';

import 'package:coffee_timer/utils/stats_civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatStatsCivilDate', () {
    test('formats start and end dates with zero-padded components', () {
      expect(formatStatsCivilDate(DateTime(2026, 1, 1)), '2026-01-01');
      expect(formatStatsCivilDate(DateTime(2026, 12, 31)), '2026-12-31');
      expect(formatStatsCivilDate(DateTime(2026, 2, 3)), '2026-02-03');
    });

    test('preserves a local DateTime own civil components', () {
      final localDate = DateTime(2026, 7, 1, 0, 30);

      expect(formatStatsCivilDate(localDate), '2026-07-01');
    });

    test('preserves a UTC DateTime own civil components', () {
      final utcDate = DateTime.utc(2026, 7, 1, 0, 1);

      expect(formatStatsCivilDate(utcDate), '2026-07-01');
    });

    test('preserves a DST-adjacent civil date', () {
      final dstAdjacentDate = DateTime(2026, 3, 29, 12);

      expect(formatStatsCivilDate(dstAdjacentDate), '2026-03-29');
    });
  });

  test('daily RPC methods preserve dates while timestamp methods use UTC', () {
    final source = File(
      'lib/providers/database_provider.dart',
    ).readAsStringSync();

    final brewedDaily = _sourceBetween(
      source,
      'fetchGlobalBrewedCoffeeAmountAggregated(',
      'fetchGlobalBrewsCountAggregated(',
    );
    final countDaily = _sourceBetween(
      source,
      'fetchGlobalBrewsCountAggregated(',
      'fetchGlobalTopRecipes(',
    );
    final recipesDaily = _sourceBetween(
      source,
      'fetchGlobalTopRecipesAggregated(',
      'fetchUserYearlyPercentile(',
    );

    for (final methodSource in [brewedDaily, countDaily, recipesDaily]) {
      expect(methodSource, contains('formatStatsCivilDate(start)'));
      expect(methodSource, contains('formatStatsCivilDate(end)'));
      expect(methodSource, isNot(contains('.toUtc()')));
    }

    final brewedTimestamps = _sourceBetween(
      source,
      'fetchGlobalBrewedCoffeeAmount(',
      'fetchGlobalBrewedCoffeeAmountAggregated(',
    );
    final recipeTimestamps = _sourceBetween(
      source,
      'fetchGlobalTopRecipes(',
      'fetchGlobalTopRecipesAggregated(',
    );

    for (final methodSource in [brewedTimestamps, recipeTimestamps]) {
      expect(methodSource, contains('start.toUtc()'));
      expect(methodSource, contains('end.toUtc()'));
    }
  });
}

String _sourceBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start + startMarker.length);

  expect(start, isNonNegative, reason: 'Missing $startMarker');
  expect(
    end,
    greaterThan(start),
    reason: 'Missing $endMarker after $startMarker',
  );
  return source.substring(start, end);
}
