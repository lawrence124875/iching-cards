/// App 更新提示（2026-10-28 Lawrence 決定：每一版都要有，HANDOFF §2）。畫面只認這個介面；
/// Google Play In-App Updates 只出現在 `play_app_updates.dart`。
abstract class AppUpdates {
  /// 商店有新版、而且可以在 App 內背景下載時回傳 true。查不到（非 Play 安裝、離線、iOS）回傳 false。
  Future<bool> available();

  /// 開始背景下載（Play 會先問使用者）；下載完成回傳 true。
  Future<bool> download();

  /// 安裝已下載的新版（App 會重新啟動）。
  Future<void> install();
}

/// 沒有更新功能（測試、iOS）。
class NoAppUpdates implements AppUpdates {
  const NoAppUpdates();

  @override
  Future<bool> available() async => false;

  @override
  Future<bool> download() async => false;

  @override
  Future<void> install() async {}
}
