// lib/screens/finish_screen.dart
import 'dart:async';

import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:flutter/material.dart';
import 'package:coffee_timer/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_router.gr.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coffee_beans_model.dart';
import '../models/recipe_model.dart';
import '../providers/bean_review_provider.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/country_names.dart';
import '../widgets/notification_permission_dialog.dart';
import '../widgets/base_buttons.dart';
import '../services/bean_review_prompt_service.dart';
import '../services/onboarding_service.dart';
import '../services/analytics_service.dart';
import '../services/region_service.dart';
import '../services/local_notification_scheduler_service.dart';
import '../database/database.dart';
import '../services/moments_service.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/anniversary_celebration.dart';
import '../widgets/bean_review_nudge_card.dart';
import '../widgets/falling_beans_overlay.dart';
import '../widgets/first_brew_celebration.dart';

const String _nativeAppUrl = 'https://www.timer.coffee/get/';
const String _buyMeACoffeeUrl = 'https://www.buymeacoffee.com/timercoffee';

class FinishScreen extends StatefulWidget {
  final String brewingMethodName;
  final RecipeModel recipe;
  final double waterAmount;
  final double coffeeAmount;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;

  const FinishScreen({
    super.key,
    required this.brewingMethodName,
    required this.recipe,
    required this.waterAmount,
    required this.coffeeAmount,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
  });

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  static const Duration _analyticsFlushTimeout = Duration(seconds: 1);

  late Future<String> coffeeFact;
  final AdvancedInAppReview advancedInAppReview = AdvancedInAppReview();
  final Uuid _uuid = Uuid();
  bool _permissionRequestInProgress = false;
  bool _showPromoCard = false;

  // Approximate moment the brew finished — used as the anchor for the
  // in-sync window query.
  final DateTime _brewCompletedAt = DateTime.now();

  // In-sync detection state.
  int? _inSyncCount;
  List<String> _inSyncCountries = const [];
  bool _inSyncResolved = false;
  int _inSyncThreshold = 3; // resolved per current UTC hour in initState

  // Anniversary state — resolved asynchronously since the first-brew lookup
  // may need a DAO hit.
  bool _showAnniversary = false;

  // Falling beans cameo. Toggled true when anniversary or in-sync fires.
  bool _showFallingBeans = false;

  // Futures for the two fire-and-forget DB writes this screen kicks off in
  // initState. Stored (rather than bare-called) so the bean-review-nudge
  // slot decision can await them without re-triggering the writes.
  late Future<void> _insertBrewingDataFuture;
  late Future<bool> _updateBeanWeightFuture;

  // Signals moment resolution to the finish-slot decision (plan 021,
  // "Decide once, no card-swapping"). Completed on EVERY exit path of
  // `_resolveAnniversary` / `_queryInSync` so the review-nudge card never
  // gets yanked out from under a moment that resolves after it commits.
  final Completer<void> _anniversaryCompleter = Completer<void>();
  final Completer<void> _inSyncCompleter = Completer<void>();

  // Single-card finish slot: promo > anniversary > in-sync > review nudge >
  // coffee fact. Created once here (not in build) so it isn't re-resolved on
  // every rebuild.
  late Future<_FinishSlotContent> _slotContentFuture;

  bool get _inSyncWon =>
      _inSyncResolved && _inSyncCount != null && _inSyncCount! >= _inSyncThreshold;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enabled.then((bool wakelockEnabled) {
      if (wakelockEnabled) {
        WakelockPlus.disable();
      }
    });

    AnalyticsService.instance.track(
      'brew_completed',
      properties: {
        'recipe_id': widget.recipe.id,
        'brewing_method_id': widget.recipe.brewingMethodId,
        'coffee_amount': widget.coffeeAmount,
        'water_amount': widget.waterAmount,
      },
    );

    coffeeFact = Provider.of<RecipeProvider>(
      context,
      listen: false,
    ).getRandomCoffeeFactFromDB();
    _inSyncThreshold =
        kInSyncThresholdByHour[_brewCompletedAt.toUtc().hour] ?? 3;
    requestReview();
    _insertBrewingDataFuture = insertBrewingDataToAppDatabase();
    _updateBeanWeightFuture = _updateBeanWeightAfterBrew();
    _checkAndRequestNotificationPermission();
    _resolveAnniversary();
    _queryInSync();
    // Kicks off once here (not in build) — races the review-nudge
    // eligibility decision against the moment resolutions + a soft 3s
    // deadline, falling back to the coffee fact. Safe during initState:
    // its body doesn't touch Localizations/inherited widgets before its
    // first await (see the comment below on the same rule).
    _slotContentFuture = _resolveSlotContent();
    // Both `_recordBrewForOnboarding` and `insertBrewingDataToSupabase`
    // touch `Localizations.localeOf(context)`, which registers an
    // InheritedWidget dependency and is therefore illegal during initState.
    // Defer them until after the first frame, when the inherited tree is
    // fully attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recordBrewForOnboarding();
      insertBrewingDataToSupabase();
    });
    if (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      _checkWebPromoCounter();
    }
  }

  /// Loads the user's first-brew timestamp and decides whether to show the
  /// anniversary card today. Idempotent: per-year shown flag prevents the card
  /// from re-showing on subsequent brews the same day.
  Future<void> _resolveAnniversary() async {
    // Wrapped so the anniversary-resolution completer fires on EVERY exit
    // path (including the early returns below) — the review-nudge slot
    // decision awaits it to avoid rendering the review card underneath a
    // moment that resolves later (plan 021, "Decide once").
    try {
      final moments = Provider.of<MomentsService>(context, listen: false);
      await moments.earliestBrewAt();
      if (!mounted) return;
      final shouldShow = moments.isFirstBrewAnniversary &&
          !moments.isAnniversaryShownThisYear();
      if (!shouldShow) return;
      setState(() => _showAnniversary = true);
      await moments.markDiscovered('anniversary');
      await moments.markAnniversaryShownThisYear();
      AnalyticsService.instance.track(
        'moment_shown',
        properties: {'moment_id': 'anniversary'},
      );
      _maybeFireFallingBeans();
    } finally {
      if (!_anniversaryCompleter.isCompleted) {
        _anniversaryCompleter.complete();
      }
    }
  }

  /// Counts other users' brews in a ±60s window around this brew's completion
  /// time. If the count clears the per-UTC-hour threshold, fires the in-sync
  /// celebration in place of the coffee facts card.
  Future<void> _queryInSync() async {
    // Wrapped so the in-sync-resolution completer fires on EVERY exit path
    // (forced short-circuit, signed-out, success, timeout, and error) — see
    // the matching comment on `_resolveAnniversary`.
    try {
      final moments = Provider.of<MomentsService>(context, listen: false);

      // Debug short-circuit: if the user pressed "force in-sync next brew" on
      // the Moments debug screen, honour it without touching Supabase.
      final forced = moments.consumeForcedInSync();
      if (forced != null) {
        if (!mounted) return;
        setState(() {
          _inSyncCount = forced.count;
          _inSyncCountries = forced.countries;
          _inSyncResolved = true;
        });
        if (forced.count >= _inSyncThreshold) {
          await moments.markDiscovered('in_sync');
          AnalyticsService.instance.track(
            'moment_shown',
            properties: {
              'moment_id': 'in_sync',
              'in_sync_count': forced.count,
              'country_count': forced.countries.length,
            },
          );
        }
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _inSyncResolved = true);
        return;
      }

      final start = _brewCompletedAt
          .subtract(const Duration(seconds: 60))
          .toUtc()
          .toIso8601String();
      final end = _brewCompletedAt.toUtc().toIso8601String();

      try {
        final res = await Supabase.instance.client
            .from('global_stats')
            .select('user_id, country_code')
            .gte('created_at', start)
            .lte('created_at', end)
            .neq('user_id', user.id)
            .timeout(const Duration(seconds: 3));

        // Dedupe by user_id so a peer with two brews in the window counts
        // once. Also build a frequency tally of country codes for the
        // "from …" line.
        final rows = (res as List).cast<Map<String, dynamic>>();
        final firstCountryByUser = <String, String?>{};
        for (final row in rows) {
          final uid = row['user_id']?.toString();
          if (uid == null || uid.isEmpty) continue;
          final raw = row['country_code']?.toString().trim();
          final code = (raw == null || raw.isEmpty) ? null : raw.toUpperCase();
          firstCountryByUser.putIfAbsent(uid, () => code);
        }
        final count = firstCountryByUser.length;
        final countryTally = <String, int>{};
        for (final code in firstCountryByUser.values) {
          if (code == null) continue;
          countryTally[code] = (countryTally[code] ?? 0) + 1;
        }
        final countries = countryTally.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (!mounted) return;
        setState(() {
          _inSyncCount = count;
          _inSyncCountries =
              countries.map((e) => e.key).toList(growable: false);
          _inSyncResolved = true;
        });

        if (count >= _inSyncThreshold) {
          await moments.markDiscovered('in_sync');
          AnalyticsService.instance.track(
            'moment_shown',
            properties: {
              'moment_id': 'in_sync',
              'in_sync_count': count,
              'country_count': countries.length,
            },
          );
        }
      } on TimeoutException catch (e) {
        AppLogger.error('In-sync query timed out', errorObject: e);
        if (mounted) setState(() => _inSyncResolved = true);
      } catch (e) {
        AppLogger.error('Error querying in-sync brews', errorObject: e);
        if (mounted) setState(() => _inSyncResolved = true);
      }
    } finally {
      if (!_inSyncCompleter.isCompleted) {
        _inSyncCompleter.complete();
      }
    }
  }

  void _maybeFireFallingBeans() {
    if (!mounted || _showFallingBeans) return;
    setState(() => _showFallingBeans = true);
  }

  Widget _buildInSyncCard(
    BuildContext context,
    int count,
    List<String> countries,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final fromLine = _formatInSyncCountriesLine(
      l10n: l10n,
      locale: locale,
      countries: countries,
      maxNamed: 3,
    );

    return Semantics(
      identifier: 'inSyncCard',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Icon(
                    Symbols.globe,
                    color: theme.colorScheme.primary,
                    size: AppIconSize.large + 8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.mts_inSyncCelebration(count),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (fromLine != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    fromLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the "from USA, Germany and Russia" subtitle (or a "and N others"
  /// variant when the list is long). Returns null if no countries are known.
  String? _formatInSyncCountriesLine({
    required AppLocalizations l10n,
    required Locale locale,
    required List<String> countries,
    required int maxNamed,
  }) {
    if (countries.isEmpty) return null;

    String? nameFor(String code) =>
        localizedCountryNameGenitive(code, locale) ??
        localizedCountryName(code, locale);

    final names = <String>[
      for (final c in countries.take(maxNamed))
        if (nameFor(c) != null) nameFor(c)!,
    ];
    if (names.isEmpty) return null;

    final connector = l10n.mts_inSyncCountriesConnector;
    final joined = _joinNames(names, connector);
    final extras = countries.length - names.length;
    if (extras <= 0) {
      return l10n.mts_inSyncFromCountries(joined);
    }
    return l10n.mts_inSyncFromCountriesWithOthers(joined, extras);
  }

  String _joinNames(List<String> names, String connector) {
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} $connector ${names[1]}';
    final head = names.sublist(0, names.length - 1).join(', ');
    return '$head $connector ${names.last}';
  }

  void _recordBrewForOnboarding() {
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    onboarding.recordBrew(
      recipeId: widget.recipe.id,
      brewingMethodId: widget.recipe.brewingMethodId,
    );

    // Reschedule engagement notifications (pushes brew reminders forward)
    final database = Provider.of<AppDatabase>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    unawaited(
      LocalNotificationSchedulerService.instance.rescheduleAll(
        database: database,
        onboarding: onboarding,
        locale: locale,
      ),
    );
  }

  void insertBrewingDataToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = {
        'user_id': user.id,
        'brewing_method': widget.brewingMethodName,
        'recipe_id': widget.recipe.id,
        'water_amount': widget.waterAmount,
      };

      final regionService = RegionService(Supabase.instance.client);
      final localeCode = Localizations.localeOf(context).toLanguageTag();
      final countryCode = await regionService
          .getCountryCode(localeCode: localeCode)
          .catchError((_) => null);
      if (countryCode != null) data['country_code'] = countryCode;

      try {
        await Supabase.instance.client
            .from('global_stats')
            .insert(data)
            .timeout(const Duration(seconds: 3));
      } on TimeoutException catch (e) {
        AppLogger.error('Supabase request timed out', errorObject: e);
        // Optionally, handle the timeout here
      } catch (e) {
        AppLogger.error(
          'Error inserting brewing data to Supabase',
          errorObject: e,
        );
        // Handle other exceptions as needed
      }
    }
  }

  Future<void> insertBrewingDataToAppDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final statUuid = _uuid.v7();
        final userStatProvider = Provider.of<UserStatProvider>(
          context,
          listen: false,
        );
        final database = Provider.of<AppDatabase>(context, listen: false);
        final locale = Localizations.localeOf(context).languageCode;

        // Fetch the coffee beans UUID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final coffeeBeansUuid = prefs.getString('selectedBeanUuid');

        await userStatProvider.insertUserStat(
          recipeId: widget.recipe.id,
          coffeeAmount: widget.coffeeAmount,
          waterAmount: widget.waterAmount,
          sweetnessSliderPosition: widget.sweetnessSliderPosition,
          strengthSliderPosition: widget.strengthSliderPosition,
          brewingMethodId: widget.recipe.brewingMethodId,
          statUuid: statUuid,
          coffeeBeansUuid: coffeeBeansUuid,
          grindSize: widget.recipe.grindSize,
        );
        if (coffeeBeansUuid != null && coffeeBeansUuid.isNotEmpty) {
          AnalyticsService.instance.track(
            'beans_attached',
            properties: {
              'recipe_id': widget.recipe.id,
              'brewing_method_id': widget.recipe.brewingMethodId,
            },
          );
          unawaited(
            LocalNotificationSchedulerService.instance
                .maybeScheduleBeanReviewNudge(
                  database: database,
                  beansUuid: coffeeBeansUuid,
                  locale: locale,
                ),
          );
          // Plan 011, Channel B: if this bean's roaster is a pending
          // candidate, schedule a one-shot "help add this roaster" nudge.
          unawaited(
            LocalNotificationSchedulerService.instance
                .maybeScheduleRoasterContribNudgeOnBrew(
                  database: database,
                  beansUuid: coffeeBeansUuid,
                  locale: locale,
                ),
          );
        }
        AppLogger.debug(
          'Inserted new stat with UUID: $statUuid and Coffee Beans UUID: $coffeeBeansUuid',
        );
      } catch (e) {
        AppLogger.error(
          "Error inserting brewing data to app database",
          errorObject: e,
        );
      }
    } else {
      AppLogger.debug('No user signed in');
    }
  }

  /// Returns true only when this brew crossed the bag into "empty"
  /// (`newWeight < 0.1`) — the depletion signal the review-nudge slot
  /// decision uses. Internal behavior (including the depletion-notification
  /// call) is unchanged from before this method became awaitable.
  Future<bool> _updateBeanWeightAfterBrew() async {
    try {
      // Only proceed if we have a valid coffee amount
      if (widget.coffeeAmount <= 0) {
        AppLogger.debug('No coffee amount to subtract from bean weight');
        return false;
      }
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );
      final database = Provider.of<AppDatabase>(context, listen: false);
      final locale = Localizations.localeOf(context).languageCode;

      // Get the selected bean UUID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final coffeeBeansUuid = prefs.getString('selectedBeanUuid');

      if (coffeeBeansUuid == null || coffeeBeansUuid.isEmpty) {
        AppLogger.debug('No selected bean UUID found in SharedPreferences');
        return false;
      }

      // Update the bean weight
      final newWeight = await coffeeBeansProvider.updateBeanWeightAfterBrew(
        coffeeBeansUuid,
        widget.coffeeAmount,
      );

      if (newWeight != null) {
        AppLogger.debug('Successfully updated bean weight to ${newWeight}g');
        // Bag just emptied (weight crossed to ~0) — a high-intent moment to
        // ask for a review. updateBeanWeightAfterBrew returns null when the
        // bean was already empty, so this fires only on the crossing brew.
        if (newWeight < 0.1) {
          unawaited(
            LocalNotificationSchedulerService.instance
                .maybeScheduleBeanReviewNudgeOnDepletion(
                  database: database,
                  beansUuid: coffeeBeansUuid,
                  locale: locale,
                ),
          );
          return true;
        }
        return false;
      } else {
        AppLogger.debug('Bean weight update failed or was not applicable');
        return false;
      }
    } catch (e) {
      AppLogger.debug('Error updating bean weight', errorObject: e);
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Bean-review nudge card — finish-slot resolution (plan 021)
  // ---------------------------------------------------------------------

  /// Resolves the single finish-screen card slot. Races the review-nudge
  /// eligibility decision against a soft deadline; on timeout or any error,
  /// falls back to the coffee fact (plan 021 "on deadline/error ... resolve
  /// to fact"). The deadline must exceed the in-sync query's own 3s timeout
  /// (awaited via [_inSyncCompleter]) — otherwise a slow network would
  /// always trip this deadline first and the review card could never show.
  /// Created exactly once, from initState.
  Future<_FinishSlotContent> _resolveSlotContent() async {
    try {
      return await _resolveSlotDecision().timeout(const Duration(seconds: 4));
    } catch (e) {
      AppLogger.error(
        'Bean review slot resolution failed or timed out',
        errorObject: e,
      );
      return _resolveFactContent();
    }
  }

  /// Awaits the two brew-completion writes and both moment-resolution
  /// signals, then either yields to a higher-priority moment/promo (already
  /// occupying the slot) or runs [BeanReviewPromptService.evaluate] to
  /// decide whether to show the review-nudge card. Never shows the card if
  /// a moment/promo has won — see plan "Decide once, no card-swapping".
  Future<_FinishSlotContent> _resolveSlotDecision() async {
    final depletedThisBrew = await _updateBeanWeightFuture;
    await _insertBrewingDataFuture;
    await _anniversaryCompleter.future;
    await _inSyncCompleter.future;
    if (!mounted) return _resolveFactContent();

    // A higher-priority card already claimed the slot for this brew — the
    // review card is simply not shown (no deferral, no consumed impression;
    // see plan "Losing the slot").
    if (_showAnniversary || _inSyncWon || (kIsWeb && _showPromoCard)) {
      return _resolveFactContent();
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return _resolveFactContent();

    final beansUuid = prefs.getString('selectedBeanUuid');
    final promptService = BeanReviewPromptService(prefs: prefs);
    final database = Provider.of<AppDatabase>(context, listen: false);
    final reviewProvider = Provider.of<BeanReviewProvider>(
      context,
      listen: false,
    );

    final decision = await promptService.evaluate(
      database: database,
      reviewProvider: reviewProvider,
      beansUuid: beansUuid,
      depletedThisBrew: depletedThisBrew,
    );

    if (decision.show && decision.bean != null && decision.trigger != null) {
      return _FinishSlotContent.reviewNudge(
        bean: decision.bean!,
        trigger: decision.trigger!,
        promptService: promptService,
      );
    }
    return _resolveFactContent();
  }

  /// Awaits the existing [coffeeFact] future, preserving its current
  /// data/error/pending semantics for the fact-card branch of the slot.
  Future<_FinishSlotContent> _resolveFactContent() async {
    try {
      final fact = await coffeeFact;
      return _FinishSlotContent.fact(fact);
    } catch (e) {
      return _FinishSlotContent.factError(e);
    }
  }

  void _checkAndRequestNotificationPermission() async {
    if (kIsWeb) return;

    const shownKey = 'notif_perm_ab_shown';
    const legacyKey = 'firstfinishscreen';

    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(shownKey) ?? false) return;

    // Migration: users who saw the dialog under the pre-experiment code
    // (legacy `firstfinishscreen == false`) should never be re-prompted.
    if (prefs.containsKey(legacyKey) && !(prefs.getBool(legacyKey) ?? true)) {
      await prefs.setBool(shownKey, true);
      return;
    }

    // Skip if the user already has permission — no need to ask again.
    final alreadyGranted = await NotificationService
        .instance
        .permissions
        .hasNotificationPermission;
    if (alreadyGranted) {
      await prefs.setBool(shownKey, true);
      return;
    }

    // Wait for the finish screen to fully render before interrupting with a dialog.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    AnalyticsService.instance.track(
      'notification_permission_shown',
      properties: {'brew_count': 1},
    );
    await prefs.setBool(shownKey, true);
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationPermissionDialog(
        onEnable: () => Navigator.of(context).pop(true),
        onSkip: () => Navigator.of(context).pop(false),
      ),
    );

    if (result == true && !_permissionRequestInProgress) {
      _permissionRequestInProgress = true;
      // Small delay so the dialog is fully dismissed before the system prompt.
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (mounted) {
          final granted = await _requestSystemPermissionAndUpdateSettings();
          AnalyticsService.instance.track(
            'notification_permission_result',
            properties: {'result': granted ? 'granted' : 'denied'},
          );
        }
        _permissionRequestInProgress = false;
      });
    } else if (result == false) {
      AnalyticsService.instance.track(
        'notification_permission_result',
        properties: {'result': 'skipped'},
      );
    }
  }

  Future<bool> _requestSystemPermissionAndUpdateSettings() async {
    try {
      AppLogger.debug(
        'Requesting system notification permissions from finish screen',
      );

      final granted = await NotificationService.instance.requestPermissions();

      if (granted) {
        final user = Supabase.instance.client.auth.currentUser;
        await NotificationService.instance.updateMasterToggle(
          enabled: true,
          userId: user?.id,
        );
        AppLogger.debug(
          'Notification permissions granted and master toggle updated',
        );
      } else {
        AppLogger.debug('Notification permissions denied by user');
      }

      return granted;
    } catch (e) {
      AppLogger.error(
        'Error requesting notification permissions from finish screen',
        errorObject: e,
      );
      return false;
    }
  }

  Future<void> requestReview() async {
    if (!kIsWeb) {
      advancedInAppReview
          .setMinDaysBeforeRemind(7)
          .setMinDaysAfterInstall(2)
          .setMinLaunchTimes(2)
          .setMinSecondsBeforeShowDialog(4);
      advancedInAppReview.monitor();
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _openExternalDonationLink() async {
    AnalyticsService.instance.track(
      'donation_button_tapped',
      properties: {
        'product_id': 'buymeacoffee_external',
        'source_screen': 'finish_screen',
      },
    );
    try {
      await AnalyticsService.instance.flushNow().timeout(
        _analyticsFlushTimeout,
      );
    } catch (_) {}
    await _launchURL(_buyMeACoffeeUrl);
  }

  void _checkWebPromoCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('webFinishCount') ?? 0) + 1;
    await prefs.setInt('webFinishCount', count);
    if (count % 3 == 0 && mounted) {
      setState(() {
        _showPromoCard = true;
      });
    }
  }

  Widget _buildNativeAppPromoCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Semantics(
      identifier: 'nativeAppPromoCard',
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.nativeAppPromoTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.nativeAppPromoDescription,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(0, AppButton.heightLarge),
                  padding: AppButton.paddingMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppButton.radius),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textStyle: AppButton.label,
                ),
                onPressed: () => _launchURL(_nativeAppUrl),
                icon: const Icon(Icons.download),
                label: Text(loc.nativeAppPromoButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double homeButtonWidth = (screenWidth * 0.4)
        .clamp(120.0, 150.0)
        .toDouble();
    final double supportButtonWidth = (screenWidth * 0.6)
        .clamp(200.0, 240.0)
        .toDouble();

    final showInSync = _inSyncWon;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'finishBrewTitle',
          child: Text(AppLocalizations.of(context)!.finishbrew),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Semantics(
                        identifier: 'finishMessage',
                        child: Text(
                          '${AppLocalizations.of(context)!.finishmsg} ${widget.brewingMethodName}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FirstBrewCelebration(
                      brewingMethodId: widget.recipe.brewingMethodId,
                    ),
                    // Same UI slot for promo / anniversary / in-sync /
                    // review nudge / coffee fact. Priority: promo >
                    // anniversary > in-sync > review nudge > coffee fact.
                    // Each higher tier REPLACES the default fact card so the
                    // screen stays single-card (plan 021).
                    if (kIsWeb && _showPromoCard)
                      _buildNativeAppPromoCard(context)
                    else if (_showAnniversary)
                      const AnniversaryCelebration(shouldShow: true)
                    else if (showInSync)
                      _buildInSyncCard(context, _inSyncCount!, _inSyncCountries)
                    else
                      FutureBuilder<_FinishSlotContent>(
                        future: _slotContentFuture,
                        builder: (context, snapshot) {
                          final content = snapshot.data;
                          if (content == null) {
                            // Still resolving eligibility / the coffee fact —
                            // same pending behavior as the previous
                            // plain-fact FutureBuilder.
                            return const CircularProgressIndicator();
                          }
                          switch (content.kind) {
                            case _FinishSlotKind.reviewNudge:
                              return BeanReviewNudgeCard(
                                bean: content.bean!,
                                trigger: content.trigger!,
                                promptService: content.promptService!,
                              );
                            case _FinishSlotKind.factError:
                              return Semantics(
                                identifier: 'coffeeFactCard',
                                child: Text('Error: ${content.error}'),
                              );
                            case _FinishSlotKind.fact:
                              return Semantics(
                                identifier: 'coffeeFactCard',
                                child: Card(
                                  margin: const EdgeInsets.all(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(
                                          context,
                                        ).style,
                                        children: <TextSpan>[
                                          TextSpan(
                                            text:
                                                '${AppLocalizations.of(context)!.coffeefact}: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          TextSpan(
                                            text: content.factText,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                          }
                        },
                      ),
                    const SizedBox(height: 20),
                    Semantics(
                      identifier: 'homeButton',
                      child: AppElevatedButton(
                        label: AppLocalizations.of(context)!.home,
                        onPressed: () => context.router.push(const HomeRoute()),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        height: AppButton.heightLarge,
                        width: homeButtonWidth,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (kIsWeb || !Platform.isIOS)
                      Semantics(
                        identifier: 'buyMeACoffeeButton',
                        child: AppElevatedButton(
                          label: AppLocalizations.of(context)!.support,
                          onPressed: () async => _openExternalDonationLink(),
                          icon: Icons.local_cafe,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          height: AppButton.heightLarge,
                          width: supportButtonWidth,
                        ),
                      )
                    else if (!kIsWeb && Platform.isIOS)
                      Semantics(
                        identifier: 'supportButton',
                        child: AppElevatedButton(
                          label: AppLocalizations.of(context)!.support,
                          onPressed: () =>
                              context.router.push(const DonationRoute()),
                          icon: Icons.local_cafe,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          height: AppButton.heightLarge,
                          width: supportButtonWidth,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_showFallingBeans)
            Positioned.fill(
              child: FallingBeansOverlay(
                onComplete: () {
                  if (mounted) setState(() => _showFallingBeans = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// What the single finish-screen card slot ultimately renders once
/// [_FinishScreenState._resolveSlotContent] settles: either the bean-review
/// nudge card, the coffee fact, or the coffee fact's error state (mirrors
/// the previous plain `FutureBuilder<String>` semantics — see plan 021,
/// "Finish-screen wiring").
enum _FinishSlotKind { reviewNudge, fact, factError }

class _FinishSlotContent {
  final _FinishSlotKind kind;
  final CoffeeBeansModel? bean;
  final String? trigger;
  final BeanReviewPromptService? promptService;
  final String? factText;
  final Object? error;

  const _FinishSlotContent._({
    required this.kind,
    this.bean,
    this.trigger,
    this.promptService,
    this.factText,
    this.error,
  });

  factory _FinishSlotContent.reviewNudge({
    required CoffeeBeansModel bean,
    required String trigger,
    required BeanReviewPromptService promptService,
  }) => _FinishSlotContent._(
    kind: _FinishSlotKind.reviewNudge,
    bean: bean,
    trigger: trigger,
    promptService: promptService,
  );

  factory _FinishSlotContent.fact(String text) =>
      _FinishSlotContent._(kind: _FinishSlotKind.fact, factText: text);

  factory _FinishSlotContent.factError(Object error) =>
      _FinishSlotContent._(kind: _FinishSlotKind.factError, error: error);
}
