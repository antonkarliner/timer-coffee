import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'dart:async';
import '../purchase_manager.dart';

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
  final Map<String, String> _productTitles = {
    'tip_small_coffee': 'Buy a small coffee',
    'tip_medium_coffee': 'Buy a medium coffee',
    'tip_large_coffee': 'Buy a large coffee',
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
      // Reverse sort based on the title so it shows small, medium, large
      _products.sort(
          (a, b) => _productTitles[b.id]!.compareTo(_productTitles[a.id]!));
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
          title: const Text("Error"),
          content:
              const Text("Error processing the purchase, please try again."),
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
          title: const Text("Thank You!"),
          content: const Text(
              "I really appreciate your support! Wish you a lot of great brews! ☕️"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support the development'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Thanks for considering to donate!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your donations help to cover the maintenance costs (such as developer licenses, for example). They also allow me to try more coffee brewing devices and add more recipes to the app.',
            ),
            const SizedBox(height: 32),
            ..._products.map((product) {
              if (product.id == 'tip_medium_coffee') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _makePurchase(product),
                        child: Text(
                            _productTitles[product.id] ?? 'Unknown Product'),
                      ),
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
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  onPressed: () => _makePurchase(product),
                  child: Text(_productTitles[product.id] ?? 'Unknown Product'),
                ),
              );
            }),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  context.router.push(const HomeRoute());
                },
                child: const Text('Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
