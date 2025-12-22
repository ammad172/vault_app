import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product IDs for subscriptions
class SubscriptionProducts {
  static const String monthlyPremium = 'vaultlock_premium_monthly';
  static const String annualPremium = 'vaultlock_premium_annual';
  static const String lifetimePremium = 'vaultlock_premium_lifetime';

  static const Set<String> productIds = {
    monthlyPremium,
    annualPremium,
    lifetimePremium,
  };
}

/// Subscription service to manage premium status and purchases
class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isPremium = false;
  bool _isLoading = false;
  String? _error;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const String _keyPremiumStatus = 'premium_status';
  static const String _keyPremiumExpiry = 'premium_expiry';
  static const String _keyPurchaseId = 'purchase_id';

  SubscriptionService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      _error = 'In-app purchases not available';
      notifyListeners();
      return;
    }

    // Load premium status from storage
    await _loadPremiumStatus();

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    // Load products
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    _isLoading = true;
    notifyListeners();

    try {
      final productDetailsResponse = await _iap.queryProductDetails(
        SubscriptionProducts.productIds,
      );

      if (productDetailsResponse.error != null) {
        _error = productDetailsResponse.error!.message;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _products = productDetailsResponse.productDetails;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      _error = 'Purchases not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(
        productDetails: product,
      );

      if (product.id == SubscriptionProducts.monthlyPremium ||
          product.id == SubscriptionProducts.annualPremium) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // For subscriptions, use buyNonConsumable (works for both)
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.error) {
        _error = purchase.error?.message ?? 'Purchase failed';
        _isLoading = false;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _handleSuccessfulPurchase(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Determine expiry based on product
    DateTime? expiry;
    if (purchase.productID == SubscriptionProducts.monthlyPremium) {
      expiry = DateTime.now().add(const Duration(days: 30));
    } else if (purchase.productID == SubscriptionProducts.annualPremium) {
      expiry = DateTime.now().add(const Duration(days: 365));
    } else if (purchase.productID == SubscriptionProducts.lifetimePremium) {
      expiry = DateTime.now().add(const Duration(days: 36500)); // ~100 years
    }

    // Save premium status
    await prefs.setBool(_keyPremiumStatus, true);
    if (expiry != null) {
      await prefs.setString(_keyPremiumExpiry, expiry.toIso8601String());
    }
    await prefs.setString(_keyPurchaseId, purchase.purchaseID ?? '');

    _isPremium = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_keyPremiumStatus) ?? false;
    
    if (isPremium) {
      final expiryStr = prefs.getString(_keyPremiumExpiry);
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          // Premium expired
          await prefs.setBool(_keyPremiumStatus, false);
          _isPremium = false;
        } else {
          _isPremium = true;
        }
      } else {
        // Lifetime premium (no expiry)
        _isPremium = true;
      }
    } else {
      _isPremium = false;
    }

    notifyListeners();
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      _error = 'Restore not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _iap.restorePurchases();
      await _loadPremiumStatus();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Global subscription service instance
final subscriptionService = SubscriptionService();

