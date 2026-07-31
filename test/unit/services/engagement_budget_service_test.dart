import 'dart:convert';

import 'package:coffee_timer/services/engagement_budget_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
//
// Every test drives an injected clock (`_Clock`) — no `DateTime.now()`
// appears anywhere below, matching the pattern established in
// bean_review_prompt_service_test.dart.

/// A mutable, injectable clock so tests can move time forward deterministically
/// without ever calling DateTime.now().
class _Clock {
  _Clock(this._current);
  DateTime _current;

  DateTime call() => _current;

  void advance(Duration d) => _current = _current.add(d);
  void set(DateTime t) => _current = t;
}

void main() {
  late SharedPreferences prefs;
  late _Clock clock;

  EngagementBudgetService buildService() {
    return EngagementBudgetService(prefs: prefs, now: clock.call);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    clock = _Clock(DateTime(2026, 1, 1, 12));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Shadow-mode contract (the single most important test in this file)
  // ─────────────────────────────────────────────────────────────────────────

  group('shadow mode', () {
    test('enforcementEnabled stays false', () {
      expect(EngagementBudgetService.enforcementEnabled, isFalse);
    });

    test('allowAsk returns true for a min-spacing denial', () async {
      final service = buildService();
      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'review_nudge',
      );

      // 1 hour later — well within the 48h min spacing.
      clock.advance(const Duration(hours: 1));
      final verdict = service.evaluate(
        surface: EngagementSurface.notificationPermission,
        askId: 'notif_perm',
      );
      expect(verdict, BudgetVerdict.deniedByMinSpacing);

      final allowed = await service.allowAsk(
        surface: EngagementSurface.notificationPermission,
        askId: 'notif_perm',
      );
      expect(allowed, isTrue,
          reason: 'shadow mode must always allow, regardless of verdict');
    });

    test('allowAsk returns true for a cap denial', () async {
      final service = buildService();

      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'ask-1',
      );
      clock.advance(const Duration(hours: 48));
      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );
      clock.advance(const Duration(hours: 48));

      final verdict = service.evaluate(
        surface: EngagementSurface.notificationPermission,
        askId: 'ask-3',
      );
      expect(verdict, BudgetVerdict.deniedByCap);

      final allowed = await service.allowAsk(
        surface: EngagementSurface.notificationPermission,
        askId: 'ask-3',
      );
      expect(allowed, isTrue,
          reason: 'shadow mode must always allow, regardless of verdict');
    });

    test('allowAsk returns true when the verdict is already allowed',
        () async {
      final service = buildService();
      final allowed = await service.allowAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'first-ever-ask',
      );
      expect(allowed, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Minimum spacing
  // ─────────────────────────────────────────────────────────────────────────

  group('minimum spacing', () {
    test('denies an ask inside the 48h window', () async {
      final service = buildService();
      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'ask-1',
      );

      clock.advance(const Duration(hours: 47, minutes: 59));
      final verdict = service.evaluate(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );
      expect(verdict, BudgetVerdict.deniedByMinSpacing);
    });

    test('allows an ask at exactly the 48h boundary', () async {
      final service = buildService();
      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'ask-1',
      );

      clock.advance(const Duration(hours: 48));
      final verdict = service.evaluate(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );
      expect(verdict, BudgetVerdict.allowed);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Global cap boundary
  // ─────────────────────────────────────────────────────────────────────────

  group('global cap boundary (2 per rolling 7 days)', () {
    test('2nd ask in the same rolling week is allowed, 3rd is denied by cap',
        () async {
      final service = buildService();

      // Ask 1 at day 0.
      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'ask-1',
      );

      // Evaluate ask 2 at +48h — clears min spacing, still well inside the
      // 7-day window, and only 1 prior ask counts so far.
      clock.advance(const Duration(hours: 48));
      final secondVerdict = service.evaluate(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );
      expect(secondVerdict, BudgetVerdict.allowed);
      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );

      // Evaluate ask 3 at +48h from ask 2 (day 4) — clears min spacing
      // against ask 2, but both ask 1 (day 0) and ask 2 (day 2) are still
      // inside the rolling 7-day window, so the cap of 2 is already used.
      clock.advance(const Duration(hours: 48));
      final thirdVerdict = service.evaluate(
        surface: EngagementSurface.notificationPermission,
        askId: 'ask-3',
      );
      expect(thirdVerdict, BudgetVerdict.deniedByCap);
    });

    test('cap resets once the older ask rolls out of the 7-day window',
        () async {
      final service = buildService();

      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'ask-1',
      );
      clock.advance(const Duration(hours: 48));
      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );

      // Move far enough that ask-1 (and ask-2) have rolled out of the
      // rolling 7-day cap window, and also clear the 48h spacing rule.
      clock.advance(const Duration(days: 8));
      final verdict = service.evaluate(
        surface: EngagementSurface.notificationPermission,
        askId: 'ask-3',
      );
      expect(verdict, BudgetVerdict.allowed);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Home/finish popup dedup
  // ─────────────────────────────────────────────────────────────────────────

  group('home + finish popup dedup', () {
    test('same popup id at home and finish counts once toward the cap',
        () async {
      final service = buildService();

      // Fill the cap with the popup pair (should only use 1 of 2 slots).
      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'popup-x',
      );
      clock.advance(const Duration(hours: 1));
      await service.recordAsk(
        surface: EngagementSurface.finishPopup,
        askId: 'popup-x',
      );

      // A wholly different ask should still be allowed — only 1 slot used
      // by the popup pair, not 2 — as long as it clears min spacing.
      clock.advance(const Duration(hours: 48));
      final verdict = service.evaluate(
        surface: EngagementSurface.notificationPermission,
        askId: 'notif_perm',
      );
      expect(verdict, BudgetVerdict.allowed);
    });

    test(
        'evaluating the finish_popup face right after the home_popup face '
        'of the same id does not self-trip min spacing', () async {
      final service = buildService();

      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'popup-x',
      );

      // Almost no time has passed — well inside the 48h spacing window —
      // but this is the *same* ask surfacing on its second door, so it must
      // not be denied by spacing against itself.
      clock.advance(const Duration(minutes: 5));
      final verdict = service.evaluate(
        surface: EngagementSurface.finishPopup,
        askId: 'popup-x',
      );
      expect(verdict, BudgetVerdict.allowed);
    });

    test('different popup ids do not dedup against each other', () async {
      final service = buildService();

      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'popup-x',
      );
      clock.advance(const Duration(hours: 1));
      final verdict = service.evaluate(
        surface: EngagementSurface.finishPopup,
        askId: 'popup-y',
      );
      expect(verdict, BudgetVerdict.deniedByMinSpacing,
          reason: 'a different popup id is a genuinely different ask');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Rolling-window pruning
  // ─────────────────────────────────────────────────────────────────────────

  group('rolling-window pruning', () {
    test('entries older than 30 days are dropped on the next write',
        () async {
      final service = buildService();

      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'old-ask',
      );

      clock.advance(const Duration(days: 31));
      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'new-ask',
      );

      final raw = prefs.getString('engagement_budget_log');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, hasLength(1));
      expect(decoded.single['askId'], 'new-ask');
    });

    test('entries within 30 days survive a write', () async {
      final service = buildService();

      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'kept-ask',
      );

      clock.advance(const Duration(days: 29));
      await service.recordAsk(
        surface: EngagementSurface.homePopup,
        askId: 'new-ask',
      );

      final raw = prefs.getString('engagement_budget_log');
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, hasLength(2));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // recordAsk bookkeeping
  // ─────────────────────────────────────────────────────────────────────────

  group('recordAsk', () {
    test('never throws and persists an entry retrievable via evaluate',
        () async {
      final service = buildService();
      await service.recordAsk(
        surface: EngagementSurface.finishSlot,
        askId: 'ask-1',
      );

      clock.advance(const Duration(minutes: 1));
      final verdict = service.evaluate(
        surface: EngagementSurface.homePopup,
        askId: 'ask-2',
      );
      expect(verdict, BudgetVerdict.deniedByMinSpacing);
    });
  });
}
