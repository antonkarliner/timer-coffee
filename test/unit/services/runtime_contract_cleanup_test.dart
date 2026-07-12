import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/gift_offer_model.dart';
import 'package:coffee_timer/screens/giftbox_list_screen.dart';
import 'package:coffee_timer/services/roaster_color_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoasterColorService.fromBackendHex', () {
    test('handles absent, marker, and invalid values', () {
      expect(RoasterColorService.fromBackendHex(null), isA<RoasterColorNone>());
      expect(
        RoasterColorService.fromBackendHex('monochrome'),
        isA<RoasterColorMonochrome>(),
      );
      expect(
        RoasterColorService.fromBackendHex('#invalid'),
        isA<RoasterColorNone>(),
      );
    });

    test('keeps the near-black threshold and muted brand colors', () {
      expect(
        RoasterColorService.fromBackendHex('#333333'),
        isA<RoasterColorMonochrome>(),
      );

      final boundary = RoasterColorService.fromBackendHex('#3C3C3C');
      expect(boundary, isA<RoasterColorVibrant>());
      expect((boundary as RoasterColorVibrant).color.toARGB32(), 0xFF3C3C3C);

      final muted = RoasterColorService.fromBackendHex('#DDDDCC');
      expect(muted, isA<RoasterColorVibrant>());
      expect((muted as RoasterColorVibrant).color.toARGB32(), 0xFFDDDDCC);
    });
  });

  testWidgets('gift offer card keeps its active navigation callback', (
    tester,
  ) async {
    var taps = 0;
    final offer = GiftOffer(
      id: 'offer-1',
      slug: 'partner-offer',
      partnerName: 'Partner Coffee',
      localeUsed: const Locale('en'),
      regions: const ['worldwide'],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GiftOfferCard(offer: offer, onTap: () => taps++),
        ),
      ),
    );

    expect(find.text('Partner Coffee'), findsOneWidget);
    await tester.tap(find.byType(InkWell).first);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
