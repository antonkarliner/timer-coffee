// purchase_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:coffee_timer/utils/app_logger.dart';

typedef DeliverProductCallback = void Function(PurchaseDetails details);
typedef PurchaseErrorCallback = void Function(IAPError error);

class PurchaseManager {
  static final PurchaseManager _singleton = PurchaseManager._internal();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  DeliverProductCallback? onProductDelivered;
  PurchaseErrorCallback? onPurchaseError;

  factory PurchaseManager() {
    return _singleton;
  }

  PurchaseManager._internal() {
    _initialize();
  }

  static bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS;
  }

  bool get isSupported => _isSupportedPlatform;

  void _initialize() {
    if (!_isSupportedPlatform) {
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdates =
        InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseUpdates.listen(_listenToPurchaseUpdated);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        onProductDelivered?.call(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchaseDetails.error!);
      }

      // Call completePurchase for every purchase
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  void setDeliverProductCallback(DeliverProductCallback? callback) {
    onProductDelivered = callback;
  }

  void setPurchaseErrorCallback(PurchaseErrorCallback? callback) {
    onPurchaseError = callback;
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }

  Future<void> restorePurchasesIfSupported() async {
    if (!_isSupportedPlatform) {
      return;
    }
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (error) {
      // Ignore restore errors on startup; platform-specific flows handle messaging.
      AppLogger.warning('restorePurchases failed', errorObject: error);
    }
  }
}
