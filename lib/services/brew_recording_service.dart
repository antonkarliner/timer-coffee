// lib/services/brew_recording_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../database/database.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/user_stat_provider.dart';
import '../utils/app_logger.dart';
import 'analytics_service.dart';

/// Signature shared by [LocalNotificationSchedulerService]'s
/// `maybeScheduleBeanReviewNudge`, `maybeScheduleRoasterContribNudgeOnBrew`,
/// and `maybeScheduleBeanReviewNudgeOnDepletion` — all three take the same
/// three named arguments and return `Future<void>`. Declared here (rather
/// than importing the scheduler service directly) so
/// [BrewRecordingService] takes the operations it needs as plain
/// function parameters — the cleanest testable seam, since
/// `LocalNotificationSchedulerService`'s constructor is private and the
/// real singleton can't be faked by subclassing from a test file.
typedef BeanReviewNudgeCall =
    Future<void> Function({
      required AppDatabase database,
      required String beansUuid,
      required String locale,
    });

/// Performs the `global_stats` insert for a resolved payload. Kept as an
/// injectable function (rather than a raw `SupabaseClient`) for the same
/// testability reason as [BeanReviewNudgeCall] — tests can substitute a
/// simple closure without standing up a real Supabase client.
typedef GlobalStatInsert = Future<void> Function(Map<String, dynamic> data);

/// Coordinates the two completion writes that must start after inherited
/// widgets are available, while still exposing stable futures to taste
/// saving and the finish-slot decision. Moved unchanged from
/// `finish_screen.dart` (plan 042, Item B, Phase B1) — same class name,
/// same semantics, including the `completeError` paths: `FinishScreen`'s
/// `_ratingRowReady` behaviour depends on errors propagating through
/// [insertFuture] exactly as before.
///
/// Not `@visibleForTesting`: `FinishScreen` holds one of these as production
/// state, so the annotation would be a lie that `flutter analyze` flags at
/// every production use site.
class BrewCompletionWriteGate {
  final Completer<void> _insertCompleter = Completer<void>();
  final Completer<bool> _beanWeightCompleter = Completer<bool>();
  bool _started = false;

  Future<void> get insertFuture => _insertCompleter.future;
  Future<bool> get beanWeightFuture => _beanWeightCompleter.future;

  void start({
    required Future<void> Function() insertBrew,
    required Future<bool> Function() updateBeanWeight,
  }) {
    if (_started) return;
    _started = true;
    unawaited(_completeInsert(insertBrew));
    unawaited(_completeBeanWeight(updateBeanWeight));
  }

  Future<void> _completeInsert(Future<void> Function() operation) async {
    try {
      await operation();
      _insertCompleter.complete();
    } catch (error, stackTrace) {
      _insertCompleter.completeError(error, stackTrace);
    }
  }

  Future<void> _completeBeanWeight(Future<bool> Function() operation) async {
    try {
      _beanWeightCompleter.complete(await operation());
    } catch (error, stackTrace) {
      _beanWeightCompleter.completeError(error, stackTrace);
    }
  }
}

/// Plain-data bundle for a single completed guided brew — everything the
/// three [BrewRecordingService] operations need, gathered once by
/// `FinishScreen`'s `BuildContext`-bound wrapper methods so the service
/// itself stays context-free (plan 042, Item B, Phase B1).
///
/// [localeCode] is `Locale.toLanguageTag()` (used for country-code
/// resolution); [languageCode] is `Locale.languageCode` (used for
/// notification scheduling, which resolves its own localizations from a
/// bare language code). [countryCode] must already be resolved by the
/// caller — [BrewRecordingService] never touches `RegionService` or
/// `Localizations` itself. [userId] must likewise already be resolved
/// (`Supabase.instance.client.auth.currentUser?.id`) — the service never
/// touches the Supabase auth singleton directly, again for testability.
class BrewRecordingRequest {
  final String statUuid;
  final String recipeId;
  final String brewingMethodId;
  final String brewingMethodName;
  final double coffeeAmount;
  final double waterAmount;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final String grindSize;
  final double? waterTemp;
  final String? coffeeBeansUuid;
  final String localeCode;
  final String languageCode;
  final int entrySource;
  final String? countryCode;
  final String? userId;

  const BrewRecordingRequest({
    required this.statUuid,
    required this.recipeId,
    required this.brewingMethodId,
    required this.brewingMethodName,
    required this.coffeeAmount,
    required this.waterAmount,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
    required this.grindSize,
    this.waterTemp,
    this.coffeeBeansUuid,
    required this.localeCode,
    required this.languageCode,
    required this.entrySource,
    this.countryCode,
    this.userId,
  });
}

/// Context-free brew-completion recording (plan 042, Item B, Phase B1).
/// Extracted unchanged in behaviour from `finish_screen.dart`'s
/// `insertBrewingDataToAppDatabase`, `insertBrewingDataToSupabase`, and
/// `_updateBeanWeightAfterBrew` — see that file's thin wrapper methods for
/// the `BuildContext`-bound plumbing (Provider lookups, `Localizations`,
/// `SharedPreferences`, `RegionService`) this service deliberately does not
/// do. Must not import `flutter/material.dart`, take a `BuildContext`, or
/// call `Provider.of` — everything it needs arrives as an explicit
/// parameter.
///
/// Adds one intentional behaviour beyond the extraction: idempotency on
/// [BrewRecordingRequest.statUuid]. [recordLocalBrew] inserts the
/// `user_stats` row, schedules the two brew-time nudges, and emits
/// `beans_attached` at most once per stat UUID — a repeat call for a UUID
/// already recorded returns immediately, doing none of that again.
/// [updateBeanWeight] is gated on the exact same "already recorded" check,
/// since it mutates a running total (the bean's package weight) and is the
/// one operation here that is not naturally idempotent — double-decrementing
/// a bag is the worst failure mode. Under today's call patterns nothing
/// calls either method twice for the same UUID, so this changes no observed
/// behaviour; it exists so plan 042 Phase B2's orphan recovery (recording a
/// brew from a killed-app recovery pass at next launch) can race a later
/// `FinishScreen` mount for the same brew without double-counting.
class BrewRecordingService {
  final Set<String> _recordedStatUuids = <String>{};

  /// Exposed for tests only — production code should never need to inspect
  /// this directly, only rely on the idempotent behaviour it drives.
  @visibleForTesting
  bool hasRecordedForTesting(String statUuid) =>
      _recordedStatUuids.contains(statUuid);

  /// Mirrors the former `insertBrewingDataToAppDatabase`: inserts the
  /// `user_stats` row via [userStatProvider], then — only when a bean is
  /// attached — emits `beans_attached` and schedules the bean-review and
  /// roaster-contribution nudges. Logs and rethrows on failure, exactly as
  /// before; `FinishScreen`'s `BrewCompletionWriteGate` depends on that
  /// rethrow to surface the failure to `insertFuture`.
  Future<void> recordLocalBrew({
    required BrewRecordingRequest request,
    required UserStatProvider userStatProvider,
    required AppDatabase database,
    required BeanReviewNudgeCall scheduleBeanReviewNudge,
    required BeanReviewNudgeCall scheduleRoasterContribNudge,
  }) async {
    if (_recordedStatUuids.contains(request.statUuid)) return;

    if (request.userId == null) {
      AppLogger.debug('No user signed in');
      return;
    }

    try {
      await userStatProvider.insertUserStat(
        recipeId: request.recipeId,
        coffeeAmount: request.coffeeAmount,
        waterAmount: request.waterAmount,
        sweetnessSliderPosition: request.sweetnessSliderPosition,
        strengthSliderPosition: request.strengthSliderPosition,
        brewingMethodId: request.brewingMethodId,
        statUuid: request.statUuid,
        coffeeBeansUuid: request.coffeeBeansUuid,
        grindSize: request.grindSize,
        waterTemp: request.waterTemp,
        entrySource: request.entrySource,
      );

      final coffeeBeansUuid = request.coffeeBeansUuid;
      if (coffeeBeansUuid != null && coffeeBeansUuid.isNotEmpty) {
        AnalyticsService.instance.track(
          'beans_attached',
          properties: {
            'recipe_id': request.recipeId,
            'brewing_method_id': request.brewingMethodId,
          },
        );
        unawaited(
          scheduleBeanReviewNudge(
            database: database,
            beansUuid: coffeeBeansUuid,
            locale: request.languageCode,
          ),
        );
        // Plan 011, Channel B: if this bean's roaster is a pending
        // candidate, schedule a one-shot "help add this roaster" nudge.
        unawaited(
          scheduleRoasterContribNudge(
            database: database,
            beansUuid: coffeeBeansUuid,
            locale: request.languageCode,
          ),
        );
      }
      AppLogger.debug(
        'Inserted new stat with UUID: ${request.statUuid} and Coffee Beans UUID: $coffeeBeansUuid',
      );
      _recordedStatUuids.add(request.statUuid);
    } catch (e) {
      AppLogger.error(
        "Error inserting brewing data to app database",
        errorObject: e,
      );
      rethrow;
    }
  }

  /// Mirrors the former `insertBrewingDataToSupabase`: inserts the
  /// `global_stats` row via [insertGlobalStat]. `request.countryCode` must
  /// already be resolved (the caller owns the `RegionService` lookup, which
  /// needs `Localizations`). Swallows timeouts and other errors exactly as
  /// before — this write was always best-effort and never rethrows.
  Future<void> recordRemoteBrew({
    required BrewRecordingRequest request,
    required GlobalStatInsert insertGlobalStat,
  }) async {
    final userId = request.userId;
    if (userId == null) return;

    final data = <String, dynamic>{
      'user_id': userId,
      'brewing_method': request.brewingMethodName,
      'recipe_id': request.recipeId,
      'water_amount': request.waterAmount,
    };
    final countryCode = request.countryCode;
    if (countryCode != null) data['country_code'] = countryCode;

    try {
      await insertGlobalStat(data).timeout(const Duration(seconds: 3));
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

  /// Mirrors the former `_updateBeanWeightAfterBrew`: decrements the
  /// attached bean's package weight via [coffeeBeansProvider] and, on
  /// depletion, schedules the depletion review nudge. Returns `true` only
  /// when this brew crossed the bag into "empty" — the depletion signal the
  /// finish-slot decision uses. Preserves every early-return path and its
  /// `bool` result exactly.
  ///
  /// Gated on the same "already recorded this statUuid" check
  /// [recordLocalBrew] populates — see the class doc for why this one
  /// operation needs the guard even though nothing calls it twice today.
  Future<bool> updateBeanWeight({
    required BrewRecordingRequest request,
    required CoffeeBeansProvider coffeeBeansProvider,
    required AppDatabase database,
    required BeanReviewNudgeCall scheduleBeanReviewNudgeOnDepletion,
  }) async {
    if (_recordedStatUuids.contains(request.statUuid)) return false;

    try {
      // Only proceed if we have a valid coffee amount
      if (request.coffeeAmount <= 0) {
        AppLogger.debug('No coffee amount to subtract from bean weight');
        return false;
      }

      final coffeeBeansUuid = request.coffeeBeansUuid;
      if (coffeeBeansUuid == null || coffeeBeansUuid.isEmpty) {
        AppLogger.debug('No selected bean UUID found in SharedPreferences');
        return false;
      }

      // Update the bean weight
      final newWeight = await coffeeBeansProvider.updateBeanWeightAfterBrew(
        coffeeBeansUuid,
        request.coffeeAmount,
      );

      if (newWeight != null) {
        AppLogger.debug('Successfully updated bean weight to ${newWeight}g');
        // Bag just emptied (weight crossed to ~0) — a high-intent moment to
        // ask for a review. updateBeanWeightAfterBrew returns null when the
        // bean was already empty, so this fires only on the crossing brew.
        if (newWeight < 0.1) {
          unawaited(
            scheduleBeanReviewNudgeOnDepletion(
              database: database,
              beansUuid: coffeeBeansUuid,
              locale: request.languageCode,
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
}
