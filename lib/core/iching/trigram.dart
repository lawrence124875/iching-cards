/// 八經卦。lines 由下而上，true＝陽爻。
/// label／nature 是漢字原始資料（組卦名「地山謙」用）；介面顯示一律經過 l10n（IchingTerms.trigramLabel／trigramImage）。
enum Trigram {
  qian('乾', '天', [true, true, true]),
  dui('兌', '澤', [true, true, false]),
  li('離', '火', [true, false, true]),
  zhen('震', '雷', [true, false, false]),
  xun('巽', '風', [false, true, true]),
  kan('坎', '水', [false, true, false]),
  gen('艮', '山', [false, false, true]),
  kun('坤', '地', [false, false, false]);

  const Trigram(this.label, this.nature, this.lines);

  final String label;
  final String nature;
  final List<bool> lines;

  static Trigram fromLines(List<bool> l) {
    assert(l.length == 3);
    return values.firstWhere(
        (t) => t.lines[0] == l[0] && t.lines[1] == l[1] && t.lines[2] == l[2]);
  }
}
