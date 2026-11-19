import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:coffee_timer/utils/stock_links.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/for_you_card.dart';
import 'package:coffee_timer/widgets/stock_bean_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// English ARB strings the tests interact with.
const _title = 'For you';
const _subtitle = 'In stock now, picked from what you brew';
const _yourRoasterMarker = 'Your roaster';
const _viewLabel = 'View at roaster';
const _dismissLabel = 'Not for me';
const _showMoreLabel = 'Show more';
const _showLessLabel = 'Show less';
const _undoLabel = 'Undo';
const _hiddenMessage =
    'Bean suggestions are off. You can turn them back on in Settings.';

/// Hand-written fake — no Supabase anywhere in these tests (same shape as
/// the one in test/unit/providers/recommendation_provider_test.dart).
class _FakeClient implements BeanRecommendationClient {
  RecommendationResult? fetchResult;
  Future<RecommendationResult?> Function(String? locale)? fetchImpl;
  Object? dismissError;
  BeanRecommendationStatus generateStatus = BeanRecommendationStatus.ok;

  int fetchCount = 0;
  final List<String> dismissedIds = [];
  final List<String> clickedIds = [];

  @override
  Future<RecommendationResult?> fetch({String? locale}) async {
    fetchCount++;
    final impl = fetchImpl;
    if (impl != null) return impl(locale);
    return fetchResult;
  }

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async => generateStatus;

  @override
  Future<void> dismiss(String stockId) async {
    if (dismissError != null) throw dismissError!;
    dismissedIds.add(stockId);
  }

  @override
  Future<void> logReferredClick(String stockId, String surface) async {
    clickedIds.add(stockId);
  }

  int deleteMineCount = 0;

  @override
  Future<void> deleteMine() async => deleteMineCount++;
}

/// Real provider that records how `ensureLoaded` is invoked: how often,
/// with which locale tags, and whether the very first call happened while
/// the framework was in the build/layout/paint phase (it must not).
class _CountingProvider extends RecommendationProvider {
  _CountingProvider({
    required super.client,
    required super.currentUserId,
    required super.featureFlagEnabled,
    required super.countryCodeLookup,
    required super.prefs,
    super.clock,
  });

  int ensureLoadedCalls = 0;
  final List<String> locales = [];

  /// Whether call #1 ran during the persistent (build/layout/paint) phase.
  bool? _firstCallDuringBuildPhase;
  bool get firstCallDuringBuildPhase => _firstCallDuringBuildPhase ?? false;

  @override
  Future<void> ensureLoaded(String localeCode) {
    ensureLoadedCalls++;
    locales.add(localeCode);
    _firstCallDuringBuildPhase ??=
        SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks;
    return super.ensureLoaded(localeCode);
  }
}

BeanRecommendation rec(
  String id, {
  String name = 'Test Bean',
  String roaster = 'Test Roaster',
  String? reason,
  String? mode,
  String? productUrl,
  List<String> origins = const [],
  String? slug = 'roaster-slug',
}) => BeanRecommendation(
      stockId: id,
      beanName: name,
      roasterName: roaster,
      roasterSlug: slug,
      reason: reason,
      mode: mode,
      productUrl: productUrl,
      originCountryCodes: origins,
    );

class _Harness extends StatelessWidget {
  const _Harness({
    required this.provider,
    this.locale = const Locale('en'),
    this.maxItems = 3,
    this.textScaler = TextScaler.noScaling,
  });

  final RecommendationProvider provider;
  final Locale locale;
  final int maxItems;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          // MaterialApp no longer takes a textScaler; override it here so
          // every descendant Text scales.
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Scaffold(
            body: ListView(
              children: [
                ChangeNotifierProvider<RecommendationProvider>.value(
                  value: provider,
                  // Keyed by provider: a fresh provider forces a remount
                  // (a bare const card would be the identical widget across
                  // pumpWidget calls and never re-run initState), while the
                  // same provider across a locale change keeps the element —
                  // matching production, where the Hub remount is what
                  // re-runs initState.
                  child: ForYouCard(
                    key: ObjectKey(provider),
                    maxItems: maxItems,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<({_CountingProvider provider, _FakeClient client})> _pumpCard(
  WidgetTester tester, {
  _FakeClient? client,
  List<BeanRecommendation> items = const [],
  Locale locale = const Locale('en'),
  int maxItems = 3,
  bool flagOn = true,
  TextScaler textScaler = TextScaler.noScaling,
  DateTime Function()? clock,
  Future<String?> Function(String localeCode)? countryCodeLookup,
  StackRouter? router,
}) async {
  final c = client ?? _FakeClient();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final provider = _CountingProvider(
    client: c,
    currentUserId: () => 'user-1',
    featureFlagEnabled: () => flagOn,
    countryCodeLookup: countryCodeLookup ?? (localeCode) async => 'DE',
    prefs: prefs,
    clock: clock,
  );
  if (items.isNotEmpty) {
    c.fetchResult = RecommendationResult(
      hasRecommendations: true,
      items: items,
    );
  }
  addTearDown(provider.dispose);
  Widget app = _Harness(
    provider: provider,
    locale: locale,
    maxItems: maxItems,
    textScaler: textScaler,
  );
  if (router != null) {
    app = StackRouterScope(controller: router, stateHash: 0, child: app);
  }
  await tester.pumpWidget(app);
  return (provider: provider, client: c);
}

/// Same route recorder used by coffee_journey_card_try_recipe_test.dart.
class _RecordingStackRouter extends Mock implements StackRouter {
  PageRouteInfo? pushedRoute;

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushedRoute = route;
    return null;
  }
}

void main() {
  group('analytics', () {
    // Initialise outside the widget test's fake-async zone, as the existing
    // journey-card and Settings tests do. Assertions inspect the real buffer.
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AnalyticsService.resetForTesting();
      await AnalyticsService.initialize(await SharedPreferences.getInstance());
      AnalyticsService.sendOverride = (_) async {};
    });
    tearDown(AnalyticsService.resetForTesting);

    List<Map<String, dynamic>> events(String name) => AnalyticsService
        .instance
        .bufferedEventsForTesting
        .where((event) => event['event_name'] == name)
        .toList();

    testWidgets('shown counts only displayed rows and fires once across '
        'rebuilds, locale changes and dismissals', (tester) async {
      final env = await _pumpCard(
        tester,
        items: [
          rec('s1', mode: 'your_roaster'),
          rec('s2', mode: 'near_you'),
          rec('s3', mode: 'your_roaster'),
          rec('s4', mode: 'not_displayed'),
        ],
      );
      await tester.pumpAndSettle();
      expect(events('for_you_shown'), hasLength(1));
      expect(events('for_you_shown').single['category'], 'beans');
      // Collapsed is the default: one row visible, three picks available.
      expect(events('for_you_shown').single['properties'], {
        'count': 1,
        'modes': 'your_roaster',
        'available': 3,
      });

      await tester.pumpWidget(_Harness(provider: env.provider));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _Harness(provider: env.provider, locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      // Dismiss all rows, including the previously capped fourth pick.
      for (final id in ['s1', 's2', 's3', 's4']) {
        await env.provider.dismiss(id);
        await tester.pumpAndSettle();
      }
      expect(find.byType(Card), findsNothing);
      expect(events('for_you_shown'), hasLength(1));
      expect(events('for_you_unavailable'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'row taps, link opens and dismissals carry displayed position',
      (tester) async {
        final router = _RecordingStackRouter();
        final env = await _pumpCard(
          tester,
          router: router,
          items: [
            rec('s1', name: 'Bean A', mode: 'your_roaster'),
            rec(
              's2',
              name: 'Bean B',
              mode: 'near_you',
              productUrl: 'https://shop.example.com/b',
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Collapsed by default: expand so the second pick's row exists.
        await tester.tap(find.text(_showMoreLabel));
        await tester.pumpAndSettle();
        expect(events('for_you_expanded'), hasLength(1));
        expect(events('for_you_expanded').single['category'], 'beans');
        expect(events('for_you_expanded').single['properties'], {'count': 2});

        await tester.tap(find.text('Bean B'));
        await tester.pumpAndSettle();
        expect(router.pushedRoute, isA<RoasterProfileRoute>());
        expect(
          (router.pushedRoute as RoasterProfileRoute).args!.slug,
          'roaster-slug',
        );
        expect(
          (router.pushedRoute as RoasterProfileRoute).args!.highlightStockId,
          's2',
        );
        await tester.tap(find.text(_viewLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_dismissLabel).last);
        await tester.pumpAndSettle();

        for (final name in [
          'for_you_pick_tapped',
          'for_you_link_opened',
          'for_you_dismissed',
        ]) {
          expect(events(name), hasLength(1));
          expect(events(name).single['category'], 'beans');
          expect(events(name).single['properties'], {
            'stock_id': 's2',
            'position': 1,
            'mode': 'near_you',
          });
        }
        expect(env.client.clickedIds, ['s2']);
        expect(env.client.dismissedIds, ['s2']);
        await tester.tap(find.text(_dismissLabel));
        await tester.pumpAndSettle();
        expect(events('for_you_dismissed').last['properties'], {
          'stock_id': 's1',
          'position': 0,
          'mode': 'your_roaster',
        });
        expect(
          events('for_you_pick_tapped'),
          hasLength(1),
          reason: 'nested buttons must not count as profile taps',
        );
        expect(events('for_you_shown'), hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('unavailable fires once per status with the lookup country', (
      tester,
    ) async {
      var now = DateTime(2026, 11, 16);
      final client = _FakeClient()
        ..fetchResult = const RecommendationResult(hasRecommendations: false)
        ..generateStatus = BeanRecommendationStatus.insufficientHistory;
      final env = await _pumpCard(
        tester,
        client: client,
        clock: () => now,
        countryCodeLookup: (_) async => 'fr',
      );
      await tester.pumpAndSettle();
      expect(events('for_you_unavailable').single['properties'], {
        'status': 'insufficient_history',
        'country': 'FR',
      });

      await tester.pumpWidget(_Harness(provider: env.provider));
      await tester.pumpAndSettle();
      now = now.add(const Duration(hours: 7));
      client.generateStatus = BeanRecommendationStatus.noSupply;
      await tester.pumpWidget(
        _Harness(provider: env.provider, locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      expect(events('for_you_unavailable').last['properties'], {
        'status': 'no_supply',
        'country': 'FR',
      });

      now = now.add(const Duration(hours: 7));
      client.generateStatus = BeanRecommendationStatus.insufficientHistory;
      await tester.pumpWidget(
        _Harness(provider: env.provider, locale: const Locale('ru')),
      );
      await tester.pumpAndSettle();
      expect(events('for_you_unavailable'), hasLength(2));
      client.fetchResult = null;
      await tester.pumpWidget(
        _Harness(provider: env.provider, locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();
      expect(events('for_you_unavailable'), hasLength(3));
      expect(events('for_you_unavailable').last['properties'], {
        'status': 'error',
        'country': 'FR',
      });
      expect(
        events('for_you_unavailable').map((e) => e['category']),
        everyElement('beans'),
      );
      expect(events('for_you_shown'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unavailable omits country when no lookup has succeeded', (
      tester,
    ) async {
      final env = await _pumpCard(tester);
      await tester.pumpAndSettle();
      expect(events('for_you_unavailable').single['properties'], {
        'status': 'error',
      });
      await tester.pumpWidget(
        _Harness(provider: env.provider, locale: const Locale('de')),
      );
      await tester.pumpAndSettle();
      expect(events('for_you_unavailable'), hasLength(1));
    });

    testWidgets('flag gate and an empty answer without status emit nothing', (
      tester,
    ) async {
      await _pumpCard(tester, flagOn: false);
      await tester.pumpAndSettle();
      await _pumpCard(
        tester,
        client: _FakeClient()
          ..fetchResult = const RecommendationResult(hasRecommendations: true),
      );
      await tester.pumpAndSettle();
      expect(AnalyticsService.instance.bufferedEventsForTesting, isEmpty);
    });

    testWidgets('zero displayed rows do not count as shown', (tester) async {
      await _pumpCard(tester, maxItems: 0, items: [rec('s1')]);
      await tester.pumpAndSettle();
      expect(events('for_you_shown'), isEmpty);
    });
  });

  group('non-ready states render nothing', () {
    testWidgets('hidden (flag off) → empty, no exception', (tester) async {
      final env = await _pumpCard(
        tester,
        flagOn: false,
        items: [rec('s1', name: 'Bean 1')],
      );
      await tester.pumpAndSettle();

      expect(env.provider.state, RecommendationState.hidden);
      expect(env.client.fetchCount, 0, reason: 'gates fire before any fetch');
      expect(find.text(_title), findsNothing);
      expect(find.text(_dismissLabel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('idle → empty, no exception', (tester) async {
      final env = await _pumpCard(tester, items: [rec('s1', name: 'Bean 1')]);
      await tester.pumpAndSettle();
      expect(find.text('Bean 1'), findsOneWidget);

      // Opt-out → hidden; re-enabling resets the provider to idle without
      // any reload, so the card must stay gone in the idle state too.
      await env.provider.setOptedOut(true);
      await tester.pumpAndSettle();
      await env.provider.setOptedOut(false);
      await tester.pumpAndSettle();

      expect(env.provider.state, RecommendationState.idle);
      expect(find.text(_title), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading → empty, no exception', (tester) async {
      final gate = Completer<RecommendationResult?>();
      final client = _FakeClient()..fetchImpl = (_) => gate.future;
      final env = await _pumpCard(tester, client: client);
      await tester.pump();

      expect(env.provider.state, RecommendationState.loading);
      expect(find.text(_title), findsNothing);
      expect(find.text(_subtitle), findsNothing);
      expect(tester.takeException(), isNull);

      gate.complete(RecommendationResult(
        hasRecommendations: true,
        items: [rec('s1', name: 'Bean 1')],
      ));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('actions use the default button label style', (tester) async {
      await _pumpCard(tester, items: [
        rec('s1', productUrl: 'https://shop.example.com/b1'),
        rec('s2'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(_viewLabel), findsOneWidget);
      expect(find.text(_dismissLabel), findsOneWidget);
      expect(find.text(_showMoreLabel), findsOneWidget);
      expect(find.text('Your taste profile'), findsOneWidget);
      final buttons =
          tester.widgetList<AppTextButton>(find.byType(AppTextButton));
      expect(buttons.length, greaterThanOrEqualTo(4));
      expect(buttons.map((button) => button.textStyle), everyElement(isNull));
    });

    testWidgets('ready with 5 items → collapsed one row, expanded maxItems',
        (tester) async {
      final items = List.generate(
        5,
        (i) => rec('s$i', name: 'Bean ${i + 1}'),
      );
      await _pumpCard(tester, items: items);
      await tester.pumpAndSettle();

      expect(find.text(_title), findsOneWidget);
      expect(find.text('Bean 1'), findsOneWidget);
      expect(find.text('Bean 2'), findsNothing);
      expect(find.text('Bean 5'), findsNothing);
      expect(find.byType(StockBeanCard), findsOneWidget);

      await tester.tap(find.text(_showMoreLabel));
      await tester.pumpAndSettle();

      expect(find.text('Bean 1'), findsOneWidget);
      expect(find.text('Bean 2'), findsOneWidget);
      expect(find.text('Bean 3'), findsOneWidget);
      expect(find.text('Bean 4'), findsNothing);
      expect(find.text('Bean 5'), findsNothing);
      expect(find.byType(StockBeanCard), findsNWidgets(3));
    });

    testWidgets('maxItems: 1 → one card, no expand control',
        (tester) async {
      final items = List.generate(
        5,
        (i) => rec('s$i', name: 'Bean ${i + 1}'),
      );
      await _pumpCard(tester, items: items, maxItems: 1);
      await tester.pumpAndSettle();

      expect(find.text('Bean 1'), findsOneWidget);
      expect(find.text('Bean 2'), findsNothing);
      expect(find.byType(StockBeanCard), findsOneWidget);
      expect(find.text(_showMoreLabel), findsNothing,
          reason: 'expanding could never reveal anything at maxItems 1');
    });

    testWidgets('reason shown when present', (tester) async {
      await _pumpCard(tester, items: [rec('s1', reason: 'Bright and juicy.')]);
      await tester.pumpAndSettle();

      expect(find.text('Bright and juicy.'), findsOneWidget);
    });

    testWidgets('null reason → localized origin names joined', (tester) async {
      await _pumpCard(
        tester,
        items: [rec('s1', origins: ['BR', 'CO'])],
      );
      await tester.pumpAndSettle();

      expect(find.text('Brazil · Colombia'), findsOneWidget);
    });

    testWidgets('unknown origin codes are skipped, not shown', (tester) async {
      await _pumpCard(
        tester,
        items: [
          rec('s1', origins: ['BR', 'XX']),
          rec('s2', origins: ['ZZ', 'QQ']),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Brazil'), findsOneWidget,
          reason: 'XX is skipped, BR alone is shown');
      expect(find.textContaining('·'), findsNothing,
          reason: 'second row has no nameable origins → line omitted entirely');
    });

    testWidgets('your_roaster shows the marker, near_you does not',
        (tester) async {
      await _pumpCard(
        tester,
        items: [
          rec('s1', mode: 'your_roaster'),
          rec('s2', mode: 'near_you'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Roaster · $_yourRoasterMarker'), findsOneWidget);
      final rows = find.textContaining(_yourRoasterMarker);
      expect(rows, findsOneWidget);
    });

    testWidgets(
        'no productUrl (null, empty, javascript:, ftp:) → no view button',
        (tester) async {
      for (final url in [
        null,
        '',
        'javascript:alert(1)',
        'ftp://files.example.com/a.zip',
      ]) {
        await _pumpCard(tester, items: [rec('s1', productUrl: url)]);
        await tester.pumpAndSettle();

        expect(find.text(_viewLabel), findsNothing, reason: 'url: $url');
        expect(find.text(_dismissLabel), findsOneWidget, reason: 'url: $url');
      }
    });

    testWidgets('valid https productUrl → view button, tap logs the click',
        (tester) async {
      final env = await _pumpCard(
        tester,
        items: [rec('s1', productUrl: 'https://shop.example.com/beans/x')],
      );
      await tester.pumpAndSettle();

      expect(find.text(_viewLabel), findsOneWidget);

      await tester.tap(find.text(_viewLabel));
      await tester.pumpAndSettle();

      expect(env.client.clickedIds, ['s1']);
      expect(tester.takeException(), isNull,
          reason: 'launchUrl has no handler in tests; the handler must '
              'tolerate that');
    });
  });

  testWidgets('source note is absent when picks are shown', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpCard(tester, items: [rec('s1', name: 'Bean A')]);
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Bean A'), findsOneWidget);
    final l10n = AppLocalizations.of(tester.element(find.byType(ForYouCard)))!;
    expect(find.text(l10n.stockSourceNote), findsNothing);
    expect(find.bySemanticsIdentifier('forYouSourceNote'), findsNothing);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  group('buildStockProductUrl', () {
    test('adds the three UTM parameters with the for_you campaign', () {
      final uri = buildStockProductUrl(
        'https://shop.example.com/beans/abc',
        campaign: 'for_you',
      );
      expect(uri, isNotNull);
      expect(uri!.queryParameters['utm_source'], 'timer.coffee');
      expect(uri.queryParameters['utm_medium'], 'app');
      expect(uri.queryParameters['utm_campaign'], 'for_you');
    });

    test('the roaster-profile surface carries its own campaign', () {
      final uri = buildStockProductUrl(
        'https://shop.example.com/beans/abc',
        campaign: 'roaster_profile',
      );
      expect(uri!.queryParameters['utm_campaign'], 'roaster_profile');
    });

    test('preserves existing query parameters', () {
      final uri = buildStockProductUrl(
        'https://shop.example.com/beans/abc?grind=filter&size=250g',
        campaign: 'for_you',
      );
      expect(uri!.queryParameters['grind'], 'filter');
      expect(uri.queryParameters['size'], '250g');
      expect(uri.queryParameters['utm_campaign'], 'for_you');
    });

    test('does not overwrite a utm_* the URL already has', () {
      final uri = buildStockProductUrl(
        'https://shop.example.com/a?utm_source=newsletter',
        campaign: 'for_you',
      );
      expect(uri!.queryParameters['utm_source'], 'newsletter');
      expect(uri.queryParameters['utm_medium'], 'app',
          reason: 'missing UTM params are still added');
    });

    test('keeps http (not just https)', () {
      final uri = buildStockProductUrl(
        'http://shop.example.com/a',
        campaign: 'for_you',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'http');
    });

    test('rejects non-http(s), junk and empty', () {
      expect(buildStockProductUrl('javascript:alert(1)', campaign: 'for_you'),
          isNull);
      expect(
          buildStockProductUrl('ftp://files.example.com/a.zip',
              campaign: 'for_you'),
          isNull);
      expect(buildStockProductUrl('not a url', campaign: 'for_you'), isNull);
      expect(buildStockProductUrl('   ', campaign: 'for_you'), isNull);
      expect(buildStockProductUrl('', campaign: 'for_you'), isNull);
      expect(buildStockProductUrl(null, campaign: 'for_you'), isNull);
    });
  });

  group('dismiss', () {
    testWidgets('"Not for me" removes the row and reports the dismissal',
        (tester) async {
      final env = await _pumpCard(
        tester,
        items: [rec('s1', name: 'Bean A'), rec('s2', name: 'Bean B')],
      );
      await tester.pumpAndSettle();
      expect(find.text('Bean A'), findsOneWidget);

      await tester.tap(find.text(_dismissLabel).first);
      await tester.pumpAndSettle();

      expect(env.client.dismissedIds, ['s1']);
      expect(find.text('Bean A'), findsNothing);
      expect(find.text('Bean B'), findsOneWidget,
          reason: 'the next pick takes the collapsed first row');
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_showMoreLabel), findsNothing,
          reason: 'one pick left → the expand control disappears');
    });

    testWidgets('dismissing the last row removes the card', (tester) async {
      final env = await _pumpCard(tester, items: [rec('s1', name: 'Bean A')]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(_dismissLabel));
      await tester.pumpAndSettle();

      expect(env.client.dismissedIds, ['s1']);
      expect(env.provider.state, RecommendationState.hidden);
      expect(find.text(_title), findsNothing);
    });
  });

  group('ensureLoaded triggers', () {
    testWidgets('once after the first frame, never during build, again on '
        'locale change', (tester) async {
      final gate = Completer<RecommendationResult?>();
      final client = _FakeClient()..fetchImpl = (_) => gate.future;
      final env = await _pumpCard(tester, client: client);

      expect(env.provider.ensureLoadedCalls, 1,
          reason: 'exactly one call, issued after the first frame');
      expect(env.provider.locales, ['en']);
      expect(env.provider.firstCallDuringBuildPhase, isFalse,
          reason: 'must never run synchronously inside build');

      await tester.pump();
      expect(env.provider.ensureLoadedCalls, 1,
          reason: 'a further frame must not re-trigger');

      gate.complete(RecommendationResult(
        hasRecommendations: true,
        items: [rec('s1')],
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _Harness(provider: env.provider, locale: const Locale('de')),
      );
      expect(env.provider.ensureLoadedCalls, 2);
      expect(env.provider.locales, ['en', 'de']);
    });
  });

  group('layout stress', () {
    Future<void> pumpStress(
      WidgetTester tester,
      Locale locale,
      String longName,
      String longReason,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpCard(
        tester,
        locale: locale,
        textScaler: TextScaler.linear(1.3),
        items: [
          rec('s1', name: longName, reason: longReason),
          rec(
            's2',
            name: longName,
            mode: 'your_roaster',
            productUrl: 'https://shop.example.com/beans/long?grind=filter',
            roaster: 'Eine Sehr Lange Rösterei Bezeichnung GmbH & Co. KG',
          ),
          rec('s3', name: longName, origins: ['BR', 'ET', 'ID']),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('320x640, text scale 1.3, 120-char name, de', (tester) async {
      await pumpStress(
        tester,
        const Locale('de'),
        'Kaffeebohnen' * 10,
        'Ausgewählt, weil du helle Röstungen mit Fruchtnoten magst und '
            'diese Bohne genau zu deinen letzten Brühungen passt. ',
      );
      expect(find.text('Für dich'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Mehr anzeigen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'expanded rows must fit the same small surface');
    });

    testWidgets('320x640, text scale 1.3, 120-char name, ru', (tester) async {
      await pumpStress(
        tester,
        const Locale('ru'),
        'Кофейное зерно ' * 8,
        'Подобрано, потому что вам нравятся светлая обжарка и фруктовые '
            'ноты, и это зерно идеально подходит под ваши заваривания. ',
      );
      expect(find.text('Для вас'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Показать ещё'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('320x640, text scale 1.3, 120-char name, ar (RTL)',
        (tester) async {
      await pumpStress(
        tester,
        const Locale('ar'),
        'حبوب البن الممتازة ' * 7,
        'تم اختيار هذا لأنك تفضل التحميص الفاتح مع نكهات الفواكه، وهو '
            'مناسب تماماً لتحضيراتك الأخيرة. ',
      );
      expect(find.text('لك'), findsOneWidget);
      // The hide control renders at the trailing (left) edge in RTL.
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('عرض المزيد'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    testWidgets('identifiers exist and the tree is valid', (tester) async {
      final handle = tester.ensureSemantics();

      await _pumpCard(
        tester,
        items: [
          rec('s1', productUrl: 'https://shop.example.com/beans/x'),
          rec('s2'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('forYouCard'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouHide'), findsOneWidget);
      // Collapsed: only the first pick is in the tree.
      expect(find.bySemanticsIdentifier('forYouItem_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouItem_1'), findsNothing,
          reason: 'the second pick is hidden while collapsed');
      expect(find.bySemanticsIdentifier('forYouView_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouDismiss_0'), findsOneWidget);

      await tester.tap(find.text(_showMoreLabel));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('forYouItem_1'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouDismiss_1'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouView_1'), findsNothing,
          reason: 'second item has no usable productUrl');
      expect(tester.takeException(), isNull);

      // Must be disposed inside the test body: the binding verifies handles
      // are gone before tearDowns run.
      handle.dispose();
    });
  });

  group('expansion, hiding and launch mode', () {
    // Same real-buffer pattern as the analytics group above.
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AnalyticsService.resetForTesting();
      await AnalyticsService.initialize(await SharedPreferences.getInstance());
      AnalyticsService.sendOverride = (_) async {};
    });
    tearDown(AnalyticsService.resetForTesting);

    List<Map<String, dynamic>> events(String name) => AnalyticsService
        .instance
        .bufferedEventsForTesting
        .where((event) => event['event_name'] == name)
        .toList();

    testWidgets('collapse → expand → collapse fires for_you_expanded only '
        'on expand, with the rows now shown', (tester) async {
      await _pumpCard(
        tester,
        items: [
          rec('s1', name: 'Bean A'),
          rec('s2', name: 'Bean B'),
          rec('s3', name: 'Bean C'),
          rec('s4', name: 'Bean D'),
        ],
      );
      await tester.pumpAndSettle();

      // Collapsed: the first pick only, one card, no dividers, Show more
      // present.
      expect(find.text('Bean A'), findsOneWidget);
      expect(find.text('Bean B'), findsNothing);
      expect(find.byType(StockBeanCard), findsOneWidget);
      expect(find.text(_showMoreLabel), findsOneWidget);

      await tester.tap(find.text(_showMoreLabel));
      await tester.pumpAndSettle();

      // maxItems caps the expansion at three cards.
      expect(find.text('Bean A'), findsOneWidget);
      expect(find.text('Bean B'), findsOneWidget);
      expect(find.text('Bean C'), findsOneWidget);
      expect(find.text('Bean D'), findsNothing);
      expect(find.byType(StockBeanCard), findsNWidgets(3));
      expect(find.byType(Divider), findsNothing,
          reason: 'separate cards have no dividers between rows');
      expect(find.text(_showLessLabel), findsOneWidget);
      expect(events('for_you_expanded'), hasLength(1));
      expect(events('for_you_expanded').single['category'], 'beans');
      expect(events('for_you_expanded').single['properties'], {'count': 3});

      // Three full cards are taller than the 800×600 test surface.
      await tester.ensureVisible(find.text(_showLessLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_showLessLabel));
      await tester.pumpAndSettle();

      expect(find.text('Bean A'), findsOneWidget);
      expect(find.text('Bean B'), findsNothing);
      expect(find.text(_showMoreLabel), findsOneWidget);
      // Collapsing must not fire the event again.
      expect(events('for_you_expanded'), hasLength(1));
    });

    testWidgets('a single pick has no expand control', (tester) async {
      await _pumpCard(tester, items: [rec('s1', name: 'Bean A')]);
      await tester.pumpAndSettle();
      expect(find.text('Bean A'), findsOneWidget);
      expect(find.text(_showMoreLabel), findsNothing);
      expect(find.text(_showLessLabel), findsNothing);
    });

    testWidgets('hide control opts out, hides the card and offers Undo; '
        'Undo opts back in and reloads', (tester) async {
      final env = await _pumpCard(tester, items: [rec('s1', name: 'Bean A')]);
      await tester.pumpAndSettle();
      expect(find.text('Bean A'), findsOneWidget);
      final callsBefore = env.provider.ensureLoadedCalls;

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(env.provider.optedOut, isTrue);
      expect(find.text(_title), findsNothing);
      expect(find.text('Bean A'), findsNothing);
      expect(find.text(_hiddenMessage), findsOneWidget);
      expect(find.text(_undoLabel), findsOneWidget);
      expect(env.client.deleteMineCount, 0,
          reason: 'the server deletion waits for the snackbar, so Undo '
              'loses nothing');
      expect(
        events('for_you_setting_toggled').map((e) => e['properties']),
        [
          {'enabled': false, 'source': 'card'},
        ],
      );
      expect(
        events('for_you_setting_toggled').map((e) => e['category']),
        everyElement('beans'),
      );

      await tester.tap(find.text(_undoLabel));
      await tester.pumpAndSettle();

      expect(env.provider.optedOut, isFalse);
      expect(env.provider.ensureLoadedCalls, callsBefore + 1,
          reason: 'Undo must reload — setOptedOut(false) resets to idle, so '
              'without ensureLoaded the card would stay empty');
      expect(env.provider.locales.last, 'en');
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Bean A'), findsOneWidget);
      expect(
        events('for_you_setting_toggled').map((e) => e['properties']),
        [
          {'enabled': false, 'source': 'card'},
          {'enabled': true, 'source': 'card_undo'},
        ],
      );
      expect(env.client.deleteMineCount, 0, reason: 'Undo deletes nothing');
      expect(tester.takeException(), isNull);
    });

    testWidgets('hide control deletes on the server once the snackbar '
        'closes without Undo', (tester) async {
      final env = await _pumpCard(tester, items: [rec('s1', name: 'Bean A')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(env.client.deleteMineCount, 0);

      ScaffoldMessenger.of(
        tester.element(find.text(_hiddenMessage)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      expect(env.provider.optedOut, isTrue);
      expect(env.client.deleteMineCount, 1);
      expect(tester.takeException(), isNull);
    });

    test('launch mode: in-app browser natively, platform default on web', () {
      expect(stockLaunchMode(isWeb: false), LaunchMode.inAppBrowserView);
      expect(stockLaunchMode(isWeb: true), LaunchMode.platformDefault);
    });
  });
}
