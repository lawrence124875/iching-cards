/// 播放單一音檔（HANDOFF §9.1：平台相關的部分包在介面後面）。
abstract class AudioPlayback {
  /// 載入檔案，回傳長度；失敗時拋出例外。
  Future<Duration?> load(String filePath);

  /// 開始或繼續播放（不等播完）。
  Future<void> play();
  Future<void> pause();

  /// 目前播放位置（播放中會依時間推算，適合每個畫格讀取）。
  Duration get position;

  Future<void> dispose();
}
