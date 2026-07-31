import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import '../utils/app_logger.dart';

/// Result of [EngagementBudgetService.evaluate] — the pure, fully-live
/// verdict on whether an ask would be allowed under the shadow-mode budget
/// parameters. This is computed and unit-tested in full even though nothing
/// in Phase A0 enforces it (see [EngagementBudgetService.enforcementEnabled]).
enum BudgetVerdict {
  /// Under both the rolling-window cap and the minimum-spacing rule.
  allowed,

  /// Would exceed [EngagementBudgetService.maxAsksPerWindow] asks within
  /// [EngagementBudgetService.rollingWindow].
  deniedByCap,

  /// Would land within [EngagementBudgetService.minSpacing] of the most
  /// recent ask.
  deniedByMinSpacing,
}

/// The surfaces this service knows how to budget. Only **ask** surfaces are
/// ever passed here — delight (moments: anniversary, in-sync, first-brew)
/// and capture (the brew-evaluation star row) are never consulted against
/// this budget at all; there is no special-case branch for them here, they
/// simply never call in. See plan 039, "Ask vs. delight vs. capture".
abstract class EngagementSurface {
  static const String finishSlot = 'finish_slot';
  static const String notificationPermission = 'notification_permission';
  static const String nativeReviewPrompt = 'native_review_prompt';
  static const String homePopup = 'home_popup';
  static const String finishPopup = 'finish_popup';

  /// All valid surface values, for validation/debugging.
  static const Set<String> all = {
    finishSlot,
    notificationPermission,
    nativeReviewPrompt,
    homePopup,
    finishPopup,
  };
}

/// Reasons an ask can be denied, carried on the `engagement_ask_suppressed`
/// analytics event.
abstract class EngagementSuppressionReason {
  /// The rolling-window cap ([EngagementBudgetService.maxAsksPerWindow] /
  /// [EngagementBudgetService.rollingWindow]) was exceeded.
  static const String budgetCap = 'budget_cap';

  /// The minimum spacing ([EngagementBudgetService.minSpacing]) between two
  /// asks was violated.
  static const String minSpacing = 'min_spacing';

  /// A candidate lost the finish-screen slot to a higher-priority candidate.
  /// This is slot priority, not the budget, so it always carries
  /// `enforced: true` regardless of [EngagementBudgetService.enforcementEnabled].
  /// **Nothing in Phase A0 emits this reason** — it exists only as part of
  /// the event contract for a future phase (A2 and beyond) to use.
  static const String lostSlot = 'lost_slot';
}

/// Single place that answers "has this user seen enough asks recently,
/// and would this one be allowed given everything else going on" — without
/// rewriting any existing surface's own eligibility logic
/// ([BeanReviewPromptService](bean_review_prompt_service.dart), the launch
/// popup's own recency/session checks, etc. keep deciding *whether they
/// personally qualify*; this service decides *whether they're allowed to
/// render given everything else on the budget*).
///
/// See plan 039 ("Item A — EngagementBudgetService") for the full design.
/// This is Phase A0: the rolling log, the pure verdict, and both analytics
/// events are fully live; **enforcement is not** — see
/// [enforcementEnabled]. No UI is wired to this service yet.
///
/// **Ask vs. delight vs. capture**: only *ask* surfaces
/// ([EngagementSurface]) are ever passed to this service. Delight (moments)
/// and capture (the brew-evaluation star row) surfaces are simply never
/// passed in — there is no special-case branch here for them, callers just
/// don't call in for those surfaces.
///
/// **Data model**: a bounded JSON list of `{surface, askId, shownAtMs}`
/// stored under a single [SharedPreferences] key, pruned to a rolling
/// [pruneWindow] on every write. No Drift schema change — consistent with
/// [BeanReviewPromptService]'s and the notification scheduler's existing
/// prefs-based bookkeeping.
///
/// **Dedup rule**: a [EngagementSurface.homePopup] and a
/// [EngagementSurface.finishPopup] exposure that share the same `askId`
/// count as *one* ask toward the cap, and must not trip minimum spacing
/// against each other — see the dedup handling inside [evaluate].
class EngagementBudgetService {
  EngagementBudgetService({
    required SharedPreferences prefs,
    DateTime Function() now = DateTime.now,
  })  : _prefs = prefs,
        _now = now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const String _keyLog = 'engagement_budget_log';

  /// Entries older than this are dropped on every write. Independent of
  /// [rollingWindow] — this bounds the log's size, the window below bounds
  /// the cap's lookback.
  static const Duration pruneWindow = Duration(days: 30);

  /// Shadow parameters (decision D1) — real numbers to be set from the
  /// accumulated `engagement_ask_suppressed` data once enforcement ships.
  static const int maxAsksPerWindow = 2;
  static const Duration rollingWindow = Duration(days: 7);
  static const Duration minSpacing = Duration(hours: 48);

  /// **Must stay false in Phase A0.** Enforcement is an evidence-gated
  /// follow-up (see plan 039's post-ship checklist) — flipping this is
  /// explicitly out of scope here. While false, [allowAsk] always returns
  /// `true` regardless of [evaluate]'s verdict, but still emits
  /// `engagement_ask_suppressed { ..., enforced: false }` whenever the
  /// verdict was a denial, so the suppression trail accumulates before the
  /// commitment.
  static const bool enforcementEnabled = false;

  /// Pure verdict computation — no analytics emission, no log write. Fully
  /// live even though nothing in Phase A0 enforces it.
  ///
  /// Never throws: any prefs/JSON failure degrades to [BudgetVerdict.allowed]
  /// (fail open, matching [BeanReviewPromptService.evaluate]'s degrade-to-skip
  /// posture — here "skip the gate" means "allow").
  BudgetVerdict evaluate({
    required String surface,
    required String askId,
  }) {
    try {
      final nowMs = _now().millisecondsSinceEpoch;
      final deduped = _dedupedByKey(_readLog());
      final candidateKey = _dedupKeyFor(surface, askId);

      // Exclude the candidate's own dedup group: a home_popup exposure and
      // a later finish_popup exposure of the *same* askId are one ask, so
      // evaluating the second face must not trip spacing/cap against the
      // first face of itself. Entries belonging to any *other* ask (a
      // different askId, or a non-popup surface) are still fully counted.
      final others =
          deduped.entries.where((e) => e.key != candidateKey).map((e) => e.value);

      // Minimum spacing: any other counted ask must be at least minSpacing
      // away.
      for (final entry in others) {
        final delta = nowMs - entry.shownAtMs;
        if (delta >= 0 && delta < minSpacing.inMilliseconds) {
          return BudgetVerdict.deniedByMinSpacing;
        }
      }

      // Rolling-window cap: count other counted asks within rollingWindow.
      final windowStartMs = nowMs - rollingWindow.inMilliseconds;
      final countInWindow =
          others.where((e) => e.shownAtMs >= windowStartMs).length;
      if (countInWindow >= maxAsksPerWindow) {
        return BudgetVerdict.deniedByCap;
      }

      return BudgetVerdict.allowed;
    } catch (e) {
      AppLogger.error('Failed to evaluate engagement budget', errorObject: e);
      return BudgetVerdict.allowed;
    }
  }

  /// Public gate. Computes [evaluate]'s verdict; while [enforcementEnabled]
  /// is `false` this **always returns `true`** (allow), but still emits
  /// `engagement_ask_suppressed` whenever the verdict was a denial, with
  /// `enforced: false`.
  ///
  /// Never throws — degrades to allow on any failure.
  Future<bool> allowAsk({
    required String surface,
    required String askId,
  }) async {
    try {
      final verdict = evaluate(surface: surface, askId: askId);

      if (verdict != BudgetVerdict.allowed) {
        final reason = verdict == BudgetVerdict.deniedByCap
            ? EngagementSuppressionReason.budgetCap
            : EngagementSuppressionReason.minSpacing;
        AnalyticsService.maybeInstance?.track(
          'engagement_ask_suppressed',
          properties: {
            'surface': surface,
            'ask_id': askId,
            'reason': reason,
            'enforced': enforcementEnabled,
          },
        );
      }

      if (!enforcementEnabled) {
        return true;
      }

      return verdict == BudgetVerdict.allowed;
    } catch (e) {
      AppLogger.error('Failed to gate engagement ask', errorObject: e);
      return true;
    }
  }

  /// Appends a new log entry (pruning to [pruneWindow] on write) and emits
  /// `engagement_ask_shown {surface, ask_id}`. Callers are responsible for
  /// only calling this when the ask actually rendered (render-gated, like
  /// [BeanReviewPromptService.recordImpression]).
  ///
  /// Never throws — logs and no-ops on failure.
  Future<void> recordAsk({
    required String surface,
    required String askId,
  }) async {
    try {
      final nowMs = _now().millisecondsSinceEpoch;
      final entries = _readLog()
        ..add(_BudgetLogEntry(
          surface: surface,
          askId: askId,
          shownAtMs: nowMs,
        ));
      await _writeLog(_prune(entries, nowMs));

      AnalyticsService.maybeInstance?.track(
        'engagement_ask_shown',
        properties: {
          'surface': surface,
          'ask_id': askId,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to record engagement ask', errorObject: e);
    }
  }

  // ──────────────────── Log bookkeeping ────────────────────

  List<_BudgetLogEntry> _readLog() {
    final raw = _prefs.getString(_keyLog);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => _BudgetLogEntry.tryFromJson(m))
          .whereType<_BudgetLogEntry>()
          .toList();
    } catch (e) {
      AppLogger.error('Failed to decode engagement budget log',
          errorObject: e);
      return [];
    }
  }

  Future<void> _writeLog(List<_BudgetLogEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyLog, encoded);
  }

  List<_BudgetLogEntry> _prune(List<_BudgetLogEntry> entries, int nowMs) {
    final cutoffMs = nowMs - pruneWindow.inMilliseconds;
    return entries.where((e) => e.shownAtMs >= cutoffMs).toList();
  }

  /// Collapses a home/finish-popup pair sharing the same [askId] into a
  /// single entry (keeping the earliest `shownAtMs` of the pair), so it
  /// counts once toward the cap. Every other surface dedups only against
  /// itself (i.e. never collapses with a different log entry), since its key
  /// is unique per write.
  Map<String, _BudgetLogEntry> _dedupedByKey(List<_BudgetLogEntry> raw) {
    final byKey = <String, _BudgetLogEntry>{};
    for (final entry in raw) {
      if (!EngagementSurface.all.contains(entry.surface)) continue;
      final key = _dedupKeyFor(entry.surface, entry.askId, entry.shownAtMs);
      final existing = byKey[key];
      if (existing == null || entry.shownAtMs < existing.shownAtMs) {
        byKey[key] = entry;
      }
    }
    return byKey;
  }

  /// A popup surface ([EngagementSurface.homePopup] /
  /// [EngagementSurface.finishPopup]) shares a dedup key with its sibling
  /// surface when the askId matches; every other surface's key is
  /// disambiguated by [uniqueSalt] (the entry's own timestamp when reading
  /// the log, or omitted — i.e. always unique — when identifying a fresh
  /// candidate ask in [evaluate]) so non-popup entries never collapse with
  /// one another.
  String _dedupKeyFor(String surface, String askId, [int? uniqueSalt]) {
    if (surface == EngagementSurface.homePopup ||
        surface == EngagementSurface.finishPopup) {
      return 'popup:$askId';
    }
    return uniqueSalt == null
        ? 'candidate:$surface:$askId'
        : '$surface:$askId:$uniqueSalt';
  }
}

class _BudgetLogEntry {
  final String surface;
  final String askId;
  final int shownAtMs;

  const _BudgetLogEntry({
    required this.surface,
    required this.askId,
    required this.shownAtMs,
  });

  Map<String, dynamic> toJson() => {
        'surface': surface,
        'askId': askId,
        'shownAtMs': shownAtMs,
      };

  static _BudgetLogEntry? tryFromJson(Map raw) {
    final surface = raw['surface'];
    final askId = raw['askId'];
    final shownAtMs = raw['shownAtMs'];
    if (surface is! String || askId is! String || shownAtMs is! int) {
      return null;
    }
    return _BudgetLogEntry(surface: surface, askId: askId, shownAtMs: shownAtMs);
  }
}
