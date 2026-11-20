import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/gift_offer_model.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:coffee_timer/screens/giftbox_offer_detail_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brew_flow_async_context_test.mocks.dart';

void main() {
  late SharedPreferences prefs;
  late AnalyticsService analytics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Timer.Coffee',
      packageName: 'timer.coffee',
      version: '3.10.2',
      buildNumber: '491',
      buildSignature: '',
    );
    prefs = await SharedPreferences.getInstance();
    analytics = await AnalyticsService.initialize(prefs);
  });

  tearDown(AnalyticsService.resetForTesting);

  testWidgets('opens offers directly after general analytics opt-out', (
    tester,
  ) async {
    const slug = 'coffee-offer';
    const locale = Locale('en');
    const partnerUrl = 'https://partner.example/offers/coffee?code=discount';
    final db = MockDatabaseProvider();
    when(db.fetchGiftOfferBySlug(slug, locale: locale)).thenAnswer(
      (_) async => GiftOffer(
        id: 'offer-1',
        slug: slug,
        partnerName: 'Coffee Partner',
        localeUsed: locale,
        websiteUrl: partnerUrl,
      ),
    );
    final launches = <Uri>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') {
        launches.add(Uri.parse(call.arguments['url'] as String));
      }
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await analytics.setGeneralEnabled(false);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseProvider>.value(value: db),
          ChangeNotifierProvider(create: (_) => SnowEffectProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: GiftBoxOfferDetailScreen(slug: slug),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cta = find.text('Visit Partner Website');
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(launches.single, Uri.parse(partnerUrl));
    expect(prefs.containsKey('giftbox_install_id'), isFalse);

    await analytics.setGeneralEnabled(true);
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(launches, hasLength(2));
    expect(launches.last.host, 'timer.coffee');
    expect(launches.last.path, '/go/$slug');
    expect(launches.last.queryParameters['iid'], isNotEmpty);
    expect(
      launches.last.queryParameters['iid'],
      prefs.getString('giftbox_install_id'),
    );
  });
}
