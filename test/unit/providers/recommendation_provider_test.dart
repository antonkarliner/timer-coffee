import 'dart:async';

import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hand-written fake — no Supabase anywhere in these tests.
class _FakeClient implements BeanRecommendationClient {
  RecommendationResult? fetchResult;
  Object? fetchError;
  BeanRecommendationStatus generateStatus = BeanRecommendationStatus.ok;
  Object? generateError;
  Object? dismissError;
  Object? deleteMineError;
  Object? logClickError;

  /// Replaces the default fetch behaviour (used to hold loads open).
  Future<RecommendationResult?> Function(String? locale)? fetchImpl;
  Future<BeanRecommendationStatus> Function(String locale, String? cc)?
      generateImpl;

  int fetchCount = 0;
  int generateCount = 0;
  int dismissCount = 0;
  int logClickCount = 0;
  int deleteMineCount = 0;
  final List<String> dismissedIds = [];
  final List<String> clickedIds = [];
  final List<String> clickSurfaces = [];
  final List<String> generateLocales = [];
  final List<String?> generateCountryCodes = [];

  @override
  Future<RecommendationResult?> fetch({String? locale}) async {
    fetchCount++;
    final impl = fetchImpl;
    if (impl != null) return impl(locale);
    if (fetchError != null) throw fetchError!;
    return fetchResult;
  }

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async {
    generateCount++;
    generateLocales.add(locale);
    generateCountryCodes.add(countryCode);
    final impl = generateImpl;
    if (impl != null) return impl(locale, countryCode);
    if (generateError != null) throw generateError!;
    return generateStatus;
  }

  @override
  Future<void> dismiss(String stockId) async {
    dismissCount++;
    dismissedIds.add(stockId);
    if (dismissError != null) throw dismissError!;
  }

  @override
  Future<void> logReferredClick(String stockId, String surface) async {
    logClickCount++;
    clickedIds.add(stockId);
    clickSurfaces.add(surface);
    if (logClickError != null) throw logClickError!;
  }

  @override
  Future<void> deleteMine() async {
    deleteMineCount++;
    if (deleteMineError != null) throw deleteMineError!;
  }
}

void main() {
  // Let fire-and-forget / microtask chains in the provider settle. Fake
  // calls only await Completers and microtasks, so this is deterministic.
  Future<void> settle() async {
    for (var i = 0; i < 25; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  RecommendationResult result({
    bool hasRecommendations = true,
    bool stale = false,
    List<BeanRecommendation> items = const [],
  }) => RecommendationResult(
        hasRecommendations: hasRecommendations,
        stale: stale,
        items: items,
      );

  BeanRecommendation item(String id, {String name = 'Test Bean'}) =>
      BeanRecommendation(
        stockId: id,
        beanName: name,
        roasterName: 'Test Roaster',
      );

  group('RecommendationProvider', () {
    late SharedPreferences prefs;
    late _FakeClient client;
    String? userId = 'user-1';
    bool flagOn = true;
    DateTime now = DateTime(2026, 11, 16, 12);
    final created = <RecommendationProvider>[];
    final disposed = <RecommendationProvider>{};

    /// Tracks a manual dispose so tearDown never double-disposes.
    void disposeInTearDown(RecommendationProvider p) => disposed.add(p);

    RecommendationProvider make({
      Future<String?> Function(String localeCode)? countryCodeLookup,
    }) {
      final c = _FakeClient();
      client = c;
      final p = RecommendationProvider(
        client: c,
        currentUserId: () => userId,
        featureFlagEnabled: () => flagOn,
        countryCodeLookup: countryCodeLookup ?? (localeCode) async => 'DE',
        prefs: prefs,
        clock: () => now,
      );
      created.add(p);
      return p;
    }

    /// A second provider sharing the same client/prefs — simulates the next
    /// hub open on a fresh instance.
    RecommendationProvider makeWith({
      required BeanRecommendationClient existingClient,
    }) {
      final p = RecommendationProvider(
        client: existingClient,
        currentUserId: () => userId,
        featureFlagEnabled: () => flagOn,
        countryCodeLookup: (localeCode) async => 'DE',
        prefs: prefs,
        clock: () => now,
      );
      created.add(p);
      return p;
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      userId = 'user-1';
      flagOn = true;
      now = DateTime(2026, 11, 16, 12);
    });

    tearDown(() {
      for (final p in created) {
        if (disposed.contains(p)) continue;
        p.dispose();
      }
      created.clear();
      disposed.clear();
    });

    group('lastCountryCode', () {
      test(
        'null until lookup, upper-cased and updated by later lookups',
        () async {
          String? country = 'fr';
          final p = make(countryCodeLookup: (_) async => country);
          client.fetchResult = result(hasRecommendations: false);
          client.generateStatus = BeanRecommendationStatus.noSupply;
          expect(p.lastCountryCode, isNull);

          await p.ensureLoaded('en');
          expect(p.lastCountryCode, 'FR');
          // The analytics getter must not alter the generate request.
          expect(client.generateCountryCodes, ['fr']);

          country = 'de';
          now = now.add(const Duration(hours: 7));
          await p.ensureLoaded('de');
          expect(p.lastCountryCode, 'DE');

          country = null;
          now = now.add(const Duration(hours: 7));
          await p.ensureLoaded('ru');
          expect(p.lastCountryCode, isNull);

          country = 'not-a-code';
          now = now.add(const Duration(hours: 7));
          await p.ensureLoaded('fr');
          expect(p.lastCountryCode, isNull);
        },
      );

      test(
        'lookup failures never throw and preserve the last known code',
        () async {
          var fail = true;
          final p = make(
            countryCodeLookup: (_) async {
              if (fail) throw StateError('lookup unavailable');
              return 'gb';
            },
          );
          client.fetchResult = result(hasRecommendations: false);
          client.generateStatus = BeanRecommendationStatus.noSupply;

          await p.ensureLoaded('en');
          expect(p.lastCountryCode, isNull);
          fail = false;
          now = now.add(const Duration(hours: 7));
          await p.ensureLoaded('de');
          expect(p.lastCountryCode, 'GB');
          fail = true;
          now = now.add(const Duration(hours: 7));
          await p.ensureLoaded('fr');
          expect(p.lastCountryCode, 'GB');
          expect(client.generateCountryCodes, [null, 'gb', null]);
        },
      );
    });

    group('gates (hidden, no network)', () {
      test('flag off → hidden, no network call', () async {
        flagOn = false;
        final p = make();
        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(client.fetchCount, 0);
        expect(client.generateCount, 0);
        expect(p.unavailableStatus, isNull);
      });

      test('no user id → hidden, no network call', () async {
        userId = null;
        final p = make();
        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(client.fetchCount, 0);
        expect(client.generateCount, 0);
      });

      test('persisted opt-out → hidden, no network call', () async {
        await prefs.setBool(RecommendationProvider.optOutPrefKey, true);
        final p = make();
        await p.ensureLoaded('en');

        expect(p.optedOut, isTrue);
        expect(p.state, RecommendationState.hidden);
        expect(client.fetchCount, 0);
      });

      test('flag turning on later lets the next call load for real', () async {
        flagOn = false;
        final p = make();
        await p.ensureLoaded('en');
        expect(p.state, RecommendationState.hidden);
        expect(client.fetchCount, 0);

        flagOn = true;
        client.fetchResult = result(items: [item('s1')]);
        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.ready);
        expect(client.fetchCount, 1);
      });
    });

    group('ready path', () {
      test('items → ready; repeated calls do not re-fetch', () async {
        final p = make();
        client.fetchResult = result(items: [item('s1'), item('s2')]);

        await p.ensureLoaded('en');
        expect(p.state, RecommendationState.ready);
        expect(p.items.map((i) => i.stockId), ['s1', 's2']);
        expect(p.isFirstLoad, isFalse);
        expect(p.unavailableStatus, isNull);

        await p.ensureLoaded('en');
        expect(client.fetchCount, 1);
        expect(client.generateCount, 0);
      });

      test('locale change reloads', () async {
        final p = make();
        client.fetchResult = result(items: [item('s1')]);
        await p.ensureLoaded('en');
        expect(client.fetchCount, 1);

        await p.ensureLoaded('de');
        expect(client.fetchCount, 2);
        expect(p.state, RecommendationState.ready);
      });

      test('user id change reloads', () async {
        final p = make();
        client.fetchResult = result(items: [item('s1')]);
        await p.ensureLoaded('en');
        expect(client.fetchCount, 1);

        userId = 'user-2';
        client.fetchResult = result(items: [item('s9')]);
        await p.ensureLoaded('en');

        expect(client.fetchCount, 2);
        expect(p.items.single.stockId, 's9');
      });
    });

    group('first generation (never generated)', () {
      test('ok → loading with skeleton, then ready', () async {
        final p = make();
        final initialFetch = Completer<RecommendationResult?>();
        final generateGate = Completer<BeanRecommendationStatus>();
        client.fetchImpl = (locale) async {
          if (client.fetchCount == 1) return initialFetch.future;
          return result(items: [item('fresh')]);
        };
        client.generateImpl = (locale, cc) => generateGate.future;

        final done = p.ensureLoaded('en');
        await settle();
        expect(p.state, RecommendationState.loading);
        expect(p.isFirstLoad, isFalse,
            reason: 'plain fetches show no skeleton');

        initialFetch.complete(result(hasRecommendations: false));
        await settle();
        // Skeleton rows only while the very first generation runs.
        expect(p.state, RecommendationState.loading);
        expect(p.isFirstLoad, isTrue);

        generateGate.complete(BeanRecommendationStatus.ok);
        await done;
        expect(p.state, RecommendationState.ready);
        expect(p.items.single.stockId, 'fresh');
        expect(p.isFirstLoad, isFalse);
        expect(client.generateCount, 1);
        expect(client.generateLocales, ['en']);
        expect(client.generateCountryCodes, ['DE']);
        // The throttle timestamp is recorded from the injected clock.
        expect(
          prefs.getInt('bean_recs_last_generate_user-1'),
          now.millisecondsSinceEpoch,
        );
      });

      test('insufficient_history → hidden with unavailableStatus', () async {
        final p = make();
        client.fetchResult = result(hasRecommendations: false);
        client.generateStatus = BeanRecommendationStatus.insufficientHistory;

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, 'insufficient_history');
        expect(p.isFirstLoad, isFalse);
        expect(client.generateCount, 1);
        expect(client.fetchCount, 1, reason: 'no refetch after non-ok');
      });

      test('no_supply → hidden with unavailableStatus', () async {
        final p = make();
        client.fetchResult = result(hasRecommendations: false);
        client.generateStatus = BeanRecommendationStatus.noSupply;

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, 'no_supply');
      });

      test('ok but no items → hidden, no unavailableStatus', () async {
        final p = make();
        client.generateStatus = BeanRecommendationStatus.ok;
        client.fetchImpl = (locale) async {
          if (client.fetchCount == 1) return result(hasRecommendations: false);
          return result(hasRecommendations: true, items: const []);
        };

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, isNull);
        expect(client.generateCount, 1);
        expect(client.fetchCount, 2);
      });

      test('generate throwing → hidden, behaves as nothing new', () async {
        final p = make();
        client.fetchResult = result(hasRecommendations: false);
        client.generateError = Exception('boom');

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, isNull);
        expect(client.fetchCount, 1);
      });

      test('country lookup failure still generates, with null country',
          () async {
        final c = _FakeClient();
        client = c;
        final p = RecommendationProvider(
          client: c,
          currentUserId: () => userId,
          featureFlagEnabled: () => flagOn,
          countryCodeLookup: (localeCode) async => throw Exception('no geo'),
          prefs: prefs,
          clock: () => now,
        );
        created.add(p);
        c.generateStatus = BeanRecommendationStatus.ok;
        c.fetchImpl = (locale) async {
          if (c.fetchCount == 1) return result(hasRecommendations: false);
          return result(items: [item('fresh')]);
        };

        await p.ensureLoaded('en');

        expect(c.generateCountryCodes, [null]);
        expect(p.state, RecommendationState.ready);
      });
    });

    group('nothing-to-show (hasRecommendations true, empty items)', () {
      test('not stale → hidden, no generation', () async {
        final p = make();
        client.fetchResult =
            result(hasRecommendations: true, items: const []);

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, isNull);
        expect(client.generateCount, 0);
        expect(client.fetchCount, 1);
      });

      test('stale → hidden, then background refresh brings items', () async {
        final p = make();
        final generateGate = Completer<BeanRecommendationStatus>();
        client.fetchResult = result(
          hasRecommendations: true,
          stale: true,
          items: const [],
        );
        client.fetchImpl = (locale) async {
          if (client.fetchCount == 1) return client.fetchResult;
          return result(items: [item('regenerated')]);
        };
        client.generateImpl = (locale, cc) => generateGate.future;

        await p.ensureLoaded('en');
        await settle();

        expect(p.state, RecommendationState.hidden);
        expect(client.generateCount, 1, reason: 'background generate started');

        generateGate.complete(BeanRecommendationStatus.ok);
        await settle();

        expect(p.state, RecommendationState.ready);
        expect(p.items.single.stockId, 'regenerated');
      });
    });

    group('stale-while-revalidate', () {
      test('keeps old items immediately and replaces them on success',
          () async {
        final p = make();
        final generateGate = Completer<BeanRecommendationStatus>();
        client.fetchResult =
            result(stale: true, items: [item('old-1'), item('old-2')]);
        client.fetchImpl = (locale) async {
          if (client.fetchCount == 1) return client.fetchResult;
          return result(items: [item('new-1')]);
        };
        client.generateImpl = (locale, cc) => generateGate.future;

        await p.ensureLoaded('en');

        // Old list is visible right away, no skeleton.
        expect(p.state, RecommendationState.ready);
        expect(p.isFirstLoad, isFalse);
        expect(p.items.map((i) => i.stockId), ['old-1', 'old-2']);

        generateGate.complete(BeanRecommendationStatus.ok);
        await settle();

        expect(p.state, RecommendationState.ready);
        expect(p.items.map((i) => i.stockId), ['new-1']);
        expect(client.generateCount, 1);
        expect(p.unavailableStatus, isNull);
      });

      test('generate failure keeps the old list', () async {
        final p = make();
        client.fetchResult = result(stale: true, items: [item('old-1')]);
        client.generateError = Exception('offline');

        await p.ensureLoaded('en');
        await settle();

        expect(p.state, RecommendationState.ready);
        expect(p.items.map((i) => i.stockId), ['old-1']);
        expect(client.generateCount, 1);
        expect(client.fetchCount, 1,
            reason: 'no refetch after failed generate');
      });

      test('refresh does not resurrect items dismissed this session',
          () async {
        final p = make();
        final generateGate = Completer<BeanRecommendationStatus>();
        client.fetchResult =
            result(stale: true, items: [item('a'), item('b')]);
        client.fetchImpl = (locale) async {
          if (client.fetchCount == 1) return client.fetchResult;
          return result(items: [item('a'), item('b')]);
        };
        client.generateImpl = (locale, cc) => generateGate.future;

        await p.ensureLoaded('en');
        await p.dismiss('a');
        expect(p.items.map((i) => i.stockId), ['b']);

        generateGate.complete(BeanRecommendationStatus.ok);
        await settle();

        expect(p.items.map((i) => i.stockId), ['b'],
            reason: 'refresh landed after dismissal; must not bring a back');
      });
    });

    group('fetch failures', () {
      test('null result → hidden with error status', () async {
        final p = make();
        client.fetchResult = null;

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, 'error');
      });

      test('exception → hidden with error status, never throws', () async {
        final p = make();
        client.fetchError = Exception('no network');

        await p.ensureLoaded('en');

        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, 'error');
      });
    });

    group('generate throttle', () {
      test('second generation within 6h is skipped', () async {
        final first = make();
        final sharedClient = client;
        client.fetchResult = result(hasRecommendations: false);
        client.generateStatus = BeanRecommendationStatus.insufficientHistory;

        await first.ensureLoaded('en');
        expect(sharedClient.generateCount, 1);

        // Next hub open: fresh provider, same prefs, only 5h later.
        now = now.add(const Duration(hours: 5));
        final second = makeWith(existingClient: sharedClient);

        await second.ensureLoaded('en');

        expect(sharedClient.generateCount, 1,
            reason: 'throttled: no second call within 6h');
        expect(second.state, RecommendationState.hidden);
        expect(second.unavailableStatus, isNull);
      });

      test('generation after 6h runs again', () async {
        final first = make();
        final sharedClient = client;
        client.fetchResult = result(hasRecommendations: false);
        client.generateStatus = BeanRecommendationStatus.insufficientHistory;

        await first.ensureLoaded('en');
        expect(sharedClient.generateCount, 1);

        now = now.add(const Duration(hours: 6, minutes: 1));
        final second = makeWith(existingClient: sharedClient);

        await second.ensureLoaded('en');

        expect(sharedClient.generateCount, 2);
        expect(second.unavailableStatus, 'insufficient_history');
      });
    });

    group('dismiss', () {
      test('removes optimistically and calls the client', () async {
        final p = make();
        client.fetchResult = result(items: [item('a'), item('b')]);
        await p.ensureLoaded('en');

        await p.dismiss('a');

        expect(p.items.map((i) => i.stockId), ['b']);
        expect(p.state, RecommendationState.ready);
        expect(client.dismissedIds, ['a']);
      });

      test('last item → hidden', () async {
        final p = make();
        client.fetchResult = result(items: [item('a')]);
        await p.ensureLoaded('en');

        await p.dismiss('a');

        expect(p.items, isEmpty);
        expect(p.state, RecommendationState.hidden);
        expect(p.unavailableStatus, isNull);
      });

      test('network failure is tolerated, item stays removed', () async {
        final p = make();
        client.fetchResult = result(items: [item('a'), item('b')]);
        client.dismissError = Exception('offline');
        await p.ensureLoaded('en');

        await p.dismiss('a');

        expect(p.items.map((i) => i.stockId), ['b']);
        expect(p.state, RecommendationState.ready);
        expect(client.dismissedIds, ['a']);
      });
    });

    group('opt-out', () {
      test('persists, clears items, calls deleteMine', () async {
        final p = make();
        client.fetchResult = result(items: [item('a')]);
        await p.ensureLoaded('en');
        expect(p.state, RecommendationState.ready);

        await p.setOptedOut(true);

        expect(p.optedOut, isTrue);
        expect(p.state, RecommendationState.hidden);
        expect(p.items, isEmpty);
        expect(client.deleteMineCount, 1);
        expect(prefs.getBool(RecommendationProvider.optOutPrefKey), isTrue);
      });

      test('deleteMine failure keeps the opt-out stored', () async {
        final p = make();
        client.deleteMineError = Exception('offline');

        await p.setOptedOut(true);

        expect(p.optedOut, isTrue);
        expect(prefs.getBool(RecommendationProvider.optOutPrefKey), isTrue);
        expect(p.state, RecommendationState.hidden);
      });

      test('re-enable resets to idle and the next call loads', () async {
        final p = make();
        await p.setOptedOut(true);
        client.fetchResult = result(items: [item('a')]);

        await p.setOptedOut(false);

        expect(p.optedOut, isFalse);
        expect(p.state, RecommendationState.idle);
        expect(prefs.getBool(RecommendationProvider.optOutPrefKey), isFalse);

        await p.ensureLoaded('en');
        expect(p.state, RecommendationState.ready);
        expect(p.items.single.stockId, 'a');
      });

      test('opt out → opt in → ensureLoaded generates again despite the '
          'throttle', () async {
        final p = make();
        client.fetchResult = result(hasRecommendations: false);
        client.generateStatus = BeanRecommendationStatus.insufficientHistory;
        await p.ensureLoaded('en');
        expect(client.generateCount, 1);
        expect(
          prefs.getInt('bean_recs_last_generate_user-1'),
          now.millisecondsSinceEpoch,
          reason: 'the generate recorded its throttle entry',
        );

        await p.setOptedOut(true);
        await p.setOptedOut(false);
        expect(
          prefs.getInt('bean_recs_last_generate_user-1'),
          isNull,
          reason: 'opt-in must clear the generate-throttle entry',
        );

        // Same clock: still inside the 6-hour window, so only the removed
        // entry — not elapsed time — lets generate run again. Without the
        // reset the re-enabled card would stay hidden until the window
        // elapsed.
        await p.ensureLoaded('en');
        expect(client.generateCount, 2);
      });
    });

    group('logLinkOpened', () {
      test('forwards stock id and default surface', () async {
        final p = make();

        await p.logLinkOpened('stock-7');

        expect(client.clickedIds, ['stock-7']);
        expect(client.clickSurfaces, ['for_you_card']);
      });

      test('custom surface and swallowed errors', () async {
        final p = make();
        client.logClickError = Exception('offline');

        await p.logLinkOpened('stock-7', surface: 'bean_detail');

        expect(client.clickSurfaces, ['bean_detail']);
      });
    });

    group('dispose safety', () {
      test('no notifyListeners after dispose (load finishing mid-air)',
          () async {
        final p = make();
        final fetchGate = Completer<RecommendationResult?>();
        client.fetchImpl = (locale) => fetchGate.future;

        final done = p.ensureLoaded('en');
        await settle();
        expect(p.state, RecommendationState.loading);

        var notifications = 0;
        p.addListener(() => notifications++);
        disposeInTearDown(p);
        p.dispose();

        fetchGate.complete(result(items: [item('late')]));
        await done;
        await settle();

        expect(notifications, 0,
            reason: 'late load result must not notify after dispose');
      });
    });

    group('concurrency', () {
      test('concurrent calls share one in-flight load', () async {
        final p = make();
        final gate = Completer<RecommendationResult?>();
        client.fetchImpl = (locale) => gate.future;

        final a = p.ensureLoaded('en');
        final b = p.ensureLoaded('en');
        gate.complete(result(items: [item('a')]));

        await a;
        await b;

        expect(client.fetchCount, 1);
        expect(p.state, RecommendationState.ready);
      });
    });
  });
}
