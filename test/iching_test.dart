import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/cast_result.dart';
import 'package:iching_cards/core/iching/divination_method.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/iching/hexagram_table.dart';
import 'package:iching_cards/core/iching/trigram.dart';

CastResult castOf(List<int> values) =>
    CastResult(methodId: 'test', lines: [for (final v in values) LineValue.fromValue(v)]);

void main() {
  group('卦序表', () {
    test('64 卦卦序不重複', () {
      expect(HexagramTable.all.map((h) => h.number).toSet().length, 64);
      for (var n = 1; n <= 64; n++) {
        expect(HexagramTable.byNumber(n).number, n);
      }
    });

    test('謙＝上坤下艮、屯＝水雷屯、乾為天', () {
      expect(HexagramTable.numberOf(Trigram.kun, Trigram.gen), 15);
      expect(HexagramTable.byNumber(15).fullName, '地山謙');
      expect(HexagramTable.byNumber(3).fullName, '水雷屯');
      expect(HexagramTable.byNumber(1).fullName, '乾為天');
      expect(HexagramTable.byNumber(15).symbol, '䷎');
    });

    test('六爻 → 卦序 → 六爻 可來回', () {
      for (final h in HexagramTable.all) {
        expect(HexagramTable.numberFromLines(h.lines), h.number);
      }
    });
  });

  group('起卦', () {
    test('簡單抽卡沒有變爻', () {
      final r = Random(1);
      for (var i = 0; i < 200; i++) {
        final c = const SimpleDraw().cast(r);
        expect(c.hasChanges, isFalse);
        expect(c.changed, isNull);
      }
    });

    test('三枚銅錢只會出現 6–9', () {
      final r = Random(2);
      for (var i = 0; i < 500; i++) {
        final v = const ThreeCoins().step(r).line.value;
        expect(v, inInclusiveRange(6, 9));
      }
    });

    test('蓍草三變：每變掛扐根數合規，機率接近 1:5:7:3（老陰:少陽:少陰:老陽）', () {
      final r = Random(3);
      const n = 64000;
      final counts = {6: 0, 7: 0, 8: 0, 9: 0};
      for (var i = 0; i < n; i++) {
        final s = const YarrowStalks().step(r);
        expect(s.removed[0], anyOf(5, 9));
        expect(s.removed[1], anyOf(4, 8));
        expect(s.removed[2], anyOf(4, 8));
        expect(s.remaining, anyOf(24, 28, 32, 36));
        counts[s.line.value] = counts[s.line.value]! + 1;
      }
      // 1:5:7:3 是假設每變兩種餘數機率固定的理想值；實際隨機分堆約 5%／29%／45%／21%，容許 ±3 個百分點
      for (final e in {6: 1, 7: 5, 8: 7, 9: 3}.entries) {
        expect(counts[e.key]! / n, closeTo(e.value / 16, 0.03), reason: '${e.key}');
      }
      expect(const YarrowStalks().cast(r).methodId, 'yarrow');
    });

    test('乾卦六爻皆老陽 → 之卦為坤', () {
      final c = castOf([9, 9, 9, 9, 9, 9]);
      expect(c.primary, 1);
      expect(c.changed, 2);
    });
  });

  group('朱熹變爻規則', () {
    const rule = ZhuXiFocusRule();

    test('0 變：本卦卦辭', () {
      final f = rule.focus(castOf([7, 7, 7, 7, 7, 7]));
      expect(f.items.single.kind, FocusKind.judgment);
      expect(f.items.single.hexagram, 1);
    });

    test('1 變：該爻', () {
      final f = rule.focus(castOf([9, 7, 7, 7, 7, 7]));
      expect(f.items.single.position, 1);
      expect(f.items.single.hexagram, 1);
    });

    test('2 變：以上爻為主', () {
      final f = rule.focus(castOf([9, 7, 9, 7, 7, 7]));
      expect(f.items.firstWhere((i) => i.primary).position, 3);
    });

    test('4 變：之卦兩不變爻，以下爻為主', () {
      final c = castOf([9, 9, 7, 9, 7, 9]);
      final f = rule.focus(c);
      expect(f.items.every((i) => i.hexagram == c.changed), isTrue);
      expect(f.items.firstWhere((i) => i.primary).position, 3);
    });

    test('6 變：乾用九、坤用六、其他看之卦卦辭', () {
      expect(rule.focus(castOf([9, 9, 9, 9, 9, 9])).items.single.position, 7);
      expect(rule.focus(castOf([6, 6, 6, 6, 6, 6])).items.single.hexagram, 2);
      final other = rule.focus(castOf([9, 6, 9, 6, 9, 6]));
      expect(other.items.single.kind, FocusKind.judgment);
    });
  });
}
