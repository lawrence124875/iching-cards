import 'package:flutter/widgets.dart';

/// 廣告（REFERENCE §23；位置規則 HANDOFF §2.1，2026-10-28）。畫面只認這個介面；
/// AdMob 只出現在 `lib/core/admob/admob_ads.dart`。
///
/// 三種廣告：底部橫幅（首頁、卦記列表、起卦前畫面）、插頁（只在每天第一次免費起卦、
/// 顯示解讀前播一則）、獎勵（使用者自己選擇觀看，換一次額外起卦）。訂閱戶全部不顯示（[enabled] = false）。
abstract class AdService {
  /// 訂閱狀態改變時由 main.dart 設定；false＝不載入、不顯示任何廣告。
  bool get enabled;
  set enabled(bool value);

  /// 底部橫幅；不顯示時回傳 null（畫面就不留空位）。
  Widget? banner();

  /// 先在背景載入插頁（今天第一次免費起卦一開始就呼叫，翻牌、擲錢的時間拿來載入）。
  void preloadInterstitial();

  /// 等插頁載入好，最多 [timeout]；已載入就立刻回傳。
  Future<AdLoad> loadInterstitial({Duration timeout = const Duration(seconds: 3)});

  /// 播放已載入的插頁，關掉後才回傳；真的顯示過回傳 true。
  Future<bool> showInterstitial();

  /// 載入並播放獎勵廣告（使用者選擇「看廣告再起一卦」時）。
  Future<RewardedOutcome> showRewarded();

  /// 是否需要在選單提供「廣告隱私設定」（歐洲等需要同意的地區才為 true，Google UMP）。
  bool get privacyOptionsRequired;

  Future<void> showPrivacyOptions();
}

/// 插頁載入結果。除了 [ready] 以外都直接顯示解讀。
enum AdLoad {
  ready,

  /// 不能請求廣告（訂閱戶、尚未同意、SDK 未初始化）。
  unavailable,

  /// 載入失敗或沒有填充。
  failed,

  /// 超過等待時間。
  timeout,
}

/// 獎勵廣告結果。[failed]（載入失敗、無填充、播放失敗）仍給這一次起卦（HANDOFF §2.1）。
enum RewardedOutcome {
  /// 看完、拿到獎勵。
  earned,

  /// 有播放，但使用者中途關掉。
  dismissed,

  failed,
}

/// 沒有廣告（測試、訂閱戶、AdMob 初始化失敗）。
class NoAds implements AdService {
  @override
  bool enabled = false;

  @override
  Widget? banner() => null;

  @override
  void preloadInterstitial() {}

  @override
  Future<AdLoad> loadInterstitial({Duration timeout = const Duration(seconds: 3)}) async => AdLoad.unavailable;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Future<RewardedOutcome> showRewarded() async => RewardedOutcome.failed;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> showPrivacyOptions() async {}
}
