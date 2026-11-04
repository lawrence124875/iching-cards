import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/cross/cross_reading.dart';
import 'package:iching_cards/core/iching/cast_result.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/meihua/lunar_moment.dart';
import 'package:iching_cards/core/meihua/meihua_engine.dart';
import 'package:iching_cards/core/meihua/meihua_forecast.dart';

CastResult cast(List<int> v) => CastResult(methodId: 'coins', lines: [for (final x in v) LineValue.fromValue(x)]);

UnifiedReading u(TrendLevel l, TimingWindow t, List<String> tags) => UnifiedReading(level: l, timing: t, tags: tags);

void main() {
  group('易經映射到五級', () {
    test('分數 → 五級', () {
      expect(IchingForecast.levelOfScore(2), TrendLevel.great);
      expect(IchingForecast.levelOfScore(1), TrendLevel.good);
      expect(IchingForecast.levelOfScore(0), TrendLevel.even);
      expect(IchingForecast.levelOfScore(-1), TrendLevel.minorBlock);
      expect(IchingForecast.levelOfScore(-2), TrendLevel.block);
      expect(IchingForecast.levelOfScore(5), TrendLevel.great);
      expect(IchingForecast.levelOfScore(-9), TrendLevel.block);
    });

    test('多段先限制 −2～+2 再平均、四捨五入', () {
      expect(IchingForecast.level([2, -1]), TrendLevel.good); // 0.5 → 1
      expect(IchingForecast.level([1, -2]), TrendLevel.minorBlock); // −0.5 → −1
      expect(IchingForecast.level([1, 1]), TrendLevel.good);
      expect(IchingForecast.level([5, 0]), TrendLevel.good); // 5 先限制成 2 → 平均 1
      expect(IchingForecast.level([]), TrendLevel.even);
    });

    test('應期看主要那一段的爻位', () {
      FocusResult one(FocusItem i) => FocusResult([i], FocusCase.one);
      expect(IchingForecast.timing(one(const FocusItem.line(1, 1, primary: true))), TimingWindow.soon);
      expect(IchingForecast.timing(one(const FocusItem.line(1, 2, primary: true))), TimingWindow.soon);
      expect(IchingForecast.timing(one(const FocusItem.line(1, 4, primary: true))), TimingWindow.days);
      expect(IchingForecast.timing(one(const FocusItem.line(1, 6, primary: true))), TimingWindow.weeks);
      expect(IchingForecast.timing(one(const FocusItem.line(1, 7, primary: true))), TimingWindow.season);
      expect(IchingForecast.timing(one(const FocusItem.judgment(1, primary: true))), TimingWindow.season);
      // 兩個變爻：看標為 primary 的上面那一爻
      expect(
        IchingForecast.timing(const FocusResult(
          [FocusItem.line(1, 2), FocusItem.line(1, 5, primary: true)],
          FocusCase.two,
        )),
        TimingWindow.weeks,
      );
    });

    test('吉凶表查詢：查不到當 0，超出範圍限制', () {
      final t = IchingTrendTable.fromJson({
        '15': {'judgment': 1, '3': 2},
        '01': {'1': 9},
      });
      expect(t.score(const FocusItem.judgment(15)), 1);
      expect(t.score(const FocusItem.line(15, 3)), 2);
      expect(t.score(const FocusItem.line(15, 4)), 0);
      expect(t.score(const FocusItem.judgment(64)), 0);
      expect(t.score(const FocusItem.line(1, 1)), 2);
    });

    final table = IchingTrendTable.fromJson({
      '15': {'judgment': 1, '3': 1, '6': -1},
    });

    test('地山謙無變爻：看卦辭 → 吉、一季內，標籤＝坤、艮', () {
      final r = UnifiedReading.iching(cast([8, 8, 7, 8, 8, 8]), table);
      expect(r.level, TrendLevel.good);
      expect(r.timing, TimingWindow.season);
      expect(r.tags, ['kun', 'gen']);
    });

    test('地山謙九三動：看三爻 → 吉、數日內', () {
      final r = UnifiedReading.iching(cast([8, 8, 9, 8, 8, 8]), table);
      expect(r.level, TrendLevel.good);
      expect(r.timing, TimingWindow.days);
    });

    test('地山謙上六動：看上爻 → 小阻、數週內', () {
      final r = UnifiedReading.iching(cast([8, 8, 7, 8, 8, 6]), table);
      expect(r.level, TrendLevel.minorBlock);
      expect(r.timing, TimingWindow.weeks);
    });

    test('兩個變爻：兩段平均（1 與 −1 → 平）', () {
      final r = UnifiedReading.iching(cast([8, 8, 9, 8, 8, 6]), table);
      expect(r.level, TrendLevel.even);
      expect(r.timing, TimingWindow.weeks);
    });
  });

  test('梅花端沿用既有趨勢與應期；標籤＝體、用', () {
    // 觀梅占：澤火革初爻動，體兌用離，用克體（−2）＋丑月土生金相（+1）→ 小阻
    final m = MeihuaEngine.byTime(
        const LunarMoment(yearNumber: 5, month: 12, day: 17, hourNumber: 9, monthBranch: 1));
    final r = UnifiedReading.meihua(m);
    expect(r.level, TrendLevel.minorBlock);
    expect(r.level, m.trend);
    expect(r.timing, m.timing);
    expect(r.tags, ['dui', 'li']);
  });

  group('共識／分歧判斷', () {
    test('方向', () {
      expect(directionOf(TrendLevel.great), TrendDirection.pos);
      expect(directionOf(TrendLevel.good), TrendDirection.pos);
      expect(directionOf(TrendLevel.even), TrendDirection.even);
      expect(directionOf(TrendLevel.minorBlock), TrendDirection.neg);
      expect(directionOf(TrendLevel.block), TrendDirection.neg);
    });

    test('同方向＝共識；一方持平＝部分呼應；一正一負＝分歧', () {
      const p = TrendDirection.pos, e = TrendDirection.even, n = TrendDirection.neg;
      expect(CrossResult.verdictOf(p, p), CrossVerdict.consensus);
      expect(CrossResult.verdictOf(e, e), CrossVerdict.consensus);
      expect(CrossResult.verdictOf(n, n), CrossVerdict.consensus);
      expect(CrossResult.verdictOf(p, e), CrossVerdict.partial);
      expect(CrossResult.verdictOf(e, n), CrossVerdict.partial);
      expect(CrossResult.verdictOf(n, e), CrossVerdict.partial);
      expect(CrossResult.verdictOf(p, n), CrossVerdict.divergence);
      expect(CrossResult.verdictOf(n, p), CrossVerdict.divergence);
    });

    test('大吉與吉同向；小阻與阻同向', () {
      final a = CrossResult(u(TrendLevel.great, TimingWindow.soon, ['qian']), u(TrendLevel.good, TimingWindow.soon, ['kun']));
      expect(a.verdict, CrossVerdict.consensus);
      final b = CrossResult(u(TrendLevel.block, TimingWindow.soon, ['qian']), u(TrendLevel.minorBlock, TimingWindow.soon, ['kun']));
      expect(b.verdict, CrossVerdict.consensus);
    });

    test('共同主題、應期重疊、模板鍵', () {
      final c = CrossResult(
        u(TrendLevel.good, TimingWindow.days, ['kun', 'gen']),
        u(TrendLevel.minorBlock, TimingWindow.weeks, ['gen', 'li']),
      );
      expect(c.verdict, CrossVerdict.divergence);
      expect(c.sharedTags, ['gen']);
      expect(c.timingOverlap, isFalse);
      expect(c.nearerTiming, TimingWindow.days);
      expect(c.comboKey, 'pos_neg');

      final d = CrossResult(
        u(TrendLevel.even, TimingWindow.soon, ['qian']),
        u(TrendLevel.even, TimingWindow.soon, ['kun']),
      );
      expect(d.sharedTags, isEmpty);
      expect(d.timingOverlap, isTrue);
      expect(d.comboKey, 'even_even');
    });

    test('模板挑選固定（同一組卦回看一樣）', () {
      final items = ['a', 'b', 'c'];
      final seed = CrossResult.seedOf(15, 49);
      expect(CrossResult.pick(items, seed), CrossResult.pick(items, seed));
      expect(CrossResult.pick(items, seed), items[(15 * 64 + 49) % 3]);
    });
  });
}
