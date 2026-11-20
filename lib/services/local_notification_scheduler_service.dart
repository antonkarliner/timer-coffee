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
  // One-shot "second brew" reminder (plan 065, Phase 1): sent once, the
  // morning after a user's first completed brew.
  static const _idSecondBrew = 1003;
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
  // One-shot "brew later" reminder (plan 065, Phase 6a): the user asks to be
  // reminded about a specific recipe at a chosen time.
  static const _idBrewLater = 1901;

  static Iterable<int> get _beanReviewNudgeIds =>
      List.generate(_beanReviewNudgeSlots, (i) => _idBeanReviewNudgeBase + i);

  static Iterable<int> get _roasterContribNudgeIds => List.generate(
      _roasterContribNudgeSlots, (i) => _idRoasterContribNudgeBase + i);

  static final _allIds = <int>[
    _idBrewReminder,
    _idBrewEscalation,
    _idSecondBrew,
    _idDiscoverBeans,
    _idDiscoverPulse,
    _idMorningReminder,
    _idWeeklySummary,
    _idBeanFreshness,
    _idBrewMilestone,
    ..._beanReviewNudgeIds,
    _idRecipeExplore,
    ..._roasterContribNudgeIds,
    _idBrewLater,
  ];

  // --- SharedPreferences cooldown keys ---
  static const _keyLastCelebratedMilestone = 'notif_last_celebrated_milestone';
  static const _keyRecipeExploreShown = 'notif_recipe_explore_shown';
  static const _keyBeanFreshnessPending = 'notif_bean_freshness_pending';
  static const _keyBeanFreshnessNudged = 'notif_bean_freshness_nudged';
  static const _keyBeanFreshnessLastFiredMs =
      'notif_bean_freshness_last_fired_ms';
  // Written by the pre-2026-09-10 cooldown implementation, which no longer
  // exists. Upgrading installs still carry them, so they are removed on the
  // first run that gets this far; see [_clearLegacyFreshnessKeys].
  static const _legacyKeyBeanFreshnessLastUuid =
      'notif_bean_freshness_last_uuid';
  static const _legacyKeyBeanFreshnessLastDate =
      'notif_bean_freshness_last_date';
  static const _keyMorningLastTrackedMs = 'notif_morning_last_tracked_ms';
  static const _keyWeeklyLastTrackedMs = 'notif_weekly_last_tracked_ms';
  // One-shot "second brew" reminder (plan 065, Phase 1): last-tracked fire
  // instant for [_trackScheduledOnce], so repeated [rescheduleAll] calls for
  // the same fire time emit `notification_scheduled` only once.
  static const _keySecondBrewLastTrackedMs =
      'notif_second_brew_last_tracked_ms';
  // Re-arm pending reminders after cancellation; cooldown starts only once a
  // persisted fire time has elapsed (presumed delivered).
  static const _keyBrewReminderPending = 'notif_brew_reminder_pending_v1';
  static const _keyBrewReminderLastFiredMs = 'notif_brew_reminder_last_fired_ms';
  static const _keyBrewReminderLastFiredAnchorMs =
      'notif_brew_reminder_last_fired_anchor_ms';
  static const _legacyKeyBrewReminderLastScheduled =
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
  // One-shot "brew later" reminder (plan 065, Phase 6a): JSON of
  // {"recipeId","methodId","recipeName","fireAtMs","setAtMs","source"}. Source
  // of truth for materialize; at most one pending reminder exists at a time —
  // setting a new one overwrites.
  static const _keyBrewLaterScheduled = 'notif_brew_later_v1';

  // --- Milestone thresholds ---
  static const _milestoneThresholds = [10, 25, 50, 100, 250, 500];

  // --- Test seams ---
  // Set [testMode] = true in tests to bypass NotificationService platform calls.
  // [testScheduled] models the current pending OS queue so assertions can
  // inspect id + payload without touching the platform plugin.

  @visibleForTesting
  static bool testMode = false;

  @visibleForTesting
  static final List<({int id, String? payload})> testScheduled = [];

  @visibleForTesting
  static final List<int> testCancelledIds = [];

  Future<void> _beanReviewOperationTail = Future<void>.value();

  @visibleForTesting
  static void resetTestState() {
    testScheduled.clear();
    testCancelledIds.clear();
    instance._beanReviewOperationTail = Future<void>.value();
  }

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
        _scheduleMorningReminder(settings, l10n, prefs),
        _scheduleWeeklyReminder(settings, userStatsDao, l10n, prefs),
        _scheduleBeanFreshnessAlert(
            settings, coffeeBeansDao, userStatsDao, l10n, prefs),
        _scheduleBeanReviewNudges(
            settings, coffeeBeansDao, userStatsDao, l10n, prefs),
        _materializeRoasterContribNudges(l10n: l10n),
        _materializeBrewLater(userStatsDao, l10n),
        _scheduleSecondBrewReminder(
          userStatsDao,
          recipesDao,
          brewingMethodsDao,
          settings,
          l10n,
          prefs,
          locale,
        ),
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

  /// Remove only engagement reminders; brewing timers use other IDs.
  Future<void> cancelEngagementReminders() async {
    for (final id in _allIds) {
      await _cancelNotification(id);
    }
  }

  Future<void> _cancelAll() async {
    final beanReviewCancellation =
        _enqueueBeanReviewOperation(_cancelBeanReviewNudges);

    if (!testMode) {
      final service = NotificationService.instance;
      for (final id in _allIds) {
        if (_beanReviewNudgeIds.contains(id)) continue;
        await service.cancelNotification(id);
      }
    }
    await beanReviewCancellation;
  }

  Future<void> _enqueueBeanReviewOperation(
      Future<void> Function() operation) {
    final queued = _beanReviewOperationTail.then((_) => operation());
    _beanReviewOperationTail = queued.catchError((Object _, StackTrace _) {});
    return queued;
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
      testScheduled.removeWhere((call) => call.id == id);
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

  Future<void> _cancelNotification(int id) async {
    if (testMode) {
      testScheduled.removeWhere((call) => call.id == id);
      testCancelledIds.add(id);
      return;
    }
    await NotificationService.instance.cancelNotification(id);
  }

  // ---------------------------------------------------------------------------
  // Tier 1 — Brew reminders
  // ---------------------------------------------------------------------------

  Future<void> _scheduleBrewReminders(
    UserStatsDao dao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    final now = DateTime.now();
    if (prefs.containsKey(_legacyKeyBrewReminderLastScheduled)) {
      await prefs.remove(_legacyKeyBrewReminderLastScheduled);
    }

    var lastFiredMs = prefs.getInt(_keyBrewReminderLastFiredMs);
    var lastFiredAnchorMs = prefs.getInt(_keyBrewReminderLastFiredAnchorMs);
    int? deliveredMs;
    int? deliveredAnchorMs;
    final raw = prefs.getString(_keyBrewReminderPending);
    if (raw != null) {
      try {
        final pending = jsonDecode(raw);
        if (pending is Map &&
            pending['a'] is int &&
            (pending['g'] == null || pending['g'] is int) &&
            (pending['e'] == null || pending['e'] is int)) {
          for (final fireMs in [pending['g'], pending['e']]) {
            if (fireMs is int &&
                fireMs <= now.millisecondsSinceEpoch &&
                (deliveredMs == null || fireMs > deliveredMs)) {
              deliveredMs = fireMs;
              deliveredAnchorMs = pending['a'] as int;
            }
          }
        }
      } catch (_) {
        // Malformed pending state cannot establish a presumed delivery.
      }
    }
    if (deliveredMs != null &&
        (lastFiredMs == null || deliveredMs > lastFiredMs)) {
      lastFiredMs = deliveredMs;
      lastFiredAnchorMs = deliveredAnchorMs;
      await prefs.setInt(_keyBrewReminderLastFiredMs, deliveredMs);
      await prefs.setInt(_keyBrewReminderLastFiredAnchorMs, deliveredAnchorMs!);
    }

    final allStats = await dao.fetchAllStats();
    if (allStats.isEmpty) {
      await prefs.remove(_keyBrewReminderPending);
      return;
    }

    // allStats is ordered by createdAt DESC — first item is most recent.
    final lastBrew = allStats.first.createdAt;
    final anchorMs = lastBrew.millisecondsSinceEpoch;
    final gentle = _atTime(lastBrew.add(const Duration(days: 5)), 10, 0);
    final escalation = _atTime(lastBrew.add(const Duration(days: 10)), 10, 0);
    final cooldownUntilMs = lastFiredMs == null
        ? null
        : lastFiredMs + const Duration(days: 14).inMilliseconds;
    bool canArm(DateTime fireTime) =>
        fireTime.isAfter(now) &&
        (cooldownUntilMs == null ||
            fireTime.millisecondsSinceEpoch >= cooldownUntilMs ||
            lastFiredAnchorMs == anchorMs);
    int? gentleMs;
    int? escalationMs;

    final rng = Random();

    if (canArm(gentle)) {
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
      gentleMs = gentle.millisecondsSinceEpoch;
    }
    if (canArm(escalation)) {
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
      escalationMs = escalation.millisecondsSinceEpoch;
    }

    if (gentleMs == null && escalationMs == null) {
      await prefs.remove(_keyBrewReminderPending);
    } else {
      await prefs.setString(
        _keyBrewReminderPending,
        jsonEncode({'a': anchorMs, 'g': gentleMs, 'e': escalationMs}),
      );
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

  /// Next morning-reminder fire time: always tomorrow at [hour]:[minute], never
  /// today. This only runs while the app is in the foreground (cold start,
  /// resume, settings, finish screen), and a user who has opened the app today
  /// doesn't need today's "time to brew" nudge — so opening the app before the
  /// reminder time disarms it for the day.
  ///
  /// Uses the DateTime constructor (not Duration.add) so DST transitions are
  /// handled correctly — adding 86400 s on a 23-hour DST day shifts the
  /// wall-clock time by one hour.
  @visibleForTesting
  static DateTime morningReminderTarget(DateTime now, int hour, int minute) =>
      DateTime(now.year, now.month, now.day + 1, hour, minute);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Re-arms only the morning reminder. Called when the app returns to the
  /// foreground: a warm resume skips [rescheduleAll] (which runs on cold
  /// start), so without this a user who resumes at 07:00 would still get the
  /// 08:30 reminder.
  Future<void> rescheduleMorningReminderOnResume({
    required String locale,
  }) async {
    try {
      if (!testMode && !await _canSchedule()) return;
      await _scheduleMorningReminder(
        NotificationSettingsService.instance,
        lookupAppLocalizations(Locale(locale)),
        await SharedPreferences.getInstance(),
      );
    } catch (e) {
      AppLogger.error('Failed to reschedule morning reminder on resume',
          errorObject: e);
    }
  }

  Future<void> _scheduleMorningReminder(
    NotificationSettingsService settings,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    if (!await settings.isMorningReminderEnabled()) return;

    final time = await settings.getMorningReminderTime();
    final now = DateTime.now();
    final target = morningReminderTarget(now, time.hour, time.minute);

    // An occurrence still pending for today is being replaced by tomorrow's:
    // the user opened the app before it fired, so it never will.
    final pendingMs = prefs.getInt(_keyMorningLastTrackedMs);
    if (pendingMs != null) {
      final pending = DateTime.fromMillisecondsSinceEpoch(pendingMs);
      if (pending.isAfter(now) && _isSameDay(pending, now)) {
        AnalyticsService.maybeInstance?.track(
          'notification_cancelled',
          properties: {
            'notification_type': 'morning_reminder',
            'reason': 'app_opened',
          },
        );
      }
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
    await _trackScheduledOnce(
      prefs: prefs,
      key: _keyMorningLastTrackedMs,
      notificationType: 'morning_reminder',
      fireAt: target,
    );
  }

  Future<void> _scheduleWeeklyReminder(
    NotificationSettingsService settings,
    UserStatsDao dao,
    AppLocalizations l10n,
    SharedPreferences prefs,
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
    await _trackScheduledOnce(
      prefs: prefs,
      key: _keyWeeklyLastTrackedMs,
      notificationType: 'weekly_summary',
      fireAt: target,
    );
  }

  static const _freshnessRestDays = 14;
  static const _freshnessRestCapDays = 28;
  static const _freshnessIdleDays = 14;
  static const _freshnessIdleCapDays = 35;
  static const _freshnessUserFloorDays = 7;
  static const _freshnessHour = 11;

  Map<String, dynamic>? _readFreshnessPending(SharedPreferences prefs) {
    final raw = prefs.getString(_keyBeanFreshnessPending);
    if (raw == null || raw.isEmpty) return null;
    try {
      final pending = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final uuid = pending['u'];
      final trigger = pending['t'];
      final fireMs = pending['f'];
      if (uuid is! String ||
          (trigger != 'rest' && trigger != 'idle') ||
          fireMs is! int) {
        return null;
      }
      return pending;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeFreshnessPending(
    SharedPreferences prefs,
    String uuid,
    String trigger,
    DateTime fireAt,
  ) async {
    await prefs.setString(
      _keyBeanFreshnessPending,
      jsonEncode({'u': uuid, 't': trigger, 'f': fireAt.millisecondsSinceEpoch}),
    );
  }

  Future<void> _clearFreshnessPending(SharedPreferences prefs) async {
    await prefs.remove(_keyBeanFreshnessPending);
  }

  /// Drops the two SharedPreferences keys left behind by the old cooldown
  /// implementation. Guarded by [SharedPreferences.containsKey] so it costs one
  /// in-memory lookup per run once they are gone, rather than needing a
  /// migration flag of its own — a flag would replace two dead keys with one.
  Future<void> _clearLegacyFreshnessKeys(SharedPreferences prefs) async {
    if (prefs.containsKey(_legacyKeyBeanFreshnessLastUuid)) {
      await prefs.remove(_legacyKeyBeanFreshnessLastUuid);
    }
    if (prefs.containsKey(_legacyKeyBeanFreshnessLastDate)) {
      await prefs.remove(_legacyKeyBeanFreshnessLastDate);
    }
  }

  Set<String> _freshnessNudgedTriggers(SharedPreferences prefs, String uuid) {
    final raw = prefs.getString(_keyBeanFreshnessNudged);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final triggers = map[uuid];
      if (triggers is! List) return <String>{};
      return triggers.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _markFreshnessNudged(
    SharedPreferences prefs,
    String uuid,
    String trigger,
  ) async {
    final raw = prefs.getString(_keyBeanFreshnessNudged);
    Map<String, dynamic> map;
    try {
      map = raw == null || raw.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      map = <String, dynamic>{};
    }
    final existing = map[uuid];
    final triggers = existing is List
        ? existing.whereType<String>().toSet()
        : <String>{};
    triggers.add(trigger);
    map[uuid] = triggers.toList();
    await prefs.setString(_keyBeanFreshnessNudged, jsonEncode(map));
  }

  Future<void> _pruneFreshnessNudged(
    SharedPreferences prefs,
    Set<String> liveUuids,
  ) async {
    final raw = prefs.getString(_keyBeanFreshnessNudged);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final oldLength = map.length;
      map.removeWhere((uuid, _) => !liveUuids.contains(uuid));
      if (map.length != oldLength) {
        await prefs.setString(_keyBeanFreshnessNudged, jsonEncode(map));
      }
    } catch (_) {
      return;
    }
  }

  Future<void> _scheduleBeanFreshnessAlert(
    NotificationSettingsService settings,
    CoffeeBeansDao dao,
    UserStatsDao statsDao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    await _clearLegacyFreshnessKeys(prefs);

    var pending = _readFreshnessPending(prefs);
    final pendingFireMs = pending?['f'];
    if (pending != null &&
        pendingFireMs is int &&
        pendingFireMs <= DateTime.now().millisecondsSinceEpoch) {
      final uuid = pending['u'] as String;
      final trigger = pending['t'] as String;
      await _markFreshnessNudged(prefs, uuid, trigger);
      await prefs.setInt(_keyBeanFreshnessLastFiredMs, pendingFireMs);
      await _clearFreshnessPending(prefs);
      AnalyticsService.maybeInstance?.track(
        'notification_presumed_delivered',
        properties: {
          'notification_type': 'bean_freshness',
          'trigger': trigger,
        },
      );
      pending = null;
    }

    if (!await settings.isBeanFreshnessEnabled()) {
      await _clearFreshnessPending(prefs);
      return;
    }

    final beans = await dao.fetchAllCoffeeBeans();
    final stats = await statsDao.fetchAllStats();
    final statsByBean = <String, ({int count, DateTime lastBrew})>{};
    for (final stat in stats) {
      final uuid = stat.coffeeBeansUuid;
      if (uuid == null) continue;
      final existing = statsByBean[uuid];
      statsByBean[uuid] = (
        count: (existing?.count ?? 0) + 1,
        lastBrew: existing == null || stat.createdAt.isAfter(existing.lastBrew)
            ? stat.createdAt
            : existing.lastBrew,
      );
    }

    final liveUuids = beans.map((bean) => bean.beansUuid).toSet();
    await _pruneFreshnessNudged(prefs, liveUuids);

    final now = DateTime.now();
    final lastFiredMs = prefs.getInt(_keyBeanFreshnessLastFiredMs);
    final floorAt = lastFiredMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            lastFiredMs,
          ).add(const Duration(days: _freshnessUserFloorDays));
    final candidates =
        <({CoffeeBeansModel bean, String trigger, DateTime fireAt})>[];

    for (final bean in beans) {
      final roast = bean.roastDate;
      if (bean.isDeleted || roast == null || roast.isAfter(now)) continue;
      if (bean.packageWeightGrams != null && bean.packageWeightGrams! < 0.1) {
        continue;
      }

      final nudged = _freshnessNudgedTriggers(prefs, bean.beansUuid);
      final beanStats = statsByBean[bean.beansUuid];
      late final String trigger;
      late DateTime fireAt;
      if (beanStats == null || beanStats.count == 0) {
        trigger = 'rest';
        if (nudged.contains(trigger)) continue;
        if (now.isAfter(
          roast.add(const Duration(days: _freshnessRestCapDays)),
        )) {
          continue;
        }
        fireAt = _atTime(
          roast.add(const Duration(days: _freshnessRestDays)),
          _freshnessHour,
          0,
        );
      } else {
        trigger = 'idle';
        if (nudged.contains(trigger)) continue;
        fireAt = _atTime(
          beanStats.lastBrew.add(const Duration(days: _freshnessIdleDays)),
          _freshnessHour,
          0,
        );
        if (fireAt.isAfter(
          roast.add(const Duration(days: _freshnessIdleCapDays)),
        )) {
          continue;
        }
      }

      if (!fireAt.isAfter(now)) {
        fireAt = _nextAtHour(now, _freshnessHour);
      }
      if (floorAt != null && fireAt.isBefore(floorAt)) {
        fireAt = _atTime(floorAt, _freshnessHour, 0);
      }

      final capDays = trigger == 'rest'
          ? _freshnessRestCapDays
          : _freshnessIdleCapDays;
      if (fireAt.isAfter(roast.add(Duration(days: capDays)))) continue;

      candidates.add((bean: bean, trigger: trigger, fireAt: fireAt));
    }

    if (candidates.isEmpty) {
      await _clearFreshnessPending(prefs);
      return;
    }

    candidates.sort((a, b) {
      final fireComparison = a.fireAt.compareTo(b.fireAt);
      if (fireComparison != 0) return fireComparison;
      return b.bean.roastDate!.compareTo(a.bean.roastDate!);
    });
    final candidate = candidates.first;
    final bean = candidate.bean;
    final trigger = candidate.trigger;
    final fireAt = candidate.fireAt;

    final beanName = bean.name.isNotEmpty ? bean.name : bean.roaster;
    final body = trigger == 'rest'
        ? l10n.notifBeanFreshnessRestBody(beanName)
        : l10n.notifBeanFreshnessIdleBody(beanName);
    await _schedule(
      id: _idBeanFreshness,
      title: l10n.notifBeanFreshnessTitle,
      body: body,
      at: fireAt,
      payload: '/beans/${bean.beansUuid}',
    );

    final fireMs = fireAt.millisecondsSinceEpoch;
    final pendingChanged =
        pending == null ||
        pending['u'] != bean.beansUuid ||
        pending['t'] != trigger ||
        pending['f'] != fireMs;
    await _writeFreshnessPending(prefs, bean.beansUuid, trigger, fireAt);
    if (pendingChanged) {
      AnalyticsService.maybeInstance?.track(
        'notification_scheduled',
        properties: {
          'notification_type': 'bean_freshness',
          'trigger': trigger,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tier 3 — Bean review nudge
  // ---------------------------------------------------------------------------

  // Mirrored in BeanReviewPromptService.minBrews (used by the finish-screen
  // review nudge card) — keep both in sync.
  static const int _beanReviewMinBrews = 5;

  /// Lower brew floor for the depletion trigger: finishing a bag is itself a
  /// strong review-intent signal, so we don't require the full 5-brew history.
  /// Mirrored in BeanReviewPromptService.depletionMinBrews — keep in sync.
  static const int _beanReviewDepletionMinBrews = 2;

  /// Reactive entry point — called after a brew is persisted. Records a
  /// one-time review nudge if this bean just crossed the 5-brew threshold,
  /// has no review yet, and has never been nudged, then (re-)materializes all
  /// pending nudges into the OS.
  Future<void> maybeScheduleBeanReviewNudge({
    required AppDatabase database,
    required String beansUuid,
    required String locale,
  }) =>
      _enqueueBeanReviewOperation(() => _maybeScheduleBeanReviewNudgeBody(
            database: database,
            beansUuid: beansUuid,
            locale: locale,
          ));

  Future<void> _maybeScheduleBeanReviewNudgeBody({
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
  }) =>
      _enqueueBeanReviewOperation(
          () => _maybeScheduleBeanReviewNudgeOnDepletionBody(
                database: database,
                beansUuid: beansUuid,
                locale: locale,
              ));

  Future<void> _maybeScheduleBeanReviewNudgeOnDepletionBody({
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
  /// watchlist. Persists terminal state before cancelling the bean's exact OS
  /// notification ID, keeping the one-time guard set. No-op if no un-fired
  /// nudge is pending (a review after the nudge fired is a conversion, not a
  /// cancel).
  Future<void> cancelPendingNudgeOnReview({
    required AppDatabase database,
    required String beansUuid,
  }) =>
      _enqueueBeanReviewOperation(() => _cancelPendingNudgeOnReviewBody(
            database: database,
            beansUuid: beansUuid,
          ));

  Future<void> _cancelPendingNudgeOnReviewBody({
    required AppDatabase database,
    required String beansUuid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readInflightNudges(prefs);
      final raw = map[beansUuid];
      final entry = raw is Map
          ? raw.cast<String, dynamic>()
          : <String, dynamic>{};
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final fireMs = entry['f'];

      final dao = CoffeeBeansDao(database);
      final bean = await dao.fetchCoffeeBeansByUuid(beansUuid);
      final decidedAt = bean?.reviewNudgeScheduledAt;
      final beanFireAt = decidedAt == null
          ? null
          : _atTime(decidedAt.add(const Duration(days: 1)), 10, 0);
      final hasFutureNudge = (fireMs is int && fireMs > nowMs) ||
          (beanFireAt?.isAfter(now) ?? false);
      if (!hasFutureNudge) return;

      int? notificationId;
      final storedId = entry['i'];
      if (storedId is int &&
          storedId >= _idBeanReviewNudgeBase &&
          storedId < _idBeanReviewNudgeBase + _beanReviewNudgeSlots) {
        notificationId = storedId;
      } else {
        final pending = await _pendingBeanReviewNudges(dao, now: now);
        final index =
            pending.indexWhere((item) => item.bean.beansUuid == beansUuid);
        if (index >= 0 && index < _beanReviewNudgeSlots) {
          notificationId = _idBeanReviewNudgeBase + index;
        }
      }

      final trigger = entry['t'] ?? 'unknown';
      map.remove(beansUuid);
      await prefs.setString(_keyBeanReviewInflight, jsonEncode(map));
      await dao.updateReviewNudgeScheduledAt(
          beansUuid, now.subtract(const Duration(days: 2)));

      if (notificationId != null) {
        await _cancelNotification(notificationId);
      } else {
        AppLogger.debug(
            'No safe notification ID for reviewed bean $beansUuid; '
            'the next full reschedule will clear the stale notification');
      }

      if (!testMode) {
        AnalyticsService.instance.track(
          'notification_cancelled',
          properties: {
            'notification_type': 'bean_review_nudge',
            'trigger': trigger,
            'reason': 'reviewed',
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
  ) =>
      _enqueueBeanReviewOperation(() => _scheduleBeanReviewNudgesBody(
            settings,
            coffeeBeansDao,
            userStatsDao,
            l10n,
            prefs,
          ));

  Future<void> _scheduleBeanReviewNudgesBody(
    NotificationSettingsService settings,
    CoffeeBeansDao coffeeBeansDao,
    UserStatsDao userStatsDao,
    AppLocalizations l10n,
    SharedPreferences prefs,
  ) async {
    // The OS band was already cancelled by [_cancelAll]. Retire its durable
    // state too, so cancelled nudges are neither counted as delivered nor
    // recreated if the setting is enabled again.
    if (!await settings.isBeanReviewNudgeEnabled()) {
      await _retireBeanReviewNudgesOnDisable(coffeeBeansDao, prefs);
      return;
    }
    await _flushPresumedDeliveries(prefs);
    await _runBeanReviewBacklogScan(coffeeBeansDao, userStatsDao, prefs);
    await _materializeBeanReviewNudges(dao: coffeeBeansDao, l10n: l10n);
  }

  Future<void> _retireBeanReviewNudgesOnDisable(
    CoffeeBeansDao dao,
    SharedPreferences prefs,
  ) async {
    await _flushPresumedDeliveries(prefs);

    final now = DateTime.now();
    final inflight = _readInflightNudges(prefs);
    final triggersByUuid = <String, String>{};
    inflight.forEach((uuid, value) {
      final entry = (value as Map).cast<String, dynamic>();
      triggersByUuid[uuid] = entry['t'] as String? ?? 'unknown';
    });

    final pending = await _pendingBeanReviewNudges(dao, now: now);
    for (final item in pending) {
      triggersByUuid.putIfAbsent(item.bean.beansUuid, () => 'unknown');
    }
    if (triggersByUuid.isEmpty) return;

    final terminalAt = now.subtract(const Duration(days: 2));
    for (final entry in triggersByUuid.entries) {
      await dao.updateReviewNudgeScheduledAt(entry.key, terminalAt);
      inflight.remove(entry.key);
      if (!testMode) {
        AnalyticsService.instance.track(
          'notification_cancelled',
          properties: {
            'notification_type': 'bean_review_nudge',
            'trigger': entry.value,
            'reason': 'setting_off',
          },
        );
      }
    }
    await prefs.setString(_keyBeanReviewInflight, jsonEncode(inflight));
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
        },
      );
    }
  }

  /// Emits `notification_scheduled` at most once per distinct [fireAt].
  ///
  /// [rescheduleAll] is idempotent and runs on app start, on every settings
  /// toggle and after every finished brew, re-arming these recurring
  /// reminders each time. Emitting on every call would produce several events
  /// a day per user and make the count useless as a delivery denominator, so
  /// the last-tracked fire instant is persisted and an event is emitted only
  /// when the target instant actually changes.
  Future<void> _trackScheduledOnce({
    required SharedPreferences prefs,
    required String key,
    required String notificationType,
    required DateTime fireAt,
  }) async {
    final ms = fireAt.millisecondsSinceEpoch;
    if (prefs.getInt(key) == ms) return;
    await prefs.setInt(key, ms);
    AnalyticsService.maybeInstance?.track(
      'notification_scheduled',
      properties: {'notification_type': notificationType},
    );
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
  /// time). Materialization also stores the assigned notification ID here so a
  /// review can cancel the exact pending notification.
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

    final prefs = await SharedPreferences.getInstance();
    final inflight = _readInflightNudges(prefs);
    final pending = await _pendingBeanReviewNudges(dao);
    var assignmentsChanged = false;

    for (var i = 0; i < pending.length && i < _beanReviewNudgeSlots; i++) {
      final bean = pending[i].bean;
      final id = _idBeanReviewNudgeBase + i;
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
      final rawEntry = inflight[bean.beansUuid];
      final entry = rawEntry is Map
          ? rawEntry.cast<String, dynamic>()
          : <String, dynamic>{};
      final trigger = entry['t'] as String?;
      final payload = trigger != null
          ? '/beans/${bean.beansUuid}?focus=review&t=$trigger'
          : '/beans/${bean.beansUuid}?focus=review';

      await _schedule(
        id: id,
        title: _beanReviewTitleFor(l10n, bean),
        body: l10n.notifBeanReviewNudgeBody,
        at: pending[i].fireAt,
        payload: payload,
        imagePath: imagePath,
      );

      if (rawEntry is Map && entry['i'] != id) {
        entry['i'] = id;
        inflight[bean.beansUuid] = entry;
        assignmentsChanged = true;
      }
    }

    if (assignmentsChanged) {
      await prefs.setString(_keyBeanReviewInflight, jsonEncode(inflight));
    }
  }

  /// Returns pending beans in the exact positional-ID assignment order used by
  /// materialization. Legacy in-flight entries without a stored ID use this
  /// same list to resolve their notification safely.
  Future<List<({CoffeeBeansModel bean, DateTime fireAt})>>
      _pendingBeanReviewNudges(
    CoffeeBeansDao dao, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final candidates = await dao.fetchPendingBeanReviewNudges(
      since: current.subtract(const Duration(days: 2)),
      limit: _beanReviewNudgeSlots,
    );

    // Derive fire times, drop past-due ones, soonest first so the earliest
    // nudge takes the base ID.
    final pending = <({CoffeeBeansModel bean, DateTime fireAt})>[];
    for (final bean in candidates) {
      final decidedAt = bean.reviewNudgeScheduledAt;
      if (decidedAt == null) continue;
      final fireAt = _atTime(decidedAt.add(const Duration(days: 1)), 10, 0);
      if (!fireAt.isAfter(current)) continue;
      pending.add((bean: bean, fireAt: fireAt));
    }
    pending.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return pending;
  }

  /// Cancels every notification in the bean-review ID band.
  Future<void> _cancelBeanReviewNudges() async {
    for (final id in _beanReviewNudgeIds) {
      await _cancelNotification(id);
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
  // One-shot "brew later" reminder (plan 065, Phase 6a)
  // ---------------------------------------------------------------------------

  /// Reads and validates the pending brew-later entry, or returns null when
  /// absent or corrupt.
  ({
    String recipeId,
    String methodId,
    String recipeName,
    DateTime fireAt,
    DateTime setAt,
    String source,
  })? _readBrewLater(SharedPreferences prefs) {
    final raw = prefs.getString(_keyBrewLaterScheduled);
    if (raw == null || raw.isEmpty) return null;
    try {
      final entry = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final recipeId = entry['recipeId'];
      final methodId = entry['methodId'];
      final fireMs = entry['fireAtMs'];
      if (recipeId is! String || methodId is! String || fireMs is! int) {
        return null;
      }
      return (
        recipeId: recipeId,
        methodId: methodId,
        recipeName: entry['recipeName'] as String? ?? '',
        fireAt: DateTime.fromMillisecondsSinceEpoch(fireMs),
        setAt: DateTime.fromMillisecondsSinceEpoch(
            entry['setAtMs'] as int? ?? 0),
        source: entry['source'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Schedules the one-shot "brew later" reminder for [recipeId] at [fireAt].
  /// At most one pending reminder exists — a new call overwrites the previous
  /// one. Returns false (and does nothing) when [fireAt] is not in the future
  /// or, outside test mode, notifications cannot be scheduled.
  Future<bool> setBrewLater({
    required String recipeId,
    required String methodId,
    required DateTime fireAt,
    required String source,
    required String locale,
    required String recipeName,
    DateTime? now,
  }) async {
    final setAt = now ?? DateTime.now();
    if (!fireAt.isAfter(setAt)) return false;
    if (!testMode && !await _canSchedule()) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBrewLaterScheduled, jsonEncode({
      'recipeId': recipeId,
      'methodId': methodId,
      'recipeName': recipeName,
      'fireAtMs': fireAt.millisecondsSinceEpoch,
      'setAtMs': setAt.millisecondsSinceEpoch,
      'source': source,
    }));

    final l10n = lookupAppLocalizations(Locale(locale));
    await _schedule(
      id: _idBrewLater,
      title: l10n.notifBrewLaterTitle(recipeName),
      body: l10n.notifBrewLaterBody,
      at: fireAt,
      payload: '/recipes/$methodId/$recipeId?t=brew_later',
    );

    AnalyticsService.maybeInstance?.track(
      'notification_scheduled',
      properties: {'notification_type': 'brew_later'},
    );
    return true;
  }

  /// Cancels a still-pending brew-later reminder (e.g. the user started
  /// brewing after all). Removes the entry, cancels OS id [_idBrewLater] and
  /// emits `notification_cancelled`. No-op when nothing is pending.
  Future<void> cancelBrewLater({required String reason}) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = _readBrewLater(prefs);
    if (entry == null) return;
    await prefs.remove(_keyBrewLaterScheduled);
    await _cancelNotification(_idBrewLater);
    AnalyticsService.maybeInstance?.track(
      'notification_cancelled',
      properties: {'notification_type': 'brew_later', 'reason': reason},
    );
  }

  /// The pending reminder, as long as its fire time is still in the future.
  /// Corrupt entries read as absent and are removed.
  Future<({String recipeId, String methodId, DateTime fireAt})?>
      pendingBrewLater() async {
    final prefs = await SharedPreferences.getInstance();
    final entry = _readBrewLater(prefs);
    if (entry == null) {
      // Present but unparseable → clean the key up so it doesn't sit forever.
      if (prefs.containsKey(_keyBrewLaterScheduled)) {
        await prefs.remove(_keyBrewLaterScheduled);
      }
      return null;
    }
    if (!entry.fireAt.isAfter(DateTime.now())) return null;
    return (
      recipeId: entry.recipeId,
      methodId: entry.methodId,
      fireAt: entry.fireAt,
    );
  }

  /// Entry point used by [rescheduleAll]. (Re-)creates the one-shot brew-later
  /// notification from its prefs entry — self-healing across restarts, the
  /// same pattern [_materializeRoasterContribNudges] uses. An elapsed fire time
  /// is presumed delivered first, so a subsequent brew cannot count as a
  /// cancellation. Only a still-future reminder the user out-brewed (a
  /// [UserStatsDao] row newer than setAt) is cancelled with reason 'brewed'.
  /// Re-arming a still-future reminder emits no analytics.
  Future<void> _materializeBrewLater(
    UserStatsDao userStatsDao,
    AppLocalizations l10n,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = _readBrewLater(prefs);
    if (entry == null) {
      // Present but unparseable → drop it; nothing to re-arm.
      if (prefs.containsKey(_keyBrewLaterScheduled)) {
        await prefs.remove(_keyBrewLaterScheduled);
      }
      return;
    }

    if (!entry.fireAt.isAfter(DateTime.now())) {
      // Past-due → presumed delivered; count once, then drop.
      await prefs.remove(_keyBrewLaterScheduled);
      AnalyticsService.maybeInstance?.track(
        'notification_presumed_delivered',
        properties: {'notification_type': 'brew_later'},
      );
      return;
    }

    // The user brewed after the reminder was set → it is moot.
    final allStats = await userStatsDao.fetchAllStats();
    if (allStats.any((s) => s.createdAt.isAfter(entry.setAt))) {
      await prefs.remove(_keyBrewLaterScheduled);
      AnalyticsService.maybeInstance?.track(
        'notification_cancelled',
        properties: {'notification_type': 'brew_later', 'reason': 'brewed'},
      );
      return;
    }

    await _schedule(
      id: _idBrewLater,
      title: l10n.notifBrewLaterTitle(entry.recipeName),
      body: l10n.notifBrewLaterBody,
      at: entry.fireAt,
      payload: '/recipes/${entry.methodId}/${entry.recipeId}?t=brew_later',
    );
  }

  // ---------------------------------------------------------------------------
  // One-shot "second brew" reminder (plan 065, Phase 1)
  // ---------------------------------------------------------------------------

  /// Fire time for the one-shot "second brew" reminder: the calendar day after
  /// [firstBrewAt] at the brew's own hour:minute, clamped into 06:00–11:00 —
  /// earlier than 06:00 becomes 06:00, later than 11:00 becomes 08:00 so an
  /// afternoon or evening brewer gets a morning nudge, not a repeat of the
  /// same hour.
  ///
  /// Uses the DateTime constructor (not Duration.add) so DST transitions keep
  /// the wall-clock time — adding 86400 s on a 23-hour DST day shifts it by
  /// one hour.
  @visibleForTesting
  static DateTime secondBrewReminderTarget(DateTime firstBrewAt) {
    final nextDay = DateTime(firstBrewAt.year, firstBrewAt.month,
        firstBrewAt.day + 1, firstBrewAt.hour, firstBrewAt.minute);
    final minutes = nextDay.hour * 60 + nextDay.minute;
    if (minutes < 6 * 60) {
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 6, 0);
    }
    if (minutes > 11 * 60) {
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 8, 0);
    }
    return nextDay;
  }

  /// Schedules the one-shot "second brew" reminder. Only when the user has
  /// completed exactly one brew, the daily morning reminder is off (a user
  /// with a daily reminder must not get two notifications the same morning),
  /// and the target is still in the future. Independent of
  /// [_scheduleBrewReminders] — its day-5/day-10 logic and cooldown are
  /// untouched. Because [rescheduleAll] cancels every id in [_allIds] first
  /// and this gate fails on two or more rows, the pending reminder
  /// disappears once the second brew is logged.
  Future<void> _scheduleSecondBrewReminder(
    UserStatsDao userStatsDao,
    RecipesDao recipesDao,
    BrewingMethodsDao brewingMethodsDao,
    NotificationSettingsService settings,
    AppLocalizations l10n,
    SharedPreferences prefs,
    String locale,
  ) async {
    final allStats = await userStatsDao.fetchAllStats();
    if (allStats.length != 1) return;
    final firstBrew = allStats.single;

    if (await settings.isMorningReminderEnabled()) return;

    final target = secondBrewReminderTarget(firstBrew.createdAt);
    if (!target.isAfter(DateTime.now())) return;

    // Resolve the recipe name locally, falling back to the brewing method's
    // name; without either there is no sensible text and we skip scheduling.
    // The recipe's own method id is the one the deep link route needs.
    final recipe =
        await recipesDao.getRecipeModelById(firstBrew.recipeId, locale);
    String? recipeName;
    String? methodId;
    if (recipe != null) {
      if (recipe.name.trim().isNotEmpty) recipeName = recipe.name;
      methodId = recipe.brewingMethodId;
    }
    methodId ??= firstBrew.brewingMethodId;
    recipeName ??=
        await brewingMethodsDao.getBrewingMethodNameById(methodId);
    if (recipeName == null || recipeName.trim().isEmpty) return;

    await _schedule(
      id: _idSecondBrew,
      title: l10n.notifSecondBrewTitle,
      body: l10n.notifSecondBrewBody(recipeName),
      at: target,
      payload: '/recipes/$methodId/${firstBrew.recipeId}?t=second_brew',
    );
    await _trackScheduledOnce(
      prefs: prefs,
      key: _keySecondBrewLastTrackedMs,
      notificationType: 'second_brew',
      fireAt: target,
    );
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  /// Returns [date] with time set to [hour]:[minute].
  DateTime _atTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime _nextAtHour(DateTime now, int hour) {
    final today = DateTime(now.year, now.month, now.day, hour);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, hour);
  }

  /// Checks whether the user's first brew is at least [days] old.
  Future<bool> _isFirstBrewOldEnough(UserStatsDao dao, int days) async {
    final earliest = await dao.fetchEarliestStat();
    if (earliest == null) return false;
    return DateTime.now().difference(earliest.createdAt).inDays >= days;
  }
}
