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
import 'package:coffee_timer/services/roaster_contribution_service.dart';
import 'package:coffee_timer/services/roaster_directory_service.dart';
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
  // Bean review nudges use a reserved band of IDs (1601..1610) so several beans
  // can each hold a pending nudge instead of clobbering a single shared ID.
  static const _idBeanReviewNudgeBase = 1601;
  static const _beanReviewNudgeSlots = 10;
  static const _idRecipeExplore = 1701;
  // Roaster-contribution nudges use a reserved band (1801..1810) so several
  // roasters can each hold a pending nudge (plan 011, Channel B).
  static const _idRoasterContribNudgeBase = 1801;
  static const _roasterContribNudgeSlots = 10;

  static Iterable<int> get _beanReviewNudgeIds =>
      List.generate(_beanReviewNudgeSlots, (i) => _idBeanReviewNudgeBase + i);

  static Iterable<int> get _roasterContribNudgeIds => List.generate(
      _roasterContribNudgeSlots, (i) => _idRoasterContribNudgeBase + i);

  static final _allIds = <int>[
    _idBrewReminder,
    _idBrewEscalation,
    _idDiscoverBeans,
    _idDiscoverPulse,
    _idMorningReminder,
    _idWeeklySummary,
    _idBeanFreshness,
    _idBrewMilestone,
    ..._beanReviewNudgeIds,
    _idRecipeExplore,
    ..._roasterContribNudgeIds,
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
  // In-flight nudge watchlist for delivery measurement: JSON map of
  // beanUuid -> {"t": trigger, "f": fireAtMs}. Entries are removed once their
  // fire time elapses (presumed delivered) or the nudge is cancelled.
  static const _keyBeanReviewInflight = 'notif_bean_review_inflight_v1';
  // Roaster-contribution nudge (plan 011, Channel B): JSON map of
  // clusterId -> {"roaster","beanUuid","f": fireAtMs}. Source of truth for
  // materialize; entries drop when the cluster is resolved, cancelled, or
  // past-due (presumed delivered).
  static const _keyRoasterContribScheduled =
      'notif_roaster_contrib_scheduled_v1';

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
        _scheduleBeanReviewNudges(
            settings, coffeeBeansDao, userStatsDao, l10n, prefs),
        _materializeRoasterContribNudges(l10n: l10n),
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

  /// Lower brew floor for the depletion trigger: finishing a bag is itself a
  /// strong review-intent signal, so we don't require the full 5-brew history.
  static const int _beanReviewDepletionMinBrews = 2;

  /// Reactive entry point — called after a brew is persisted. Records a
  /// one-time review nudge if this bean just crossed the 5-brew threshold,
  /// has no review yet, and has never been nudged, then (re-)materializes all
  /// pending nudges into the OS.
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
      await _stampAndTrackNudge(
          bean: bean, dao: coffeeBeansDao, prefs: prefs, trigger: 'brew_count');
      await _materializeBeanReviewNudges(dao: coffeeBeansDao, l10n: l10n);
    } catch (e) {
      AppLogger.error('Failed to schedule bean review nudge', errorObject: e);
    }
  }

  /// Reactive entry point for bean depletion — the bag was emptied, either
  /// automatically by a brew or via the manual "set to zero" control. Uses a
  /// lower brew floor ([_beanReviewDepletionMinBrews]) than the brew-count
  /// trigger. Shares the one-time guard, so a bean that both crosses the brew
  /// threshold and empties on the same brew is nudged only once.
  Future<void> maybeScheduleBeanReviewNudgeOnDepletion({
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
      if (stats.length < _beanReviewDepletionMinBrews) return;

      if (await _hasExistingBeanReview(beansUuid)) return;

      final l10n = lookupAppLocalizations(Locale(locale));
      final prefs = await SharedPreferences.getInstance();
      await _stampAndTrackNudge(
          bean: bean, dao: coffeeBeansDao, prefs: prefs, trigger: 'depletion');
      await _materializeBeanReviewNudges(dao: coffeeBeansDao, l10n: l10n);
    } catch (e) {
      AppLogger.error('Failed to schedule depletion review nudge',
          errorObject: e);
    }
  }

  /// Cancels a still-pending review nudge for [beansUuid] because the user just
  /// reviewed the bean — so we don't ask for a review they already wrote. Emits
  /// `notification_cancelled{reason:'reviewed'}` and drops it from the in-flight
  /// watchlist. Pushes the decision timestamp into the past so the next
  /// reschedule's materialize removes the pending OS notification without
  /// re-nudging (the one-time guard stays set). No-op if no un-fired nudge is
  /// pending (a review after the nudge fired is a conversion, not a cancel).
  Future<void> cancelPendingNudgeOnReview({
    required AppDatabase database,
    required String beansUuid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readInflightNudges(prefs);
      final raw = map[beansUuid];
      if (raw == null) return;
      final entry = (raw as Map).cast<String, dynamic>();
      final fireMs = entry['f'] as int? ?? 0;
      if (fireMs <= DateTime.now().millisecondsSinceEpoch) return;

      final trigger = entry['t'] ?? 'unknown';
      map.remove(beansUuid);
      await prefs.setString(_keyBeanReviewInflight, jsonEncode(map));

      final dao = CoffeeBeansDao(database);
      await dao.updateReviewNudgeScheduledAt(
          beansUuid, DateTime.now().subtract(const Duration(days: 2)));

      if (!testMode) {
        AnalyticsService.instance.track(
          'notification_cancelled',
          properties: {
            'notification_type': 'bean_review_nudge',
            'trigger': trigger,
            'reason': 'reviewed',
            'bean_uuid': beansUuid,
          },
        );
      }
    } catch (e) {
      AppLogger.error('Failed to cancel nudge on review', errorObject: e);
    }
  }

  /// Entry point used by [rescheduleAll]. Runs the one-shot backlog scan / drip
  /// (which only *stamps* eligible beans) and then re-materializes every pending
  /// nudge. Because [rescheduleAll] runs on every app open and cancels the whole
  /// ID band up front, a nudge that hasn't fired yet is recreated here on each
  /// pass — the same self-healing pattern the other engagement notifications use,
  /// instead of being scheduled once and lost on the next launch.
  Future<void> _scheduleBeanReviewNudges(
    NotificationSettingsService settings,
    CoffeeBeansDao coffeeBeansDao,
    UserStatsDao userStatsDao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    // When disabled, the band was already cancelled by [_cancelAll]; leave it.
    if (!await settings.isBeanReviewNudgeEnabled()) return;
    await _flushPresumedDeliveries(prefs);
    await _runBeanReviewBacklogScan(coffeeBeansDao, userStatsDao, prefs);
    await _materializeBeanReviewNudges(dao: coffeeBeansDao, l10n: l10n);
  }

  /// One-shot backlog scan + 7-day drip for existing eligible beans. Only stamps
  /// beans with a decision timestamp; OS scheduling is done by
  /// [_materializeBeanReviewNudges]. Assumes the toggle is already enabled.
  Future<void> _runBeanReviewBacklogScan(
    CoffeeBeansDao coffeeBeansDao,
    UserStatsDao userStatsDao,
    SharedPreferences prefs,
  ) async {
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
      await _stampAndTrackNudge(
          bean: first, dao: coffeeBeansDao, prefs: prefs, trigger: 'backlog');
      final remaining = filtered.skip(1).map((b) => b.beansUuid).toList();
      await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode(remaining));
      return;
    }

    // Drip path: stamp one more from the queue every 7 days.
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

      await _stampAndTrackNudge(
          bean: bean, dao: coffeeBeansDao, prefs: prefs, trigger: 'backlog');
      await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode(queue));
      return;
    }
    await prefs.setString(_keyBeanReviewBacklogQueue, jsonEncode(queue));
  }

  /// Records the "decided to nudge" timestamp on the bean — used both as the
  /// one-time guard and to derive the fire time — plus the drip cooldown and the
  /// analytics event. [trigger] tags which path scheduled it ('brew_count',
  /// 'depletion', 'backlog') for funnel analysis. Does not touch the OS; see
  /// [_materializeBeanReviewNudges].
  Future<void> _stampAndTrackNudge({
    required CoffeeBeansModel bean,
    required CoffeeBeansDao dao,
    required SharedPreferences prefs,
    required String trigger,
  }) async {
    final now = DateTime.now();
    await dao.updateReviewNudgeScheduledAt(bean.beansUuid, now);
    await prefs.setInt(
        _keyBeanReviewLastScheduledMs, now.millisecondsSinceEpoch);
    await _addInflightNudge(prefs, bean.beansUuid, trigger, now);

    if (!testMode) {
      AnalyticsService.instance.track(
        'notification_scheduled',
        properties: {
          'notification_type': 'bean_review_nudge',
          'trigger': trigger,
          'bean_uuid': bean.beansUuid,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Delivery measurement (in-flight watchlist)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _readInflightNudges(SharedPreferences prefs) {
    final raw = prefs.getString(_keyBeanReviewInflight);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Adds a nudge to the in-flight watchlist (bean uuid → trigger + derived fire
  /// time) so [_flushPresumedDeliveries] can emit a delivery event once its fire
  /// time elapses. Pure analytics bookkeeping — does not affect scheduling.
  Future<void> _addInflightNudge(SharedPreferences prefs, String beansUuid,
      String trigger, DateTime decidedAt) async {
    final map = _readInflightNudges(prefs);
    final fireAt = _atTime(decidedAt.add(const Duration(days: 1)), 10, 0);
    map[beansUuid] = {'t': trigger, 'f': fireAt.millisecondsSinceEpoch};
    await prefs.setString(_keyBeanReviewInflight, jsonEncode(map));
  }

  /// Emits `notification_presumed_delivered` for every in-flight nudge whose
  /// fire time has elapsed, then drops it from the watchlist (so it fires once).
  /// iOS gives no delivery callback for a background-fired local notification, so
  /// this is an inference — "the fire window elapsed while scheduled" — hence
  /// *presumed*. Confounders (Focus/DND, revoked permission, cleared banner) are
  /// accepted as noise. Runs on each app open via [_scheduleBeanReviewNudges].
  Future<void> _flushPresumedDeliveries(SharedPreferences prefs) async {
    final map = _readInflightNudges(prefs);
    if (map.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final delivered = <String>[];
    map.forEach((uuid, value) {
      final entry = (value as Map).cast<String, dynamic>();
      final fireMs = entry['f'] as int? ?? 0;
      if (fireMs <= nowMs) delivered.add(uuid);
    });
    if (delivered.isEmpty) return;
    for (final uuid in delivered) {
      final entry = (map.remove(uuid) as Map).cast<String, dynamic>();
      if (!testMode) {
        AnalyticsService.instance.track(
          'notification_presumed_delivered',
          properties: {
            'notification_type': 'bean_review_nudge',
            'trigger': entry['t'] ?? 'unknown',
            'bean_uuid': uuid,
          },
        );
      }
    }
    await prefs.setString(_keyBeanReviewInflight, jsonEncode(map));
  }

  /// (Re-)creates OS notifications for every bean with a pending nudge. Safe to
  /// call repeatedly: it cancels the reserved ID band first, then schedules each
  /// pending bean at its derived fire time (decision day + 1 at 10:00). A nudge
  /// whose fire time has already passed is treated as delivered and skipped, so
  /// each bean fires at most once.
  Future<void> _materializeBeanReviewNudges({
    required CoffeeBeansDao dao,
    required AppLocalizations l10n,
  }) async {
    await _cancelBeanReviewNudges();

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final inflight = _readInflightNudges(prefs);
    final candidates = await dao.fetchPendingBeanReviewNudges(
      since: now.subtract(const Duration(days: 2)),
      limit: _beanReviewNudgeSlots,
    );

    // Derive fire times, drop past-due ones, soonest first so the earliest
    // nudge takes the base ID.
    final pending = <({CoffeeBeansModel bean, DateTime fireAt})>[];
    for (final bean in candidates) {
      final decidedAt = bean.reviewNudgeScheduledAt;
      if (decidedAt == null) continue;
      final fireAt = _atTime(decidedAt.add(const Duration(days: 1)), 10, 0);
      if (!fireAt.isAfter(now)) continue;
      pending.add((bean: bean, fireAt: fireAt));
    }
    pending.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    for (var i = 0; i < pending.length && i < _beanReviewNudgeSlots; i++) {
      final bean = pending[i].bean;
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

      // Carry the trigger in the payload so a tap can be attributed to it.
      final entry = inflight[bean.beansUuid];
      final trigger = entry is Map ? entry['t'] as String? : null;
      final payload = trigger != null
          ? '/beans/${bean.beansUuid}?focus=review&t=$trigger'
          : '/beans/${bean.beansUuid}?focus=review';

      await _schedule(
        id: _idBeanReviewNudgeBase + i,
        title: _beanReviewTitleFor(l10n, bean),
        body: l10n.notifBeanReviewNudgeBody,
        at: pending[i].fireAt,
        payload: payload,
        imagePath: imagePath,
      );
    }
  }

  /// Cancels every notification in the bean-review ID band.
  Future<void> _cancelBeanReviewNudges() async {
    if (testMode) return;
    for (final id in _beanReviewNudgeIds) {
      await NotificationService.instance.cancelNotification(id);
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
        id: _idBeanReviewNudgeBase,
        title: title,
        body: body,
        payload: payload,
        imagePath: imagePath,
      );
    } else {
      await NotificationService.instance.scheduleLocalNotification(
        id: _idBeanReviewNudgeBase,
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
      final bundle =
          await RoasterDirectoryService.instance.fetchBundle(roasterName);
      if (bundle == null) return null;
      final original = bundle['roaster_logo_url']?.trim();
      final mirror = bundle['roaster_logo_mirror_url']?.trim();
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

  /// Chooses the title framing from the bean's live state: a "you finished it"
  /// framing once the bag is depleted (weight at/near zero), otherwise the
  /// standard "how was it?" framing. Reading live weight means a re-materialized
  /// nudge reflects the bean's current state without persisting the trigger.
  String _beanReviewTitleFor(AppLocalizations l10n, CoffeeBeansModel bean) {
    final pw = bean.packageWeightGrams;
    final depleted = pw != null && pw < 0.1;
    return depleted
        ? _beanReviewDepletionTitle(l10n, bean)
        : _beanReviewNudgeTitle(l10n, bean);
  }

  /// Depletion variant of [_beanReviewNudgeTitle] ("You finished X by Y").
  String _beanReviewDepletionTitle(
      AppLocalizations l10n, CoffeeBeansModel bean) {
    if (bean.name.isNotEmpty && bean.roaster.isNotEmpty) {
      return l10n.notifBeanReviewDepletionTitle(bean.name, bean.roaster);
    }
    final displayName = bean.name.isNotEmpty ? bean.name : bean.roaster;
    return l10n.notifBeanReviewDepletionTitleNoRoaster(displayName);
  }

  // ---------------------------------------------------------------------------
  // Channel B — Roaster website contribution nudge (plan 011)
  // ---------------------------------------------------------------------------

  /// Reactive entry point — called after a brew is persisted with an attached
  /// bean. If the bean's roaster is a *pending* candidate the user hasn't
  /// resolved (contributed or dismissed) and no nudge is already scheduled for
  /// it, records a one-shot "help add this roaster" nudge for next morning and
  /// (re-)materializes it into the OS. Gated on the master notification toggle
  /// only. Never throws.
  Future<void> maybeScheduleRoasterContribNudgeOnBrew({
    required AppDatabase database,
    required String beansUuid,
    required String locale,
  }) async {
    try {
      if (!testMode && !await _canSchedule()) return;

      final coffeeBeansDao = CoffeeBeansDao(database);
      final bean = await coffeeBeansDao.fetchCoffeeBeansByUuid(beansUuid);
      if (bean == null || bean.isDeleted || bean.roaster.isEmpty) return;

      // Is the roaster a pending candidate the user hasn't resolved yet?
      final eligibility = await RoasterContributionService.instance
          .checkEligibility(bean.roaster);
      final clusterId = eligibility.clusterId;
      if (!eligibility.eligible || clusterId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final map = _readRoasterContribScheduled(prefs);
      if (map.containsKey(clusterId)) return; // one-shot per roaster cluster

      final fireAt =
          _atTime(DateTime.now().add(const Duration(days: 1)), 10, 0);
      map[clusterId] = {
        'roaster': bean.roaster,
        'beanUuid': beansUuid,
        'f': fireAt.millisecondsSinceEpoch,
      };
      await prefs.setString(_keyRoasterContribScheduled, jsonEncode(map));

      if (!testMode) {
        AnalyticsService.instance.track(
          'notification_scheduled',
          properties: {
            'notification_type': 'roaster_contribution_nudge',
            'trigger': 'brew',
            'cluster_id': clusterId,
          },
        );
      }

      final l10n = lookupAppLocalizations(Locale(locale));
      await _materializeRoasterContribNudges(l10n: l10n);
    } catch (e) {
      AppLogger.error('Failed to schedule roaster contribution nudge',
          errorObject: e);
    }
  }

  /// Cancels a still-pending roaster-contribution nudge for [clusterId] because
  /// the user resolved it (submitted or dismissed via the in-app card). Drops it
  /// from the scheduled map and, if it hadn't fired yet, emits
  /// `notification_cancelled`. The stale OS notification is removed on the next
  /// [rescheduleAll] (materialize also skips resolved clusters). No-op if none
  /// pending.
  Future<void> cancelRoasterContribNudge(
    String clusterId, {
    String reason = 'resolved',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readRoasterContribScheduled(prefs);
      final raw = map.remove(clusterId);
      if (raw == null) return;
      await prefs.setString(_keyRoasterContribScheduled, jsonEncode(map));

      final entry = (raw as Map).cast<String, dynamic>();
      final fireMs = entry['f'] as int? ?? 0;
      if (fireMs > DateTime.now().millisecondsSinceEpoch && !testMode) {
        AnalyticsService.instance.track(
          'notification_cancelled',
          properties: {
            'notification_type': 'roaster_contribution_nudge',
            'reason': reason,
            'cluster_id': clusterId,
          },
        );
      }
    } catch (e) {
      AppLogger.error('Failed to cancel roaster contribution nudge',
          errorObject: e);
    }
  }

  /// Entry point used by [rescheduleAll]. (Re-)creates the OS notifications for
  /// every scheduled roaster-contribution nudge from the prefs map — self-healing
  /// across restarts, the same pattern the bean-review nudge uses. Flushes
  /// past-due entries (presumed delivered) and drops resolved clusters.
  Future<void> _materializeRoasterContribNudges({
    required AppLocalizations l10n,
  }) async {
    await _cancelRoasterContribNudges();

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final map = _readRoasterContribScheduled(prefs);
    if (map.isEmpty) return;

    final pending = <({
      String clusterId,
      String roaster,
      String beanUuid,
      DateTime fireAt
    })>[];
    var mutated = false;

    for (final clusterId in map.keys.toList()) {
      final entry = (map[clusterId] as Map).cast<String, dynamic>();
      final fireMs = entry['f'] as int? ?? 0;
      final fireAt = DateTime.fromMillisecondsSinceEpoch(fireMs);

      if (await RoasterContributionService.instance.isResolved(clusterId)) {
        map.remove(clusterId);
        mutated = true;
        continue;
      }
      if (!fireAt.isAfter(now)) {
        // Past-due → presumed delivered; count once, then drop.
        map.remove(clusterId);
        mutated = true;
        if (!testMode) {
          AnalyticsService.instance.track(
            'notification_presumed_delivered',
            properties: {
              'notification_type': 'roaster_contribution_nudge',
              'cluster_id': clusterId,
            },
          );
        }
        continue;
      }
      pending.add((
        clusterId: clusterId,
        roaster: entry['roaster'] as String? ?? '',
        beanUuid: entry['beanUuid'] as String? ?? '',
        fireAt: fireAt,
      ));
    }

    if (mutated) {
      await prefs.setString(_keyRoasterContribScheduled, jsonEncode(map));
    }

    // Soonest first so the earliest nudge takes the base ID.
    pending.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    for (var i = 0;
        i < pending.length && i < _roasterContribNudgeSlots;
        i++) {
      final p = pending[i];
      String? imagePath;
      if (!testMode && p.roaster.isNotEmpty) {
        try {
          final url = await _resolveRoasterLogoUrl(p.roaster);
          if (url != null) {
            imagePath = await NotificationImageHelper.downloadLogoToCache(url);
          }
        } catch (e) {
          AppLogger.debug('Roaster logo resolve failed: $e');
        }
      }
      await _schedule(
        id: _idRoasterContribNudgeBase + i,
        title: l10n.roasterContributionNotifTitle(
            p.roaster.isNotEmpty ? p.roaster : l10n.roaster),
        body: l10n.roasterContributionNotifBody,
        at: p.fireAt,
        payload: '/beans/${p.beanUuid}?t=roaster_contribution',
        imagePath: imagePath,
      );
    }
  }

  Future<void> _cancelRoasterContribNudges() async {
    if (testMode) return;
    for (final id in _roasterContribNudgeIds) {
      await NotificationService.instance.cancelNotification(id);
    }
  }

  Map<String, dynamic> _readRoasterContribScheduled(SharedPreferences prefs) {
    final raw = prefs.getString(_keyRoasterContribScheduled);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
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
