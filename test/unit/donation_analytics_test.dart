import 'package:coffee_timer/purchase_manager.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  final purchaseManager = PurchaseManager();

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    purchaseManager.setDeliverProductCallback(null);
    purchaseManager.setPurchaseErrorCallback(null);
    purchaseManager.setPurchaseCancelledCallback(null);
    AnalyticsService.resetForTesting();
  });

  test('canceled purchase invokes cancellation callback only', () {
    PurchaseDetails? cancelledPurchase;
    var deliveryCount = 0;
    var errorCount = 0;
    purchaseManager.setDeliverProductCallback((_) => deliveryCount++);
    purchaseManager.setPurchaseErrorCallback((_) => errorCount++);
    purchaseManager.setPurchaseCancelledCallback((purchase) {
      cancelledPurchase = purchase;
    });

    final purchase = _purchaseDetails(PurchaseStatus.canceled);
    purchaseManager.processPurchaseUpdatesForTesting([purchase]);

    expect(cancelledPurchase, same(purchase));
    expect(deliveryCount, 0);
    expect(errorCount, 0);
  });

  test('error purchase without details supplies a synthetic error', () {
    IAPError? receivedError;
    purchaseManager.setPurchaseErrorCallback((error) {
      receivedError = error;
    });

    expect(
      () => purchaseManager.processPurchaseUpdatesForTesting([
        _purchaseDetails(PurchaseStatus.error),
      ]),
      returnsNormally,
    );
    expect(receivedError, isNotNull);
    expect(receivedError!.source, 'unknown');
    expect(receivedError!.code, 'unknown_error');
  });

  test('purchased purchase invokes delivery callback only', () {
    PurchaseDetails? deliveredPurchase;
    var cancellationCount = 0;
    var errorCount = 0;
    purchaseManager.setDeliverProductCallback((purchase) {
      deliveredPurchase = purchase;
    });
    purchaseManager.setPurchaseErrorCallback((_) => errorCount++);
    purchaseManager.setPurchaseCancelledCallback((_) => cancellationCount++);

    final purchase = _purchaseDetails(PurchaseStatus.purchased);
    purchaseManager.processPurchaseUpdatesForTesting([purchase]);

    expect(deliveredPurchase, same(purchase));
    expect(cancellationCount, 0);
    expect(errorCount, 0);
  });

  test(
    'donation_cancelled is registered as a general analytics event',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final analytics = await AnalyticsService.initialize(preferences);

      analytics.track(
        'donation_cancelled',
        properties: {
          'product_id': 'tip_small_coffee',
          'source_screen': 'donation_screen',
        },
      );

      expect(analytics.bufferLength, 1);
      expect(
        analytics.bufferedEventsForTesting.single['event_name'],
        'donation_cancelled',
      );
      expect(analytics.bufferedEventsForTesting.single['category'], 'general');
    },
  );
}

PurchaseDetails _purchaseDetails(PurchaseStatus status) {
  return PurchaseDetails(
    productID: 'tip_small_coffee',
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  );
}
