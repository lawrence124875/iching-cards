import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../monetization/ad_service.dart';

/// AdMob 實作（REFERENCE §23）。**唯一 import google_mobile_ads 的檔案**；拔除廣告＝
/// Services 改用 NoAds、移除套件與 patch_android.sh 的 APPLICATION_ID。
///
/// - 同意（Google UMP）：歐洲等地區先顯示同意表單，`canRequestAds` 為 true 才載入廣告；
///   表單內容在 AdMob →「隱私權與訊息」設定（使用者操作）。
/// - 廣告單元 ID 由 CI 以 --dart-define 注入（GitHub Secrets）；沒注入時用 Google 官方測試 ID。
/// - 廣告內容分級上限 PG；敏感類別（酒精、賭博等）在 AdMob 後台封鎖（PLAY_CONSOLE.md §5 第 6 項）。
class AdMobAds implements AdService {
  AdMobAds._();

  // trim：Secret 若誤存空白或換行，視同沒設定（不拿無效 ID 去請求）。
  static final _bannerId = const String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID').trim();
  static final _interstitialId = const String.fromEnvironment('ADMOB_INTERSTITIAL_AD_UNIT_ID').trim();
  static final _rewardedId = const String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID').trim();

  // Google 官方測試廣告單元（Android 與 iOS 各一組）。正式單元由 CI 以 dart-define 傳入（iOS 建置傳 iOS 的單元）。
  // 每個單元各自防呆：沒注入的那個用測試 ID；上架用的 AAB 由 CI 檢查三個都有值。
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;
  static String _unit(String id, {required String ios, required String android}) =>
      id.isNotEmpty ? id : (_ios ? ios : android);
  static String get bannerUnit => _unit(_bannerId,
      ios: 'ca-app-pub-3940256099942544/2934735716', android: 'ca-app-pub-3940256099942544/6300978111');
  static String get _interstitialUnit => _unit(_interstitialId,
      ios: 'ca-app-pub-3940256099942544/4411468910', android: 'ca-app-pub-3940256099942544/1033173712');
  static String get _rewardedUnit => _unit(_rewardedId,
      ios: 'ca-app-pub-3940256099942544/1712485313', android: 'ca-app-pub-3940256099942544/5224354917');

  /// 三個廣告單元都用正式 ID（Release 說明顯示用）。
  static bool get usingRealUnits => _bannerId.isNotEmpty && _interstitialId.isNotEmpty && _rewardedId.isNotEmpty;

  bool _started = false;
  bool _enabled = false;
  bool _sdkReady = false;
  bool _privacyRequired = false;
  bool _fullScreenShowing = false;
  InterstitialAd? _interstitial;
  DateTime? _interstitialLoadedAt;
  Completer<bool>? _interstitialLoading;
  RewardedAd? _rewarded;
  final ValueNotifier<int> _bannerEpoch = ValueNotifier(0);

  /// 建立後立刻可用（還不顯示廣告）；[start] 在 runApp 之後於背景執行，
  /// 不讓同意表單或網路拖慢啟動。
  static AdMobAds create() => AdMobAds._();

  /// 先查同意狀態（需要時顯示表單），可以請求廣告才初始化 SDK。任何失敗都只是不顯示廣告。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _gatherConsent().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('廣告同意流程失敗：$e');
    }
    try {
      if (await ConsentInformation.instance.canRequestAds()) await _startSdk();
    } catch (e) {
      debugPrint('AdMob 初始化失敗，不顯示廣告：$e');
    }
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) async {
        try {
          _privacyRequired = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
        } catch (_) {}
        if (!done.isCompleted) done.complete();
      }),
      (FormError e) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  Future<void> _startSdk() async {
    if (_sdkReady) return;
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
    );
    _sdkReady = true;
    _bannerEpoch.value++;
  }

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _bannerEpoch.value++; // 讓畫面上的橫幅重建（訂閱後立刻消失）
    if (!value) {
      _interstitial?.dispose();
      _interstitial = null;
      _rewarded?.dispose();
      _rewarded = null;
    }
  }

  bool get _canShow => _enabled && _sdkReady;

  // ---------------- 橫幅 ----------------

  @override
  Widget? banner() => _BannerSlot(ads: this);

  // ---------------- 插頁 ----------------
  // 一天最多一則（每天第一次免費起卦、顯示解讀前）。不預先常駐載入：起卦一開始才載入，
  // 避免白白請求；AdMob 廣告載入超過一小時會過期，所以超過 50 分鐘就重新載入。

  bool get _interstitialFresh {
    final at = _interstitialLoadedAt;
    return _interstitial != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 50);
  }

  Future<bool> _loadInterstitial() {
    if (!_canShow) return Future.value(false);
    if (_interstitialFresh) return Future.value(true);
    final pending = _interstitialLoading;
    if (pending != null) return pending.future;
    _interstitial?.dispose();
    _interstitial = null;
    final c = _interstitialLoading = Completer<bool>();
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoadedAt = DateTime.now();
          _interstitialLoading = null;
          c.complete(true);
        },
        onAdFailedToLoad: (_) {
          _interstitialLoading = null;
          c.complete(false);
        },
      ),
    );
    return c.future;
  }

  @override
  void preloadInterstitial() => unawaited(_loadInterstitial());

  @override
  Future<AdLoad> loadInterstitial({Duration timeout = const Duration(seconds: 3)}) async {
    if (!_canShow) return AdLoad.unavailable;
    try {
      return await _loadInterstitial().timeout(timeout) ? AdLoad.ready : AdLoad.failed;
    } on TimeoutException {
      return AdLoad.timeout; // 晚到的廣告留著，50 分鐘內下次可用
    }
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    final foreground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!_canShow || !_interstitialFresh || ad == null || _fullScreenShowing || !foreground) return false;
    _interstitial = null;
    _interstitialLoadedAt = null;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _fullScreenShowing = true,
      onAdDismissedFullScreenContent: (a) {
        _fullScreenShowing = false;
        a.dispose();
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        _fullScreenShowing = false;
        a.dispose();
        if (!closed.isCompleted) closed.complete(false);
      },
    );
    _fullScreenShowing = true;
    await ad.show();
    return closed.future.timeout(const Duration(minutes: 3), onTimeout: () {
      _fullScreenShowing = false;
      return true;
    });
  }

  // ---------------- 獎勵 ----------------

  Future<bool> _loadRewarded() async {
    if (!_canShow) return false;
    if (_rewarded != null) return true;
    final c = Completer<bool>();
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          if (!c.isCompleted) c.complete(true);
        },
        onAdFailedToLoad: (_) {
          if (!c.isCompleted) c.complete(false);
        },
      ),
    );
    return c.future.timeout(const Duration(seconds: 10), onTimeout: () => false);
  }

  @override
  Future<RewardedOutcome> showRewarded() async {
    if (!await _loadRewarded()) return RewardedOutcome.failed;
    final ad = _rewarded;
    if (ad == null || _fullScreenShowing) return RewardedOutcome.failed;
    _rewarded = null;
    final closed = Completer<bool>(); // true＝有顯示
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        _fullScreenShowing = false;
        a.dispose();
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        _fullScreenShowing = false;
        a.dispose();
        if (!closed.isCompleted) closed.complete(false);
      },
    );
    _fullScreenShowing = true;
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    final shown = await closed.future.timeout(const Duration(minutes: 3), onTimeout: () => true);
    if (earned) return RewardedOutcome.earned;
    return shown ? RewardedOutcome.dismissed : RewardedOutcome.failed;
  }

  // ---------------- 隱私選項 ----------------

  @override
  bool get privacyOptionsRequired => _privacyRequired;

  @override
  Future<void> showPrivacyOptions() async {
    final c = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? e) async {
      try {
        if (await ConsentInformation.instance.canRequestAds()) await _startSdk();
      } catch (_) {}
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }
}

/// 底部橫幅：載入成功才佔位；訂閱後（enabled＝false）自動消失。
class _BannerSlot extends StatefulWidget {
  const _BannerSlot({required this.ads});

  final AdMobAds ads;

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.ads._bannerEpoch.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (!widget.ads._canShow) {
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _loaded = false);
    } else if (_ad == null) {
      _load();
    }
  }

  void _load() {
    if (!widget.ads._canShow) return;
    _ad = BannerAd(
      adUnitId: AdMobAds.bannerUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    widget.ads._bannerEpoch.removeListener(_refresh);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: Center(
          child: SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad)),
        ),
      ),
    );
  }
}
