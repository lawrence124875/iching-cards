/// App 內評分邀請（ASO-STRATEGY §4.1，2026-11-09 Lawrence 同意）。畫面與流程只認這個介面；
/// 套件 in_app_review 只出現在 `store_app_review.dart`。
abstract class AppReview {
  /// 請商店顯示評分視窗。商店自己決定要不要真的顯示（有配額），App 拿不到結果，也不能追問。
  Future<void> request();
}

/// 沒有評分功能（測試）。
class NoAppReview implements AppReview {
  const NoAppReview();

  @override
  Future<void> request() async {}
}
