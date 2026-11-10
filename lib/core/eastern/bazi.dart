/// 八字本月能量（HANDOFF §4-3 C，規格 iching-content docs/EASTERN-PLAN.md §4），純計算。
///
/// 只看日主（日干）五行，對流年、流月干支看生剋；不做喜用神。年、月都以節氣（立春、各月的「節」）換。
/// 天干 0＝甲 … 9＝癸；地支 0＝子 … 11＝亥。五行 0 木、1 火、2 土、3 金、4 水（相生順序）。
library;

enum Element { wood, fire, earth, metal, water }

/// 本月能量：高、穩、耗。
enum MonthEnergy { high, steady, drain }

/// 日主與另一個五行的關係。
enum Relation { sameAsMe, generatesMe, iGenerate, iControl, controlsMe }

Element stemElement(int stem) => Element.values[(stem % 10) ~/ 2];

const _branchElements = [4, 2, 0, 0, 2, 1, 1, 2, 3, 3, 2, 4]; // 子水 丑土 寅卯木 辰土 巳午火 未土 申酉金 戌土 亥水

Element branchElement(int branch) => Element.values[_branchElements[branch % 12]];

Relation relation(Element me, Element other) {
  final m = me.index, o = other.index;
  if (m == o) return Relation.sameAsMe;
  if ((o + 1) % 5 == m) return Relation.generatesMe;
  if ((m + 1) % 5 == o) return Relation.iGenerate;
  if ((m + 2) % 5 == o) return Relation.iControl;
  return Relation.controlsMe;
}

/// 生我／同我 +1、我生／我剋 0、剋我 −1。
int relationScore(Relation r) => switch (r) {
      Relation.sameAsMe || Relation.generatesMe => 1,
      Relation.iGenerate || Relation.iControl => 0,
      Relation.controlsMe => -1,
    };

/// 本月能量：流月干支各算 2 倍、流年干支各 1 倍，總分 ≥2 高、≤−2 耗、其他穩。
class BaziMonth {
  BaziMonth({required this.dayStem, required this.yearStem, required this.yearBranch, required this.monthStem, required this.monthBranch});

  final int dayStem;
  final int yearStem;
  final int yearBranch;
  final int monthStem;
  final int monthBranch;

  Element get dayMaster => stemElement(dayStem);

  /// 依序：流年干、流年支、流月干、流月支。
  List<Relation> get relations => [
        relation(dayMaster, stemElement(yearStem)),
        relation(dayMaster, branchElement(yearBranch)),
        relation(dayMaster, stemElement(monthStem)),
        relation(dayMaster, branchElement(monthBranch)),
      ];

  int get score {
    final r = relations.map(relationScore).toList();
    return r[0] + r[1] + 2 * (r[2] + r[3]);
  }

  MonthEnergy get energy {
    final s = score;
    if (s >= 2) return MonthEnergy.high;
    if (s <= -2) return MonthEnergy.drain;
    return MonthEnergy.steady;
  }
}
