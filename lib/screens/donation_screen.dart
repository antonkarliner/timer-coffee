import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'dart:async';
import '../purchase_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class DonationScreen extends StatefulWidget {
  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final Set<String> _kIds = {
    'tip_large_coffee',
    'tip_medium_coffee',
    'tip_small_coffee'
  };
  late List<ProductDetails> _products;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    PurchaseManager().initialize(); // Initialize global subscription here
  }

  @override
  void dispose() {
    PurchaseManager().dispose(); // Dispose of the global subscription here
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    setState(() {
      _products = response.productDetails;
      // Sort the products based on the predefined order of _kIds
      _products.sort((a, b) =>
          _kIds.toList().indexOf(a.id).compareTo(_kIds.toList().indexOf(b.id)));
    });
  }

  void _makePurchase(ProductDetails productDetails) {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        _deliverProduct(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    });
  }

  void _handleError(IAPError error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.donationerr),
          content: Text(AppLocalizations.of(context)!.donationerrmsg),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.donationok),
          content: Text(AppLocalizations.of(context)!.donationtnx),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Map<String, String> getProductTitles(BuildContext context) {
    return {
      'tip_small_coffee': AppLocalizations.of(context)!.tipsmall,
      'tip_medium_coffee': AppLocalizations.of(context)!.tipmedium,
      'tip_large_coffee': AppLocalizations.of(context)!.tiplarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final productTitles = getProductTitles(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.supportdevelopment),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.supportdevtnx,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.supportdevmsg),
            const SizedBox(height: 32),
            ..._products.map((product) {
              Widget button = ElevatedButton(
                onPressed: () => _makePurchase(product),
                child: Text(productTitles[product.id] ?? 'Unknown Product'),
              );

              // Add badge for the medium tip
              if (product.id == 'tip_medium_coffee') {
                button = Stack(
                  alignment: Alignment.center,
                  children: [
                    button,
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.brown,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                );
              }

              return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), child: button);
            }),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  context.router.push(const HomeRoute());
                },
                child: Text(AppLocalizations.of(context)!.home),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
