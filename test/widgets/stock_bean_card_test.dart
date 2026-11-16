import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffee_timer/widgets/stock_bean_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for [StockBeanCard] (plan 017 phase 5d) — the shared
/// pick/stock card used by the Hub's "For you" block and the roaster
/// profile's "In stock now" section.
///
/// Network images: no test here performs a real image fetch. Under the
/// test binding `flutter_cache_manager` cannot reach `path_provider`, so a
/// [CachedNetworkImage] never resolves: it stays in its placeholder state
/// deterministically. The error-fallback branches are therefore verified
/// deterministically by invoking the built widget's `errorWidget` closure
/// directly (that closure is what renders on a real load failure).
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget harness({
    String? imageUrl,
    String? logoUrl,
    String? logoMirrorUrl,
    String title = 'Yirgacheffe Washed',
    String? subtitle,
    String? body,
    List<Widget> actions = const <Widget>[],
    VoidCallback? onTap,
    Locale locale = const Locale('en'),
    TextScaler textScaler = TextScaler.noScaling,
  }) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: Scaffold(
              body: ListView(
                children: [
                  StockBeanCard(
                    title: title,
                    subtitle: subtitle,
                    body: body,
                    imageUrl: imageUrl,
                    logoUrl: logoUrl,
                    logoMirrorUrl: logoMirrorUrl,
                    actions: actions,
                    onTap: onTap,
                    semanticsIdentifier: 'stockCard',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  group('photo slot', () {
    testWidgets('a usable http(s) URL builds a CachedNetworkImage',
        (tester) async {
      await tester.pumpWidget(
        harness(imageUrl: 'https://cdn.example.com/bag.jpg'),
      );
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      // The URL is passed through untouched — no Supabase rewriting.
      expect(image.imageUrl, 'https://cdn.example.com/bag.jpg');
      expect(image.fit, BoxFit.cover);
      await tester.pumpAndSettle();
      // The fetch never completes under the test binding, so the slot
      // stays in its placeholder state — no fallback icon yet, no noise.
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the photo error fallback is the storefront placeholder '
        'when there is no logo', (tester) async {
      await tester.pumpWidget(
        harness(imageUrl: 'https://cdn.example.com/bag.jpg'),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.errorWidget, isNotNull);
      final context = tester.element(find.byType(StockBeanCard));
      final fallback = image.errorWidget!(context, image.imageUrl, 'x');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: fallback))),
      );
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byType(RoasterLogo), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the photo error fallback is the roaster logo when logo '
        'URLs exist', (tester) async {
      await tester.pumpWidget(
        harness(
          imageUrl: 'https://cdn.example.com/bag.jpg',
          logoUrl: 'https://cdn.example.com/logo.png',
          logoMirrorUrl: 'https://mirror.example.com/logo.png',
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.errorWidget, isNotNull);
      final context = tester.element(find.byType(StockBeanCard));
      final fallback = image.errorWidget!(context, image.imageUrl, 'x');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: fallback))),
      );
      expect(find.byType(RoasterLogo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a non-empty, non-http image URL is ignored',
        (tester) async {
      for (final url in [
        'javascript:alert(1)',
        'ftp://files.example.com/bag.jpg',
        'data:image/png;base64,AAAA',
      ]) {
        await tester.pumpWidget(harness(imageUrl: url));
        await tester.pump();
        expect(find.byType(CachedNetworkImage), findsNothing,
            reason: 'url: $url');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('no photo but a logo → RoasterLogo fallback',
        (tester) async {
      await tester.pumpWidget(
        harness(
          logoUrl: 'https://cdn.example.com/logo.png',
          logoMirrorUrl: 'https://mirror.example.com/logo.png',
        ),
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(RoasterLogo), findsOneWidget);
      // The logo URLs do not resolve under the test binding; the logo
      // widget ends at its storefront placeholder.
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('neither photo nor logo → storefront placeholder icon',
        (tester) async {
      await tester.pumpWidget(harness());
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(RoasterLogo), findsNothing);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('hasHttpImageUrl accepts only non-empty http(s) with a host', () {
      expect(StockBeanCard.hasHttpImageUrl('https://cdn.example.com/a.jpg'),
          isTrue);
      expect(StockBeanCard.hasHttpImageUrl('http://cdn.example.com/a.jpg'),
          isTrue);
      expect(StockBeanCard.hasHttpImageUrl('  https://cdn.example.com  '),
          isTrue);
      expect(StockBeanCard.hasHttpImageUrl('https://'), isFalse);
      expect(StockBeanCard.hasHttpImageUrl('javascript:alert(1)'), isFalse);
      expect(StockBeanCard.hasHttpImageUrl('ftp://files.example.com'),
          isFalse);
      expect(StockBeanCard.hasHttpImageUrl('not a url'), isFalse);
      expect(StockBeanCard.hasHttpImageUrl(''), isFalse);
      expect(StockBeanCard.hasHttpImageUrl('   '), isFalse);
      expect(StockBeanCard.hasHttpImageUrl(null), isFalse);
    });
  });

  group('content and actions', () {
    testWidgets('renders title, subtitle and body text', (tester) async {
      await tester.pumpWidget(harness(
        subtitle: 'Test Roaster',
        body: 'Bright and juicy.',
      ));
      expect(find.text('Yirgacheffe Washed'), findsOneWidget);
      expect(find.text('Test Roaster'), findsOneWidget);
      expect(find.text('Bright and juicy.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no actions → none rendered; card tap fires onTap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(harness(onTap: () => taps++));
      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(AppTextButton), findsNothing);

      await tester.tap(find.text('Yirgacheffe Washed'));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('action buttons are tappable without triggering the card '
        'tap', (tester) async {
      var cardTaps = 0;
      var actionTaps = 0;
      await tester.pumpWidget(harness(
        onTap: () => cardTaps++,
        actions: [
          AppTextButton(
            label: 'View',
            onPressed: () => actionTaps++,
            isFullWidth: false,
            padding: const EdgeInsetsDirectional.only(
              end: AppSpacing.base,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            textStyle: AppTextStyles.body,
          ),
        ],
      ));
      expect(find.byType(AppTextButton), findsOneWidget);
      // AppButton.heightMedium (48) ≥ the 44 pt minimum tap height.
      final size = tester.getSize(find.byType(AppTextButton));
      expect(size.height, greaterThanOrEqualTo(44));

      await tester.tap(find.text('View'));
      await tester.pump();
      expect(actionTaps, 1);
      expect(cardTaps, 0, reason: 'nested buttons must not count as card taps');
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes its semantics identifier', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(harness());
      expect(find.bySemanticsIdentifier('stockCard'), findsOneWidget);
      handle.dispose();
    });
  });

  group('layout stress (320x640, text scale 1.3)', () {
    Future<void> pumpStress(
      WidgetTester tester,
      Locale locale,
      String longTitle,
      String longSubtitle,
      String longBody,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(harness(
        locale: locale,
        textScaler: TextScaler.linear(1.3),
        title: longTitle,
        subtitle: longSubtitle,
        body: longBody,
        actions: [
          AppTextButton(
            label: 'Ansehen',
            onPressed: () {},
            isFullWidth: false,
            textStyle: AppTextStyles.body,
          ),
        ],
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('120-char title, de', (tester) async {
      await pumpStress(
        tester,
        const Locale('de'),
        'Kaffeebohnen' * 10,
        'Eine Sehr Lange Rösterei Bezeichnung GmbH & Co. KG · Entkoffeiniert',
        'Ausgewählt, weil du helle Röstungen mit Fruchtnoten magst und '
            'diese Bohne genau zu deinen letzten Brühungen passt. ',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('120-char title, ru', (tester) async {
      await pumpStress(
        tester,
        const Locale('ru'),
        'Кофейное зерно ' * 8,
        'Очень Длинное Название Обжарочной Компании · Без кофеина',
        'Подобрано, потому что вам нравятся светлая обжарка и фруктовые '
            'ноты, и это зерно идеально подходит под ваши заваривания. ',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('120-char title, ar (RTL)', (tester) async {
      await pumpStress(
        tester,
        const Locale('ar'),
        'حبوب البن الممتازة ' * 7,
        'محمصة القهوة الممتازة · منزوع الكافيين',
        'تم اختيار هذا لأنك تفضل التحميص الفاتح مع نكهات الفواكه، وهو '
            'مناسب تماماً لتحضيراتك الأخيرة. ',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
