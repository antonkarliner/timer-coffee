import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:coffee_timer/widgets/for_you_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// English ARB strings the tests interact with.
const _title = 'For you';
const _subtitle = 'In stock now, picked from what you brew';
const _yourRoasterMarker = 'Your roaster';
const _viewLabel = 'View at roaster';
const _dismissLabel = 'Not for me';

/// Hand-written fake — no Supabase anywhere in these tests (same shape as
/// the one in test/unit/providers/recommendation_provider_test.dart).
class _FakeClient implements BeanRecommendationClient {
  RecommendationResult? fetchResult;
  Future<RecommendationResult?> Function(String? locale)? fetchImpl;
  Object? dismissError;

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
  }) async =>
      BeanRecommendationStatus.ok;

  @override
  Future<void> dismiss(String stockId) async {
    if (dismissError != null) throw dismissError!;
    dismissedIds.add(stockId);
  }

  @override
  Future<void> logReferredClick(String stockId, String surface) async {
    clickedIds.add(stockId);
  }

  @override
  Future<void> deleteMine() async {}
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
}) async {
  final c = client ?? _FakeClient();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final provider = _CountingProvider(
    client: c,
    currentUserId: () => 'user-1',
    featureFlagEnabled: () => flagOn,
    countryCodeLookup: (localeCode) async => 'DE',
    prefs: prefs,
  );
  if (items.isNotEmpty) {
    c.fetchResult = RecommendationResult(
      hasRecommendations: true,
      items: items,
    );
  }
  addTearDown(provider.dispose);
  await tester.pumpWidget(
    _Harness(
      provider: provider,
      locale: locale,
      maxItems: maxItems,
      textScaler: textScaler,
    ),
  );
  return (provider: provider, client: c);
}

void main() {
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
    testWidgets('ready with 5 items → exactly maxItems rows', (tester) async {
      final items = List.generate(
        5,
        (i) => rec('s$i', name: 'Bean ${i + 1}'),
      );
      await _pumpCard(tester, items: items);
      await tester.pumpAndSettle();

      expect(find.text(_title), findsOneWidget);
      expect(find.text('Bean 1'), findsOneWidget);
      expect(find.text('Bean 2'), findsOneWidget);
      expect(find.text('Bean 3'), findsOneWidget);
      expect(find.text('Bean 4'), findsNothing);
      expect(find.text('Bean 5'), findsNothing);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('maxItems: 1 → one row, no divider', (tester) async {
      final items = List.generate(
        5,
        (i) => rec('s$i', name: 'Bean ${i + 1}'),
      );
      await _pumpCard(tester, items: items, maxItems: 1);
      await tester.pumpAndSettle();

      expect(find.text('Bean 1'), findsOneWidget);
      expect(find.text('Bean 2'), findsNothing);
      expect(find.byType(Divider), findsNothing);
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

  group('buildForYouProductUrl', () {
    test('adds the three UTM parameters', () {
      final uri = buildForYouProductUrl('https://shop.example.com/beans/abc');
      expect(uri, isNotNull);
      expect(uri!.queryParameters['utm_source'], 'timer.coffee');
      expect(uri.queryParameters['utm_medium'], 'app');
      expect(uri.queryParameters['utm_campaign'], 'for_you');
    });

    test('preserves existing query parameters', () {
      final uri = buildForYouProductUrl(
        'https://shop.example.com/beans/abc?grind=filter&size=250g',
      );
      expect(uri!.queryParameters['grind'], 'filter');
      expect(uri.queryParameters['size'], '250g');
      expect(uri.queryParameters['utm_campaign'], 'for_you');
    });

    test('does not overwrite a utm_* the URL already has', () {
      final uri = buildForYouProductUrl(
        'https://shop.example.com/a?utm_source=newsletter',
      );
      expect(uri!.queryParameters['utm_source'], 'newsletter');
      expect(uri.queryParameters['utm_medium'], 'app',
          reason: 'missing UTM params are still added');
    });

    test('keeps http (not just https)', () {
      final uri = buildForYouProductUrl('http://shop.example.com/a');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'http');
    });

    test('rejects non-http(s), junk and empty', () {
      expect(buildForYouProductUrl('javascript:alert(1)'), isNull);
      expect(buildForYouProductUrl('ftp://files.example.com/a.zip'), isNull);
      expect(buildForYouProductUrl('not a url'), isNull);
      expect(buildForYouProductUrl('   '), isNull);
      expect(buildForYouProductUrl(''), isNull);
      expect(buildForYouProductUrl(null), isNull);
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
      expect(find.text('Bean B'), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
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
      expect(find.bySemanticsIdentifier('forYouItem_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouItem_1'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouView_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouDismiss_0'), findsOneWidget);
      expect(find.bySemanticsIdentifier('forYouView_1'), findsNothing,
          reason: 'second item has no usable productUrl');
      expect(find.bySemanticsIdentifier('forYouDismiss_1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Must be disposed inside the test body: the binding verifies handles
      // are gone before tearDowns run.
      handle.dispose();
    });
  });
}
