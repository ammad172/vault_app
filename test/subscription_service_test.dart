import 'package:flutter_test/flutter_test.dart';
import 'package:vault_app/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionService Tests', () {
    late SubscriptionService subscriptionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      subscriptionService = SubscriptionService();
    });

    tearDown(() {
      subscriptionService.dispose();
    });

    test('Product IDs are defined correctly', () {
      expect(SubscriptionProducts.monthlyPremium, isNotEmpty);
      expect(SubscriptionProducts.annualPremium, isNotEmpty);
      expect(SubscriptionProducts.lifetimePremium, isNotEmpty);
      expect(SubscriptionProducts.productIds.length, equals(3));
    });

    test('isPremium returns false initially', () {
      expect(subscriptionService.isPremium, isFalse);
    });

    test('isLoading returns false initially', () {
      expect(subscriptionService.isLoading, isFalse);
    });

    test('products list is empty initially', () {
      expect(subscriptionService.products, isEmpty);
    });

    test('getProduct returns null for non-existent product', () {
      final product = subscriptionService.getProduct('non_existent');
      expect(product, isNull);
    });
  });
}

