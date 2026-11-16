import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:coffee_timer/services/clients/roaster_stock_client.dart';
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:coffee_timer/widgets/roaster_stock_section.dart';
import 'package:coffee_timer/widgets/stock_bean_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sectionTitle = 'In stock now';
const _viewLabel = 'View at roaster';
const _showMoreLabel = 'Show more';
const _showLessLabel = 'Show less';
const _forYouMarker = 'For you';
const _decafMarker = 'Decaf';
const _sourceNote =
    'Listings come from roasters’ public websites and may be out of date. '
    'Timer.Coffee isn’t responsible for content on other sites.';
const _sourceNoteDe = 'Die Auflistungen stammen von den öffentlichen '
    'Webseiten der Röstereien und können veraltet sein. Timer.Coffee ist '
    'nicht für Inhalte auf anderen Seiten verantwortlich.';
const _sourceNoteRu = 'Списки взяты с публичных сайтов обжарщиков и могут '
    'быть устаревшими. Timer.Coffee не отвечает за содержимое других сайтов.';
const _sourceNoteAr = 'تأتي القوائم من مواقع المحامص العامة وقد تكون قديمة. '
    'لا يتحمل Timer.Coffee مسؤولية المحتوى على المواقع الأخرى.';

/// Hand-written fake — no Supabase anywhere in these tests.
class _FakeStockClient implements RoasterStockClient {
  _FakeStockClient({this.result, this.error});

  RoasterStockResult? result;
  Object? error;

  int fetchCount = 0;
  String? fetchedSlug;
  int? fetchedLimit;
  final List<String> clickedIds = [];

  @override
  Future<RoasterStockResult?> fetchRoasterStock(String slug,
      {int limit = 30}) async {
    fetchCount++;
    fetchedSlug = slug;
    fetchedLimit = limit;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<void> logReferredClick(String stockId) async {
    clickedIds.add(stockId);
  }
}

class _FakeRecClient implements BeanRecommendationClient {
  _FakeRecClient(this.items);

  final List<BeanRecommendation> items;

  @override
  Future<RecommendationResult?> fetch({String? locale}) async =>
      RecommendationResult(hasRecommendations: true, items: items);

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async =>
      BeanRecommendationStatus.ok;

  @override
  Future<void> dismiss(String stockId) async {}

  @override
  Future<void> logReferredClick(String stockId, String surface) async {}

  @override
  Future<void> deleteMine() async {}
}

/// Records every launch at the `plugins.flutter.io/url_launcher` method
/// channel — the single seam every `url_launcher` mode funnels through
/// (its default `launchUrl` derives `useSafariVC`/`useWebView` from the
/// requested mode). Proves which URL (campaign included) was opened and
/// whether it went to the in-app browser, and keeps the tests off real
/// platform plugins.
class _RecordingLauncher {
  final List<({String url, bool inApp})> launched = [];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        launched.add((
          url: call.arguments['url'] as String,
          inApp: call.arguments['useWebView'] as bool,
        ));
        return true;
      },
    );
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
  }
}

RoasterStockItem stock(
  String id, {
  String name = 'Test Bean',
  String? imageUrl,
  List<String> origins = const [],
  bool isDecaf = false,
  String? productUrl,
}) =>
    RoasterStockItem(
      stockId: id,
      beanName: name,
      imageUrl: imageUrl,
      originCountryCodes: origins,
      isDecaf: isDecaf,
      productUrl: productUrl,
    );

BeanRecommendation pick(String id, {String name = 'Picked Bean'}) =>
    BeanRecommendation(
      stockId: id,
      beanName: name,
      roasterName: 'Test Roaster',
    );

Future<RecommendationProvider> _picksProvider(
  List<BeanRecommendation> items,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final provider = RecommendationProvider(
    client: _FakeRecClient(items),
    currentUserId: () => 'user-1',
    featureFlagEnabled: () => true,
    countryCodeLookup: (_) async => null,
    prefs: prefs,
  );
  await provider.ensureLoaded('en');
  return provider;
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required RoasterStockClient client,
  Map<String, bool> flags = const {FeatureFlagKeys.beanRecommendations: true},
  RecommendationProvider? picks,
  String? highlightStockId,
  Widget Function(Widget)? wrapSection,
  String? Function()? currentUserId,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final section = RoasterStockSection(
    slug: 'botanica',
    roasterName: 'Botanica Coffee Roasters',
    highlightStockId: highlightStockId,
    logoUrl: 'https://cdn.example.com/logo.png',
    logoMirrorUrl: 'https://mirror.example.com/logo.png',
    client: client,
    currentUserId: currentUserId ?? (() => 'user-1'),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<Map<String, bool>>.value(value: flags),
        if (picks != null)
          ChangeNotifierProvider<RecommendationProvider>.value(value: picks),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: Scaffold(
              body: wrapSection?.call(section) ?? ListView(children: [section]),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    AnalyticsService.sendOverride = (_) async {};
  });
  tearDown(AnalyticsService.resetForTesting);

  List<Map<String, dynamic>> events(String name) => AnalyticsService
      .instance.bufferedEventsForTesting
      .where((event) => event['event_name'] == name)
      .toList();

  group('visibility and fetching', () {
    testWidgets('flag off → nothing rendered and no fetch', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1')]),
      );
      await _pumpSection(tester, client: client, flags: const {});
      await tester.pumpAndSettle();

      expect(find.byType(SectionCard), findsNothing);
      expect(find.text(_sectionTitle), findsNothing);
      expect(client.fetchCount, 0,
          reason: 'a hidden section must not touch the network');
      expect(events('roaster_stock_shown'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading → nothing rendered, then the section appears',
        (tester) async {
      final gate = Completer<RoasterStockResult?>();
      final gated = _GatedClient(gate);
      await _pumpSection(tester, client: gated);
      await tester.pump();
      expect(find.byType(SectionCard), findsNothing,
          reason: 'no spinner while loading');
      expect(events('roaster_stock_shown'), isEmpty);

      gate.complete(RoasterStockResult(
        total: 1,
        items: [stock('s1', name: 'Bean 1')],
      ));
      await tester.pumpAndSettle();
      expect(find.text(_sectionTitle), findsOneWidget);
      expect(find.text('Bean 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error → nothing rendered, no exception escapes',
        (tester) async {
      final client = _FakeStockClient(error: Exception('rpc failed'));
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(client.fetchCount, 1);
      expect(find.byType(SectionCard), findsNothing);
      expect(events('roaster_stock_shown'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty stock → nothing rendered', (tester) async {
      final client = _FakeStockClient(
        result: const RoasterStockResult(total: 0, items: []),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(client.fetchCount, 1);
      expect(find.byType(SectionCard), findsNothing);
      expect(events('roaster_stock_shown'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fetches once per slug with the section slug and the 30 '
        'limit', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1')]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(client.fetchCount, 1, reason: 'loads once, not per rebuild');
      expect(client.fetchedSlug, 'botanica');
      expect(client.fetchedLimit, 30);
      expect(tester.takeException(), isNull);
    });
  });

  group('section expansion', () {
    testWidgets('starts expanded; header hides and restores cards and note '
        'without repeating analytics or fetching', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1', name: 'Bean 1')]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.text('Bean 1').hitTestable(), findsOneWidget);
      expect(find.text(_sourceNote).hitTestable(), findsOneWidget);
      expect(events('roaster_stock_shown'), hasLength(1));

      await tester.tap(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      expect(find.text(_sectionTitle).hitTestable(), findsOneWidget);
      expect(find.byType(StockBeanCard), findsNothing);
      expect(find.text(_sourceNote), findsNothing);
      expect(events('roaster_stock_shown'), hasLength(1));

      await tester.tap(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      expect(find.text('Bean 1').hitTestable(), findsOneWidget);
      expect(find.text(_sourceNote).hitTestable(), findsOneWidget);
      expect(events('roaster_stock_shown'), hasLength(1));
      expect(client.fetchCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Show more state survives header collapse and expansion',
        (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          for (var i = 0; i < 6; i++) stock('s$i', name: 'Bean $i'),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNWidgets(4));

      await tester.ensureVisible(find.text(_showMoreLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_showMoreLabel));
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNWidgets(6));

      await tester.ensureVisible(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNothing);
      await tester.tap(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNWidgets(6));
      expect(find.text(_showLessLabel), findsOneWidget);
      expect(find.text(_showMoreLabel), findsNothing);
      expect(events('roaster_stock_shown'), hasLength(1));

      await tester.ensureVisible(find.text(_showLessLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_showLessLabel));
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a highlight rebuild does not scroll a collapsed section',
        (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var scrollStarts = 0;
      Widget wrapSection(Widget section) =>
          NotificationListener<ScrollStartNotification>(
            onNotification: (_) {
              scrollStarts++;
              return false;
            },
            child: SingleChildScrollView(
              controller: controller,
              child: Column(children: [
                const SizedBox(height: 1000),
                section,
                const SizedBox(height: 1000),
              ]),
            ),
          );
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1', name: 'Bean 1')]),
      );
      await _pumpSection(tester, client: client, wrapSection: wrapSection);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_sectionTitle));
      await tester.pumpAndSettle();
      controller.jumpTo(0);
      scrollStarts = 0;

      await _pumpSection(
        tester,
        client: client,
        highlightStockId: 's1',
        wrapSection: wrapSection,
      );
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNothing);
      expect(controller.offset, 0);
      expect(scrollStarts, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('source note', () {
    testWidgets('part of the section: shown under the cards when it is',
        (tester) async {
      final handle = tester.ensureSemantics();
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1', name: 'Bean 1')]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.text(_sourceNote), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('roasterStockSourceNote'),
        findsOneWidget,
      );
      expect(
        tester.getBottomRight(find.text(_sourceNote)).dy,
        greaterThan(tester.getBottomRight(find.text('Bean 1')).dy),
        reason: 'the note sits under the cards (and the expand control)',
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('goes with the section: absent when the flag is off',
        (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1')]),
      );
      await _pumpSection(tester, client: client, flags: const {});
      await tester.pumpAndSettle();

      expect(find.byType(SectionCard), findsNothing);
      expect(find.text(_sourceNote), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('cards', () {
    testWidgets('up to 4 cards collapsed, Show more reveals the rest, '
        'Show less collapses', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(
          total: 6,
          items: List.generate(
            6,
            (i) => stock(
              's$i',
              name: 'Bean $i',
              productUrl: 'https://shop.example.com/b$i',
            ),
          ),
        ),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.text(_sectionTitle), findsOneWidget);
      expect(find.byType(StockBeanCard), findsNWidgets(4));
      expect(find.text('Bean 4'), findsNothing);
      expect(find.text(_showMoreLabel), findsOneWidget);

      // Four cards are taller than the 800×600 test surface.
      await tester.ensureVisible(find.text(_showMoreLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_showMoreLabel));
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNWidgets(6));
      expect(find.text('Bean 4'), findsOneWidget);
      expect(find.text('Bean 5'), findsOneWidget);
      expect(find.text(_showLessLabel), findsOneWidget);

      await tester.ensureVisible(find.text(_showLessLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_showLessLabel));
      await tester.pumpAndSettle();
      expect(find.byType(StockBeanCard), findsNWidgets(4));
      expect(find.text(_showMoreLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fewer than 4 items → no expand control', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(
          total: 2,
          items: [stock('s1', name: 'Bean 1'), stock('s2', name: 'Bean 2')],
        ),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.byType(StockBeanCard), findsNWidgets(2));
      expect(find.text(_showMoreLabel), findsNothing);
      expect(find.text(_showLessLabel), findsNothing);
    });

    testWidgets('origin names joined with the summary separator, unknown '
        'codes skipped', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock('s1', origins: ['BR', 'CO']),
          stock('s2', origins: ['XX', 'QQ']),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.text('Brazil · Colombia'), findsOneWidget);
      expect(find.textContaining('·'), findsOneWidget,
          reason: 'the second item has no nameable origins → line omitted');
      expect(tester.takeException(), isNull);
    });

    testWidgets('decaf marker appended after a separator', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock('s1', origins: ['CO'], isDecaf: true),
          stock('s2', isDecaf: true),
          stock('s3'),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.text('Colombia · $_decafMarker'), findsOneWidget);
      expect(find.text(_decafMarker), findsOneWidget,
          reason: 'no origins → the marker alone, without a leading '
              'separator');
      expect(find.text('· $_decafMarker'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no price shown', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(
          items: [stock('s1', productUrl: 'https://shop.example.com/b')],
        ),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.textContaining('€'), findsNothing);
      expect(find.textContaining('EUR'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('picks', () {
    testWidgets('pinned first, marker on the secondary line, counts in the '
        'shown event', (tester) async {
      final picks = await _picksProvider([
        pick('s2'),
        pick('not-in-stock'),
      ]);
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock('s1', name: 'Bean 1', origins: ['CO']),
          stock('s2', name: 'Bean 2'),
          stock('s3', name: 'Bean 3'),
        ]),
      );
      await _pumpSection(tester, client: client, picks: picks);
      await tester.pumpAndSettle();

      // The pick (Bean 2, stock s2) moved to the front.
      final cards = tester.widgetList<StockBeanCard>(
        find.descendant(
          of: find.byType(SectionCard),
          matching: find.byType(StockBeanCard),
        ),
      ).toList();
      expect(cards.map((c) => c.title), ['Bean 2', 'Bean 1', 'Bean 3']);
      expect(find.text(_forYouMarker), findsOneWidget);
      expect(find.text('Test Roaster · $_forYouMarker'), findsNothing,
          reason: 'the marker joins the stock item’s own line, not a '
              'roaster line');
      expect(
        find.text('$_forYouMarker · $_decafMarker'),
        findsNothing,
      );
      // The pinned card's secondary line is exactly the marker (no origins,
      // not decaf).
      expect(cards.first.subtitle, _forYouMarker);

      expect(events('roaster_stock_shown'), hasLength(1));
      expect(events('roaster_stock_shown').single['category'], 'beans');
      expect(events('roaster_stock_shown').single['properties'], {
        'count': 3,
        'total': 3,
        'picks': 1,
        'highlighted': false,
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('works without a RecommendationProvider in scope',
        (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1', name: 'Bean 1')]),
      );
      await _pumpSection(tester, client: client, picks: null);
      await tester.pumpAndSettle();

      expect(find.text(_sectionTitle), findsOneWidget);
      expect(find.text('Bean 1'), findsOneWidget);
      expect(events('roaster_stock_shown').single['properties'], {
        'count': 1,
        'total': 1,
        'picks': 0,
        'highlighted': false,
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('a provider whose state is not ready contributes no picks',
        (tester) async {
      final picks = await _picksProvider([pick('s2')]);
      await picks.setOptedOut(true);
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock('s1', name: 'Bean 1'),
          stock('s2', name: 'Bean 2'),
        ]),
      );
      await _pumpSection(tester, client: client, picks: picks);
      await tester.pumpAndSettle();

      final cards = tester.widgetList<StockBeanCard>(
        find.descendant(
          of: find.byType(SectionCard),
          matching: find.byType(StockBeanCard),
        ),
      ).toList();
      expect(cards.map((c) => c.title), ['Bean 1', 'Bean 2'],
          reason: 'opted out → no picks → no pinning, no marker');
      expect(find.text(_forYouMarker), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('highlighted stock', () {
    for (final alreadyPicked in [false, true]) {
      testWidgets('highlighted bean is first and marked while collapsed '
          '(already picked: $alreadyPicked)', (tester) async {
        final picks = await _picksProvider([
          for (var i = 1; i <= 4; i++) pick('s$i'),
          if (alreadyPicked) pick('s5'),
        ]);
        final client = _FakeStockClient(
          result: RoasterStockResult(items: [
            for (var i = 0; i < 6; i++) stock('s$i', name: 'Bean $i'),
          ]),
        );
        await _pumpSection(
          tester,
          client: client,
          picks: picks,
          highlightStockId: 's5',
        );
        await tester.pumpAndSettle();

        final cards = tester
            .widgetList<StockBeanCard>(find.byType(StockBeanCard))
            .toList();
        expect(cards.map((card) => card.title),
            ['Bean 5', 'Bean 1', 'Bean 2', 'Bean 3']);
        expect(cards.first.subtitle, _forYouMarker);
        expect(find.text('Bean 4'), findsNothing);
        expect(find.text(_showMoreLabel), findsOneWidget);
        expect(events('roaster_stock_shown').single['properties'], {
          'count': 4,
          'total': 6,
          'picks': alreadyPicked ? 5 : 4,
          'highlighted': true,
        });
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('missing highlighted bean preserves pinned order and counts',
        (tester) async {
      final picks = await _picksProvider([
        for (var i = 1; i <= 4; i++) pick('s$i'),
      ]);
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          for (var i = 0; i < 6; i++) stock('s$i', name: 'Bean $i'),
        ]),
      );
      await _pumpSection(
        tester,
        client: client,
        picks: picks,
        highlightStockId: 'sold-out',
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<StockBeanCard>(find.byType(StockBeanCard))
          .toList();
      expect(cards.map((card) => card.title),
          ['Bean 1', 'Bean 2', 'Bean 3', 'Bean 4']);
      expect(cards.map((card) => card.subtitle), everyElement(_forYouMarker));
      expect(events('roaster_stock_shown').single['properties'], {
        'count': 4,
        'total': 6,
        'picks': 4,
        'highlighted': false,
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('highlight works without an enclosing Scrollable',
        (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1', name: 'Bean 1')]),
      );
      await _pumpSection(
        tester,
        client: client,
        highlightStockId: 's1',
        wrapSection: (section) => section,
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Bean 1'), findsOneWidget);
      expect(find.text(_forYouMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reveals section after loading, only once across rebuilds',
        (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var scrollStarts = 0;
      Widget wrapSection(Widget section) =>
          NotificationListener<ScrollStartNotification>(
            onNotification: (_) {
              scrollStarts++;
              return false;
            },
            child: SingleChildScrollView(
              controller: controller,
              child: Column(children: [
                const SizedBox(height: 1000),
                section,
                const SizedBox(height: 1000),
              ]),
            ),
          );
      final gate = Completer<RoasterStockResult?>();
      final client = _GatedClient(gate);
      await _pumpSection(
        tester,
        client: client,
        highlightStockId: 's1',
        wrapSection: wrapSection,
      );
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
      expect(scrollStarts, 0);

      gate.complete(RoasterStockResult(items: [stock('s1', name: 'Bean 1')]));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(scrollStarts, 1);
      final sectionTop = tester.getTopLeft(find.byType(SectionCard)).dy;
      expect(sectionTop, inInclusiveRange(0, 100));
      expect(find.text('Bean 1').hitTestable(), findsOneWidget);

      controller.jumpTo(0);
      scrollStarts = 0;
      await _pumpSection(
        tester,
        client: client,
        highlightStockId: 's1',
        wrapSection: wrapSection,
      );
      await tester.pumpAndSettle();
      expect(controller.offset, 0,
          reason: 'a rebuild must not scroll the user back to the section');
      expect(scrollStarts, 0);
      expect(events('roaster_stock_shown'), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('link opening', () {
    testWidgets('opens with the roaster_profile campaign in the in-app '
        'browser and logs the click when signed in', (tester) async {
      final launcher = _RecordingLauncher()..install();
      addTearDown(launcher.uninstall);

      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock(
            's1',
            name: 'Bean 1',
            productUrl: 'https://shop.example.com/b1?grind=filter',
          ),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      await tester.tap(find.text(_viewLabel));
      await tester.pumpAndSettle();

      expect(launcher.launched, hasLength(1));
      final launch = launcher.launched.single;
      expect(launch.url, startsWith('https://shop.example.com/b1'));
      expect(launch.url, contains('utm_campaign=roaster_profile'));
      expect(launch.url, contains('utm_source=timer.coffee'));
      expect(launch.inApp, isTrue,
          reason: 'the request went through the in-app browser path');
      expect(client.clickedIds, ['s1']);

      expect(events('roaster_stock_link_opened'), hasLength(1));
      expect(events('roaster_stock_link_opened').single['category'], 'beans');
      expect(events('roaster_stock_link_opened').single['properties'], {
        'stock_id': 's1',
        'position': 0,
        'is_pick': false,
      });
      expect(tester.takeException(), isNull);
    });

    testWidgets('signed out → the link still opens, no click is logged',
        (tester) async {
      final launcher = _RecordingLauncher()..install();
      addTearDown(launcher.uninstall);

      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock(
            's1',
            name: 'Bean 1',
            productUrl: 'https://shop.example.com/b1',
          ),
        ]),
      );
      await _pumpSection(tester, client: client, currentUserId: () => null);
      await tester.pumpAndSettle();

      await tester.tap(find.text(_viewLabel));
      await tester.pumpAndSettle();

      expect(launcher.launched, hasLength(1),
          reason: 'opening the link must not depend on being signed in');
      expect(client.clickedIds, isEmpty);
      expect(events('roaster_stock_link_opened'), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the card does the same as the button', (tester) async {
      final launcher = _RecordingLauncher()..install();
      addTearDown(launcher.uninstall);

      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock(
            's1',
            name: 'Bean 1',
            productUrl: 'https://shop.example.com/b1',
          ),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bean 1'));
      await tester.pumpAndSettle();

      expect(launcher.launched, hasLength(1));
      expect(launcher.launched.single.url, contains('roaster_profile'));
      expect(client.clickedIds, ['s1']);
      expect(events('roaster_stock_link_opened'), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no usable product_url → no button, card tap does nothing',
        (tester) async {
      final launcher = _RecordingLauncher()..install();
      addTearDown(launcher.uninstall);

      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock('s1', name: 'Bean 1', productUrl: 'javascript:alert(1)'),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.text(_viewLabel), findsNothing);
      await tester.tap(find.text('Bean 1'));
      await tester.pumpAndSettle();
      expect(launcher.launched, isEmpty);
      expect(client.clickedIds, isEmpty);
      expect(events('roaster_stock_link_opened'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the shown event fires once across rebuilds', (tester) async {
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [stock('s1', name: 'Bean 1')]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(events('roaster_stock_shown'), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    testWidgets('identifiers exist and the tree is valid', (tester) async {
      final handle = tester.ensureSemantics();
      final client = _FakeStockClient(
        result: RoasterStockResult(items: [
          stock('s1', name: 'Bean 1', productUrl: 'https://shop.example.com'),
          stock('s2', name: 'Bean 2'),
          stock('s3', name: 'Bean 3'),
        ]),
      );
      await _pumpSection(tester, client: client);
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier('roasterStockSection'), findsOneWidget);
      expect(find.bySemanticsIdentifier('roasterStockItem_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('roasterStockItem_1'), findsOneWidget);
      expect(find.bySemanticsIdentifier('roasterStockItem_2'), findsOneWidget);
      expect(find.bySemanticsIdentifier('roasterStockItem_3'), findsNothing);
      expect(find.bySemanticsIdentifier('roasterStockView_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('roasterStockSourceNote'),
          findsOneWidget);
      expect(find.bySemanticsIdentifier('roasterStockView_1'), findsNothing,
          reason: 'the second item has no usable productUrl');
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  group('layout stress (320x640, text scale 1.3)', () {
    Future<void> pumpStress(
      WidgetTester tester,
      Locale locale,
      String longName,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _FakeStockClient(
        result: RoasterStockResult(
          total: 6,
          items: List.generate(
            6,
            (i) => stock(
              's$i',
              name: longName,
              origins: i.isEven ? ['BR', 'XX'] : [],
              isDecaf: i.isOdd,
              productUrl: 'https://shop.example.com/very/long/path/b$i',
            ),
          ),
        ),
      );
      await _pumpSection(
        tester,
        client: client,
        locale: locale,
        textScaler: TextScaler.linear(1.3),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('120-char names, de', (tester) async {
      await pumpStress(tester, const Locale('de'), 'Kaffeebohnen' * 10);
      expect(find.text('Jetzt vorrätig'), findsOneWidget);
      expect(find.text(_sourceNoteDe), findsOneWidget,
          reason: 'the long German note must wrap without overflowing');
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Mehr anzeigen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mehr anzeigen'));
      await tester.pumpAndSettle();
      expect(find.text(_sourceNoteDe), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'expanded cards must fit the same small surface');
    });

    testWidgets('120-char names, ru', (tester) async {
      await pumpStress(tester, const Locale('ru'), 'Кофейное зерно ' * 8);
      expect(find.text('Сейчас в наличии'), findsOneWidget);
      expect(find.text(_sourceNoteRu), findsOneWidget,
          reason: 'the long Russian note must wrap without overflowing');
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Показать ещё'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Показать ещё'));
      await tester.pumpAndSettle();
      expect(find.text(_sourceNoteRu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('120-char names, ar (RTL)', (tester) async {
      await pumpStress(tester, const Locale('ar'), 'حبوب البن الممتازة ' * 7);
      expect(find.text('متوفر الآن'), findsOneWidget);
      expect(find.text(_sourceNoteAr), findsOneWidget,
          reason: 'the long Arabic note must wrap without overflowing (RTL)');
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('عرض المزيد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض المزيد'));
      await tester.pumpAndSettle();
      expect(find.text(_sourceNoteAr), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// A client whose fetch is parked on a [Completer] — for the loading state.
class _GatedClient implements RoasterStockClient {
  _GatedClient(this.gate);

  final Completer<RoasterStockResult?> gate;

  @override
  Future<RoasterStockResult?> fetchRoasterStock(String slug,
          {int limit = 30}) =>
      gate.future;

  @override
  Future<void> logReferredClick(String stockId) async {}
}
