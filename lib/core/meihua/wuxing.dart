import '../iching/trigram.dart';

/// 五行。名稱在 l10n；這裡只放生剋規則（梅花易數模組用）。
enum WuXing {
  wood,
  fire,
  earth,
  metal,
  water;

  /// 我生者。
  WuXing get generates => WuXing.values[(index + 1) % 5];

  /// 我克者。
  WuXing get overcomes => WuXing.values[(index + 2) % 5];

  static WuXing ofTrigram(Trigram t) => switch (t) {
        Trigram.qian || Trigram.dui => metal,
        Trigram.li => fire,
        Trigram.zhen || Trigram.xun => wood,
        Trigram.kan => water,
        Trigram.gen || Trigram.kun => earth,
      };

  /// 地支（0＝子 … 11＝亥）所屬五行；用於月令。
  static WuXing ofBranch(int branch) => const [
        water, earth, wood, wood, earth, fire,
        fire, earth, metal, metal, earth, water,
      ][branch % 12];
}

/// 體用之間的生剋（從「體」＝自己的角度看）。
enum TiYongRelation {
  /// 體用同五行。
  sameElement,

  /// 用生體：外在的事／對方滋養自己。
  yongGeneratesTi,

  /// 體生用：自己付出給事／對方。
  tiGeneratesYong,

  /// 體克用：自己能掌握事／對方。
  tiOvercomesYong,

  /// 用克體：事／對方給自己壓力。
  yongOvercomesTi;

  static TiYongRelation of(WuXing ti, WuXing yong) {
    if (ti == yong) return sameElement;
    if (yong.generates == ti) return yongGeneratesTi;
    if (ti.generates == yong) return tiGeneratesYong;
    if (ti.overcomes == yong) return tiOvercomesYong;
    return yongOvercomesTi;
  }
}

/// 月令旺衰：卦的五行在當月的強弱（旺、相、休、囚、死）。
enum SeasonalStrength {
  /// 與月令同五行。
  prosperous,

  /// 月令生它。
  strong,

  /// 它生月令。
  resting,

  /// 它克月令。
  confined,

  /// 月令克它。
  dead;

  static SeasonalStrength of(WuXing element, WuXing month) {
    if (element == month) return prosperous;
    if (month.generates == element) return strong;
    if (element.generates == month) return resting;
    if (element.overcomes == month) return confined;
    return dead;
  }
}
