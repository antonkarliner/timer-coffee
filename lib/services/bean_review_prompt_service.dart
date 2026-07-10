import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Result of [BeanReviewPromptService.evaluate]. `show == false` means the
/// finish screen should fall back to its existing coffee-fact card; the
/// caller must not read [trigger] / [bean] in that case.
class BeanReviewPromptDecision {
  final bool show;
  final String? trigger; // 'brew_count' | 'depletion'
  final CoffeeBeansModel? bean;

  const BeanReviewPromptDecision({
    required this.show,
    this.trigger,
    this.bean,
  });

  const BeanReviewPromptDecision.skip()
      : show = false,
        trigger = null,
        bean = null;
}

/// Pure, injectable eligibility + frequency-capping logic for the finish-
/// screen bean-review nudge card (plan 021). Kept separate from
/// [LocalNotificationSchedulerService] (1,283 LOC, notification-bound) so the
/// decision and its caps are unit-testable without widget/notification
/// scaffolding.
///
/// All capping state lives in [SharedPreferences] — no Drift schema change.
class BeanReviewPromptService {
  BeanReviewPromptService({
    DateTime Function() now = DateTime.now,
    required SharedPreferences prefs,
    bool Function() isSignedIn = _defaultIsSignedIn,
  })  : _now = now,
        _prefs = prefs,
        _isSignedIn = isSignedIn;

  final DateTime Function() _now;
  final SharedPreferences _prefs;
  final bool Function() _isSignedIn;

  static bool _defaultIsSignedIn() =>
      Supabase.instance.client.auth.currentUser != null;

  // Brew-count threshold mirrors
  // LocalNotificationSchedulerService._beanReviewMinBrews
  // (lib/services/local_notification_scheduler_service.dart ~line 560) — keep
  // both in sync.
  static const int minBrews = 5;

  // Mirrors LocalNotificationSchedulerService._beanReviewDepletionMinBrews
  // (~line 564) — keep both in sync.
  static const int depletionMinBrews = 2;

  static const int maxImpressionsPerBean = 3;
  static const Duration globalCooldown = Duration(days: 3);

  static const String _keyGlobalLastShownMs = 'review_card_last_shown_ms';

  static String _impressionsKey(String beansUuid) =>
      'review_card_imp_$beansUuid';

  /// Decides whether the review nudge card should be shown for the brew that
  /// just completed. Checks run cheapest-first so the common ineligible case
  /// (no bean attached, signed out, cap already hit) never touches the DB or
  /// network:
  /// 1. `beansUuid` present.
  /// 2. Signed in (the review lookup can't answer otherwise).
  /// 3. Per-bean impression cap (applies to every trigger).
  /// 4. Bean exists locally and is not soft-deleted.
  /// 5. Brew count → trigger resolution (`depletion` if this brew emptied the
  ///    bag and brew count >= [depletionMinBrews]; else `brew_count` if brew
  ///    count >= [minBrews]; else skip).
  /// 6. Global 3-day cooldown — `brew_count` only; `depletion` bypasses it
  ///    (strongest intent signal, and it is inherently once-per-bag) but
  ///    still respects the per-bean cap from step 3.
  /// 7. No existing review by this user for this bean (the only
  ///    network-capable step; already timeout-guarded inside
  ///    [BeanReviewProvider.fetchUserReviewByBeanUuid]).
  ///
  /// Never throws — any failure is logged and resolves to a skip decision so
  /// the finish screen can always fall back to the coffee fact.
  Future<BeanReviewPromptDecision> evaluate({
    required AppDatabase database,
    required BeanReviewProvider reviewProvider,
    required String? beansUuid,
    required bool depletedThisBrew,
  }) async {
    try {
      if (beansUuid == null || beansUuid.isEmpty) {
        return const BeanReviewPromptDecision.skip();
      }

      if (!_isSignedIn()) {
        return const BeanReviewPromptDecision.skip();
      }

      final impressions = _prefs.getInt(_impressionsKey(beansUuid)) ?? 0;
      if (impressions >= maxImpressionsPerBean) {
        return const BeanReviewPromptDecision.skip();
      }

      final bean =
          await CoffeeBeansDao(database).fetchCoffeeBeansByUuid(beansUuid);
      if (bean == null || bean.isDeleted) {
        return const BeanReviewPromptDecision.skip();
      }

      final stats =
          await UserStatsDao(database).fetchStatsByBeanUuid(beansUuid);
      final brewCount = stats.length;

      String? trigger;
      if (depletedThisBrew && brewCount >= depletionMinBrews) {
        trigger = 'depletion';
      } else if (brewCount >= minBrews) {
        trigger = 'brew_count';
      }
      if (trigger == null) {
        return const BeanReviewPromptDecision.skip();
      }

      if (trigger == 'brew_count') {
        final lastShownMs = _prefs.getInt(_keyGlobalLastShownMs) ?? 0;
        if (lastShownMs > 0) {
          final elapsed = _now().difference(
              DateTime.fromMillisecondsSinceEpoch(lastShownMs));
          if (elapsed < globalCooldown) {
            return const BeanReviewPromptDecision.skip();
          }
        }
      }

      final existingReview =
          await reviewProvider.fetchUserReviewByBeanUuid(beansUuid);
      if (existingReview != null) {
        return const BeanReviewPromptDecision.skip();
      }

      return BeanReviewPromptDecision(show: true, trigger: trigger, bean: bean);
    } catch (e) {
      AppLogger.error('Failed to evaluate bean review prompt', errorObject: e);
      return const BeanReviewPromptDecision.skip();
    }
  }

  /// Bumps the per-bean impression counter and the global last-shown
  /// timestamp. Called by the card widget on its first frame — render-gated,
  /// so evaluating eligible but losing the slot to a higher-priority card
  /// never burns an impression or starts the cooldown. Does not emit
  /// analytics; the widget emits `review_nudge_card_shown` itself, using the
  /// returned count as the event's `impression_count` property.
  ///
  /// Returns the NEW per-bean impression count after the increment (i.e. 1
  /// on the first call for a given bean, 2 on the second, ...).
  Future<int> recordImpression(String beansUuid) async {
    final key = _impressionsKey(beansUuid);
    final current = _prefs.getInt(key) ?? 0;
    final updated = current + 1;
    await _prefs.setInt(key, updated);
    await _prefs.setInt(_keyGlobalLastShownMs, _now().millisecondsSinceEpoch);
    return updated;
  }
}
