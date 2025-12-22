import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/premium_service.dart';

/// Ad banner widget that only shows for free tier users
class AdBannerWidget extends StatefulWidget {
  final AdSize? adSize;
  final String? adUnitId;

  const AdBannerWidget({
    super.key,
    this.adSize,
    this.adUnitId,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Test ad unit IDs - Replace with your actual AdSense ad unit IDs
  // For Android: ca-app-pub-3940256099942544/6300978111 (test)
  // For iOS: ca-app-pub-3940256099942544/2934735716 (test)
  String get _adUnitId {
    if (widget.adUnitId != null) return widget.adUnitId!;
    
    // Use test ad unit IDs for development
    // TODO: Replace with your actual AdSense ad unit IDs before production
    return 'ca-app-pub-3940256099942544/6300978111'; // Android test ad
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Don't load ads for premium users
    if (premiumService.isPremium) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: widget.adSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          // Don't show error in production, just don't display ad
          if (kDebugMode) {
            print('Ad failed to load: $error');
          }
          ad.dispose();
        },
        onAdOpened: (_) {
          // Ad opened
        },
        onAdClosed: (_) {
          // Ad closed, reload
          _loadAd();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads for premium users
    if (premiumService.isPremium) {
      return const SizedBox.shrink();
    }

    // Don't show if ad not loaded
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

