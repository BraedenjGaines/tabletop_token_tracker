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
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _loading = true;
  String _statusMessage = '';
  Timer? _statusClearTimer;

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
      onDone: () => _subscription?.cancel(),
      onError: (error) => _setStatus('Purchase error: $error', isError: true),
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    bool available = false;
    try {
      available = await _iap.isAvailable();
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = 'Store unreachable: $e';
      });
      return;
    }

    if (!available) {
      setState(() {
        _loading = false;
        _statusMessage = 'Store not available on this device.';
      });
      return;
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds);

    // Diagnostic logging — surfaces in `flutter logs` and Xcode console.
    debugPrint('IAP query error: ${response.error}');
    debugPrint('IAP notFoundIDs: ${response.notFoundIDs}');
    debugPrint('IAP productDetails count: ${response.productDetails.length}');

    if (response.error != null) {
      setState(() {
        _loading = false;
        _statusMessage = 'Store error: ${response.error!.message}';
      });
      return;
    }

    if (response.productDetails.isEmpty) {
      final missing = response.notFoundIDs.isNotEmpty
          ? '\nMissing: ${response.notFoundIDs.join(", ")}'
          : '';
      setState(() {
        _loading = false;
        _statusMessage = 'Tips unavailable at this time.$missing';
      });
      return;
    }

    final sorted = response.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    setState(() {
      _products = sorted;
      _loading = false;
      _statusMessage = '';
    });
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _iap.completePurchase(purchase);
          _setStatus('Thank you for your support! 🙏');
          break;
        case PurchaseStatus.error:
          _setStatus(
            'Purchase failed: ${purchase.error?.message ?? "unknown error"}',
            isError: true,
          );
          break;
        case PurchaseStatus.canceled:
          _setStatus('');
          break;
        case PurchaseStatus.pending:
          _setStatus('Processing...');
          break;
      }
    }
  }

  void _setStatus(String message, {bool isError = false}) {
    _statusClearTimer?.cancel();
    if (!mounted) return;
    setState(() => _statusMessage = message);
    if (message.isNotEmpty && !isError) {
      _statusClearTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _statusMessage = '');
      });
    }
  }

  void _buyTip(ProductDetails product) {
    final PurchaseParam param = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: param);
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
      _setStatus('Restore complete.');
    } catch (e) {
      _setStatus('Restore failed: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _statusClearTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mutedText = Colors.grey;
    final bool isErrorStatus = _statusMessage.toLowerCase().contains('fail') ||
        _statusMessage.toLowerCase().contains('error') ||
        _statusMessage.toLowerCase().contains('unreachable') ||
        _statusMessage.toLowerCase().contains('unavailable');

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              'FaB Companion',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0',
              style: TextStyle(fontSize: 16, color: mutedText),
            ),
            const SizedBox(height: 24),
            const Text(
              'This is a fan made app designed to help track tokens, life totals, and other game elements for Flesh and Blood. I hope it makes your games more enjoyable!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please feel free to send any feedback or suggestions you have!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // --- Tip section ---
            const Text(
              'Support the Developer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enjoying FaB Companion? A tip helps support continued development and new features.',
              style: TextStyle(fontSize: 14, color: mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (_loading)
              const CircularProgressIndicator()
            else if (_products.isEmpty)
              const Text(
                'Tips unavailable at this time.',
                style: TextStyle(color: mutedText),
                textAlign: TextAlign.center,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () => _buyTip(product),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            product.price,
                            style: const TextStyle(
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
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: isErrorStatus ? Colors.red : Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Restore Purchases — required by Apple even for consumables.
            if (_products.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _restorePurchases,
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                launchUrl(
                  Uri.parse(
                      'https://github.com/BraedenjGaines/tabletop_token_tracker'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Row(
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
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '© 2026 Braeden Gaines. All Rights Reserved.',
              style: TextStyle(fontSize: 12, color: mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This app is not affiliated with, endorsed by, or sponsored by Legend Story Studios or any other game company. Flesh and Blood is a trademark of Legend Story Studios.',
              style: TextStyle(fontSize: 11, color: mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}