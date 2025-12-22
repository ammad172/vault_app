import 'package:flutter/foundation.dart';
import '../services/vault_service.dart';
import '../services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to check premium features and enforce limits
class PremiumService extends ChangeNotifier {
  static const int freeTierMaxEntries = 25;
  static const int freeTierMaxPasswordGenerations = 10;
  static const String _keyPasswordGenerationCount = 'password_gen_count';
  static const String _keyPasswordGenerationDate = 'password_gen_date';

  PremiumService() {
    // Listen to subscription changes
    subscriptionService.addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  /// Check if user has premium subscription
  bool get isPremium => subscriptionService.isPremium;

  /// Get current entry count
  int get currentEntryCount {
    try {
      return VaultService.getEntriesSnapshot().length;
    } catch (_) {
      return 0;
    }
  }

  /// Check if user can add more entries
  bool canAddEntry() {
    if (isPremium) return true;
    return currentEntryCount < freeTierMaxEntries;
  }

  /// Get remaining free entries
  int getRemainingFreeEntries() {
    if (isPremium) return -1; // Unlimited
    return (freeTierMaxEntries - currentEntryCount).clamp(0, freeTierMaxEntries);
  }

  /// Check if user can generate password
  Future<bool> canGeneratePassword() async {
    if (isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyPasswordGenerationCount) ?? 0;
    final dateStr = prefs.getString(_keyPasswordGenerationDate);
    
    // Reset count if it's a new day
    if (dateStr != null) {
      final lastDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (now.day != lastDate.day ||
          now.month != lastDate.month ||
          now.year != lastDate.year) {
        await prefs.setInt(_keyPasswordGenerationCount, 0);
        await prefs.setString(_keyPasswordGenerationDate, now.toIso8601String());
        return true;
      }
    } else {
      await prefs.setString(_keyPasswordGenerationDate, DateTime.now().toIso8601String());
    }

    return count < freeTierMaxPasswordGenerations;
  }

  /// Record password generation
  Future<void> recordPasswordGeneration() async {
    if (isPremium) return;

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyPasswordGenerationCount) ?? 0) + 1;
    await prefs.setInt(_keyPasswordGenerationCount, count);
    await prefs.setString(_keyPasswordGenerationDate, DateTime.now().toIso8601String());
  }

  /// Get remaining password generations for today
  Future<int> getRemainingPasswordGenerations() async {
    if (isPremium) return -1; // Unlimited

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyPasswordGenerationCount) ?? 0;
    return (freeTierMaxPasswordGenerations - count).clamp(0, freeTierMaxPasswordGenerations);
  }

  /// Check if cloud backup is available
  bool canUseCloudBackup() {
    return isPremium;
  }

  /// Check if advanced password health is available
  bool canUseAdvancedHealth() {
    return isPremium;
  }

  /// Get upgrade message for entry limit
  String getEntryLimitMessage() {
    if (isPremium) return 'Unlimited entries';
    final remaining = getRemainingFreeEntries();
    if (remaining == 0) {
      return 'Entry limit reached. Upgrade to Premium for unlimited entries.';
    }
    return '$remaining of $freeTierMaxEntries entries remaining';
  }

  /// Get upgrade message for password generation limit
  Future<String> getPasswordGenerationLimitMessage() async {
    if (isPremium) return 'Unlimited password generation';
    final remaining = await getRemainingPasswordGenerations();
    if (remaining == 0) {
      return 'Daily limit reached. Upgrade to Premium for unlimited generation.';
    }
    return '$remaining of $freeTierMaxPasswordGenerations generations remaining today';
  }
}

/// Global premium service instance
final premiumService = PremiumService();

