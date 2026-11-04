import '../iching/cast_result.dart';
import '../iching/focus_rule.dart';
import '../iching/hexagram_table.dart';
import '../meihua/meihua_cast.dart';
import '../meihua/meihua_forecast.dart';

/// 雙卦交叉解讀（易經 × 梅花，HANDOFF §2.4），純計算，單元測試見 test/cross_test.dart。
///
/// 兩套解卦先各自轉成同一格式 [UnifiedReading]：五級趨勢、主題標籤（八卦鍵）、應期區間；
/// 再由 [CrossResult] 判斷共識／部分呼應／分歧，並依方向組合挑模板（文案在 iching-content `<語言>/cross/templates.json`）。

/// 趨勢方向：大吉／吉＝正，平＝中，小阻／阻＝負。
enum TrendDirection { pos, even, neg }

TrendDirection directionOf(TrendLevel l) => switch (l) {
      TrendLevel.great || TrendLevel.good => TrendDirection.pos,
      TrendLevel.even => TrendDirection.even,
      TrendLevel.minorBlock || TrendLevel.block => TrendDirection.neg,
    };

/// 共識（同方向）、部分呼應（一方持平，仍算分歧）、分歧（一正一負）。
enum CrossVerdict { consensus, partial, divergence }

/// 易經卦辭／爻辭的吉凶分數表（iching-content `cross/iching_trend.json`，由 tools/build_cross.py 產生）。
/// 每段分數已限制在 −2～+2；鍵：卦序兩位數 → {"judgment": n, "1".."7": n}（7＝用九／用六）。
class IchingTrendTable {
  IchingTrendTable(this._scores);

  factory IchingTrendTable.fromJson(Map<String, dynamic> j) => IchingTrendTable({
        for (final e in j.entries)
          int.parse(e.key): {
            for (final s in (e.value as Map<String, dynamic>).entries) s.key: (s.value as num).toInt(),
          },
      });

  final Map<int, Map<String, int>> _scores;

  /// 查不到時當 0（平）。
  int score(FocusItem item) {
    final key = item.kind == FocusKind.judgment ? 'judgment' : '${item.position}';
    return (_scores[item.hexagram]?[key] ?? 0).clamp(-2, 2);
  }
}

/// 易經端映射到五級趨勢與應期。
class IchingForecast {
  IchingForecast._();

  /// 分數 → 五級：2 大吉、1 吉、0 平、−1 小阻、−2 阻。
  static TrendLevel levelOfScore(int s) => switch (s.clamp(-2, 2)) {
        2 => TrendLevel.great,
        1 => TrendLevel.good,
        0 => TrendLevel.even,
        -1 => TrendLevel.minorBlock,
        _ => TrendLevel.block,
      };

  /// 本次重點各段分數平均、四捨五入（.5 遠離 0）。
  static TrendLevel level(List<int> scores) {
    if (scores.isEmpty) return TrendLevel.even;
    final avg = scores.map((s) => s.clamp(-2, 2)).reduce((a, b) => a + b) / scores.length;
    return levelOfScore(avg.round());
  }

  /// 應期看主要那一段：初、二爻近期；三、四爻數日內；五、上爻數週內；卦辭或用九／用六一季內。
  static TimingWindow timing(FocusResult focus) {
    final main = focus.items.firstWhere((i) => i.primary, orElse: () => focus.items.first);
    final p = main.kind == FocusKind.line ? main.position! : 0;
    return switch (p) {
      1 || 2 => TimingWindow.soon,
      3 || 4 => TimingWindow.days,
      5 || 6 => TimingWindow.weeks,
      _ => TimingWindow.season,
    };
  }
}

/// 一套解卦的統一輸出。[tags] 是八卦鍵（Trigram.name），顯示文字在模板 `tags`。
class UnifiedReading {
  const UnifiedReading({required this.level, required this.timing, required this.tags});

  /// 易經：依朱熹變爻規則選段、查吉凶表；標籤＝本卦上下卦。
  factory UnifiedReading.iching(CastResult cast, IchingTrendTable table, {FocusRule rule = const ZhuXiFocusRule()}) {
    final focus = rule.focus(cast);
    final info = HexagramTable.byNumber(cast.primary);
    return UnifiedReading(
      level: IchingForecast.level([for (final i in focus.items) table.score(i)]),
      timing: IchingForecast.timing(focus),
      tags: _unique([info.upper.name, info.lower.name]),
    );
  }

  /// 梅花：沿用既有趨勢與應期；標籤＝體卦、用卦。
  factory UnifiedReading.meihua(MeihuaCast c) =>
      UnifiedReading(level: c.trend, timing: c.timing, tags: _unique([c.ti.name, c.yong.name]));

  final TrendLevel level;
  final TimingWindow timing;
  final List<String> tags;

  TrendDirection get direction => directionOf(level);

  static List<String> _unique(List<String> l) => [...{...l}];
}

/// 兩套解卦的交叉結果。
class CrossResult {
  CrossResult(this.iching, this.meihua);

  final UnifiedReading iching;
  final UnifiedReading meihua;

  CrossVerdict get verdict => verdictOf(iching.direction, meihua.direction);

  static CrossVerdict verdictOf(TrendDirection a, TrendDirection b) {
    if (a == b) return CrossVerdict.consensus;
    if (a == TrendDirection.even || b == TrendDirection.even) return CrossVerdict.partial;
    return CrossVerdict.divergence;
  }

  /// 兩邊都有的主題（依易經端順序）。
  List<String> get sharedTags => [for (final t in iching.tags) if (meihua.tags.contains(t)) t];

  bool get timingOverlap => iching.timing == meihua.timing;

  /// 兩邊較近的應期（應期不同時當第一個檢查點）。
  TimingWindow get nearerTiming => iching.timing.index <= meihua.timing.index ? iching.timing : meihua.timing;

  /// 模板鍵：易經方向_梅花方向（如 pos_neg）。
  String get comboKey => '${iching.direction.name}_${meihua.direction.name}';

  /// 從候選文案中固定挑一則（同一組卦每次回看都一樣）。
  static T pick<T>(List<T> items, int seed) => items[seed.abs() % items.length];

  /// 挑選用的種子：易經本卦與梅花本卦。
  static int seedOf(int ichingPrimary, int meihuaPrimary) => ichingPrimary * 64 + meihuaPrimary;
}
