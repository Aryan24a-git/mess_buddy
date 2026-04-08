import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:flutter/foundation.dart';
import 'ad_service.dart';

class UnityAdsService {
  static final UnityAdsService _instance = UnityAdsService._internal();
  factory UnityAdsService() => _instance;

  UnityAdsService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await UnityAds.init(
      gameId: AdService.unityGameId,
      testMode: kDebugMode,
      onComplete: () {
        _isInitialized = true;
        _loadPlacement(AdService.interstitialPlacementId);
        _loadPlacement(AdService.rewardedPlacementId);
      },
      onFailed: (error, message) => debugPrint('Unity Ads Init Failed: $error $message'),
    );
  }

  void _loadPlacement(String placementId) {
    UnityAds.load(
      placementId: placementId,
      onComplete: (placementId) => debugPrint('Load Complete: $placementId'),
      onFailed: (placementId, error, message) => debugPrint('Load Failed: $placementId $error $message'),
    );
  }

  void showInterstitialAd() {
    UnityAds.showVideoAd(
      placementId: AdService.interstitialPlacementId,
      onComplete: (placementId) => _loadPlacement(placementId),
      onFailed: (placementId, error, message) => _loadPlacement(placementId),
      onStart: (placementId) => debugPrint('Ad Start: $placementId'),
      onClick: (placementId) => debugPrint('Ad Click: $placementId'),
    );
  }

  void showRewardedAd({required Function() onReward}) {
    UnityAds.showVideoAd(
      placementId: AdService.rewardedPlacementId,
      onComplete: (placementId) {
        onReward();
        _loadPlacement(placementId);
      },
      onFailed: (placementId, error, message) => _loadPlacement(placementId),
    );
  }
}
