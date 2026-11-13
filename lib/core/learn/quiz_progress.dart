import 'dart:math';

import '../monetization/cast_quota.dart';

/// 認卦練習的進度（0.9.0，參考塔羅 App 的認牌練習）：簡化的間隔重複（Leitner 盒）。
/// 每卦一個盒號 0～4：答對 +1、答錯回 0；出題時盒號越低越常出現。存檔沿用 [QuotaStorage]（`hexagram_quiz.json`）。
class QuizProgress {
  QuizProgress({QuotaStorage? storage}) : _storage = storage ?? MemoryQuotaStorage();

  final QuotaStorage _storage;
  static const maxBox = 4;

  Future<Map<int, int>> boxes() async {
    final j = await _storage.read();
    final raw = j['boxes'];
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (int.tryParse('${e.key}') != null && e.value is num) int.parse('${e.key}'): (e.value as num).toInt(),
    };
  }

  /// 已熟悉（盒號達到最高）的卦數。
  Future<int> mastered() async => (await boxes()).values.where((b) => b >= maxBox).length;

  /// 依盒號加權抽 [count] 個不重複的卦序（盒號 0 權重 5，盒號 4 權重 1）。
  Future<List<int>> pick(int count, Random random) async {
    final b = await boxes();
    final pool = [for (var n = 1; n <= 64; n++) n];
    final out = <int>[];
    while (out.length < count && pool.isNotEmpty) {
      final weights = [for (final n in pool) maxBox + 1 - (b[n] ?? 0).clamp(0, maxBox)];
      var r = random.nextInt(weights.fold(0, (a, w) => a + w));
      var i = 0;
      while (r >= weights[i]) {
        r -= weights[i];
        i++;
      }
      out.add(pool.removeAt(i));
    }
    return out;
  }

  Future<void> record(int hex, {required bool correct}) async {
    final b = await boxes();
    b[hex] = correct ? min((b[hex] ?? 0) + 1, maxBox) : 0;
    await _storage.write({
      'boxes': {for (final e in b.entries) '${e.key}': e.value},
    });
  }
}
