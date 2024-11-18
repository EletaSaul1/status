import 'dart:io';
import 'dart:math';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7379857532809789/5271941115'; // Replace with your ad unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7379857532809789/9774292905'; // Replace with your ad unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static bool shouldShowInterstitial() {
    // 30% chance to show interstitial ad
    return Random().nextDouble() < 0.3;
  }
}
