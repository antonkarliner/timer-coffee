import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/notification_image_helper.dart';
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
  static const _idBeanReviewNudge = 1601;
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
    _idBeanReviewNudge,
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
  static const _keyBeanReviewBacklogScanned =
      'notif_bean_review_backlog_scanned_v1';
  static const _keyBeanReviewBacklogQueue = 'notif_bean_review_backlog_uuids';
  static const _keyBeanReviewLastScheduledMs =
      'notif_bean_review_last_scheduled_ms';

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
        _scheduleBeanReviewBacklog(
            settings, coffeeBeansDao, userStatsDao, l10n, prefs),
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
    String? imagePath,
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
      imagePath: imagePath,
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
    final distinctRecipes =
        weeklyStats.map((s) => s.recipeId).toSet().length;

    // Sunday at 18:00 — today if it's still Sunday and 18:00 hasn't passed,
    // otherwise next Sunday. Without this branch, a Sunday-morning reschedule
    // (e.g. from a daily brewer's first brew) cancels the pending 18:00 recap
    // and pushes it a week out, so the recap never fires.
    final todayAt6pm = DateTime(now.year, now.month, now.day, 18, 0);
    final DateTime target;
    if (now.weekday == DateTime.sunday && now.isBefore(todayAt6pm)) {
      target = todayAt6pm;
    } else {
      final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      final nextSunday = now.add(Duration(
        days: daysUntilSunday == 0 ? 7 : daysUntilSunday,
      ));
      target =
          DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 18, 0);
    }

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
  // Tier 3 — Bean review nudge
  // ---------------------------------------------------------------------------

  static const int _beanReviewMinBrews = 5;

  /// Reactive entry point — called after a brew is persisted. Schedules a
  /// one-time review nudge if this bean just crossed the 5-brew threshold,
  /// has no review yet, and has never been nudged.
  Future<void> maybeScheduleBeanReviewNudge({
    required AppDatabase database,
    required String beansUuid,
    required String locale,
  }) async {
    try {
      final settings = NotificationSettingsService.instance;
      if (!await settings.isBeanReviewNudgeEnabled()) return;
      if (!testMode && !await _canSchedule()) return;

      final coffeeBeansDao = CoffeeBeansDao(database);
      final userStatsDao = UserStatsDao(database);
      final bean = await coffeeBeansDao.fetchCoffeeBeansByUuid(beansUuid);
      if (bean == null || bean.isDeleted) return;
      if (bean.reviewNudgeScheduledAt != null) return;

      final stats = await userStatsDao.fetchStatsByBeanUuid(beansUuid);
      if (stats.length < _beanReviewMinBrews) return;

      if (await _hasExistingBeanReview(beansUuid)) return;

      final l10n = lookupAppLocalizations(Locale(locale));
      final prefs = await SharedPreferences.getInstance();
      await _scheduleNudgeFor(
          bean: bean, dao: coffeeBeansDao, prefs: prefs, l10n: l10n);
    } catch (e) {
      AppLogger.error('Failed to schedule bean review nudge', errorObject: e);
    }
  }

  /// One-shot backlog scan + 7-day drip for existing eligible beans.
  Future<void> _scheduleBeanReviewBacklog(
    NotificationSettingsService settings,
    CoffeeBeansDao coffeeBeansDao,
    UserStatsDao userStatsDao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    if (!await settings.isBeanReviewNudgeEnabled()) return;

    final alreadyScanned =
        prefs.getBool(_keyBeanReviewBacklogScanned) ?? false;

    if (!alreadyScanned) {
      final candidates = await coffeeBeansDao.fetchBeanReviewBacklogCandidates(
        activeWithinDays: 30,
        minBrews: _beanReviewMinBrews,
        limit: 3,
      );

      // Skip beans where the user already has a review.
      final filtered = <CoffeeBeansModel>[];
      for (final c in candidates) {
        if (await _hasExistingBeanReview(c.beansUuid)) continue;
        filtered.add(c);
      }

      await prefs.setBool(_keyBeanReviewBacklogScanned, true);
      if (filtered.isEmpty) {
        await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode([]));
        return;
      }

      final first = filtered.first;
      await _scheduleNudgeFor(
          bean: first, dao: coffeeBeansDao, prefs: prefs, l10n: l10n);
      final remaining = filtered.skip(1).map((b) => b.beansUuid).toList();
      await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode(remaining));
      return;
    }

    // Drip path: schedule one more from the queue every 7 days.
    final queueJson = prefs.getString(_keyBeanReviewBacklogQueue);
    if (queueJson == null) return;
    final queue = (jsonDecode(queueJson) as List).cast<String>();
    if (queue.isEmpty) return;

    final lastMs = prefs.getInt(_keyBeanReviewLastScheduledMs) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - lastMs <
        const Duration(days: 7).inMilliseconds) {
      return;
    }

    while (queue.isNotEmpty) {
      final uuid = queue.first;
      final bean = await coffeeBeansDao.fetchCoffeeBeansByUuid(uuid);
      queue.removeAt(0);
      if (bean == null ||
          bean.isDeleted ||
          bean.reviewNudgeScheduledAt != null) {
        continue;
      }
      final stats = await userStatsDao.fetchStatsByBeanUuid(uuid);
      if (stats.length < _beanReviewMinBrews) continue;
      if (await _hasExistingBeanReview(uuid)) continue;

      await _scheduleNudgeFor(
          bean: bean, dao: coffeeBeansDao, prefs: prefs, l10n: l10n);
      await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode(queue));
      return;
    }
    await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode(queue));
  }

  Future<void> _scheduleNudgeFor({
    required CoffeeBeansModel bean,
    required CoffeeBeansDao dao,
    required SharedPreferences prefs,
    required AppLocalizations l10n,
  }) async {
    String? imagePath;
    if (!testMode && bean.roaster.isNotEmpty) {
      try {
        final url = await _resolveRoasterLogoUrl(bean.roaster);
        if (url != null) {
          imagePath = await NotificationImageHelper.downloadLogoToCache(url);
        }
      } catch (e) {
        AppLogger.debug('Roaster logo resolve failed: $e');
      }
    }

    final title = _beanReviewNudgeTitle(l10n, bean);
    final body = l10n.notifBeanReviewNudgeBody;

    final scheduledAt = DateTime.now();
    await dao.updateReviewNudgeScheduledAt(bean.beansUuid, scheduledAt);
    await prefs.setInt(
        _keyBeanReviewLastScheduledMs, scheduledAt.millisecondsSinceEpoch);

    await _schedule(
      id: _idBeanReviewNudge,
      title: title,
      body: body,
      at: _atTime(DateTime.now().add(const Duration(days: 1)), 10, 0),
      payload: '/beans/${bean.beansUuid}?focus=review',
      imagePath: imagePath,
    );

    if (!testMode) {
      AnalyticsService.instance.track(
        'notification_scheduled',
        properties: {
          'notification_type': 'bean_review_nudge',
          'bean_uuid': bean.beansUuid,
          'has_image': imagePath != null,
        },
      );
    }
  }

  /// Test-only: builds and fires the bean review nudge for the given bean,
  /// bypassing all gating (brew count, existing review, prior nudge, master
  /// toggle, permission). Used by the notification debug tooling.
  ///
  /// When [delay] is zero the notification is shown immediately; otherwise it
  /// is scheduled for `now + delay` (so the tester can background the app).
  /// Returns the deeplink payload that was used.
  Future<String> debugFireBeanReviewNudge({
    required AppDatabase database,
    required String beansUuid,
    required String locale,
    Duration delay = Duration.zero,
  }) async {
    final coffeeBeansDao = CoffeeBeansDao(database);
    final bean = await coffeeBeansDao.fetchCoffeeBeansByUuid(beansUuid);
    if (bean == null) {
      throw StateError('Bean not found: $beansUuid');
    }

    String? imagePath;
    if (bean.roaster.isNotEmpty) {
      try {
        final url = await _resolveRoasterLogoUrl(bean.roaster);
        if (url != null) {
          imagePath = await NotificationImageHelper.downloadLogoToCache(url);
        }
      } catch (e) {
        AppLogger.debug('Roaster logo resolve failed (debug): $e');
      }
    }

    final l10n = lookupAppLocalizations(Locale(locale));
    final title = _beanReviewNudgeTitle(l10n, bean);
    final body = l10n.notifBeanReviewNudgeBody;
    final payload = '/beans/${bean.beansUuid}?focus=review';

    if (delay == Duration.zero) {
      await NotificationService.instance.showLocalNotification(
        id: _idBeanReviewNudge,
        title: title,
        body: body,
        payload: payload,
        imagePath: imagePath,
      );
    } else {
      await NotificationService.instance.scheduleLocalNotification(
        id: _idBeanReviewNudge,
        title: title,
        body: body,
        scheduledDate: DateTime.now().add(delay),
        payload: payload,
        imagePath: imagePath,
      );
    }
    return payload;
  }

  Future<bool> _hasExistingBeanReview(String beansUuid) async {
    if (testMode) return false;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final response = await Supabase.instance.client
          .from('bean_reviews')
          .select('id')
          .eq('user_id', user.id)
          .eq('coffee_beans_uuid', beansUuid)
          .maybeSingle();
      return response != null;
    } catch (e) {
      AppLogger.debug('Bean review existence check failed: $e');
      return false;
    }
  }

  Future<String?> _resolveRoasterLogoUrl(String roasterName) async {
    try {
      final response = await Supabase.instance.client
          .rpc('search_roaster_unaccent', params: {'search_name': roasterName})
          .maybeSingle();
      if (response == null) return null;
      final original = (response['roaster_logo_url'] as String?)?.trim();
      final mirror = (response['roaster_logo_mirror_url'] as String?)?.trim();
      final hasOriginal = original != null && original.isNotEmpty;
      final hasMirror = mirror != null && mirror.isNotEmpty;
      if (hasOriginal && hasMirror && _looksLikeGifUrl(original)) {
        return mirror;
      }
      if (hasOriginal) return original;
      if (hasMirror) return mirror;
      return null;
    } catch (e) {
      AppLogger.debug('Roaster logo lookup failed: $e');
      return null;
    }
  }

  static bool _looksLikeGifUrl(String url) {
    final lower = url.toLowerCase();
    final path = lower.split('?').first;
    if (path.endsWith('.gif')) return true;
    return lower.contains('format=gif') || lower.contains('fm=gif');
  }

  /// Builds the review-nudge title: includes the roaster when both the bean
  /// name and roaster are present ("How was X by Y?"), otherwise falls back to
  /// the name-only variant ("How was X?").
  String _beanReviewNudgeTitle(AppLocalizations l10n, CoffeeBeansModel bean) {
    if (bean.name.isNotEmpty && bean.roaster.isNotEmpty) {
      return l10n.notifBeanReviewNudgeTitle(bean.name, bean.roaster);
    }
    final displayName = bean.name.isNotEmpty ? bean.name : bean.roaster;
    return l10n.notifBeanReviewNudgeTitleNoRoaster(displayName);
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
