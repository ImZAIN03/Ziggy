import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton that owns every AdMob interaction for Ziggy.
///
/// Usage:
///   await AdManager.instance.initialize();   // once in main()
///   AdManager.instance.onGameOver(onComplete: () { ... });
///   AdManager.instance.showRewarded(onRewarded: () { ... }, ...);
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  // ── Ad unit IDs ──────────────────────────────────────────────────────────────

  // Google's canonical test IDs — safe to use during development.
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedId     = 'ca-app-pub-3940256099942544/5224354917';

  // Production IDs — only active in release builds.
  static const _prodInterstitialId = 'ca-app-pub-9788310162130092/2595813717';
  static const _prodRewardedId     = 'ca-app-pub-9788310162130092/5451939126';

  static String get _interstitialId =>
      kDebugMode ? _testInterstitialId : _prodInterstitialId;

  static String get _rewardedId =>
      kDebugMode ? _testRewardedId : _prodRewardedId;

  // ── Internal state ────────────────────────────────────────────────────────────

  InterstitialAd? _interstitial;
  RewardedAd?     _rewarded;

  bool _interstitialLoading = false;
  bool _rewardedLoading     = false;

  /// Counts every game-over; interstitial fires on multiples of 3.
  int _gameOverCount = 0;

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Initialise the AdMob SDK and pre-load both ad formats.
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
  }

  /// Returns [true] when a rewarded ad is pre-loaded and ready to show.
  bool get isRewardedReady => _rewarded != null;

  // ── Interstitial ──────────────────────────────────────────────────────────────

  void loadInterstitial() {
    if (_interstitialLoading) return;
    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdManager] Interstitial failed to load: $err');
          _interstitial = null;
          _interstitialLoading = false;
        },
      ),
    );
  }

  /// Call on every game-over. Shows an interstitial every 3rd time, then calls
  /// [onComplete] once the ad is dismissed (or immediately if no ad fires).
  void onGameOver({required VoidCallback onComplete}) {
    _gameOverCount++;

    if (_gameOverCount % 3 == 0 && _interstitial != null) {
      _showInterstitial(onComplete: onComplete);
    } else {
      onComplete();
    }
  }

  void _showInterstitial({required VoidCallback onComplete}) {
    final ad = _interstitial!;
    _interstitial = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadInterstitial(); // pre-load the next one
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        debugPrint('[AdManager] Interstitial failed to show: $err');
        a.dispose();
        loadInterstitial();
        onComplete(); // still show game-over screen
      },
    );

    ad.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────────

  void loadRewarded() {
    if (_rewardedLoading) return;
    _rewardedLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdManager] Rewarded failed to load: $err');
          _rewarded = null;
          _rewardedLoading = false;
        },
      ),
    );
  }

  /// Show the rewarded ad.
  ///
  /// * [onRewarded]               — user watched enough to earn the reward.
  /// * [onDismissedWithoutReward] — user closed the ad before earning.
  /// * [onFailed]                 — ad not available or failed to show.
  void showRewarded({
    required VoidCallback onRewarded,
    VoidCallback? onDismissedWithoutReward,
    VoidCallback? onFailed,
  }) {
    if (_rewarded == null) {
      debugPrint('[AdManager] Rewarded ad not ready.');
      onFailed?.call();
      return;
    }

    final ad = _rewarded!;
    _rewarded = null; // prevent double-show

    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadRewarded(); // pre-load next
        if (!earned) onDismissedWithoutReward?.call();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        debugPrint('[AdManager] Rewarded failed to show: $err');
        a.dispose();
        loadRewarded();
        onFailed?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
        onRewarded();
      },
    );
  }
}
