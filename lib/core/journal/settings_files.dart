import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 一併放進卦記備份檔的設定（換手機、Android↔iPhone 時保留）。
/// 只收白名單裡的檔案：不含每日起卦額度（避免重設次數）、通知權限紀錄、使用統計同意、介紹頁是否看過。
/// 訂閱不在這裡：由商店帳號「恢復購買」取回。
class SettingsFiles {
  SettingsFiles._();

  static const names = [
    'theme.json', // 外觀
    'guying.json', // 古圖
    'birth_profile.json', // 出生資料（紫微・八字）
    'meihua_city.txt', // 梅花城市／經度
    'hexagram_quiz.json', // 認卦練習進度
    'daily_hexagram.json', // 今日一卦連續天數
  ];

  static Future<Directory> _dir() => getApplicationDocumentsDirectory();

  /// 讀出存在的設定檔（檔名 → 內容）。讀不到的略過。
  static Future<Map<String, String>> collect() async {
    final dir = await _dir();
    final out = <String, String>{};
    for (final n in names) {
      try {
        final f = File('${dir.path}/$n');
        if (await f.exists()) out[n] = await f.readAsString();
      } catch (_) {}
    }
    return out;
  }

  /// 寫回設定檔（只寫白名單），回傳寫入幾個。重新開啟 App 後生效。
  static Future<int> restore(Map<String, String> files) async {
    final dir = await _dir();
    var n = 0;
    for (final e in files.entries) {
      if (!names.contains(e.key)) continue;
      try {
        await File('${dir.path}/${e.key}').writeAsString(e.value);
        n++;
      } catch (_) {}
    }
    return n;
  }
}
