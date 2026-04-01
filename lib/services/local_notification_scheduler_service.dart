import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/services/notification_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';

class LocalNotificationSchedulerService {
  static final LocalNotificationSchedulerService instance =
      LocalNotificationSchedulerService._();
  LocalNotificationSchedulerService._();

  // --- Notification IDs ---
  static const _idBrewReminder = 1001;
  static const _idBrewEscalation = 1002;
  static const _idDiscoverBeans = 1101;
  static const _idDiscoverPulse = 1103;
  static const _idMorningReminder = 1201;
  static const _idWeeklySummary = 1301;
  static const _idBeanFreshness = 1401;
  static const _idBrewMilestone = 1501;
  static const _idRecipeExplore = 1701;

  static const _allIds = [
    _idBrewReminder,
    _idBrewEscalation,
    _idDiscoverBeans,
    _idDiscoverPulse,
    _idMorningReminder,
    _idWeeklySummary,
    _idBeanFreshness,
    _idBrewMilestone,
    _idRecipeExplore,
  ];

  // --- SharedPreferences cooldown keys ---
  static const _keyLastCelebratedMilestone = 'notif_last_celebrated_milestone';
  static const _keyRecipeExploreShown = 'notif_recipe_explore_shown';
  static const _keyBeanFreshnessLastUuid = 'notif_bean_freshness_last_uuid';
  static const _keyBeanFreshnessLastDate = 'notif_bean_freshness_last_date';
  // Prevents brew inactivity reminders from firing more than once per 14 days,
  // so casual brewers with ~weekly cadence aren't repeatedly nagged.
  static const _keyBrewReminderLastScheduled =
      'notif_brew_reminder_last_scheduled';

  // --- Milestone thresholds ---
  static const _milestoneThresholds = [10, 25, 50, 100, 250, 500];

  // --- Test seams ---
  // Set [testMode] = true in tests to bypass NotificationService platform calls.
  // Every notification that would have been scheduled is instead appended to
  // [testScheduled] so assertions can inspect id + payload without touching the OS.

  @visibleForTesting
  static bool testMode = false;

  @visibleForTesting
  static final List<({int id, String? payload})> testScheduled = [];

  @visibleForTesting
  static void resetTestState() => testScheduled.clear();

  /// Idempotent reschedule: cancels all engagement notifications, then
  /// re-schedules based on current state.
  Future<void> rescheduleAll({
    required AppDatabase database,
    required OnboardingService onboarding,
    required String locale,
  }) async {
    try {
      if (!testMode && !await _canSchedule()) return;

      await _cancelAll();

      final l10n = lookupAppLocalizations(Locale(locale));
      final prefs = await SharedPreferences.getInstance();
      final userStatsDao = UserStatsDao(database);
      final coffeeBeansDao = CoffeeBeansDao(database);
      final recipesDao = RecipesDao(database);
      final brewingMethodsDao = BrewingMethodsDao(database);
      final settings = NotificationSettingsService.instance;

      await Future.wait([
        // Tier 1
        _scheduleBrewReminders(userStatsDao, l10n, prefs),
        _scheduleFeatureDiscoveryBeans(onboarding, userStatsDao, l10n),
        _scheduleFeatureDiscoveryPulse(onboarding, userStatsDao, l10n),
        _scheduleBrewMilestoneCelebration(userStatsDao, l10n, prefs),
        // Tier 2
        _scheduleRecipeExplorationNudge(
          userStatsDao,
          recipesDao,
          brewingMethodsDao,
          l10n,
          prefs,
          locale,
        ),
        // Tier 3 (optional, toggleable)
        _scheduleMorningReminder(settings, l10n),
        _scheduleWeeklyReminder(settings, userStatsDao, l10n),
        _scheduleBeanFreshnessAlert(settings, coffeeBeansDao, l10n, prefs),
      ]);

      AppLogger.debug('Engagement notifications rescheduled');
    } catch (e) {
      AppLogger.error('Failed to reschedule engagement notifications',
          errorObject: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<bool> _canSchedule() async {
    final service = NotificationService.instance;
    if (!service.isInitialized) return false;
    return await service.settings.isMasterEnabled();
  }

  Future<void> _cancelAll() async {
    if (testMode) return;
    final service = NotificationService.instance;
    for (final id in _allIds) {
      await service.cancelNotification(id);
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    if (at.isBefore(DateTime.now())) return;
    if (testMode) {
      testScheduled.add((id: id, payload: payload));
      return;
    }
    await NotificationService.instance.scheduleLocalNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // Tier 1 — Brew reminders
  // ---------------------------------------------------------------------------

  Future<void> _scheduleBrewReminders(
    UserStatsDao dao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    final allStats = await dao.fetchAllStats();
    if (allStats.isEmpty) return;

    // 14-day cooldown — prevents casual brewers with a ~weekly cadence from
    // being nagged after every brew gap.
    final lastMs = prefs.getInt(_keyBrewReminderLastScheduled);
    if (lastMs != null) {
      final daysSinceLast = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
          .inDays;
      if (daysSinceLast < 14) return;
    }

    // allStats is ordered by createdAt DESC — first item is most recent.
    final lastBrew = allStats.first.createdAt;
    final gentle = _atTime(lastBrew.add(const Duration(days: 5)), 10, 0);
    final escalation = _atTime(lastBrew.add(const Duration(days: 10)), 10, 0);

    final now = DateTime.now();
    bool didSchedule = false;

    final rng = Random();

    if (gentle.isAfter(now)) {
      final reminderTitles = [
        l10n.notifBrewReminderTitle,
        l10n.notifBrewReminderTitle2,
        l10n.notifBrewReminderTitle3,
      ];
      final reminderBodies = [
        l10n.notifBrewReminderBody,
        l10n.notifBrewReminderBody2,
        l10n.notifBrewReminderBody3,
      ];
      final i = rng.nextInt(reminderTitles.length);
      await _schedule(
        id: _idBrewReminder,
        title: reminderTitles[i],
        body: reminderBodies[i],
        at: gentle,
        payload: 'notif:brew_reminder',
      );
      didSchedule = true;
    }
    if (escalation.isAfter(now)) {
      final escalationTitles = [
        l10n.notifBrewEscalationTitle,
        l10n.notifBrewEscalationTitle2,
        l10n.notifBrewEscalationTitle3,
      ];
      final escalationBodies = [
        l10n.notifBrewEscalationBody,
        l10n.notifBrewEscalationBody2,
        l10n.notifBrewEscalationBody3,
      ];
      final j = rng.nextInt(escalationTitles.length);
      await _schedule(
        id: _idBrewEscalation,
        title: escalationTitles[j],
        body: escalationBodies[j],
        at: escalation,
        payload: 'notif:brew_escalation',
      );
      didSchedule = true;
    }

    // Only stamp the cooldown when something was actually scheduled, so a
    // reschedule where both dates are already past doesn't reset the clock.
    if (didSchedule) {
      await prefs.setInt(
          _keyBrewReminderLastScheduled, now.millisecondsSinceEpoch);
    }
  }

  // ---------------------------------------------------------------------------
  // Tier 1 — Feature discovery
  // ---------------------------------------------------------------------------

  Future<void> _scheduleFeatureDiscoveryBeans(
    OnboardingService onboarding,
    UserStatsDao dao,
    AppLocalizations l10n,
  ) async {
    if (onboarding.milestoneAddBeans) return;
    if (!await _isFirstBrewOldEnough(dao, 5)) return;

    await _schedule(
      id: _idDiscoverBeans,
      title: l10n.notifDiscoverBeansTitle,
      body: l10n.notifDiscoverBeansBody,
      at: _atTime(DateTime.now().add(const Duration(days: 7)), 14, 0),
      payload: '/new_beans',
    );
  }

  Future<void> _scheduleFeatureDiscoveryPulse(
    OnboardingService onboarding,
    UserStatsDao dao,
    AppLocalizations l10n,
  ) async {
    if (onboarding.milestonePulse) return;
    if (!await _isFirstBrewOldEnough(dao, 5)) return;

    // Stagger 3 days after beans discovery
    await _schedule(
      id: _idDiscoverPulse,
      title: l10n.notifDiscoverPulseTitle,
      body: l10n.notifDiscoverPulseBody,
      at: _atTime(DateTime.now().add(const Duration(days: 10)), 14, 0),
      payload: '/pulse',
    );
  }

  // ---------------------------------------------------------------------------
  // Tier 1 — Brew milestone celebration
  // ---------------------------------------------------------------------------

  Future<void> _scheduleBrewMilestoneCelebration(
    UserStatsDao dao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    final allStats = await dao.fetchAllStats();
    final count = allStats.length;
    final lastCelebrated = prefs.getInt(_keyLastCelebratedMilestone) ?? 0;

    // Find the highest milestone the user has reached but not yet celebrated
    int? milestoneToFire;
    for (final threshold in _milestoneThresholds) {
      if (count >= threshold && threshold > lastCelebrated) {
        milestoneToFire = threshold;
      }
    }

    if (milestoneToFire == null) return;

    await prefs.setInt(_keyLastCelebratedMilestone, milestoneToFire);
    await _schedule(
      id: _idBrewMilestone,
      title: l10n.notifBrewMilestoneTitle,
      body: l10n.notifBrewMilestoneBody(milestoneToFire),
      at: DateTime.now().add(const Duration(hours: 2)),
      payload: '/stats',
    );
  }

  // ---------------------------------------------------------------------------
  // Tier 2 — Recipe exploration nudge
  // ---------------------------------------------------------------------------

  Future<void> _scheduleRecipeExplorationNudge(
    UserStatsDao userStatsDao,
    RecipesDao recipesDao,
    BrewingMethodsDao brewingMethodsDao,
    AppLocalizations l10n,
    SharedPreferences prefs,
    String locale,
  ) async {
    // Fire at most once ever
    if (prefs.getBool(_keyRecipeExploreShown) == true) return;

    // Only if first brew was 7+ days ago
    if (!await _isFirstBrewOldEnough(userStatsDao, 7)) return;

    final allStats = await userStatsDao.fetchAllStats();
    final brewedRecipeIds = <String>{};
    final methodBrewCounts = <String, int>{};
    for (final stat in allStats) {
      brewedRecipeIds.add(stat.recipeId);
      methodBrewCounts[stat.brewingMethodId] =
          (methodBrewCounts[stat.brewingMethodId] ?? 0) + 1;
    }

    // Only trigger if user has tried fewer than 3 distinct recipes
    if (brewedRecipeIds.length >= 3) return;

    // Sort methods by brew count descending (prefer comfort zone)
    final sortedMethods = methodBrewCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find an untried recipe from a familiar method
    String? targetRecipeId;
    String? targetMethodId;
    String? targetMethodName;
    for (final entry in sortedMethods) {
      final methodId = entry.key;
      final recipes =
          await recipesDao.fetchRecipesForBrewingMethod(methodId, locale);
      for (final recipe in recipes) {
        if (!brewedRecipeIds.contains(recipe.id)) {
          targetRecipeId = recipe.id;
          targetMethodId = methodId;
          targetMethodName =
              await brewingMethodsDao.getBrewingMethodNameById(methodId);
          break;
        }
      }
      if (targetRecipeId != null) break;
    }

    if (targetRecipeId == null || targetMethodId == null) return;

    await prefs.setBool(_keyRecipeExploreShown, true);
    await _schedule(
      id: _idRecipeExplore,
      title: l10n.notifExploreRecipesTitle(targetMethodName ?? targetMethodId),
      body: l10n.notifExploreRecipesBody(brewedRecipeIds.length),
      at: _atTime(DateTime.now().add(const Duration(days: 5)), 15, 0),
      payload: '/recipes/$targetMethodId/$targetRecipeId',
    );
  }

  // ---------------------------------------------------------------------------
  // Tier 3 — Optional (toggleable)
  // ---------------------------------------------------------------------------

  Future<void> _scheduleMorningReminder(
    NotificationSettingsService settings,
    AppLocalizations l10n,
  ) async {
    if (!await settings.isMorningReminderEnabled()) return;

    final time = await settings.getMorningReminderTime();
    final now = DateTime.now();
    var target =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (target.isBefore(now)) {
      // Use DateTime constructor (not Duration.add) so DST transitions are
      // handled correctly — adding 86400 s on a 23-hour DST day shifts the
      // wall-clock time by one hour.
      target =
          DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
    }

    final morningTitles = [
      l10n.notifMorningTitle,
      l10n.notifMorningTitle2,
      l10n.notifMorningTitle3,
    ];
    final morningBodies = [
      l10n.notifMorningBody,
      l10n.notifMorningBody2,
      l10n.notifMorningBody3,
    ];
    final i = Random().nextInt(morningTitles.length);
    await _schedule(
      id: _idMorningReminder,
      title: morningTitles[i],
      body: morningBodies[i],
      at: target,
      payload: 'notif:morning_reminder',
    );
  }

  Future<void> _scheduleWeeklyReminder(
    NotificationSettingsService settings,
    UserStatsDao dao,
    AppLocalizations l10n,
  ) async {
    if (!await settings.isWeeklySummaryEnabled()) return;

    // Collect this week's brews.
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final allStats = await dao.fetchAllStats();
    final weeklyStats = allStats
        .where((s) => !s.createdAt.isBefore(weekStart))
        .toList();
    final brewCount = weeklyStats.length;
    if (brewCount == 0) return;

    final distinctRecipes =
        weeklyStats.map((s) => s.recipeId).toSet().length;

    // Next Sunday at 18:00
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSunday = now.add(Duration(
      days: daysUntilSunday == 0 ? 7 : daysUntilSunday,
    ));
    final target =
        DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 18, 0);

    await _schedule(
      id: _idWeeklySummary,
      title: l10n.notifWeeklyTitle(brewCount),
      body: l10n.notifWeeklyBody(distinctRecipes),
      at: target,
      payload: '/stats?period=thisWeek',
    );
  }

  Future<void> _scheduleBeanFreshnessAlert(
    NotificationSettingsService settings,
    CoffeeBeansDao dao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    if (!await settings.isBeanFreshnessEnabled()) return;

    final beans = await dao.fetchAllCoffeeBeans();
    if (beans.isEmpty) return;

    // Find the most recently roasted bean
    CoffeeBeansModel? candidate;
    for (final bean in beans) {
      if (bean.roastDate == null || bean.isDeleted) continue;
      // Skip beans the user has explicitly recorded as empty (< 0.1 g)
      if (bean.packageWeightGrams != null && bean.packageWeightGrams! < 0.1) continue;
      if (candidate == null ||
          bean.roastDate!.isAfter(candidate.roastDate!)) {
        candidate = bean;
      }
    }
    if (candidate == null) return;

    final daysSinceRoast =
        DateTime.now().difference(candidate.roastDate!).inDays;
    if (daysSinceRoast < 21) return;

    // Cooldown: don't re-nag the same bean within 14 days
    final lastUuid = prefs.getString(_keyBeanFreshnessLastUuid);
    final lastDateMs = prefs.getInt(_keyBeanFreshnessLastDate);
    if (lastUuid == candidate.beansUuid && lastDateMs != null) {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastDateMs);
      if (DateTime.now().difference(lastDate).inDays < 14) return;
    }

    await prefs.setString(_keyBeanFreshnessLastUuid, candidate.beansUuid);
    await prefs.setInt(
        _keyBeanFreshnessLastDate, DateTime.now().millisecondsSinceEpoch);

    final beanName = candidate.name.isNotEmpty ? candidate.name : candidate.roaster;
    await _schedule(
      id: _idBeanFreshness,
      title: l10n.notifBeanFreshnessTitle,
      body: l10n.notifBeanFreshnessBody(beanName, daysSinceRoast),
      at: _atTime(DateTime.now().add(const Duration(days: 1)), 11, 0),
      payload: '/beans/${candidate.beansUuid}',
    );
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  /// Returns [date] with time set to [hour]:[minute].
  DateTime _atTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Checks whether the user's first brew is at least [days] old.
  Future<bool> _isFirstBrewOldEnough(UserStatsDao dao, int days) async {
    final earliest = await dao.fetchEarliestStat();
    if (earliest == null) return false;
    return DateTime.now().difference(earliest.createdAt).inDays >= days;
  }
}
