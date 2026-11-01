import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/trigram.dart';
import 'package:iching_cards/core/meihua/lunar_moment.dart';
import 'package:iching_cards/core/meihua/meihua_cast.dart';
import 'package:iching_cards/core/meihua/meihua_engine.dart';
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
}
