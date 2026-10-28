/// 免費版限制（REFERENCE §23.1；2026-10-28 定案：每天 1 次＋獎勵 1 次，見 HANDOFF §2.1）。數值可由 Remote Config 調整（`qg_` 開頭，只設在謙卦 App 條件下），
/// 不設就用這裡的預設值。解讀內容（三組解讀、爻、東西相映、經文）永遠不鎖。
class FreeLimits {
  const FreeLimits({
    this.castsPerDay = 1,
    this.rewardedPerDay = 1,
    this.journalMax = 10,
    this.freeBreathMinutes = const {1, 2},
  });

  /// 每天免費起卦次數（抽一卦、三枚銅錢合計）。
  final int castsPerDay;

  /// 每天最多可用獎勵廣告換幾次額外起卦。
  final int rewardedPerDay;

  /// 免費版卦記上限（已存的不會被刪，只是不能再新增）。
  final int journalMax;

  /// 免費版可選的呼吸時長；其餘時長與雙耳節拍屬訂閱。
  final Set<int> freeBreathMinutes;

  /// Remote Config 參數名稱與預設值（firebase_telemetry 設定預設值用）。
  static const remoteDefaults = <String, int>{
    'qg_free_casts_per_day': 1,
    'qg_free_rewarded_per_day': 1,
    'qg_free_journal_max': 10,
  };

  /// 由遠端數值建立；讀不到或數值不合理就用預設。
  factory FreeLimits.from(int Function(String key, int fallback) read) {
    int v(String k, {int min = 0, int max = 1000}) {
      final d = remoteDefaults[k]!;
      final x = read(k, d);
      return (x < min || x > max) ? d : x;
    }

    return FreeLimits(
      castsPerDay: v('qg_free_casts_per_day', min: 1),
      rewardedPerDay: v('qg_free_rewarded_per_day'),
      journalMax: v('qg_free_journal_max', min: 1),
    );
  }
}
