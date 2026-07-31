// Unit tests for a few finish-screen helpers extracted so they're testable
// without mounting `FinishScreen` (which reaches Supabase,
// `AdvancedInAppReview`, `NotificationService`, and six providers via
// `BuildContext`):
//
// - `writeFinishScreenStarRating` (plan 039 triage item 7): the star row's
//   write+track pairing — a tap now emits `diary_entry_edited` with a
//   distinct `source: 'finish_star_row'`, separable from a considered
//   in-sheet edit (`BrewEvalSheet` emits `source: 'finish_eval_sheet'`).
// - `finishScreenEntrySourceLabel` (plan 039 triage item 8): the shared
//   `entry_source` label, debug-asserted to still mean `'timer'`.

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/finish_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  const statUuid = 'finish-star-stat-1';

  Future<AppDatabase> seedDatabase() async {
    final db = openTestDatabase();
    await db.userStatsDao.insertUserStat(
      UserStatsModel(
        statUuid: statUuid,
        recipeId: 'recipe-1',
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 1,
        brewingMethodId: 'v60',
        createdAt: DateTime.utc(2026, 7, 30),
        isMarked: false,
        entrySource: 0,
        versionVector: VersionVector.initial('finish-device').toString(),
        isDeleted: false,
      ),
    );
    return db;
  }

  UserStatProvider buildProvider(AppDatabase db) =>
      UserStatProvider(db, CoffeeBeansProvider(db, DatabaseProvider(db)));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('finishScreenEntrySourceLabel', () {
    test('resolves to timer', () {
      expect(finishScreenEntrySourceLabel(), 'timer');
    });

    test('matches kFinishScreenEntrySourceCode == 0', () {
      expect(kFinishScreenEntrySourceCode, 0);
    });
  });

  group('writeFinishScreenStarRating', () {
    test('writes the rating and emits diary_entry_edited with '
        'source finish_star_row', () async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });

      await writeFinishScreenStarRating(
        userStatProvider: stats,
        statUuid: statUuid,
        rating: 4.5,
        entrySource: finishScreenEntrySourceLabel(),
      );

      final updated = await db.userStatsDao.fetchStatByUuid(statUuid);
      expect(updated?.rating, 4.5);

      final events = AnalyticsService.instance.bufferedEventsForTesting;
      final matching = events.where(
        (e) => e['event_name'] == 'diary_entry_edited',
      );
      expect(matching, hasLength(1));
      final properties =
          matching.single['properties'] as Map<String, dynamic>;
      expect(properties['field'], 'rating');
      expect(properties['entry_source'], 'timer');
      expect(properties['source'], 'finish_star_row');
      expect(
        properties['source'],
        isNot('finish_eval_sheet'),
        reason: 'the trigger tap and a considered in-sheet edit must stay '
            'separable in the data (plan 039 triage item 7)',
      );
    });
  });
}
