import '../iching/trigram.dart';
import 'meihua_engine.dart';
import 'wuxing.dart';

/// 五級趨勢（不用「凶」字）。名稱與說明在內容 roles.json 的 `level`。
enum TrendLevel { great, good, even, minorBlock, block }

/// 應期區間：近期／數日內／數週內／一季內。名稱在 roles.json 的 `timing`。
enum TimingWindow { soon, days, weeks, season }

/// 梅花易數的趨勢與應期，純計算（HANDOFF §2.2，單元測試見 test/meihua_test.dart）。
///
/// 趨勢＝體用生剋分數＋月令旺衰分數：
/// - 生剋：用生體 +2、比和 +1、體克用 +1、體生用 −1、用克體 −2。
/// - 旺衰：旺／相 +1、休 0、囚／死 −1。
/// - 合計 ≥2 大吉、1 吉、0 平、−1 小阻、≤−2 阻。
///
/// 應期＝體用先天卦數之和（2–16）＋體卦旺衰：旺最快、相休次之、囚死最慢；
/// 卦數合大於 8 再慢一級。結果只取區間，不給確切日期。
class MeihuaForecast {
  MeihuaForecast._();

  static int relationScore(TiYongRelation r) => switch (r) {
        TiYongRelation.yongGeneratesTi => 2,
        TiYongRelation.sameElement => 1,
        TiYongRelation.tiOvercomesYong => 1,
        TiYongRelation.tiGeneratesYong => -1,
        TiYongRelation.yongOvercomesTi => -2,
      };

  static int strengthScore(SeasonalStrength s) => switch (s) {
        SeasonalStrength.prosperous || SeasonalStrength.strong => 1,
        SeasonalStrength.resting => 0,
        SeasonalStrength.confined || SeasonalStrength.dead => -1,
      };

  static TrendLevel level(TiYongRelation r, SeasonalStrength s) {
    final score = relationScore(r) + strengthScore(s);
    if (score >= 2) return TrendLevel.great;
    if (score == 1) return TrendLevel.good;
    if (score == 0) return TrendLevel.even;
    if (score == -1) return TrendLevel.minorBlock;
    return TrendLevel.block;
  }

  /// 體用先天卦數之和。
  static int numberSum(Trigram ti, Trigram yong) => MeihuaEngine.numberOf(ti) + MeihuaEngine.numberOf(yong);

  static TimingWindow timing(Trigram ti, Trigram yong, SeasonalStrength s) {
    final base = switch (s) {
      SeasonalStrength.prosperous => 0,
      SeasonalStrength.strong || SeasonalStrength.resting => 1,
      SeasonalStrength.confined || SeasonalStrength.dead => 2,
    };
    final slow = numberSum(ti, yong) > 8 ? 1 : 0;
    return TimingWindow.values[(base + slow).clamp(0, TimingWindow.values.length - 1)];
  }

  /// 小阻／阻的化解方向：補「生體」的五行（用克體時它也是通關之氣，用→它→體）。
  static WuXing remedyElement(WuXing ti) => WuXing.values[(ti.index + 4) % 5];

  static bool needsRemedy(TrendLevel l) => l == TrendLevel.minorBlock || l == TrendLevel.block;
}
