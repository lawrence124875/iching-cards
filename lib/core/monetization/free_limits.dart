/// 免費版限制（REFERENCE §23.1；2026-10-28 定案：每天 1 次＋獎勵 1 次，見 HANDOFF §2.1）。數值可由 Remote Config 調整（`qg_` 開頭，只設在謙卦 App 條件下），
/// 不設就用這裡的預設值。解讀內容（三組解讀、爻、東西相映、經文）永遠不鎖。
class FreeLimits {
  const FreeLimits({
    this.castsPerDay = 1,
    this.rewardedPerDay = 1,
    this.journalMax = 10,
    this.freeBreathMinutes = const {1, 2},
    this.meihuaCastsPerDay = 1,
    this.meihuaRewardedPerDay = 1,
    this.meihuaFreeLessons = 1,
  });

  /// 每天免費起卦次數（抽一卦、三枚銅錢合計）。
  final int castsPerDay;

  /// 每天最多可用獎勵廣告換幾次額外起卦。
  final int rewardedPerDay;

  /// 免費版卦記上限（已存的不會被刪，只是不能再新增）。
  final int journalMax;

  /// 免費版可選的呼吸時長；其餘時長與雙耳節拍屬訂閱。
  final Set<int> freeBreathMinutes;

  /// 梅花易數（與起卦額度分開算，2026-10-30 定案）：每天免費時間起卦次數、獎勵廣告上限、免費課數。
  final int meihuaCastsPerDay;
  final int meihuaRewardedPerDay;
  final int meihuaFreeLessons;

  /// 梅花易數的每日額度（給另一個 [CastQuota] 用）。
  FreeLimits get meihua => FreeLimits(castsPerDay: meihuaCastsPerDay, rewardedPerDay: meihuaRewardedPerDay);

  /// Remote Config 參數名稱與預設值（firebase_telemetry 設定預設值用）。
  static const remoteDefaults = <String, int>{
    'qg_free_casts_per_day': 1,
    'qg_free_rewarded_per_day': 1,
    'qg_free_journal_max': 10,
    'qg_meihua_free_casts_per_day': 1,
    'qg_meihua_free_rewarded_per_day': 1,
    'qg_meihua_free_lessons': 1,
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
      meihuaCastsPerDay: v('qg_meihua_free_casts_per_day', min: 1),
      meihuaRewardedPerDay: v('qg_meihua_free_rewarded_per_day'),
      meihuaFreeLessons: v('qg_meihua_free_lessons', max: 12),
    );
  }
}
