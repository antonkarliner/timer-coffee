import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/gift_offer_model.dart';
import 'package:coffee_timer/screens/giftbox_list_screen.dart';
import 'package:coffee_timer/services/roaster_color_service.dart';
import 'package:coffee_timer/utils/ocr_performance_monitor.dart';
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

  test('OCR performance statistics retain their aggregation contract', () {
    final metric = OcrPerformanceMetric(
      operationType: OcrOperationType.native,
      duration: const Duration(milliseconds: 300),
      memoryUsageBefore: 100,
      memoryUsageAfter: 160,
      imageSizeBytes: 2048,
      success: true,
      deviceCapability: DeviceCapability.midRange,
      timestamp: DateTime.utc(2026, 1, 1),
    );
    final stats = OcrPerformanceStats()
      ..operationCounts[OcrOperationType.native] = 2
      ..totalDurations[OcrOperationType.native] = const Duration(
        milliseconds: 500,
      )
      ..successCounts[OcrOperationType.native] = 1
      ..metricsByDevice[DeviceCapability.midRange] = [metric];

    expect(
      stats.getAverageDuration(OcrOperationType.native),
      const Duration(milliseconds: 250),
    );
    expect(stats.getSuccessRate(OcrOperationType.native), 0.5);
    expect(stats.getAverageMemoryDelta(OcrOperationType.native), 60);
    expect(metric.toJson()['timestamp'], '2026-01-01T00:00:00.000Z');
  });
}
