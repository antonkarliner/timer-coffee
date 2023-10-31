// purchase_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

typedef DeliverProductCallback = void Function(PurchaseDetails details);

class PurchaseManager {
  static final PurchaseManager _singleton = PurchaseManager._internal();
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  late DeliverProductCallback deliverProductCallback;

  factory PurchaseManager() {
    return _singleton;
  }

  PurchaseManager._internal();

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdates =
        InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseUpdates.listen(_listenToPurchaseUpdated);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        deliverProductCallback(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    });
  }

  void _handleError(IAPError error) {
    // Implementation for showing dialog
  }

  void dispose() {
    _purchaseSubscription.cancel();
  }
}
