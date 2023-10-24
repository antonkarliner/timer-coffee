// purchase_manager.dart
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseManager {
  static final PurchaseManager _singleton = PurchaseManager._internal();
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  factory PurchaseManager() {
    return _singleton;
  }

  PurchaseManager._internal();

  void initialize(Function(List<PurchaseDetails>) callback) {
    final Stream<List<PurchaseDetails>> purchaseUpdates =
        InAppPurchase.instance.purchaseStream;

    _purchaseSubscription = purchaseUpdates.listen(callback);
  }

  void dispose() {
    _purchaseSubscription.cancel();
  }
}
