import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  DateTime? _lastAdShow;
  bool _isInitialized = false;

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7379857532809789/5271941115'; // Test Banner ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7379857532809789/9774292905'; // Test Interstitial ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  Future<bool> tryToShowInterstitialAd() async {
    if (_interstitialAd != null) {
      // Check if enough time has passed since last ad
      if (_lastAdShow != null) {
        final timeSince = DateTime.now().difference(_lastAdShow!);
        if (timeSince.inSeconds < 30) {
          return false; // Minimum 30 seconds between ads
        }
      }

      try {
        await _interstitialAd!.show();
        _lastAdShow = DateTime.now();
        return true;
      } catch (e) {
        log('Error showing interstitial ad: $e');
        return false;
      }
    }

    // If no ad is loaded, try to load one
    await _loadInterstitial();
    return false;
  }

  Future<void> _loadInterstitial() async {
    if (_interstitialAd != null) return;

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _setupInterstitialCallbacks();
          },
          onAdFailedToLoad: (error) {
            log('Interstitial ad failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      log('Error loading interstitial ad: $e');
      _interstitialAd = null;
    }
  }

  void _setupInterstitialCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastAdShow = DateTime.now();
        _loadInterstitial(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('Failed to show interstitial ad: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial(); // Try loading again
      },
    );
  }

  static BannerAd createBannerAd({
    required Function() onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
      request: const AdRequest(),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
