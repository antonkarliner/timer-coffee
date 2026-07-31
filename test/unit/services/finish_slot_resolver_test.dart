import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/services/engagement_budget_service.dart';
import 'package:coffee_timer/services/finish_slot_resolver.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

// ---------------------------------------------------------------------------
// Characterization tests for FinishSlotResolver (plan 039, Phase A0.5).
//
// These pin TODAY's `_FinishScreenState._resolveSlotDecision` /
// `_resolveFactContent` behavior exactly, extracted verbatim so Phase A1's
// "pure refactor" claim is checkable: these tests must pass UNMODIFIED after
// A1 wires the slot through EngagementBudgetService (which ships in shadow
// mode, so the outcome for every input here must stay identical).
// ---------------------------------------------------------------------------

/// Stands in for [BeanReviewProvider] so tests never touch Supabase — mirrors
/// the fake used in bean_review_prompt_service_test.dart.
class _FakeBeanReviewProvider extends BeanReviewProvider {
  BeanReviewModel? review;

  @override
  Future<BeanReviewModel?> fetchUserReviewByBeanUuid(String beansUuid) async {
    return review;
  }
}

CoffeeBeansModel _makeBean({
  String uuid = 'bean-1',
  String name = 'Test Bean',
  bool isDeleted = false,
}) {
  return CoffeeBeansModel(
    beansUuid: uuid,
    roaster: 'Test Roaster',
    name: name,
    origin: 'Ethiopia',
    isDeleted: isDeleted,
    versionVector: VersionVector.initial('test').toString(),
  );
}

UserStatsModel _makeStat({required String uuid, DateTime? createdAt}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: 'recipe-1',
    coffeeAmount: 15.0,
    waterAmount: 250.0,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: 'method-1',
    createdAt: createdAt ?? DateTime.now(),
    isMarked: false,
    versionVector: VersionVector.initial('test').toString(),
    isDeleted: false,
  );
}

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakeBeanReviewProvider reviewProvider;
  late EngagementBudgetService budget;

  Future<void> seedBrews({
    required String beansUuid,
    required int count,
  }) async {
    for (var i = 0; i < count; i++) {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'stat-$beansUuid-$i',
          createdAt: DateTime.now().subtract(Duration(days: 10 - i)),
        ).copyWith(coffeeBeansUuid: beansUuid),
      );
    }
  }

  FinishSlotResolver buildResolver({bool signedIn = true}) {
    return FinishSlotResolver(
      database: db,
      reviewProvider: reviewProvider,
      prefs: prefs,
      budget: budget,
      isSignedIn: () => signedIn,
    );
  }

  // Convenience defaults matching the common "nothing special happening"
  // case: no delight tier won, all completion writes/moments already
  // resolved, no bean selected.
  Future<FinishSlotResolution> resolveWith(
    FinishSlotResolver resolver, {
    Future<bool>? updateBeanWeightFuture,
    Future<void>? insertBrewingDataFuture,
    Future<void>? anniversaryFuture,
    Future<void>? inSyncFuture,
    bool Function()? showAnniversary,
    bool Function()? inSyncWon,
    bool Function()? showPromoCard,
    Future<String>? coffeeFact,
    bool Function()? isMounted,
    Future<LaunchPopupModel?>? whatsNewPopupFuture,
    String? locale,
    bool Function(String?)? platformMatches,
  }) {
    return resolver.resolve(
      updateBeanWeightFuture: updateBeanWeightFuture ?? Future.value(false),
      insertBrewingDataFuture: insertBrewingDataFuture ?? Future.value(),
      anniversaryFuture: anniversaryFuture ?? Future.value(),
      inSyncFuture: inSyncFuture ?? Future.value(),
      showAnniversary: showAnniversary ?? () => false,
      inSyncWon: inSyncWon ?? () => false,
      showPromoCard: showPromoCard ?? () => false,
      coffeeFact: coffeeFact ?? Future.value('Fact text'),
      isMounted: isMounted ?? () => true,
      whatsNewPopupFuture: whatsNewPopupFuture,
      locale: locale ?? 'en',
      platformMatches: platformMatches ?? ((_) => true),
    );
  }

  LaunchPopupModel makePopup({
    int id = 100,
    String platform = 'all',
  }) {
    return LaunchPopupModel(
      id: id,
      content: 'Something new.',
      locale: 'en',
      createdAt: DateTime.utc(2026, 1, 1),
      platform: platform,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = openTestDatabase();
    reviewProvider = _FakeBeanReviewProvider();
    budget = EngagementBudgetService(prefs: prefs);
  });

  tearDown(() async {
    await db.close();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Yield-to-delight guard
  // ─────────────────────────────────────────────────────────────────────────

  group('yield-to-delight guard', () {
    test('anniversary won → falls back to fact, never evaluates review',
        () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      final resolution = await resolveWith(
        resolver,
        showAnniversary: () => true,
      );

      expect(resolution.content.kind, FinishSlotKind.fact);
      expect(resolution.content.factText, 'Fact text');
    });

    test('in-sync won → falls back to fact, never evaluates review',
        () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      final resolution = await resolveWith(resolver, inSyncWon: () => true);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('web promo won → falls back to fact, never evaluates review',
        () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      // The screen passes `() => kIsWeb && _showPromoCard` — the resolver
      // itself is platform-agnostic, so the caller-combined bool is what
      // matters here.
      final resolution = await resolveWith(resolver, showPromoCard: () => true);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test(
        'delight flags are read AFTER the completion futures settle, not '
        'captured eagerly at call time', () async {
      // Regression guard for the exact race the plan's invariant warns
      // about: if the caller captured `_showAnniversary` eagerly instead of
      // via a closure, this test would see `false` (the value at call time)
      // instead of `true` (the value once the anniversary future settles).
      var showAnniversaryFlag = false;
      final anniversaryCompleter = Completer<void>();

      final resolver = buildResolver();
      final future = resolveWith(
        resolver,
        anniversaryFuture: anniversaryCompleter.future,
        showAnniversary: () => showAnniversaryFlag,
      );

      // Simulate `_resolveAnniversary`: the flag flips before the completer
      // fires, exactly like the real screen's `setState` ordering.
      showAnniversaryFlag = true;
      anniversaryCompleter.complete();

      final resolution = await future;
      expect(resolution.content.kind, FinishSlotKind.fact);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Review-nudge eligible cases
  // ─────────────────────────────────────────────────────────────────────────

  group('review-nudge eligible', () {
    test('brew_count trigger at 5 brews → reviewNudge', () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      final resolution = await resolveWith(resolver);

      expect(resolution.content.kind, FinishSlotKind.reviewNudge);
      expect(resolution.content.trigger, 'brew_count');
      expect(resolution.content.bean?.beansUuid, 'bean-1');
      expect(resolution.content.promptService, isNotNull);
    });

    test('depletion trigger at 2 brews when this brew emptied the bag',
        () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 2);

      final resolver = buildResolver();
      final resolution = await resolveWith(
        resolver,
        updateBeanWeightFuture: Future.value(true), // depletedThisBrew
      );

      expect(resolution.content.kind, FinishSlotKind.reviewNudge);
      expect(resolution.content.trigger, 'depletion');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Not-eligible → fact
  // ─────────────────────────────────────────────────────────────────────────

  group('not eligible → fact', () {
    test('no bean attached → fact', () async {
      // No 'selectedBeanUuid' written to prefs.
      final resolver = buildResolver();
      final resolution = await resolveWith(resolver);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('bean attached but below brew-count threshold → fact', () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 4);

      final resolver = buildResolver();
      final resolution = await resolveWith(resolver);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('signed out → fact even with an otherwise-eligible bean', () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver(signedIn: false);
      final resolution = await resolveWith(resolver);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // isMounted guard
  // ─────────────────────────────────────────────────────────────────────────

  group('isMounted guard', () {
    test('unmounted after completion futures settle → fact, review never '
        'evaluated', () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      final resolution = await resolveWith(resolver, isMounted: () => false);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Deadline / error fallback to fact
  // ─────────────────────────────────────────────────────────────────────────

  group('deadline / error fallback to fact', () {
    test('coffeeFact future throwing → factError (not an uncaught exception)',
        () async {
      // `Future.delayed` (a macrotask) rather than `Future.error` (which
      // completes before resolve()'s internal microtask-only awaits can
      // attach a listener, and would be flagged as an unhandled async error
      // by the test zone) — this still exercises the same catch path inside
      // `_resolveFactContent`.
      final resolver = buildResolver();
      final resolution = await resolveWith(
        resolver,
        coffeeFact: Future<String>.delayed(
          Duration.zero,
          () => throw StateError('fact fetch failed'),
        ),
      );

      expect(resolution.content.kind, FinishSlotKind.factError);
      expect(resolution.content.error, isA<StateError>());
    });

    test(
        'caller-side timeout around a hung completion future falls back to '
        'fact, mirroring _resolveSlotContent\'s 4s deadline race', () async {
      // The 4s soft deadline itself stays on the screen (_resolveSlotContent
      // wraps `.timeout()` around this exact resolve() call) — this test
      // pins that the composition still works: a resolve() that never
      // settles, raced against an outer timeout, ends up on the fact card,
      // exactly like today.
      final hungBeanWeight = Completer<bool>(); // never completes

      final resolver = buildResolver();
      final resolveFuture = resolveWith(
        resolver,
        updateBeanWeightFuture: hungBeanWeight.future,
      );

      FinishSlotContent content;
      try {
        content =
            (await resolveFuture.timeout(const Duration(milliseconds: 50)))
                .content;
      } catch (_) {
        // Mirrors _resolveSlotContent's catch → _resolveFactContent().
        try {
          content = FinishSlotContent.fact(await Future.value('Fact text'));
        } catch (e) {
          content = FinishSlotContent.factError(e);
        }
      }

      expect(content.kind, FinishSlotKind.fact);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Budget is stored, not consulted (A0.5 scope)
  // ─────────────────────────────────────────────────────────────────────────

  group('budget dependency', () {
    test('budget is threaded through unchanged and never denies the slot in '
        'A0.5', () async {
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      expect(resolver.budget, same(budget));

      // Exhaust the shadow-mode budget cap for this surface/askId before
      // resolving — since A0.5 never consults the budget, the outcome must
      // be identical to the "budget has room" case.
      await budget.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'bean_review_nudge',
      );
      await budget.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'bean_review_nudge',
      );
      expect(
        budget.evaluate(
          surface: EngagementSurface.finishSlot,
          askId: 'bean_review_nudge',
        ),
        isNot(BudgetVerdict.allowed),
      );

      final resolution = await resolveWith(resolver);
      expect(resolution.content.kind, FinishSlotKind.reviewNudge,
          reason: 'A0.5 must not consult the budget at all — wiring it in '
              'is Phase A1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Whats-new candidate (plan 039, Item C, Phase C2) — new in this revision.
  // Registered below the review nudge per decision D3.
  // ─────────────────────────────────────────────────────────────────────────

  group('whats-new candidate', () {
    test('eligible popup, no bean attached → whatsNew', () async {
      // No 'selectedBeanUuid' → review nudge never eligible, so the
      // whats-new candidate is free to claim the slot.
      await prefs.setBool('launch_popup_first_session_done', true);
      final resolver = buildResolver();
      final popup = makePopup(id: 55);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.whatsNew);
      expect(resolution.content.popup?.id, 55);
    });

    test('review nudge eligible AND popup present → review nudge wins '
        '(decision D3: whats-new ranks below review nudge)', () async {
      await prefs.setBool('launch_popup_first_session_done', true);
      await prefs.setString('selectedBeanUuid', 'bean-1');
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final resolver = buildResolver();
      final popup = makePopup(id: 56);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.reviewNudge);
    });

    test('no popup offered this visit (whatsNewPopupFuture omitted) → fact',
        () async {
      final resolver = buildResolver();
      final resolution = await resolveWith(resolver);

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('popup future resolves to null → fact', () async {
      final resolver = buildResolver();
      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(null),
      );

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test(
        'launch_popup_first_session_done unset → fact even with an eligible '
        'popup (decision D8)', () async {
      // Default SharedPreferences.setMockInitialValues({}) in setUp leaves
      // this flag unset.
      final resolver = buildResolver();
      final popup = makePopup(id: 57);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('platform mismatch → fact even with an otherwise-eligible popup '
        '(decision D8, belt-and-braces)', () async {
      await prefs.setBool('launch_popup_first_session_done', true);
      final resolver = buildResolver();
      final popup = makePopup(id: 58, platform: 'android');

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
        platformMatches: (_) => false,
      );

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('already seen at finish (lastPopupIdSeenAtFinish_<locale> matches) '
        '→ fact', () async {
      await prefs.setBool('launch_popup_first_session_done', true);
      await prefs.setInt('lastPopupIdSeenAtFinish_en', 59);
      final resolver = buildResolver();
      final popup = makePopup(id: 59);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.fact);
    });

    test('a NEWER popup id than the finish seen-state still shows → '
        'whatsNew', () async {
      await prefs.setBool('launch_popup_first_session_done', true);
      await prefs.setInt('lastPopupIdSeenAtFinish_en', 59);
      final resolver = buildResolver();
      final popup = makePopup(id: 60);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.whatsNew);
    });

    test(
        'home popup seen-state (lastPopupId_<locale>) does NOT suppress the '
        'finish exposure — independent seen-state per surface', () async {
      await prefs.setBool('launch_popup_first_session_done', true);
      // Simulates a reflex-Close at home for this exact popup id.
      await prefs.setInt('lastPopupId_en', 61);
      final resolver = buildResolver();
      final popup = makePopup(id: 61);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.whatsNew,
          reason: 'a reflex-Close at home writes lastPopupId_en, never '
              'lastPopupIdSeenAtFinish_en — the two surfaces must not share '
              'a flag');
    });

    test(
        'the resolver itself never writes the finish seen-state key or '
        'records a budget entry — both are render-gated on the card', () async {
      await prefs.setBool('launch_popup_first_session_done', true);
      final resolver = buildResolver();
      final popup = makePopup(id: 62);

      final resolution = await resolveWith(
        resolver,
        whatsNewPopupFuture: Future.value(popup),
      );

      expect(resolution.content.kind, FinishSlotKind.whatsNew);
      expect(prefs.getInt('lastPopupIdSeenAtFinish_en'), isNull);
      expect(prefs.getString('engagement_budget_log'), isNull);
    });
  });
}
