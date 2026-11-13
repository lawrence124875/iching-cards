import 'dart:math';

import '../iching/cast_result.dart';
import '../iching/hexagram_table.dart';
import '../monetization/cast_quota.dart';

/// 今日一卦（0.9.0，參考塔羅 App 的今日一張）：每天（手機當地日期）翻一次，當天再打開看到的是同一卦。
/// 2026-11-13 Lawrence 決定：不計入每日免費起卦次數。存檔沿用 [QuotaStorage]（`daily_hexagram.json`）。
class DailyHexagramStore {
  DailyHexagramStore({QuotaStorage? storage}) : _storage = storage ?? MemoryQuotaStorage();

  final QuotaStorage _storage;

  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// 今天已翻的那一卦（卦序）；還沒翻為 null。
  Future<int?> today(DateTime now) async {
    final j = await _storage.read();
    if (j['day'] != dayKey(now)) return null;
    return (j['hex'] as num?)?.toInt();
  }

  /// 今天的那一卦（還沒翻就翻一卦並記下）。
  Future<int> drawToday(DateTime now, Random random) async {
    final have = await today(now);
    if (have != null) return have;
    final j = await _storage.read();
    final streak = j['day'] == dayKey(_yesterday(now)) ? _streakOf(j) + 1 : 1;
    final hex = random.nextInt(64) + 1;
    await _storage.write({'day': dayKey(now), 'hex': hex, 'streak': streak});
    return hex;
  }

  /// 連續幾天翻了今日一卦（今天或昨天有翻才算，否則 0）。
  Future<int> streak(DateTime now) async {
    final j = await _storage.read();
    final day = j['day'];
    if (day != dayKey(now) && day != dayKey(_yesterday(now))) return 0;
    return _streakOf(j);
  }

  /// 以卦序組成一次「抽一卦」的結果（六爻皆不變），給解讀頁用。
  static CastResult castOf(int hex) => CastResult(
        methodId: 'simple',
        lines: [for (final yang in HexagramTable.byNumber(hex).lines) yang ? LineValue.youngYang : LineValue.youngYin],
      );

  static int _streakOf(Map<String, Object?> j) => (j['streak'] as num?)?.toInt() ?? 1;

  static DateTime _yesterday(DateTime now) => DateTime(now.year, now.month, now.day - 1);
}
