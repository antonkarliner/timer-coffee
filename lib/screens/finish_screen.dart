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
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../services/engagement_budget_service.dart';
import '../services/finish_slot_resolver.dart';
import '../services/onboarding_service.dart';
import '../services/analytics_service.dart';
import '../services/region_service.dart';
import '../services/local_notification_scheduler_service.dart';
import '../services/brew_recording_service.dart';
import '../database/database.dart';
import '../services/moments_service.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../widgets/anniversary_celebration.dart';
import '../widgets/bean_review_nudge_card.dart';
import '../widgets/brew_diary/brew_detail_sheet.dart' show diaryEntrySourceLabel;
import '../widgets/falling_beans_overlay.dart';
import '../widgets/finish/brew_eval_sheet.dart';
import '../widgets/finish/whats_new_card.dart';
import '../widgets/first_brew_celebration.dart';

const String _nativeAppUrl = 'https://www.timer.coffee/get/';
const String _buyMeACoffeeUrl = 'https://www.buymeacoffee.com/timercoffee';

/// The DB `entry_source` code every `FinishScreen` brew writes (plan 039
/// triage item 8). `FinishScreen` is only ever pushed from
/// `brewing_process_screen.dart`'s guided timer flow — the sole
/// `FinishScreen(` constructor call site in the codebase — never from
/// manual or legacy diary entry, so hardcoding `0` ('timer') here is safe
/// today. Keep the constant rather than threading a real value from the
/// stat row; see [finishScreenEntrySourceLabel] for the loud-failure half
/// of this guarantee.
const int kFinishScreenEntrySourceCode = 0;

/// [diaryEntrySourceLabel] of [kFinishScreenEntrySourceCode] — the
/// `entry_source` label every finish-screen analytics event and DB write
/// uses. Debug-asserts that the mapping still resolves to `'timer'`, so a
/// future change to `diaryEntrySourceLabel`'s code→label switch that
/// silently redefines what `0` means fails loudly here instead of quietly
/// mislabeling finish-screen analytics. This assert cannot catch the other
/// half of triage item 8's concern — a future caller reaching this screen
/// through a non-timer path — since there is no per-call runtime signal to
/// check against; that guarantee is structural (see the doc above) and must
/// be preserved by code review, not by this function.
String finishScreenEntrySourceLabel() {
  final label = diaryEntrySourceLabel(kFinishScreenEntrySourceCode);
  assert(
    label == 'timer',
    'FinishScreen hardcodes entrySource 0 assuming it means "timer" '
    '(guided brews only) — diaryEntrySourceLabel\'s mapping changed '
    'underneath that assumption.',
  );
  return label;
}

@visibleForTesting
Future<void> insertGuidedBrewUserStat({
  required UserStatProvider userStatProvider,
  required RecipeModel recipe,
  required double coffeeAmount,
  required double waterAmount,
  required int sweetnessSliderPosition,
  required int strengthSliderPosition,
  required String statUuid,
  required String? coffeeBeansUuid,
  required double? waterTemp,
}) {
  return userStatProvider.insertUserStat(
    recipeId: recipe.id,
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
    sweetnessSliderPosition: sweetnessSliderPosition,
    strengthSliderPosition: strengthSliderPosition,
    brewingMethodId: recipe.brewingMethodId,
    statUuid: statUuid,
    coffeeBeansUuid: coffeeBeansUuid,
    grindSize: recipe.grindSize,
    waterTemp: waterTemp,
    entrySource: kFinishScreenEntrySourceCode,
  );
}

/// Writes the finish-screen star row's rating and, once that write
/// succeeds, emits `diary_entry_edited` (plan 039 triage item 7). Extracted
/// from `_tapRatingStar` so the write+track pairing is unit-testable
/// without mounting `FinishScreen` — see `finish_screen_test.dart`.
@visibleForTesting
Future<void> writeFinishScreenStarRating({
  required UserStatProvider userStatProvider,
  required String statUuid,
  required double rating,
  required String entrySource,
}) async {
  await userStatProvider.updateDiaryRating(statUuid: statUuid, rating: rating);
  AnalyticsService.maybeInstance?.track(
    'diary_entry_edited',
    properties: {
      'field': 'rating',
      'entry_source': entrySource,
      'source': 'finish_star_row',
    },
  );
}

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
  late final String _statUuid;
  bool _permissionRequestInProgress = false;
  bool _showPromoCard = false;

  // Star row (plan 039, Item B — budget-exempt "capture" control, D2).
  // Retired the sour/balanced/bitter chips in favor of a single satisfaction
  // rating; taste balance moved into BrewEvalSheet as a re-editable field.
  double? _rating;
  // True once `_insertBrewingDataFuture` has resolved — the star row is
  // disabled until then since a rating write targets a row that doesn't
  // exist yet.
  bool _ratingRowReady = false;
  Future<void> _ratingWrite = Future<void>.value();

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

  // These writes need Localizations, so they start from didChangeDependencies.
  // The gate keeps their futures stable and prevents duplicate inserts or bean
  // deductions if inherited dependencies change later.
  final BrewCompletionWriteGate _completionWrites = BrewCompletionWriteGate();
  Future<void> get _insertBrewingDataFuture => _completionWrites.insertFuture;
  Future<bool> get _updateBeanWeightFuture =>
      _completionWrites.beanWeightFuture;

  // Signals moment resolution to the finish-slot decision (plan 021,
  // "Decide once, no card-swapping"). Completed on EVERY exit path of
  // `_resolveAnniversary` / `_queryInSync` so the review-nudge card never
  // gets yanked out from under a moment that resolves after it commits.
  final Completer<void> _anniversaryCompleter = Completer<void>();
  final Completer<void> _inSyncCompleter = Completer<void>();

  // Single-card finish slot: promo > anniversary > in-sync > review nudge >
  // coffee fact. Created once here (not in build) so it isn't re-resolved on
  // every rebuild.
  late Future<FinishSlotContent> _slotContentFuture;

  // Bean-review shared decision (plan 039, Phase B2 — "Bean review, second
  // delivery surface"). `FinishSlotResolver.resolve` (called exactly once,
  // from `_slotContentFuture`) already runs `BeanReviewPromptService
  // .evaluate()` internally; these mirror the `reviewDecision` /
  // `promptService` fields on the `FinishSlotResolution` it returns (plan
  // 039 triage item 4 — the resolver returns this instead of mutating
  // `last*` fields on itself), so both the slot card and `BrewEvalSheet`'s
  // "Rate the beans" step read the exact same decision instead of each
  // calling `evaluate()` a second time (which would double-count against
  // the per-bean impression cap — see the plan's "How the shared cap
  // actually works" for why a second `evaluate()` isn't safe even though
  // `BeanReviewPromptService` itself is never modified). The resolution's
  // `depletedThisBrew` isn't hoisted here — nothing downstream of
  // `_resolveSlotDecision` reads it.
  BeanReviewPromptDecision? _beanReviewDecision;
  BeanReviewPromptService? _beanReviewPromptService;

  // Single per-visit guard shared between the slot card
  // (`BeanReviewNudgeCard`) and the eval sheet's "Rate the beans" step:
  // whichever one actually renders first calls `recordImpression()`, and
  // this flag stops the other from also recording. Plain field (not
  // `setState`-driven) — nothing in `build()` reads it directly.
  bool _beanReviewImpressionRecorded = false;

  bool get hasBeanReviewImpressionRecorded => _beanReviewImpressionRecorded;

  void _markBeanReviewImpressionRecorded() {
    _beanReviewImpressionRecorded = true;
  }

  bool get _inSyncWon =>
      _inSyncResolved &&
      _inSyncCount != null &&
      _inSyncCount! >= _inSyncThreshold;

  // Cached during `_resolveSlotDecision` (plan 039 Phase C2), so `build()`
  // can hand them to `WhatsNewCard` synchronously without re-fetching. Both
  // are guaranteed non-null by the time the slot future can possibly resolve
  // to `FinishSlotKind.whatsNew`, since that outcome only happens after
  // `_resolveSlotDecision` has already constructed them. `_budgetForWhatsNew`
  // is also handed to `BeanReviewNudgeCard` (plan 039 triage item 1) for the
  // same reason — it's constructed before the resolver can possibly return
  // `FinishSlotKind.reviewNudge` too.
  SharedPreferences? _prefsForWhatsNew;
  EngagementBudgetService? _budgetForWhatsNew;

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
    _statUuid = _uuid.v7();
    // The Completer-backed future exists as soon as `_completionWrites` is
    // constructed, regardless of when `.start()` actually runs (from
    // `didChangeDependencies`) — safe to attach here. Errors are swallowed:
    // a failed insert already logs + rethrows inside
    // `insertBrewingDataToAppDatabase`, and the star row simply stays
    // disabled rather than writing to a row that doesn't exist.
    _insertBrewingDataFuture.then(
      (_) {
        if (mounted) setState(() => _ratingRowReady = true);
      },
      onError: (Object _, StackTrace _) {},
    );
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _completionWrites.start(
      insertBrew: insertBrewingDataToAppDatabase,
      updateBeanWeight: _updateBeanWeightAfterBrew,
    );
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
      final shouldShow =
          moments.isFirstBrewAnniversary &&
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
          _inSyncCountries = countries
              .map((e) => e.key)
              .toList(growable: false);
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

  /// Gathers the `BuildContext`-bound values [BrewRecordingService] needs and
  /// packages them as plain data. `coffeeBeansUuid` and `countryCode` are
  /// separate parameters (rather than resolved inside here) because each
  /// caller resolves them differently — or not at all — mirroring exactly
  /// what the pre-extraction methods each did.
  BrewRecordingRequest _buildBrewRecordingRequest({
    required String? userId,
    required Locale locale,
    String? coffeeBeansUuid,
    String? countryCode,
  }) {
    return BrewRecordingRequest(
      statUuid: _statUuid,
      recipeId: widget.recipe.id,
      brewingMethodId: widget.recipe.brewingMethodId,
      brewingMethodName: widget.brewingMethodName,
      coffeeAmount: widget.coffeeAmount,
      waterAmount: widget.waterAmount,
      sweetnessSliderPosition: widget.sweetnessSliderPosition,
      strengthSliderPosition: widget.strengthSliderPosition,
      grindSize: widget.recipe.grindSize,
      // Runtime RecipeModel.waterTemp is the normalized effective value.
      waterTemp: widget.recipe.waterTemp,
      coffeeBeansUuid: coffeeBeansUuid,
      localeCode: locale.toLanguageTag(),
      languageCode: locale.languageCode,
      entrySource: kFinishScreenEntrySourceCode,
      countryCode: countryCode,
      userId: userId,
    );
  }

  void insertBrewingDataToSupabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    // Pure read, no side effects — safe to resolve regardless of sign-in
    // state (previously only read inside the `user != null` branch).
    final locale = Localizations.localeOf(context);
    // Both context reads happen BEFORE the country-code await below: the user
    // can leave the finish screen while that request is in flight (the exact
    // fast-exit behaviour plan 042 is about), and reading `context` afterwards
    // would touch a deactivated element.
    final recordingService = Provider.of<BrewRecordingService>(
      context,
      listen: false,
    );

    String? countryCode;
    if (userId != null) {
      final regionService = RegionService(Supabase.instance.client);
      countryCode = await regionService
          .getCountryCode(localeCode: locale.toLanguageTag())
          .catchError((_) => null);
    }

    final request = _buildBrewRecordingRequest(
      userId: userId,
      locale: locale,
      countryCode: countryCode,
    );
    await recordingService.recordRemoteBrew(
      request: request,
      insertGlobalStat: (data) =>
          Supabase.instance.client.from('global_stats').insert(data),
    );
  }

  Future<void> insertBrewingDataToAppDatabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final recordingService = Provider.of<BrewRecordingService>(
      context,
      listen: false,
    );
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );
    final database = Provider.of<AppDatabase>(context, listen: false);
    final locale = Localizations.localeOf(context);

    // Fetch the coffee beans UUID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final coffeeBeansUuid = prefs.getString('selectedBeanUuid');

    final request = _buildBrewRecordingRequest(
      userId: userId,
      locale: locale,
      coffeeBeansUuid: coffeeBeansUuid,
    );

    await recordingService.recordLocalBrew(
      request: request,
      userStatProvider: userStatProvider,
      database: database,
      scheduleBeanReviewNudge:
          LocalNotificationSchedulerService.instance.maybeScheduleBeanReviewNudge,
      scheduleRoasterContribNudge: LocalNotificationSchedulerService
          .instance
          .maybeScheduleRoasterContribNudgeOnBrew,
    );
  }

  /// Tapping a star (1) instantly writes `rating` to the `_statUuid` row and
  /// (2) opens [BrewEvalSheet] pre-seeded with that rating (plan 039, Item
  /// B, D2 — budget-exempt, always visible). Mirrors the retired
  /// `_selectTasteBalance`'s serialized-write pattern so rapid taps can't
  /// interleave writes: `_ratingWrite = _ratingWrite.then(...)`. The sheet
  /// only opens after the write settles (success or failure), so its own
  /// field saves never race the initial rating write for the same row.
  ///
  /// Plan 039 triage item 7: once the write succeeds, emits
  /// `diary_entry_edited {field: 'rating', entry_source, source:
  /// 'finish_star_row'}` — the star row previously saved a rating with no
  /// analytics event, making rating-capture rate unmeasurable. `source` is
  /// deliberately `'finish_star_row'`, not `'finish_eval_sheet'` (the value
  /// [BrewEvalSheet] uses for its own in-sheet rating edits): the trigger
  /// tap and a considered in-sheet edit are different interactions and must
  /// stay separable in the data even when a user does both for one brew.
  Future<void> _tapRatingStar(double value) async {
    if (!_ratingRowReady) return;
    setState(() => _rating = value);

    _ratingWrite = _ratingWrite
        .then((_) async {
          await _insertBrewingDataFuture;
          if (!mounted) return;
          final userStatProvider = Provider.of<UserStatProvider>(
            context,
            listen: false,
          );
          await writeFinishScreenStarRating(
            userStatProvider: userStatProvider,
            statUuid: _statUuid,
            rating: value,
            entrySource: finishScreenEntrySourceLabel(),
          );
        })
        .catchError((Object error) {
          AppLogger.error('Error saving finish-screen rating', errorObject: error);
        });
    await _ratingWrite;
    if (!mounted) return;
    unawaited(
      showBrewEvalSheet(
        context,
        statUuid: _statUuid,
        entrySource: finishScreenEntrySourceLabel(),
        initialRating: value,
        // Keep the star row in sync with edits made inside the sheet —
        // without this it kept showing the originally tapped value after
        // the sheet closed.
        onRatingChanged: (updated) {
          if (!mounted) return;
          setState(() => _rating = updated);
        },
        reviewDecision: _beanReviewDecision,
        reviewPromptService: _beanReviewPromptService,
        hasBeanReviewImpressionRecorded: () =>
            hasBeanReviewImpressionRecorded,
        onBeanReviewImpressionRecorded: _markBeanReviewImpressionRecorded,
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Semantics(
        identifier: 'finishRatingRow',
        child: IgnorePointer(
          ignoring: !_ratingRowReady,
          child: Opacity(
            opacity: _ratingRowReady ? 1.0 : 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.finishRatePrompt,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: AppSpacing.sm),
                KeyedSubtree(
                  // RatingBar reads [initialRating] only on first build and
                  // then owns its display state, so an externally changed
                  // rating (edited inside the eval sheet) needs a new key to
                  // force a rebuild. Value-keyed rather than const for that
                  // reason — see [_tapRatingStar]'s onRatingChanged.
                  key: ValueKey<String>('finishRatingBar_${_rating ?? 0}'),
                  child: RatingBar.builder(
                    initialRating: _rating ?? 0,
                    minRating: 0.5,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: AppIconSize.large,
                    itemBuilder: (context, index) =>
                        Icon(Icons.star, color: theme.colorScheme.primary),
                    onRatingUpdate: (value) => _tapRatingStar(value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns true only when this brew crossed the bag into "empty"
  /// (`newWeight < 0.1`) — the depletion signal the review-nudge slot
  /// decision uses. Internal behavior (including the depletion-notification
  /// call) is unchanged from before this method became awaitable.
  Future<bool> _updateBeanWeightAfterBrew() async {
    final recordingService = Provider.of<BrewRecordingService>(
      context,
      listen: false,
    );
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    final database = Provider.of<AppDatabase>(context, listen: false);
    final locale = Localizations.localeOf(context);

    // Get the selected bean UUID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final coffeeBeansUuid = prefs.getString('selectedBeanUuid');

    final request = _buildBrewRecordingRequest(
      userId: Supabase.instance.client.auth.currentUser?.id,
      locale: locale,
      coffeeBeansUuid: coffeeBeansUuid,
    );

    return recordingService.updateBeanWeight(
      request: request,
      coffeeBeansProvider: coffeeBeansProvider,
      database: database,
      scheduleBeanReviewNudgeOnDepletion: LocalNotificationSchedulerService
          .instance
          .maybeScheduleBeanReviewNudgeOnDepletion,
    );
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
  Future<FinishSlotContent> _resolveSlotContent() async {
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

  /// Delegates to [FinishSlotResolver.resolve] (plan 039 Phase A1 — wired
  /// through [EngagementBudgetService] in shadow mode, so still no behavior
  /// change). This method's own job is limited to
  /// resolving the context-dependent inputs ([SharedPreferences], the
  /// [AppDatabase]/[BeanReviewProvider] providers) that the resolver itself
  /// must not reach for, and checking [mounted] before touching
  /// [context]-bound APIs.
  Future<FinishSlotContent> _resolveSlotDecision() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return _resolveFactContent();

    final database = Provider.of<AppDatabase>(context, listen: false);
    final reviewProvider = Provider.of<BeanReviewProvider>(
      context,
      listen: false,
    );
    final budget = EngagementBudgetService(prefs: prefs);
    // Cached for `build()`'s `WhatsNewCard` branch — see the field docs.
    _prefsForWhatsNew = prefs;
    _budgetForWhatsNew = budget;
    final resolver = FinishSlotResolver(
      database: database,
      reviewProvider: reviewProvider,
      prefs: prefs,
      budget: budget,
    );

    // Plan 039 Phase C2 — the whats-new candidate. Reads the same cached
    // "latest popup" the home popup reads (`RecipeProvider
    // .fetchLatestLaunchPopup`, a pass-through to `DatabaseProvider`'s
    // cached model), so this never triggers a second remote fetch. `locale`
    // must be read before any further await here so it stays consistent
    // with the seen-state key `WhatsNewCard` writes.
    final locale = Localizations.localeOf(context).languageCode;
    final whatsNewPopupFuture = Provider.of<RecipeProvider>(
      context,
      listen: false,
    ).fetchLatestLaunchPopup(locale);

    final resolution = await resolver.resolve(
      updateBeanWeightFuture: _updateBeanWeightFuture,
      insertBrewingDataFuture: _insertBrewingDataFuture,
      anniversaryFuture: _anniversaryCompleter.future,
      inSyncFuture: _inSyncCompleter.future,
      showAnniversary: () => _showAnniversary,
      inSyncWon: () => _inSyncWon,
      showPromoCard: () => kIsWeb && _showPromoCard,
      coffeeFact: coffeeFact,
      isMounted: () => mounted,
      whatsNewPopupFuture: whatsNewPopupFuture,
      locale: locale,
    );
    // Hoist the resolver's once-per-visit bean-review decision (plan 039
    // Phase B2) so the eval sheet's "Rate the beans" step can read the exact
    // same decision the slot card renders from — see the field docs above.
    // No `setState`: nothing in `build()` depends on these directly, only
    // the sheet invocation in `_tapRatingStar` reads them at tap time.
    _beanReviewDecision = resolution.reviewDecision;
    _beanReviewPromptService = resolution.promptService;
    return resolution.content;
  }

  /// Awaits the existing [coffeeFact] future, preserving its current
  /// data/error/pending semantics for the fact-card branch of the slot.
  /// Used only for the outer timeout/error fallback in [_resolveSlotContent]
  /// — the resolver has its own equivalent for the paths it owns.
  Future<FinishSlotContent> _resolveFactContent() async {
    try {
      final fact = await coffeeFact;
      return FinishSlotContent.fact(fact);
    } catch (e) {
      return FinishSlotContent.factError(e);
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

    // Same UI slot for promo / anniversary / in-sync / review nudge / coffee
    // fact. Priority is read from the shared [kFinishSlotCandidates]
    // registration table (plan 039 Phase A1) rather than hand-encoded here,
    // so a future synchronous candidate is a registration, not a rewrite of
    // this chain. Each higher tier REPLACES the default fact card so the
    // screen stays single-card (plan 021).
    //
    // Only the [FinishSlotCandidateId.resolvesSynchronously] candidates are
    // considered here — they render live from already-resolved screen state
    // the instant their flag flips, ahead of the FutureBuilder below, which
    // is exactly today's fast-path (STOP condition: this must never wait on
    // the async slot future — see plan 039, Phase A1 invariant).
    final Map<FinishSlotCandidateId, bool> syncEligibility = {
      FinishSlotCandidateId.promo: kIsWeb && _showPromoCard,
      FinishSlotCandidateId.anniversary: _showAnniversary,
      FinishSlotCandidateId.inSync: showInSync,
    };
    FinishSlotCandidateId? syncWinner;
    for (final candidate in kFinishSlotCandidates.where(
      (c) => c.resolvesSynchronously,
    )) {
      if (syncEligibility[candidate.id] == true) {
        syncWinner = candidate.id;
        break;
      }
    }

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
                    const SizedBox(height: AppSpacing.base),
                    _buildRatingRow(context),
                    const SizedBox(height: AppSpacing.base),
                    if (syncWinner == FinishSlotCandidateId.promo)
                      _buildNativeAppPromoCard(context)
                    else if (syncWinner == FinishSlotCandidateId.anniversary)
                      const AnniversaryCelebration(shouldShow: true)
                    else if (syncWinner == FinishSlotCandidateId.inSync)
                      _buildInSyncCard(context, _inSyncCount!, _inSyncCountries)
                    else
                      FutureBuilder<FinishSlotContent>(
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
                            case FinishSlotKind.reviewNudge:
                              return BeanReviewNudgeCard(
                                bean: content.bean!,
                                trigger: content.trigger!,
                                promptService: content.promptService!,
                                hasSharedImpressionRecorded: () =>
                                    hasBeanReviewImpressionRecorded,
                                onImpressionRecorded:
                                    _markBeanReviewImpressionRecorded,
                                budgetService: _budgetForWhatsNew,
                              );
                            case FinishSlotKind.whatsNew:
                              return WhatsNewCard(
                                popup: content.popup!,
                                locale: Localizations.localeOf(
                                  context,
                                ).languageCode,
                                budgetService: _budgetForWhatsNew!,
                                prefs: _prefsForWhatsNew!,
                              );
                            case FinishSlotKind.factError:
                              return Semantics(
                                identifier: 'coffeeFactCard',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.failedToLoadData,
                                ),
                              );
                            case FinishSlotKind.fact:
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
