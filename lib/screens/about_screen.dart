import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _loading = true;
  String _statusMessage = '';

  static const Set<String> _productIds = {
    'com.braedengaines.fabcompanion.tip',
    'com.braedengaines.fabcompanion.tip2',
    'com.braedengaines.fabcompanion.tip3',
  };

  @override
  void initState() {
    super.initState();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => setState(() => _statusMessage = 'Error: $error'),
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      setState(() {
        _loading = false;
        _statusMessage = 'Store not available';
      });
      return;
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds);

    // Sort by price ascending
    final sorted = response.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    setState(() {
      _products = sorted;
      _loading = false;
    });
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _iap.completePurchase(purchase);
        setState(() => _statusMessage = 'Thank you for your support! 🙏');
      } else if (purchase.status == PurchaseStatus.error) {
        setState(() => _statusMessage = 'Purchase failed. Please try again.');
      } else if (purchase.status == PurchaseStatus.canceled) {
        setState(() => _statusMessage = '');
      }
    }
  }

  void _buyTip(ProductDetails product) {
    final PurchaseParam param = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: param);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            Text(
              'FaB Companion',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              'This is a fan made app designed to help track tokens, life totals, and other game elements for Flesh and Blood. I hope it makes your games more enjoyable!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Please feel free to send any feedback or suggestions you have!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Tip Section
            Text(
              'Support the Developer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enjoying FaB Companion? A tip helps support continued development and new features.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),

            if (_loading)
              CircularProgressIndicator()
            else if (_products.isEmpty)
              Text(
                'Tips unavailable at this time.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _products.map((product) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () => _buyTip(product),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 20),
                          SizedBox(height: 4),
                          Text(
                            product.price,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (_statusMessage.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusMessage.contains('Thank')
                      ? Colors.green
                      : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                launchUrl(
                  Uri.parse('https://github.com/BraedenjGaines/tabletop_token_tracker'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'GitHub Repository',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 16),
            Text(
              '© 2026 Braeden Gaines. All Rights Reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This app is not affiliated with, endorsed by, or sponsored by Legend Story Studios or any other game company. Flesh and Blood is a trademark of Legend Story Studios.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}