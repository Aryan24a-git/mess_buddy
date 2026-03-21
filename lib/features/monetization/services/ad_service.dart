import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;

  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;

  // Use test ad units
  static const String bannerAdUnitId = kReleaseMode
      ? 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxx' // Actual ID
      : 'ca-app-pub-3940256099942544/6300978111'; // Test ID

  static const String interstitialAdUnitId = kReleaseMode
      ? 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxx' // Actual ID
      : 'ca-app-pub-3940256099942544/1033173712'; // Test ID

  Future<void> init() async {
    if (kIsWeb) return; 
    await MobileAds.instance.initialize();
    _isInitialized = true;
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (!_isInitialized || kIsWeb) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null && !kIsWeb) {
      _interstitialAd!.show();
      _interstitialAd = null; // Prevent showing the same ad again
    }
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            print('BannerAd failed to load: $error');
          }
        },
      ),
    );
  }
}
