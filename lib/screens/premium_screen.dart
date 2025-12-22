import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/session_manager.dart';
import 'package:intl/intl.dart';

/// Premium upgrade/paywall screen
class PremiumScreen extends StatefulWidget {
  static const routeName = '/premium';

  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    sessionManager.recordActivity();
    subscriptionService.addListener(_onSubscriptionChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      setState(() {});
      // If user just purchased, show success and go back
      if (subscriptionService.isPremium) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _loadProducts() async {
    await subscriptionService.loadProducts();
    if (mounted) setState(() {});
  }

  Future<void> _purchaseProduct(String productId) async {
    final product = subscriptionService.getProduct(productId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not available')),
      );
      return;
    }

    await subscriptionService.purchaseProduct(product);
  }

  Future<void> _restorePurchases() async {
    await subscriptionService.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subscriptionService.isPremium
                ? 'Purchases restored successfully!'
                : 'No purchases found to restore',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPremium = subscriptionService.isPremium;
    final isLoading = subscriptionService.isLoading;

    if (isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium Status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  'You\'re Premium!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enjoy all premium features',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _restorePurchases,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              elevation: 0,
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 64,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'VaultLock Premium',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock unlimited features and remove ads',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Features list
            _buildFeature(
              context,
              Icons.lock_open_rounded,
              'Unlimited Password Entries',
              'Store as many passwords as you need',
            ),
            _buildFeature(
              context,
              Icons.psychology_rounded,
              'Unlimited Password Generation',
              'Generate strong passwords without limits',
            ),
            _buildFeature(
              context,
              Icons.cloud_done_rounded,
              'Cloud Backup & Sync',
              'Sync your vault across all devices',
            ),
            _buildFeature(
              context,
              Icons.health_and_safety_rounded,
              'Advanced Password Health',
              'Detailed security analysis and recommendations',
            ),
            _buildFeature(
              context,
              Icons.block_rounded,
              'Ad-Free Experience',
              'Enjoy the app without interruptions',
            ),
            _buildFeature(
              context,
              Icons.support_agent_rounded,
              'Priority Support',
              'Get help when you need it',
            ),
            const SizedBox(height: 32),

            // Pricing options
            if (subscriptionService.products.isNotEmpty) ...[
              Text(
                'Choose Your Plan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Monthly plan
              _buildPricingCard(
                context,
                title: 'Monthly',
                price: _getPrice(SubscriptionProducts.monthlyPremium),
                period: '/month',
                onTap: isLoading
                    ? null
                    : () => _purchaseProduct(SubscriptionProducts.monthlyPremium),
                isPopular: false,
              ),
              const SizedBox(height: 12),

              // Annual plan (popular)
              _buildPricingCard(
                context,
                title: 'Annual',
                price: _getPrice(SubscriptionProducts.annualPremium),
                period: '/year',
                onTap: isLoading
                    ? null
                    : () => _purchaseProduct(SubscriptionProducts.annualPremium),
                isPopular: true,
                savings: 'Save 17%',
              ),
              const SizedBox(height: 12),

              // Lifetime plan
              _buildPricingCard(
                context,
                title: 'Lifetime',
                price: _getPrice(SubscriptionProducts.lifetimePremium),
                period: 'one-time',
                onTap: isLoading
                    ? null
                    : () => _purchaseProduct(SubscriptionProducts.lifetimePremium),
                isPopular: false,
                savings: 'Best Value',
              ),
            ] else ...[
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load products',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subscriptionService.error ?? 'Unknown error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // Terms
            Text(
              'By purchasing, you agree to our Terms of Service. Subscriptions auto-renew unless cancelled.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required VoidCallback? onTap,
    required bool isPopular,
    String? savings,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: isPopular ? 4 : 0,
      color: isPopular ? colors.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'POPULAR',
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isPopular) const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPopular
                                ? colors.onPrimaryContainer
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPopular
                                    ? colors.onPrimaryContainer
                                    : colors.primary,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            period,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isPopular
                                      ? colors.onPrimaryContainer.withValues(alpha: 0.8)
                                      : colors.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (savings != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        savings,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isPopular ? colors.onPrimaryContainer : colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPrice(String productId) {
    final product = subscriptionService.getProduct(productId);
    if (product == null) return '\$0.00';
    
    // Format price
    try {
      final price = double.parse(product.price);
      return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(price);
    } catch (_) {
      return product.price;
    }
  }
}

