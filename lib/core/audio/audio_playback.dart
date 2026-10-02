/// 播放單一音檔（HANDOFF §9.1：平台相關的部分包在介面後面）。
/// 整個 App 只有一個播放器（背景播放與通知控制的套件只支援單一播放器）。
abstract class AudioPlayback {
  /// 載入檔案並設定通知／鎖定畫面顯示的資訊，回傳長度；失敗時拋出例外。
  Future<Duration?> load(
    String filePath, {
    required String id,
    required String title,
    String subtitle = '',
    String? artFilePath,
  });

  /// 開始或繼續播放（不等播完）。
  Future<void> play();
  Future<void> pause();

  /// 停止並移除通知。
  Future<void> stop();

  /// 目前播放位置（播放中會依時間推算，適合每個畫格讀取）。
  Duration get position;

  /// 播放／暫停狀態改變（包含使用者在通知或鎖定畫面按的）。
  Stream<bool> get playingChanges;

  /// 播放到結尾。
  Stream<void> get completed;
}
