import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:auto_route/auto_route.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_router.gr.dart';
import 'dart:async';
import '../purchase_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final PurchaseManager _purchaseManager = PurchaseManager();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _purchaseManager.setDeliverProductCallback(_deliverProduct);
    _purchaseManager.setPurchaseErrorCallback(_handleError);
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    setState(() {
      _products = response.productDetails;
      _products.sort((a, b) =>
          _kIds.toList().indexOf(a.id).compareTo(_kIds.toList().indexOf(b.id)));
    });
  }

  void _makePurchase(ProductDetails productDetails) {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    if (mounted) {
      Future.microtask(() => showDialog(
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
          ));
    } else {}
  }

  void _handleError(IAPError error) {
    Future.microtask(() => showDialog(
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
        ));
  }

  Map<String, String> getProductTitles(BuildContext context) {
    return {
      'tip_small_coffee': AppLocalizations.of(context)!.tipsmall,
      'tip_medium_coffee': AppLocalizations.of(context)!.tipmedium,
      'tip_large_coffee': AppLocalizations.of(context)!.tiplarge,
    };
  }

  @override
  void dispose() {
    // It's important to dispose the callbacks when the widget is disposed
    PurchaseManager().setDeliverProductCallback(null);
    PurchaseManager().setPurchaseErrorCallback(null);

    // Call dispose on super class
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
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
            // Conditionally render widgets based on platform
            if (!kIsWeb &&
                Platform.isIOS) // For iOS, show the products for purchase
              ..._products.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildProductButton(product, productTitles),
                );
              })
            else if (kIsWeb ||
                !Platform.isIOS) // For web and Android, show a different button
              ElevatedButton.icon(
                onPressed: () =>
                    _launchURL('https://www.buymeacoffee.com/timercoffee'),
                icon: const Icon(Icons.local_cafe),
                label: Text(AppLocalizations.of(context)!.support),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.router.push(const HomeRoute());
              },
              child: Text(AppLocalizations.of(context)!.home),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductButton(
      ProductDetails product, Map<String, String> productTitles) {
    Widget button = ElevatedButton(
      onPressed: () => _makePurchase(product),
      child: Text(productTitles[product.id] ?? 'Unknown Product'),
    );

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
              child: const Icon(Icons.star, size: 10, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return button;
  }
}
