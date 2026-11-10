import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/eastern/bazi.dart';
import 'package:iching_cards/core/eastern/birth_profile.dart';

void main() {
  test('五行生剋', () {
    expect(relation(Element.earth, Element.fire), Relation.generatesMe);
    expect(relation(Element.earth, Element.earth), Relation.sameAsMe);
    expect(relation(Element.earth, Element.metal), Relation.iGenerate);
    expect(relation(Element.earth, Element.water), Relation.iControl);
    expect(relation(Element.earth, Element.wood), Relation.controlsMe);
    expect(branchElement(0), Element.water);
    expect(branchElement(6), Element.fire);
    expect(stemElement(6), Element.metal);
  });

  test('能量分級：月 2 倍、年 1 倍', () {
    // 戊土日主；丙午年（火生我 +1 +1）、己亥月（土同我 +2、水我剋 0）→ 4 → 高
    final m = BaziMonth(dayStem: 4, yearStem: 2, yearBranch: 6, monthStem: 5, monthBranch: 11);
    expect(m.score, 4);
    expect(m.energy, MonthEnergy.high);
    // 甲木日主；庚申年（金剋我 −1 −1）、辛酉月（−2 −2）→ −6 → 耗
    expect(BaziMonth(dayStem: 0, yearStem: 6, yearBranch: 8, monthStem: 7, monthBranch: 9).energy, MonthEnergy.drain);
    // 甲木日主；丙午年（我生 0 0）、丙申月（0、−2）→ −2 → 耗；丙午月 → 0 → 穩
    expect(BaziMonth(dayStem: 0, yearStem: 2, yearBranch: 6, monthStem: 2, monthBranch: 6).energy, MonthEnergy.steady);
  });

  test('日主：2000-01-01 為戊午日；23 點起算次日', () {
    expect(const BirthProfile(year: 2000, month: 1, day: 1).dayStem, 4);
    expect(const BirthProfile(year: 2000, month: 1, day: 1, hour: 10).dayStem, 4);
    expect(const BirthProfile(year: 1999, month: 12, day: 31, hour: 23, minute: 30).dayStem, 4);
  });

  test('節氣換月：2026-11-10 為丙午年己亥月，自立冬 11-07 起', () {
    final m = const BirthProfile(year: 2000, month: 1, day: 1).monthAt(DateTime(2026, 11, 10, 12));
    expect([m.yearStem, m.yearBranch, m.monthStem, m.monthBranch], [2, 6, 5, 11]);
    expect(baziMonthStart(DateTime(2026, 11, 10, 12)), DateTime(2026, 11, 7));
  });
}
