import 'package:flutter_test/flutter_test.dart';
import 'package:vault_app/services/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumService Tests', () {
    late PremiumService premiumService;

    setUp(() {
      // Reset shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      premiumService = PremiumService();
    });

    tearDown(() {
      premiumService.dispose();
    });

    test('Free tier max entries constant is correct', () {
      expect(PremiumService.freeTierMaxEntries, equals(25));
    });

    test('Free tier max password generations constant is correct', () {
      expect(PremiumService.freeTierMaxPasswordGenerations, equals(10));
    });

    test('isPremium returns false for free tier', () {
      expect(premiumService.isPremium, isFalse);
    });

    test('canAddEntry returns true when under limit', () {
      // Mock current entry count
      expect(premiumService.canAddEntry(), isTrue);
    });

    test('getRemainingFreeEntries returns correct value', () {
      final remaining = premiumService.getRemainingFreeEntries();
      expect(remaining, greaterThanOrEqualTo(0));
      expect(remaining, lessThanOrEqualTo(PremiumService.freeTierMaxEntries));
    });

    test('canUseCloudBackup returns false for free tier', () {
      expect(premiumService.canUseCloudBackup(), isFalse);
    });

    test('canUseAdvancedHealth returns false for free tier', () {
      expect(premiumService.canUseAdvancedHealth(), isFalse);
    });

    test('getEntryLimitMessage returns correct message', () {
      final message = premiumService.getEntryLimitMessage();
      expect(message, isNotEmpty);
      expect(message, contains('remaining'));
    });

    test('canGeneratePassword returns true initially', () async {
      final canGenerate = await premiumService.canGeneratePassword();
      expect(canGenerate, isTrue);
    });

    test('recordPasswordGeneration increments count', () async {
      await premiumService.recordPasswordGeneration();
      final remaining = await premiumService.getRemainingPasswordGenerations();
      expect(remaining, lessThan(PremiumService.freeTierMaxPasswordGenerations));
    });

    test('getPasswordGenerationLimitMessage returns correct message', () async {
      final message = await premiumService.getPasswordGenerationLimitMessage();
      expect(message, isNotEmpty);
      expect(message, contains('remaining'));
    });
  });
}

