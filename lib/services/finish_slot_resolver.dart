// lib/services/finish_slot_resolver.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/services/bean_review_prompt_service.dart';
import 'package:coffee_timer/services/engagement_budget_service.dart';

/// The [EngagementBudgetService] ask id for the bean-review nudge candidate
/// — shared between [FinishSlotResolver] (which gates on it via `allowAsk`)
/// and `BeanReviewNudgeCard` (which must `recordAsk` under the exact same
/// id once it actually paints, plan 039 triage item 1, or the gate and the
/// log disagree).
const String kBeanReviewNudgeAskId = 'bean_review_nudge';

/// What the single finish-screen card slot ultimately renders once the slot
/// decision settles: the bean-review nudge card, the what's-new popup card
/// (plan 039 Phase C2), the coffee fact, or the coffee fact's error state
/// (mirrors the previous plain `FutureBuilder<String>` semantics — see
/// plan 021, "Finish-screen wiring").
///
/// Moved out of `finish_screen.dart` (was private `_FinishSlotKind`) in
/// plan 039 Phase A0.5, so the slot decision can be unit-tested without
/// mounting the screen.
enum FinishSlotKind { reviewNudge, whatsNew, fact, factError }

/// See [FinishSlotKind]. Moved out of `finish_screen.dart` (was private
/// `_FinishSlotContent`) in plan 039 Phase A0.5.
class FinishSlotContent {
  final FinishSlotKind kind;
  final CoffeeBeansModel? bean;
  final String? trigger;
  final BeanReviewPromptService? promptService;
  final LaunchPopupModel? popup;
  final String? factText;
  final Object? error;

  const FinishSlotContent._({
    required this.kind,
    this.bean,
    this.trigger,
    this.promptService,
    this.popup,
    this.factText,
    this.error,
  });

  factory FinishSlotContent.reviewNudge({
    required CoffeeBeansModel bean,
    required String trigger,
    required BeanReviewPromptService promptService,
  }) => FinishSlotContent._(
    kind: FinishSlotKind.reviewNudge,
    bean: bean,
    trigger: trigger,
    promptService: promptService,
  );

  factory FinishSlotContent.whatsNew({required LaunchPopupModel popup}) =>
      FinishSlotContent._(kind: FinishSlotKind.whatsNew, popup: popup);

  factory FinishSlotContent.fact(String text) =>
      FinishSlotContent._(kind: FinishSlotKind.fact, factText: text);

  factory FinishSlotContent.factError(Object error) =>
      FinishSlotContent._(kind: FinishSlotKind.factError, error: error);
}

/// Everything a caller needs from a single [FinishSlotResolver.resolve]
/// call, returned as an immutable value rather than surfaced through
/// mutable `last*` fields on the resolver (plan 039 triage item 4 — the
/// `last*` fields made a previously stateless resolver stateful; restoring
/// statelessness while the code is fresh).
///
/// [reviewDecision] and [promptService] are the plan 039 Phase B2 "shared
/// decision" — set together whenever [BeanReviewPromptService.evaluate] was
/// actually reached during this [resolve] call (regardless of which
/// candidate ultimately won the slot: the review nudge itself, a
/// budget-denied review nudge falling through to whats-new/fact, etc.), and
/// both stay `null` when a higher-priority delight candidate claimed the
/// slot before `evaluate()` was ever called. Callers (`finish_screen.dart`)
/// hoist these into screen state right after awaiting [resolve] so both the
/// slot card and the eval sheet's "Rate the beans" step read the exact same
/// decision instead of each calling `evaluate()` themselves, which would
/// double-count against the per-bean impression cap.
///
/// [depletedThisBrew] is always populated once [resolve] starts (it comes
/// from the very first awaited future), regardless of which branch the
/// resolution ends up taking.
class FinishSlotResolution {
  final FinishSlotContent content;
  final BeanReviewPromptDecision? reviewDecision;
  final bool depletedThisBrew;
  final BeanReviewPromptService? promptService;

  const FinishSlotResolution({
    required this.content,
    this.reviewDecision,
    required this.depletedThisBrew,
    this.promptService,
  });
}

/// The candidates that can claim the finish-screen slot, plus the two
/// properties [FinishSlotResolver] and `finish_screen.dart`'s `build()` both
/// need to arbitrate between them. See [kFinishSlotCandidates].
enum FinishSlotCandidateId {
  /// Web-only "get the native app" promo card.
  promo,

  /// The once-a-year anniversary moment.
  anniversary,

  /// The "brewing in sync with the world" moment.
  inSync,

  /// The bean-review nudge card (plan 021) — the first-registered **ask**
  /// candidate.
  reviewNudge,

  /// The finish-screen duplicate of the home-screen launch popup (plan 039
  /// Item C, Phase C2) — the second **ask** candidate, ranked below
  /// [reviewNudge] per decision D3: bean-review eligibility is perishable
  /// (tied to a bag that gets consumed, expiring against a per-bean
  /// impression cap), whereas popup content persists across sessions and
  /// already has an independent home-screen surface.
  whatsNew,

  /// Terminal fallback: the coffee-fact card (or its error state).
  fact,
}

/// A single registered finish-slot candidate.
///
/// [resolvesSynchronously] is the property that preserves the delight
/// fast-path (see the class doc on [FinishSlotResolver]): `true` for
/// candidates that render live from already-resolved screen state the
/// instant their flag flips (delight tiers — promo, anniversary, in-sync);
/// `false` for candidates only known once [FinishSlotResolver.resolve]'s
/// internal awaits settle (the ask tier and the terminal fact fallback).
///
/// [isAsk] marks candidates that want something *from* the user and are
/// therefore consulted through [EngagementBudgetService.allowAsk] before
/// they may claim the slot — see plan 039, "Ask vs. delight vs. capture".
/// Delight and fact candidates are never consulted against the budget at
/// all; there is no special-case branch for them, they simply aren't
/// [isAsk].
class FinishSlotCandidateRegistration {
  final FinishSlotCandidateId id;
  final bool resolvesSynchronously;
  final bool isAsk;

  const FinishSlotCandidateRegistration({
    required this.id,
    required this.resolvesSynchronously,
    this.isAsk = false,
  });
}

/// Priority-ordered registration table for the finish-screen slot (plan 039
/// Phase A1), highest priority first: promo > anniversary > in-sync >
/// bean-review nudge > whats-new (plan 039 Item C, Phase C2) > coffee fact.
///
/// This replaces what used to be the same priority encoded twice — once as
/// the live `if/else` chain in `finish_screen.dart`'s `build()`, once
/// implicitly in [FinishSlotResolver.resolve]'s own checks — with a single
/// ordered source both consult. Adding a future candidate (the whats-new
/// card, a later Support Moments card) means appending a
/// [FinishSlotCandidateRegistration] here at the right priority slot, not
/// editing two call sites.
///
/// `build()` iterates the [FinishSlotCandidateRegistration.resolvesSynchronously]
/// subset directly (its own eligibility checks and card widgets stay in the
/// widget, since they read `BuildContext`-bound state this file must not
/// touch); [FinishSlotResolver.resolve] below consults the rest.
const List<FinishSlotCandidateRegistration> kFinishSlotCandidates = [
  FinishSlotCandidateRegistration(
    id: FinishSlotCandidateId.promo,
    resolvesSynchronously: true,
  ),
  FinishSlotCandidateRegistration(
    id: FinishSlotCandidateId.anniversary,
    resolvesSynchronously: true,
  ),
  FinishSlotCandidateRegistration(
    id: FinishSlotCandidateId.inSync,
    resolvesSynchronously: true,
  ),
  FinishSlotCandidateRegistration(
    id: FinishSlotCandidateId.reviewNudge,
    resolvesSynchronously: false,
    isAsk: true,
  ),
  FinishSlotCandidateRegistration(
    id: FinishSlotCandidateId.whatsNew,
    resolvesSynchronously: false,
    isAsk: true,
  ),
  FinishSlotCandidateRegistration(
    id: FinishSlotCandidateId.fact,
    resolvesSynchronously: false,
  ),
];

/// Context-free resolver for the finish-screen single-card slot decision.
///
/// Extracted from `_FinishScreenState._resolveSlotDecision` /
/// `_resolveFactContent` (plan 039 Phase A0.5) so the priority logic —
/// previously encoded a second time as a live `if/else` chain in
/// `finish_screen.dart`'s `build()` — is unit-testable without mounting the
/// widget (which reaches Supabase, `AdvancedInAppReview`,
/// `NotificationService`, and six providers via `BuildContext`).
///
/// As of Phase A1, the priority order below is read from
/// [kFinishSlotCandidates] rather than hand-encoded, and the review-nudge
/// (ask) candidate is consulted through [EngagementBudgetService.allowAsk]
/// before it may claim the slot. Because the budget ships in shadow mode
/// ([EngagementBudgetService.enforcementEnabled] is `false`), `allowAsk`
/// always returns `true`, so this remains a **pure refactor**: the outcome
/// for every input is identical to Phase A0.5's. See [budget].
///
/// Callers are responsible for:
/// - Resolving [database], [reviewProvider], [prefs], and [budget] from
///   `BuildContext`/`Provider` *before* constructing this class (this class
///   never touches `BuildContext` or `Provider` itself).
/// - Awaiting nothing before calling [resolve] — it does its own internal
///   awaiting of the futures/completers passed to it, in the same order and
///   with the same yield-to-delight timing as the original
///   `_resolveSlotDecision`.
/// - Applying the 4s soft deadline (`.timeout(...)`) around [resolve] and
///   falling back to a fact card on timeout/error — that composition stays
///   on the screen (`_resolveSlotContent`), since it is a thin wrapper with
///   no state of its own and doesn't need extracting.
class FinishSlotResolver {
  FinishSlotResolver({
    required AppDatabase database,
    required BeanReviewProvider reviewProvider,
    required SharedPreferences prefs,
    required EngagementBudgetService budget,
    DateTime Function() now = DateTime.now,
    bool Function() isSignedIn = _defaultIsSignedIn,
  }) : _database = database,
       _reviewProvider = reviewProvider,
       _prefs = prefs,
       _budget = budget,
       _now = now,
       _isSignedIn = isSignedIn;

  final AppDatabase _database;
  final BeanReviewProvider _reviewProvider;
  final SharedPreferences _prefs;
  final EngagementBudgetService _budget;
  final DateTime Function() _now;
  final bool Function() _isSignedIn;

  static bool _defaultIsSignedIn() =>
      Supabase.instance.client.auth.currentUser != null;

  static bool _alwaysMounted() => true;

  /// Default platform gate for the whats-new candidate — reuses the same
  /// normalization as `launch_popup.dart`'s `_platformMatches` (plan 039,
  /// decision D8: "platform-gate; belt-and-braces, the cached model is
  /// already server-filtered"). Injectable so tests can simulate a
  /// different runtime platform without mocking `defaultTargetPlatform`.
  static bool _defaultPlatformMatches(String? platform) {
    if (platform == null) return true;
    final normalized = platform.trim().toLowerCase();
    if (normalized == 'all') return true;

    if (kIsWeb) {
      return normalized == 'web';
    } else {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return normalized == 'ios';
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return normalized == 'android';
      }
      return false;
    }
  }

  /// Consulted (via [EngagementBudgetService.allowAsk]) for the
  /// [FinishSlotCandidateId.reviewNudge] candidate below. Ships in shadow
  /// mode (see plan 039, decision D1) so it always allows regardless of
  /// [EngagementBudgetService.evaluate]'s verdict — exposed publicly for
  /// tests that want to assert it was threaded through correctly.
  @visibleForTesting
  EngagementBudgetService get budget => _budget;

  /// Resolves the single finish-screen card slot.
  ///
  /// Reproduces `_FinishScreenState._resolveSlotDecision` exactly:
  /// 1. Awaits [updateBeanWeightFuture] (capturing `depletedThisBrew`),
  ///    then [insertBrewingDataFuture], then [anniversaryFuture], then
  ///    [inSyncFuture] — in that order, sequentially, matching the original.
  /// 2. If the caller is no longer interested ([isMounted] returns false),
  ///    falls back to the fact card.
  /// 3. Yield-to-delight guard: if [showAnniversary], [inSyncWon], or
  ///    [showPromoCard] (the caller should pass `kIsWeb && _showPromoCard`
  ///    for the last one) is true, a higher-priority card has already
  ///    claimed the slot — falls back to the fact card, exactly as today
  ///    ("Decide once, no card-swapping", plan 021).
  /// 4. Otherwise runs [BeanReviewPromptService.evaluate] and returns the
  ///    review-nudge content if eligible, else the fact card.
  ///
  /// [showAnniversary], [inSyncWon], and [showPromoCard] are callbacks
  /// (rather than plain booleans) so they are read *after* the internal
  /// awaits above settle — matching the original's timing, where these
  /// flags are only guaranteed stable once the corresponding completers
  /// fire. Passing plain booleans captured at call time would read them too
  /// early and reintroduce the exact race the completers exist to prevent.
  ///
  /// Returns a [FinishSlotResolution] rather than mutating `last*` fields on
  /// this resolver (plan 039 triage item 4) — the resolver stays stateless
  /// across calls; every piece of information a caller needs comes back on
  /// the returned value.
  Future<FinishSlotResolution> resolve({
    required Future<bool> updateBeanWeightFuture,
    required Future<void> insertBrewingDataFuture,
    required Future<void> anniversaryFuture,
    required Future<void> inSyncFuture,
    required bool Function() showAnniversary,
    required bool Function() inSyncWon,
    required bool Function() showPromoCard,
    required Future<String> coffeeFact,
    bool Function() isMounted = _alwaysMounted,
    // Plan 039, Phase C2 — the whats-new candidate. Null (the default)
    // means the caller isn't offering a popup this visit at all (e.g. no
    // cached popup, or `launch_popup_first_session_done` not yet honoured
    // by the caller — though the caller is expected to gate that upstream
    // too); the candidate is then skipped entirely, exactly as it was before
    // this candidate existed. Existing callers (and every pre-C2 test) that
    // omit this parameter get identical behavior to before C2.
    Future<LaunchPopupModel?>? whatsNewPopupFuture,
    String locale = 'en',
    bool Function(String?) platformMatches = _defaultPlatformMatches,
  }) async {
    final depletedThisBrew = await updateBeanWeightFuture;
    await insertBrewingDataFuture;
    await anniversaryFuture;
    await inSyncFuture;
    if (!isMounted()) {
      return FinishSlotResolution(
        content: await _resolveFactContent(coffeeFact),
        depletedThisBrew: depletedThisBrew,
      );
    }

    // A higher-priority (delight) candidate already claimed the slot for
    // this brew — the review card is simply not shown (no deferral, no
    // consumed impression; see plan "Losing the slot"). Read from the
    // registration table rather than hand-encoding the three flags, so a
    // future synchronous candidate only needs registering, not a new `||`
    // clause here.
    final delightWon = kFinishSlotCandidates
        .where((c) => c.resolvesSynchronously)
        .any((c) {
          switch (c.id) {
            case FinishSlotCandidateId.promo:
              return showPromoCard();
            case FinishSlotCandidateId.anniversary:
              return showAnniversary();
            case FinishSlotCandidateId.inSync:
              return inSyncWon();
            case FinishSlotCandidateId.reviewNudge:
            case FinishSlotCandidateId.whatsNew:
            case FinishSlotCandidateId.fact:
              return false;
          }
        });
    if (delightWon) {
      return FinishSlotResolution(
        content: await _resolveFactContent(coffeeFact),
        depletedThisBrew: depletedThisBrew,
      );
    }

    final beansUuid = _prefs.getString('selectedBeanUuid');
    final promptService = BeanReviewPromptService(
      prefs: _prefs,
      now: _now,
      isSignedIn: _isSignedIn,
    );

    final decision = await promptService.evaluate(
      database: _database,
      reviewProvider: _reviewProvider,
      beansUuid: beansUuid,
      depletedThisBrew: depletedThisBrew,
    );

    if (decision.show && decision.bean != null && decision.trigger != null) {
      // The review-nudge candidate is the one registered [isAsk] candidate
      // today — consult the budget gate before letting it claim the slot.
      // Shadow mode (enforcementEnabled == false) means this always allows,
      // so the outcome is unchanged from Phase A0.5 for every input; a real
      // denial here would only become possible once enforcement ships.
      final allowed = await _budget.allowAsk(
        surface: EngagementSurface.finishSlot,
        askId: kBeanReviewNudgeAskId,
      );
      if (allowed) {
        return FinishSlotResolution(
          content: FinishSlotContent.reviewNudge(
            bean: decision.bean!,
            trigger: decision.trigger!,
            promptService: promptService,
          ),
          reviewDecision: decision,
          depletedThisBrew: depletedThisBrew,
          promptService: promptService,
        );
      }
    }

    final whatsNewContent = await _resolveWhatsNew(
      whatsNewPopupFuture: whatsNewPopupFuture,
      locale: locale,
      platformMatches: platformMatches,
    );
    if (whatsNewContent != null) {
      return FinishSlotResolution(
        content: whatsNewContent,
        reviewDecision: decision,
        depletedThisBrew: depletedThisBrew,
        promptService: promptService,
      );
    }

    return FinishSlotResolution(
      content: await _resolveFactContent(coffeeFact),
      reviewDecision: decision,
      depletedThisBrew: depletedThisBrew,
      promptService: promptService,
    );
  }

  /// Resolves the [FinishSlotCandidateId.whatsNew] candidate (plan 039
  /// Phase C2), ranked below the review nudge per decision D3. Returns
  /// `null` whenever the candidate doesn't win the slot, so the caller falls
  /// through to the terminal fact card — never throws.
  ///
  /// Honours decision D8's gates:
  /// - [whatsNewPopupFuture] being `null` opts the candidate out entirely
  ///   (no popup offered this visit).
  /// - `launch_popup_first_session_done` (mirrors the home popup's gate —
  ///   not replicating the legacy `lastPopupDate_<locale>` migration, which
  ///   is home-only).
  /// - [platformMatches] (belt-and-braces; the cached model is already
  ///   server-filtered).
  /// - The independent finish-only seen-state key
  ///   (`lastPopupIdSeenAtFinish_<locale>`) — separate from the home popup's
  ///   `lastPopupId_<locale>` so a reflex-Close at home never suppresses
  ///   this exposure.
  ///
  /// Finally consults [EngagementBudgetService.allowAsk] under
  /// [EngagementSurface.finishPopup] with the popup id as the ask id — the
  /// same ask id the home popup records under [EngagementSurface.homePopup],
  /// so the two surfaces dedup against each other per
  /// [EngagementBudgetService]'s pairing rule. Shadow mode means this always
  /// allows today, same as the review-nudge candidate above.
  ///
  /// Does NOT write the seen-state key or record the budget ask itself —
  /// those are render-gated, owned by `WhatsNewCard`'s own first frame
  /// (mirrors `BeanReviewNudgeCard`'s impression bookkeeping), so a
  /// candidate that wins here but never actually gets painted (e.g. the
  /// screen is disposed before the `FutureBuilder` renders it) doesn't burn
  /// an impression.
  Future<FinishSlotContent?> _resolveWhatsNew({
    required Future<LaunchPopupModel?>? whatsNewPopupFuture,
    required String locale,
    required bool Function(String?) platformMatches,
  }) async {
    if (whatsNewPopupFuture == null) return null;

    final hasCompletedFirstSession =
        _prefs.getBool('launch_popup_first_session_done') ?? false;
    if (!hasCompletedFirstSession) return null;

    final popup = await whatsNewPopupFuture;
    if (popup == null) return null;
    if (!platformMatches(popup.platform)) return null;

    final seenId = _prefs.getInt('lastPopupIdSeenAtFinish_$locale');
    if (seenId != null && seenId == popup.id) return null;

    final allowed = await _budget.allowAsk(
      surface: EngagementSurface.finishPopup,
      askId: popup.id.toString(),
    );
    if (!allowed) return null;

    return FinishSlotContent.whatsNew(popup: popup);
  }

  /// Awaits [coffeeFact], preserving its current data/error/pending
  /// semantics for the fact-card branch of the slot.
  Future<FinishSlotContent> _resolveFactContent(Future<String> coffeeFact) async {
    try {
      final fact = await coffeeFact;
      return FinishSlotContent.fact(fact);
    } catch (e) {
      return FinishSlotContent.factError(e);
    }
  }
}
