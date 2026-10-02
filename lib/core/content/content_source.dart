import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'hexagram_content.dart';

/// 畫面只透過這個介面取得內容（依賴反轉）。目前實作讀 App 內資產；
/// 日後換成其他來源，畫面不必修改。
abstract class ContentSource {
  /// 該卦的解讀；尚未撰寫時回傳 null。
  Future<HexagramContent?> hexagram(int number);

  /// 該卦的牌面圖；尚無圖時回傳 null（畫面顯示佔位圖）。
  Future<ImageProvider?> cardArt(int number);

  /// 牌面圖原始位元組（例如給鎖定畫面的播放卡片用）；尚無圖時回傳 null。
  Future<Uint8List?> cardArtBytes(int number);
}
