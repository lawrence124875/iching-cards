import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/content/meihua_content.dart';
import 'package:iching_cards/core/iching/trigram.dart';
import 'package:iching_cards/core/meihua/lunar_moment.dart';
import 'package:iching_cards/core/meihua/meihua_cast.dart';
import 'package:iching_cards/core/meihua/meihua_engine.dart';
import 'package:iching_cards/core/meihua/meihua_forecast.dart';
import 'package:iching_cards/core/meihua/wuxing.dart';

LunarMoment at(int year, int month, int day, int hour, {int monthBranch = 2}) =>
    LunarMoment(yearNumber: year, month: month, day: day, hourNumber: hour, monthBranch: monthBranch);

void main() {
  group('時間起卦（《梅花易數》書中例）', () {
    test('觀梅占：辰年十二月十七日申時 → 澤火革，初爻動', () {
      final c = MeihuaEngine.byTime(at(5, 12, 17, 9, monthBranch: 1));
      expect(c.upper, Trigram.dui);
      expect(c.lower, Trigram.li);
      expect(c.primary, 49);
      expect(c.movingLine, 1);
      expect(c.mutual, 44); // 互見乾巽：天風姤
      expect(c.changed, 31); // 澤山咸
      expect(c.ti, Trigram.dui);
      expect(c.yong, Trigram.li);
      expect(c.relation, TiYongRelation.yongOvercomesTi); // 離火克兌金
      expect(c.tiStrength, SeasonalStrength.strong); // 丑月土生金
    });

    test('牡丹占：巳年三月十六日卯時 → 天風姤，五爻動', () {
      final c = MeihuaEngine.byTime(at(6, 3, 16, 4, monthBranch: 4));
      expect(c.primary, 44);
      expect(c.movingLine, 5);
      expect(c.mutual, 1); // 互見重乾
      expect(c.changed, 50); // 火風鼎
      expect(c.ti, Trigram.xun);
      expect(c.yong, Trigram.qian);
      expect(c.relation, TiYongRelation.yongOvercomesTi);
      expect(c.tiStrength, SeasonalStrength.confined); // 辰月土，木克土
    });
  });

  group('數字與字數起卦', () {
    test('15、9，子時 → 山天大畜，初爻動，體生用', () {
      final c = MeihuaEngine.byNumbers(15, 9, at(1, 1, 1, 1));
      expect(c.method, MeihuaMethod.number);
      expect(c.primary, 26);
      expect(c.movingLine, 1);
      expect(c.ti, Trigram.gen);
      expect(c.relation, TiYongRelation.tiGeneratesYong);
    });

    test('整除時：8 為坤、動爻 6 為上爻', () {
      final c = MeihuaEngine.byNumbers(8, 16, at(1, 1, 1, 12));
      expect(c.primary, 2);
      expect(c.movingLine, 6);
      expect(c.relation, TiYongRelation.sameElement);
    });

    test('三個字 → 上一下二：天澤履，三爻動', () {
      final c = MeihuaEngine.byWordCount(3, at(1, 1, 1, 1));
      expect(c.upper, Trigram.qian);
      expect(c.lower, Trigram.dui);
      expect(c.primary, 10);
      expect(c.movingLine, 3);
    });

    test('一個字上下同卦', () {
      expect(MeihuaEngine.byWordCount(1, at(1, 1, 1, 1)).primary, 1);
    });

    test('字數計算', () {
      expect(MeihuaEngine.countWords('梅花易數'), 4);
      expect(MeihuaEngine.countWords('plum blossom, numbers!'), 3);
      expect(MeihuaEngine.countWords('今天 good day。'), 4);
      expect(MeihuaEngine.countWords('  ，。 '), 0);
    });
  });

  group('卦象推導', () {
    test('轉成一般起卦結果：本卦、變卦、變爻一致', () {
      for (var y = 1; y <= 12; y++) {
        for (var h = 1; h <= 12; h++) {
          final c = MeihuaEngine.byTime(at(y, 7, 15, h));
          final r = c.toCastResult();
          expect(r.primary, c.primary);
          expect(r.changed, c.changed);
          expect(r.changingPositions, [c.movingLine]);
          expect(r.methodId, 'meihua_time');
        }
      }
    });

    test('從卦記還原梅花起卦', () {
      final c = MeihuaEngine.byTime(at(5, 12, 17, 9, monthBranch: 1));
      final back = MeihuaCast.fromCastResult(c.toCastResult(), monthBranch: 1)!;
      expect(back.primary, c.primary);
      expect(back.movingLine, c.movingLine);
      expect(back.method, MeihuaMethod.time);
      expect(back.relation, c.relation);
    });

    test('先天數往返', () {
      for (var n = 1; n <= 8; n++) {
        expect(MeihuaEngine.numberOf(MeihuaEngine.trigramOf(n)), n);
      }
    });

    test('五行生剋循環', () {
      expect(WuXing.wood.generates, WuXing.fire);
      expect(WuXing.water.generates, WuXing.wood);
      expect(WuXing.metal.overcomes, WuXing.wood);
      expect(WuXing.fire.overcomes, WuXing.metal);
      expect(SeasonalStrength.of(WuXing.metal, WuXing.fire), SeasonalStrength.dead);
      expect(SeasonalStrength.of(WuXing.water, WuXing.metal), SeasonalStrength.strong);
      expect(SeasonalStrength.of(WuXing.wood, WuXing.fire), SeasonalStrength.resting);
    });
  });

  group('農曆換算（lunar 套件）', () {
    test('2024-02-10 10:00＝甲辰年正月初一巳時，寅月', () {
      final m = LunarMoment.fromDateTime(DateTime(2024, 2, 10, 10));
      expect(m.yearNumber, 5);
      expect(m.month, 1);
      expect(m.day, 1);
      expect(m.hourNumber, 6);
      expect(m.monthBranch, 2);
    });

    test('23 點的子時算次日', () {
      final m = LunarMoment.fromDateTime(DateTime(2024, 2, 10, 23, 30));
      expect(m.day, 2);
      expect(m.hourNumber, 1);
    });

    test('2025-01-29 是乙巳年正月初一，但立春前仍是丑月', () {
      final m = LunarMoment.fromDateTime(DateTime(2025, 1, 29, 8));
      expect(m.yearNumber, 6);
      expect(m.month, 1);
      expect(m.hourNumber, 5);
      expect(m.monthBranch, 1);
    });

    test('閏月取同名月：2023-04-01＝閏二月十一', () {
      final m = LunarMoment.fromDateTime(DateTime(2023, 4, 1, 12));
      expect(m.yearNumber, 4);
      expect(m.month, 2);
      expect(m.day, 11);
    });
  });

  group('趨勢與應期', () {
    test('書中例：觀梅占小阻、數日內；牡丹占阻、數週內', () {
      final a = MeihuaEngine.byTime(at(5, 12, 17, 9, monthBranch: 1));
      expect(a.trend, TrendLevel.minorBlock); // 用克體 −2，丑月相 +1
      expect(a.timing, TimingWindow.days); // 兌2＋離3＝5，相
      expect(a.remedyElement, WuXing.earth); // 土生金，也通火金之關
      final b = MeihuaEngine.byTime(at(6, 3, 16, 4, monthBranch: 4));
      expect(b.trend, TrendLevel.block); // 用克體 −2，辰月囚 −1
      expect(b.timing, TimingWindow.weeks); // 巽5＋乾1＝6，囚
      expect(b.remedyElement, WuXing.water);
    });

    test('五級判斷：生剋＋旺衰', () {
      final r = TiYongRelation.values;
      final cases = {
        (TiYongRelation.yongGeneratesTi, SeasonalStrength.prosperous): TrendLevel.great,
        (TiYongRelation.yongGeneratesTi, SeasonalStrength.resting): TrendLevel.great,
        (TiYongRelation.yongGeneratesTi, SeasonalStrength.dead): TrendLevel.good,
        (TiYongRelation.sameElement, SeasonalStrength.strong): TrendLevel.great,
        (TiYongRelation.sameElement, SeasonalStrength.resting): TrendLevel.good,
        (TiYongRelation.sameElement, SeasonalStrength.dead): TrendLevel.even,
        (TiYongRelation.tiOvercomesYong, SeasonalStrength.confined): TrendLevel.even,
        (TiYongRelation.tiGeneratesYong, SeasonalStrength.prosperous): TrendLevel.even,
        (TiYongRelation.tiGeneratesYong, SeasonalStrength.resting): TrendLevel.minorBlock,
        (TiYongRelation.tiGeneratesYong, SeasonalStrength.dead): TrendLevel.block,
        (TiYongRelation.yongOvercomesTi, SeasonalStrength.prosperous): TrendLevel.minorBlock,
        (TiYongRelation.yongOvercomesTi, SeasonalStrength.resting): TrendLevel.block,
        (TiYongRelation.yongOvercomesTi, SeasonalStrength.dead): TrendLevel.block,
      };
      cases.forEach((k, v) => expect(MeihuaForecast.level(k.$1, k.$2), v, reason: '$k'));
      // 25 種組合涵蓋全部五級
      final seen = {for (final x in r) for (final y in SeasonalStrength.values) MeihuaForecast.level(x, y)};
      expect(seen, TrendLevel.values.toSet());
      expect(MeihuaForecast.needsRemedy(TrendLevel.minorBlock), isTrue);
      expect(MeihuaForecast.needsRemedy(TrendLevel.block), isTrue);
      expect(MeihuaForecast.needsRemedy(TrendLevel.even), isFalse);
    });

    test('應期：旺快、衰慢，卦數合大於 8 再慢一級', () {
      // 乾1＋兌2＝3；坤8＋坤8＝16；坎6＋震4＝10
      expect(MeihuaForecast.timing(Trigram.qian, Trigram.dui, SeasonalStrength.prosperous), TimingWindow.soon);
      expect(MeihuaForecast.timing(Trigram.kan, Trigram.zhen, SeasonalStrength.prosperous), TimingWindow.days);
      expect(MeihuaForecast.timing(Trigram.qian, Trigram.dui, SeasonalStrength.strong), TimingWindow.days);
      expect(MeihuaForecast.timing(Trigram.kun, Trigram.kun, SeasonalStrength.resting), TimingWindow.weeks);
      expect(MeihuaForecast.timing(Trigram.qian, Trigram.dui, SeasonalStrength.dead), TimingWindow.weeks);
      expect(MeihuaForecast.timing(Trigram.kun, Trigram.kun, SeasonalStrength.dead), TimingWindow.season);
      expect(MeihuaForecast.timing(Trigram.kan, Trigram.zhen, SeasonalStrength.confined), TimingWindow.season);
      expect(MeihuaForecast.numberSum(Trigram.kun, Trigram.gen), 15);
    });

    test('化解五行：生體，用克體時也是通關', () {
      for (final ti in WuXing.values) {
        final rem = MeihuaForecast.remedyElement(ti);
        expect(rem.generates, ti);
        final yong = WuXing.values.firstWhere((y) => y.overcomes == ti);
        expect(yong.generates, rem);
      }
    });
  });

  group('解卦內容', () {
    test('模板代入與 select', () {
      final c = MeihuaContent.fromJson(
        {'dui': {'name': '兌', 'image': '澤', 'self': 's'}},
        {'49': '湖裡燃起了火'},
        {
          'ti': '體卦是{name}（{image}）：',
          'relation': {'yongOvercomesTi': '用（{yong}）克體（{ti}）'},
          'elements': {'metal': '金'},
        },
      );
      expect(c.fill('ti', {'name': c.trigram('dui').name, 'image': c.trigram('dui').image}), '體卦是兌（澤）：');
      expect(c.fill('relation', {'ti': c.element('metal'), 'yong': '火'}, sub: 'yongOvercomesTi'), '用（火）克體（金）');
      expect(c.scene(49), '湖裡燃起了火');
      expect(c.trigram('kun').name, '');
    });

    // CI 會先匯入私人內容（scripts/import_content.sh）；本機沒有內容時略過。
    test('匯入的內容：繁中、英文 64 卦畫面與 12 課齊全', () {
      for (final lang in ['zh-Hant', 'en']) {
        final f = File('assets/content/$lang/meihua-scenes.json');
        if (!f.existsSync()) return;
        final scenes = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect(scenes.length, 64, reason: lang);
        for (var n = 1; n <= 12; n++) {
          expect(File('assets/content/$lang/meihua-lesson-${n.toString().padLeft(2, '0')}.json').existsSync(), isTrue,
              reason: '$lang $n');
        }
      }
    });

    test('匯入的解卦模板：五級、應期、化解、免責齊全且不用「凶」字', () {
      for (final lang in ['zh-Hant', 'en']) {
        final f = File('assets/content/$lang/meihua-roles.json');
        if (!f.existsSync()) return;
        final raw = f.readAsStringSync();
        final r = jsonDecode(raw) as Map<String, dynamic>;
        for (final l in TrendLevel.values) {
          for (final k in ['level', 'levelDesc', 'advice']) {
            expect((r[k] as Map)[l.name], isA<String>(), reason: '$lang $k.${l.name}');
          }
        }
        for (final w in TimingWindow.values) {
          expect((r['timing'] as Map)[w.name], isA<String>(), reason: '$lang timing.${w.name}');
        }
        for (final s in SeasonalStrength.values) {
          expect((r['pace'] as Map)[s.name], isA<String>(), reason: '$lang pace.${s.name}');
        }
        for (final e in WuXing.values) {
          expect((r['remedyBy'] as Map)[e.name], isA<String>(), reason: '$lang remedyBy.${e.name}');
        }
        for (final k in ['remedy', 'timingWhy', 'disclaimer']) {
          expect(r[k], isA<String>(), reason: '$lang $k');
        }
        for (final k in ['forecast', 'doing', 'trendLabel', 'timingLabel']) {
          expect((r['headings'] as Map)[k], isA<String>(), reason: '$lang headings.$k');
        }
        if (lang == 'zh-Hant') expect(raw.contains('凶'), isFalse);
      }
    });
  });
}
