import 'dart:convert';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/local_notification_scheduler_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

UserStatsModel _makeStat({
  String uuid = 'stat-1',
  String recipeId = 'recipe-1',
  String brewingMethodId = 'method-1',
  DateTime? createdAt,
}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: recipeId,
    coffeeAmount: 15.0,
    waterAmount: 250.0,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: brewingMethodId,
    createdAt: createdAt ?? DateTime.now(),
    isMarked: false,
    versionVector: VersionVector.initial('test').toString(),
    isDeleted: false,
  );
}

CoffeeBeansModel _makeBean({
  String uuid = 'bean-1',
  String name = 'Test Bean',
  DateTime? roastDate,
  bool isDeleted = false,
}) {
  return CoffeeBeansModel(
    beansUuid: uuid,
    roaster: 'Test Roaster',
    name: name,
    origin: 'Ethiopia',
    roastDate: roastDate,
    isDeleted: isDeleted,
    versionVector: VersionVector.initial('test').toString(),
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late OnboardingService onboarding;
  late SharedPreferences prefs;

  // Runs the scheduler with real DB / onboarding, but platform calls intercepted.
  Future<void> runScheduler({String locale = 'en'}) =>
      LocalNotificationSchedulerService.instance.rescheduleAll(
        database: db,
        onboarding: onboarding,
        locale: locale,
      );

  // Convenience accessors into the captured call list.
  bool scheduled(int id) =>
      LocalNotificationSchedulerService.testScheduled.any((c) => c.id == id);

  String? payloadOf(int id) =>
      LocalNotificationSchedulerService.testScheduled
          .firstWhere((c) => c.id == id,
              orElse: () => (id: id, payload: null))
          .payload;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
    await NotificationSettingsService.instance.init();
    db = openTestDatabase();
    onboarding = OnboardingService(prefs);
    LocalNotificationSchedulerService.testMode = true;
    LocalNotificationSchedulerService.resetTestState();
  });

  tearDown(() async {
    LocalNotificationSchedulerService.testMode = false;
    LocalNotificationSchedulerService.resetTestState();
    await db.close();
    AnalyticsService.resetForTesting();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Brew reminders (IDs 1001, 1002)
  // ─────────────────────────────────────────────────────────────────────────

  group('brew reminders', () {
    test('does not schedule when no stats exist', () async {
      await runScheduler();

      expect(scheduled(1001), isFalse);
      expect(scheduled(1002), isFalse);
    });

    test('schedules both reminders when last brew was 3 days ago', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 3))),
      );
      await runScheduler();

      // gentle = now-3d+5d = +2d (future); escalation = now-3d+10d = +7d (future)
      expect(scheduled(1001), isTrue);
      expect(scheduled(1002), isTrue);
    });

    test('skips gentle reminder when brew was 7 days ago, keeps escalation',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 7))),
      );
      await runScheduler();

      // gentle = now-7d+5d = -2d (past → skipped)
      // escalation = now-7d+10d = +3d (future → scheduled)
      expect(scheduled(1001), isFalse);
      expect(scheduled(1002), isTrue);
    });

    test('skips both reminders when brew was 12 days ago', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 12))),
      );
      await runScheduler();

      // gentle = -7d (past); escalation = -2d (past) → both skipped
      expect(scheduled(1001), isFalse);
      expect(scheduled(1002), isFalse);
    });

    test('brew reminder payloads are notif: scheme for analytics tracking',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 3))),
      );
      await runScheduler();

      expect(payloadOf(1001), equals('notif:brew_reminder'));
      expect(payloadOf(1002), equals('notif:brew_escalation'));
    });

    test('uses most recent brew date when multiple stats exist', () async {
      // Older brew 12 days ago — alone it would produce no reminders
      await db.userStatsDao.insertUserStat(
        _makeStat(
            uuid: 'old',
            createdAt: DateTime.now().subtract(const Duration(days: 12))),
      );
      // Recent brew 3 days ago — should produce both reminders
      await db.userStatsDao.insertUserStat(
        _makeStat(
            uuid: 'recent',
            createdAt: DateTime.now().subtract(const Duration(days: 3))),
      );
      await runScheduler();

      expect(scheduled(1001), isTrue);
      expect(scheduled(1002), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Feature discovery: beans (ID 1101)
  // ─────────────────────────────────────────────────────────────────────────

  group('feature discovery: beans', () {
    test('does not schedule when milestone already completed', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_milestone_add_beans': true,
      });
      prefs = await SharedPreferences.getInstance();
      onboarding = OnboardingService(prefs);
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 7))),
      );
      await runScheduler();

      expect(scheduled(1101), isFalse);
    });

    test('does not schedule when first brew is too recent (3 days ago)',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 3))),
      );
      await runScheduler();

      expect(scheduled(1101), isFalse);
    });

    test('schedules with /new_beans payload when milestone not done and brew 7+ days old',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 7))),
      );
      await runScheduler();

      expect(scheduled(1101), isTrue);
      expect(payloadOf(1101), equals('/new_beans'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Feature discovery: pulse (ID 1103)
  // ─────────────────────────────────────────────────────────────────────────

  group('feature discovery: pulse', () {
    test('does not schedule when milestone already completed', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_milestone_pulse': true,
      });
      prefs = await SharedPreferences.getInstance();
      onboarding = OnboardingService(prefs);
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 7))),
      );
      await runScheduler();

      expect(scheduled(1103), isFalse);
    });

    test('does not schedule when first brew is too recent (3 days ago)',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 3))),
      );
      await runScheduler();

      expect(scheduled(1103), isFalse);
    });

    test('schedules with /pulse payload when milestone not done and brew 7+ days old',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 7))),
      );
      await runScheduler();

      expect(scheduled(1103), isTrue);
      expect(payloadOf(1103), equals('/pulse'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Brew milestone celebration (ID 1501)
  // ─────────────────────────────────────────────────────────────────────────

  group('brew milestone celebration', () {
    Future<void> insertBrews(int count) async {
      for (var i = 0; i < count; i++) {
        await db.userStatsDao.insertUserStat(_makeStat(uuid: 'stat-$i'));
      }
    }

    test('does not schedule when no brews exist', () async {
      await runScheduler();

      expect(scheduled(1501), isFalse);
    });

    test('does not schedule when brew count is below all thresholds (5 brews)',
        () async {
      await insertBrews(5);
      await runScheduler();

      expect(scheduled(1501), isFalse);
    });

    test('schedules at first threshold (10 brews) with /stats payload',
        () async {
      await insertBrews(10);
      await runScheduler();

      expect(scheduled(1501), isTrue);
      expect(payloadOf(1501), equals('/stats'));
    });

    test('does not schedule when milestone already celebrated', () async {
      await insertBrews(10);
      SharedPreferences.setMockInitialValues({
        'notif_last_celebrated_milestone': 10,
      });
      // rescheduleAll reads a fresh SharedPreferences.getInstance() internally
      await runScheduler();

      expect(scheduled(1501), isFalse);
    });

    test('celebrates highest uncelebrated threshold when multiple are reached',
        () async {
      await insertBrews(50); // reaches 10, 25, 50
      SharedPreferences.setMockInitialValues({
        'notif_last_celebrated_milestone': 25,
      });
      await runScheduler();

      expect(scheduled(1501), isTrue);
      final p = await SharedPreferences.getInstance();
      expect(p.getInt('notif_last_celebrated_milestone'), 50);
    });

    test('persists celebrated milestone to prefs after scheduling', () async {
      await insertBrews(25);
      await runScheduler();

      final p = await SharedPreferences.getInstance();
      expect(p.getInt('notif_last_celebrated_milestone'), 25);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Recipe exploration nudge (ID 1701)
  // ─────────────────────────────────────────────────────────────────────────

  group('recipe exploration nudge', () {
    final oldEnough = DateTime.now().subtract(const Duration(days: 10));

    test('does not schedule when already shown (once-ever prefs key set)',
        () async {
      SharedPreferences.setMockInitialValues({
        'notif_recipe_explore_shown': true,
      });
      await db.userStatsDao.insertUserStat(_makeStat(createdAt: oldEnough));
      await runScheduler();

      expect(scheduled(1701), isFalse);
    });

    test('does not schedule when first brew is too recent (5 days ago)',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now().subtract(const Duration(days: 5))),
      );
      await runScheduler();

      expect(scheduled(1701), isFalse);
    });

    test('does not schedule when user has 3+ distinct brewed recipes',
        () async {
      await db.userStatsDao.insertUserStat(
          _makeStat(uuid: 'a', recipeId: 'r1', createdAt: oldEnough));
      await db.userStatsDao.insertUserStat(
          _makeStat(uuid: 'b', recipeId: 'r2'));
      await db.userStatsDao.insertUserStat(
          _makeStat(uuid: 'c', recipeId: 'r3'));
      await runScheduler();

      expect(scheduled(1701), isFalse);
    });

    test('does not schedule when no untried recipes exist in DB', () async {
      // In-memory DB has no recipes seeded → fetchRecipesForBrewingMethod
      // returns [] → targetRecipeId stays null → no notification.
      await db.userStatsDao.insertUserStat(_makeStat(createdAt: oldEnough));
      await runScheduler();

      expect(scheduled(1701), isFalse);
    });

    test('schedules with /recipes payload when an untried recipe exists',
        () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'stat-1',
          recipeId: 'recipe-1',
          brewingMethodId: 'method-1',
          createdAt: oldEnough,
        ),
      );
      // Seed an untried recipe in the same method (FK constraints disabled).
      await db.recipesDao.insertOrUpdateRecipe(
        RecipesCompanion.insert(
          id: 'recipe-2',
          brewingMethodId: 'method-1',
          coffeeAmount: 15.0,
          waterAmount: 250.0,
          waterTemp: 93.0,
          brewTime: 240,
        ),
      );
      await runScheduler();

      expect(scheduled(1701), isTrue);
      expect(payloadOf(1701), equals('/recipes/method-1/recipe-2'));
    });

    test('marks once-ever prefs key after scheduling', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'stat-1',
          recipeId: 'recipe-1',
          brewingMethodId: 'method-1',
          createdAt: oldEnough,
        ),
      );
      await db.recipesDao.insertOrUpdateRecipe(
        RecipesCompanion.insert(
          id: 'recipe-2',
          brewingMethodId: 'method-1',
          coffeeAmount: 15.0,
          waterAmount: 250.0,
          waterTemp: 93.0,
          brewTime: 240,
        ),
      );
      await runScheduler();

      final p = await SharedPreferences.getInstance();
      expect(p.getBool('notif_recipe_explore_shown'), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Morning reminder (ID 1201)
  // ─────────────────────────────────────────────────────────────────────────

  group('morning reminder', () {
    test('does not schedule when setting is disabled (default off)', () async {
      await runScheduler();

      expect(scheduled(1201), isFalse);
    });

    test('schedules with notif:morning_reminder payload when enabled',
        () async {
      SharedPreferences.setMockInitialValues({
        KEY_MORNING_REMINDER: true,
      });
      await NotificationSettingsService.instance.init();
      await runScheduler();

      expect(scheduled(1201), isTrue);
      expect(payloadOf(1201), equals('notif:morning_reminder'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Weekly reminder (ID 1301)
  // ─────────────────────────────────────────────────────────────────────────

  group('weekly reminder', () {
    test('does not schedule when setting is disabled (default off)', () async {
      await runScheduler();

      expect(scheduled(1301), isFalse);
    });

    test('schedules even when no brews this week (toggle is on)', () async {
      SharedPreferences.setMockInitialValues({KEY_WEEKLY_SUMMARY: true});
      await NotificationSettingsService.instance.init();
      // Brew was 8 days ago — before the start of the current ISO week
      await db.userStatsDao.insertUserStat(
        _makeStat(
            createdAt: DateTime.now().subtract(const Duration(days: 8))),
      );
      await runScheduler();

      expect(scheduled(1301), isTrue);
      expect(payloadOf(1301), equals('/stats?period=thisWeek'));
    });

    test('schedules with /stats?period=thisWeek payload when enabled and brewed this week',
        () async {
      SharedPreferences.setMockInitialValues({KEY_WEEKLY_SUMMARY: true});
      await NotificationSettingsService.instance.init();
      await db.userStatsDao.insertUserStat(
        _makeStat(createdAt: DateTime.now()),
      );
      await runScheduler();

      expect(scheduled(1301), isTrue);
      expect(payloadOf(1301), equals('/stats?period=thisWeek'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Bean freshness alert (ID 1401)
  // ─────────────────────────────────────────────────────────────────────────

  group('bean freshness alert', () {
    test('does not schedule when setting is disabled (default off)', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
            roastDate: DateTime.now().subtract(const Duration(days: 30))),
      );
      await runScheduler();

      expect(scheduled(1401), isFalse);
    });

    test('does not schedule when no beans exist', () async {
      SharedPreferences.setMockInitialValues({KEY_BEAN_FRESHNESS: true});
      await NotificationSettingsService.instance.init();
      await runScheduler();

      expect(scheduled(1401), isFalse);
    });

    test('does not schedule when most recent bean has no roastDate', () async {
      SharedPreferences.setMockInitialValues({KEY_BEAN_FRESHNESS: true});
      await NotificationSettingsService.instance.init();
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(roastDate: null),
      );
      await runScheduler();

      expect(scheduled(1401), isFalse);
    });

    test('does not schedule when bean was roasted fewer than 21 days ago',
        () async {
      SharedPreferences.setMockInitialValues({KEY_BEAN_FRESHNESS: true});
      await NotificationSettingsService.instance.init();
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
            roastDate: DateTime.now().subtract(const Duration(days: 15))),
      );
      await runScheduler();

      expect(scheduled(1401), isFalse);
    });

    test('schedules with /beans payload when bean was roasted 30+ days ago',
        () async {
      SharedPreferences.setMockInitialValues({KEY_BEAN_FRESHNESS: true});
      await NotificationSettingsService.instance.init();
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
            roastDate: DateTime.now().subtract(const Duration(days: 30))),
      );
      await runScheduler();

      expect(scheduled(1401), isTrue);
      expect(payloadOf(1401), equals('/beans/bean-1'));
    });

    test('respects 14-day cooldown — skips within cooldown window', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        KEY_BEAN_FRESHNESS: true,
        'notif_bean_freshness_last_uuid': 'bean-1',
        'notif_bean_freshness_last_date':
            now.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
      });
      await NotificationSettingsService.instance.init();
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
          uuid: 'bean-1',
          roastDate: now.subtract(const Duration(days: 30)),
        ),
      );
      await runScheduler();

      expect(scheduled(1401), isFalse); // 7 days < 14-day cooldown
    });

    test('schedules again once the 14-day cooldown has expired', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        KEY_BEAN_FRESHNESS: true,
        'notif_bean_freshness_last_uuid': 'bean-1',
        'notif_bean_freshness_last_date':
            now.subtract(const Duration(days: 15)).millisecondsSinceEpoch,
      });
      await NotificationSettingsService.instance.init();
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
          uuid: 'bean-1',
          roastDate: now.subtract(const Duration(days: 30)),
        ),
      );
      await runScheduler();

      expect(scheduled(1401), isTrue); // 15 days > 14-day cooldown
    });

    test('persists bean UUID and timestamp to prefs after scheduling',
        () async {
      SharedPreferences.setMockInitialValues({KEY_BEAN_FRESHNESS: true});
      await NotificationSettingsService.instance.init();
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
          uuid: 'bean-1',
          roastDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
      );
      await runScheduler();

      final p = await SharedPreferences.getInstance();
      expect(p.getString('notif_bean_freshness_last_uuid'), 'bean-1');
      expect(p.getInt('notif_bean_freshness_last_date'), isNotNull);
    });

    test('prefers more recently roasted bean when multiple exist', () async {
      SharedPreferences.setMockInitialValues({KEY_BEAN_FRESHNESS: true});
      await NotificationSettingsService.instance.init();
      final now = DateTime.now();
      // Both are stale, but bean-2 is the more recent one
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
          uuid: 'bean-1',
          name: 'Older Bean',
          roastDate: now.subtract(const Duration(days: 60)),
        ),
      );
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(
          uuid: 'bean-2',
          name: 'Newer Bean',
          roastDate: now.subtract(const Duration(days: 25)),
        ),
      );
      await runScheduler();

      expect(scheduled(1401), isTrue);
      // bean-2 should be recorded in prefs as it has the later roast date
      final p = await SharedPreferences.getInstance();
      expect(p.getString('notif_bean_freshness_last_uuid'), 'bean-2');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Bean review nudge (ID 1601)
  // ─────────────────────────────────────────────────────────────────────────

  group('bean review nudge — reactive', () {
    Future<void> seedBrews({
      required String beansUuid,
      required int count,
      int daysAgoFirst = 6,
    }) async {
      for (var i = 0; i < count; i++) {
        await db.userStatsDao.insertUserStat(
          _makeStat(
            uuid: 'stat-$beansUuid-$i',
            createdAt:
                DateTime.now().subtract(Duration(days: daysAgoFirst - i)),
          ).copyWith(coffeeBeansUuid: beansUuid),
        );
      }
    }

    test('does nothing when fewer than 5 brews', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-x', name: 'Yirgacheffe'),
      );
      await seedBrews(beansUuid: 'bean-x', count: 4);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
        database: db,
        beansUuid: 'bean-x',
        locale: 'en',
      );

      expect(scheduled(1601), isFalse);
    });

    test('schedules with /beans/<uuid>?focus=review when 5 brews and no review',
        () async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-x', name: 'Yirgacheffe'),
      );
      await seedBrews(beansUuid: 'bean-x', count: 5);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
        database: db,
        beansUuid: 'bean-x',
        locale: 'en',
      );

      expect(scheduled(1601), isTrue);
      expect(payloadOf(1601),
          equals('/beans/bean-x?focus=review&t=brew_count'));
    });

    test('marks reviewNudgeScheduledAt on the bean after scheduling', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-x', name: 'Yirgacheffe'),
      );
      await seedBrews(beansUuid: 'bean-x', count: 5);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
        database: db,
        beansUuid: 'bean-x',
        locale: 'en',
      );

      final updated =
          await db.coffeeBeansDao.fetchCoffeeBeansByUuid('bean-x');
      expect(updated?.reviewNudgeScheduledAt, isNotNull);
    });

    test('does not re-schedule once reviewNudgeScheduledAt is set', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-x', name: 'Yirgacheffe').copyWith(
          reviewNudgeScheduledAt: DateTime.now(),
        ),
      );
      await seedBrews(beansUuid: 'bean-x', count: 6);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
        database: db,
        beansUuid: 'bean-x',
        locale: 'en',
      );

      expect(scheduled(1601), isFalse);
    });

    test('does nothing when toggle is disabled', () async {
      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(false);

      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-x', name: 'Yirgacheffe'),
      );
      await seedBrews(beansUuid: 'bean-x', count: 5);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
        database: db,
        beansUuid: 'bean-x',
        locale: 'en',
      );

      expect(scheduled(1601), isFalse);
    });
  });

  group('bean review nudge — backlog', () {
    Future<void> seedEligibleBean({
      required String uuid,
      required String name,
      required int daysSinceLastBrew,
    }) async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: uuid, name: name),
      );
      // 5 brews, most recent `daysSinceLastBrew` days ago.
      for (var i = 0; i < 5; i++) {
        await db.userStatsDao.insertUserStat(
          _makeStat(
            uuid: 'stat-$uuid-$i',
            createdAt: DateTime.now()
                .subtract(Duration(days: daysSinceLastBrew + (4 - i))),
          ).copyWith(coffeeBeansUuid: uuid),
        );
      }
    }

    test('one-shot scan schedules first candidate and queues the rest',
        () async {
      await seedEligibleBean(uuid: 'bean-a', name: 'A', daysSinceLastBrew: 2);
      await seedEligibleBean(uuid: 'bean-b', name: 'B', daysSinceLastBrew: 5);
      await seedEligibleBean(uuid: 'bean-c', name: 'C', daysSinceLastBrew: 10);

      await runScheduler();

      expect(scheduled(1601), isTrue);
      expect(payloadOf(1601), equals('/beans/bean-a?focus=review&t=backlog'));

      final p = await SharedPreferences.getInstance();
      expect(
          p.getBool('notif_bean_review_backlog_scanned_v1'), isTrue);
      final queue = p.getString('notif_bean_review_backlog_uuids');
      expect(queue, isNotNull);
      expect(queue, contains('bean-b'));
      expect(queue, contains('bean-c'));
    });

    test('backlog scan ignores beans active more than 30 days ago', () async {
      await seedEligibleBean(uuid: 'bean-old', name: 'Old', daysSinceLastBrew: 60);

      await runScheduler();

      expect(scheduled(1601), isFalse);
    });

    test('drip waits 7 days between scheduled nudges', () async {
      // Pretend a nudge was scheduled 3 days ago and queue has one entry.
      SharedPreferences.setMockInitialValues({
        'notif_bean_review_backlog_scanned_v1': true,
        'notif_bean_review_backlog_uuids': '["bean-b"]',
        'notif_bean_review_last_scheduled_ms': DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
      });
      prefs = await SharedPreferences.getInstance();
      await NotificationSettingsService.instance.init();

      await seedEligibleBean(uuid: 'bean-b', name: 'B', daysSinceLastBrew: 2);

      await runScheduler();

      expect(scheduled(1601), isFalse);
    });

    test('drip schedules next when 7+ days have passed', () async {
      SharedPreferences.setMockInitialValues({
        'notif_bean_review_backlog_scanned_v1': true,
        'notif_bean_review_backlog_uuids': '["bean-b"]',
        'notif_bean_review_last_scheduled_ms': DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch,
      });
      prefs = await SharedPreferences.getInstance();
      await NotificationSettingsService.instance.init();

      await seedEligibleBean(uuid: 'bean-b', name: 'B', daysSinceLastBrew: 2);

      await runScheduler();

      expect(scheduled(1601), isTrue);
      expect(payloadOf(1601), equals('/beans/bean-b?focus=review&t=backlog'));

      final p = await SharedPreferences.getInstance();
      expect(p.getString('notif_bean_review_backlog_uuids'), equals('[]'));
    });
  });

  group('bean review nudge — self-healing & unique IDs', () {
    Future<void> seedBrews(String beansUuid, int count) async {
      for (var i = 0; i < count; i++) {
        await db.userStatsDao.insertUserStat(
          _makeStat(
            uuid: 'stat-$beansUuid-$i',
            createdAt: DateTime.now().subtract(Duration(days: 6 - i)),
          ).copyWith(coffeeBeansUuid: beansUuid),
        );
      }
    }

    // P0: a reactive nudge must survive the next rescheduleAll instead of being
    // cancelled and forgotten.
    test('a pending nudge is recreated by a later rescheduleAll', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'Yirgacheffe'));
      await seedBrews('bean-x', 5);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
              database: db, beansUuid: 'bean-x', locale: 'en');
      expect(scheduled(1601), isTrue);

      // Simulate the next app open: OS notification is gone, DB state persists.
      LocalNotificationSchedulerService.resetTestState();
      await runScheduler();

      expect(scheduled(1601), isTrue,
          reason: 'pending nudge should survive a reschedule cycle');
      expect(payloadOf(1601),
          equals('/beans/bean-x?focus=review&t=brew_count'));
    });

    // P1: two beans over threshold must occupy distinct IDs, not clobber 1601.
    test('two beans over threshold get distinct notification IDs', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'X'));
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-y', name: 'Y'));
      await seedBrews('bean-x', 5);
      await seedBrews('bean-y', 5);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
              database: db, beansUuid: 'bean-x', locale: 'en');
      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudge(
              database: db, beansUuid: 'bean-y', locale: 'en');

      // Re-materialize from state so both pending nudges are laid out together.
      LocalNotificationSchedulerService.resetTestState();
      await runScheduler();

      final bandCalls = LocalNotificationSchedulerService.testScheduled
          .where((c) => c.id >= 1601 && c.id <= 1610);
      expect(bandCalls.map((c) => c.id).toSet().length, 2,
          reason: 'each bean should occupy its own slot');
      expect(
        bandCalls.map((c) => c.payload).toSet(),
        {
          '/beans/bean-x?focus=review&t=brew_count',
          '/beans/bean-y?focus=review&t=brew_count'
        },
      );
    });
  });

  group('bean review nudge — depletion', () {
    Future<void> seedBrews(String beansUuid, int count) async {
      for (var i = 0; i < count; i++) {
        await db.userStatsDao.insertUserStat(
          _makeStat(
            uuid: 'stat-$beansUuid-$i',
            createdAt: DateTime.now().subtract(Duration(days: 6 - i)),
          ).copyWith(coffeeBeansUuid: beansUuid),
        );
      }
    }

    test('schedules on depletion at the 2-brew floor', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'X'));
      await seedBrews('bean-x', 2);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudgeOnDepletion(
              database: db, beansUuid: 'bean-x', locale: 'en');

      expect(scheduled(1601), isTrue);
      expect(payloadOf(1601),
          equals('/beans/bean-x?focus=review&t=depletion'));
    });

    test('does nothing on depletion with fewer than 2 brews', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'X'));
      await seedBrews('bean-x', 1);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudgeOnDepletion(
              database: db, beansUuid: 'bean-x', locale: 'en');

      expect(scheduled(1601), isFalse);
    });

    // Shared one-time guard: a bean already nudged (e.g. by the brew-count
    // trigger on the same emptying brew) must not be nudged again on depletion.
    test('does not double-nudge a bean already marked', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(
        _makeBean(uuid: 'bean-x', name: 'X')
            .copyWith(reviewNudgeScheduledAt: DateTime.now()),
      );
      await seedBrews('bean-x', 5);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudgeOnDepletion(
              database: db, beansUuid: 'bean-x', locale: 'en');

      expect(scheduled(1601), isFalse);
    });

    test('does nothing when toggle is disabled', () async {
      await NotificationSettingsService.instance
          .setBeanReviewNudgeEnabled(false);
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'X'));
      await seedBrews('bean-x', 3);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudgeOnDepletion(
              database: db, beansUuid: 'bean-x', locale: 'en');

      expect(scheduled(1601), isFalse);
    });
  });

  group('bean review nudge — delivery measurement', () {
    Future<void> seedBrews(String beansUuid, int count) async {
      for (var i = 0; i < count; i++) {
        await db.userStatsDao.insertUserStat(
          _makeStat(
            uuid: 'stat-$beansUuid-$i',
            createdAt: DateTime.now().subtract(Duration(days: 6 - i)),
          ).copyWith(coffeeBeansUuid: beansUuid),
        );
      }
    }

    test('stamping records an in-flight entry with trigger and future fire time',
        () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'X'));
      await seedBrews('bean-x', 2);

      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudgeOnDepletion(
              database: db, beansUuid: 'bean-x', locale: 'en');

      final p = await SharedPreferences.getInstance();
      final map = jsonDecode(p.getString('notif_bean_review_inflight_v1')!)
          as Map<String, dynamic>;
      expect(map.containsKey('bean-x'), isTrue);
      final entry = map['bean-x'] as Map<String, dynamic>;
      expect(entry['t'], equals('depletion'));
      expect(entry['f'] as int,
          greaterThan(DateTime.now().millisecondsSinceEpoch));
    });

    test('rescheduleAll flushes past-due in-flight nudges, keeps future ones',
        () async {
      final past = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      final future =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'notif_bean_review_inflight_v1': jsonEncode({
          'bean-past': {'t': 'depletion', 'f': past},
          'bean-future': {'t': 'brew_count', 'f': future},
        }),
      });
      prefs = await SharedPreferences.getInstance();
      await NotificationSettingsService.instance.init();

      await runScheduler();

      final p = await SharedPreferences.getInstance();
      final map = jsonDecode(p.getString('notif_bean_review_inflight_v1')!)
          as Map<String, dynamic>;
      expect(map.containsKey('bean-past'), isFalse,
          reason: 'fired nudge should be flushed (presumed delivered)');
      expect(map.containsKey('bean-future'), isTrue,
          reason: 'not-yet-fired nudge should remain in flight');
    });
  });

  group('bean review nudge — cancel on review', () {
    Future<void> seedBrews(String beansUuid, int count) async {
      for (var i = 0; i < count; i++) {
        await db.userStatsDao.insertUserStat(
          _makeStat(
            uuid: 'stat-$beansUuid-$i',
            createdAt: DateTime.now().subtract(Duration(days: 6 - i)),
          ).copyWith(coffeeBeansUuid: beansUuid),
        );
      }
    }

    test('drops a pending nudge and prevents re-materialize', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-x', name: 'X'));
      await seedBrews('bean-x', 2);
      await LocalNotificationSchedulerService.instance
          .maybeScheduleBeanReviewNudgeOnDepletion(
              database: db, beansUuid: 'bean-x', locale: 'en');
      expect(scheduled(1601), isTrue);

      await LocalNotificationSchedulerService.instance
          .cancelPendingNudgeOnReview(database: db, beansUuid: 'bean-x');

      final p = await SharedPreferences.getInstance();
      final raw = p.getString('notif_bean_review_inflight_v1');
      final map = raw == null ? {} : jsonDecode(raw) as Map;
      expect(map.containsKey('bean-x'), isFalse,
          reason: 'reviewed bean removed from in-flight watchlist');

      // A later reschedule must not recreate the superseded nudge.
      LocalNotificationSchedulerService.resetTestState();
      await runScheduler();
      expect(scheduled(1601), isFalse);
    });

    test('is a no-op when no nudge is pending', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-y', name: 'Y'));

      await LocalNotificationSchedulerService.instance
          .cancelPendingNudgeOnReview(database: db, beansUuid: 'bean-y');

      final updated =
          await db.coffeeBeansDao.fetchCoffeeBeansByUuid('bean-y');
      expect(updated?.reviewNudgeScheduledAt, isNull,
          reason: 'bean with no pending nudge is not marked terminal');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Roaster contribution nudge (IDs 1801..1810) — plan 011, Channel B
  // ─────────────────────────────────────────────────────────────────────────

  group('roaster contribution nudge', () {
    const scheduledKey = 'notif_roaster_contrib_scheduled_v1';
    const resolvedKey = 'roaster_contrib_resolved_v1';

    int msIn(Duration d) => DateTime.now().add(d).millisecondsSinceEpoch;

    test('materializes a scheduled nudge into the reserved band', () async {
      SharedPreferences.setMockInitialValues({
        scheduledKey: jsonEncode({
          'cluster-1': {
            'roaster': 'Onyx',
            'beanUuid': 'bean-1',
            'f': msIn(const Duration(days: 1)),
          },
        }),
      });

      await runScheduler();

      expect(scheduled(1801), isTrue);
      expect(payloadOf(1801), equals('/beans/bean-1?t=roaster_contribution'));
    });

    test('schedules multiple pending nudges, soonest first', () async {
      SharedPreferences.setMockInitialValues({
        scheduledKey: jsonEncode({
          'cluster-1': {
            'roaster': 'Onyx',
            'beanUuid': 'bean-1',
            'f': msIn(const Duration(days: 1)),
          },
          'cluster-2': {
            'roaster': 'Tim Wendelboe',
            'beanUuid': 'bean-2',
            'f': msIn(const Duration(days: 2)),
          },
        }),
      });

      await runScheduler();

      expect(scheduled(1801), isTrue);
      expect(scheduled(1802), isTrue);
      // Soonest takes the base ID.
      expect(payloadOf(1801), equals('/beans/bean-1?t=roaster_contribution'));
    });

    test('skips a cluster the user has already resolved', () async {
      SharedPreferences.setMockInitialValues({
        scheduledKey: jsonEncode({
          'cluster-1': {
            'roaster': 'Onyx',
            'beanUuid': 'bean-1',
            'f': msIn(const Duration(days: 1)),
          },
        }),
        resolvedKey: ['cluster-1'],
      });

      await runScheduler();

      expect(scheduled(1801), isFalse);
    });

    test('does not schedule a past-due (presumed-delivered) nudge', () async {
      SharedPreferences.setMockInitialValues({
        scheduledKey: jsonEncode({
          'cluster-1': {
            'roaster': 'Onyx',
            'beanUuid': 'bean-1',
            'f': msIn(const Duration(hours: -1)),
          },
        }),
      });

      await runScheduler();

      expect(scheduled(1801), isFalse);
    });

    test('cancelRoasterContribNudge removes a pending nudge', () async {
      SharedPreferences.setMockInitialValues({
        scheduledKey: jsonEncode({
          'cluster-1': {
            'roaster': 'Onyx',
            'beanUuid': 'bean-1',
            'f': msIn(const Duration(days: 1)),
          },
        }),
      });

      await LocalNotificationSchedulerService.instance
          .cancelRoasterContribNudge('cluster-1');

      // Dropped from the scheduled map…
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(scheduledKey);
      expect(raw == null || !raw.contains('cluster-1'), isTrue);

      // …and a later reschedule does not recreate it.
      await runScheduler();
      expect(scheduled(1801), isFalse);
    });
  });
}
