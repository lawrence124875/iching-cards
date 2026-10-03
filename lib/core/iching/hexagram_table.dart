import 'trigram.dart';

/// 六十四卦的基本資料（卦序、卦名、上下卦）。不含解讀內容：
/// 解讀由 ContentSource 提供，尚未撰寫的卦也能從這裡顯示卦名與卦象。
class HexagramInfo {
  const HexagramInfo({
    required this.number,
    required this.name,
    required this.pinyin,
    required this.english,
    required this.upper,
    required this.lower,
  });

  final int number;

  /// 漢字卦名（原始資料）。介面顯示請用 l10n 的 IchingTerms.hexName／hexFullName（依語言）。
  final String name;
  final String pinyin;

  /// 英文卦義（與術語表 en.meaning 一致，2026-10-03 定稿）。介面一律用術語表（IchingTerms），
  /// 這裡只是原始資料與測試對照；glossary_test 會檢查兩者一致。
  final String english;
  final Trigram upper;
  final Trigram lower;

  String get fullName =>
      upper == lower ? '$name為${upper.nature}' : '${upper.nature}${lower.nature}$name';

  /// Unicode 卦象符號（U+4DC0 起依文王卦序排列）。
  String get symbol => String.fromCharCode(0x4DC0 + number - 1);

  /// 由下而上六爻，true＝陽。
  List<bool> get lines => [...lower.lines, ...upper.lines];

  /// 兩位數卦序，對應內容與圖檔命名（01、15…）。
  String get code => number.toString().padLeft(2, '0');
}

class HexagramTable {
  HexagramTable._();

  static const _order = [
    Trigram.qian, Trigram.zhen, Trigram.kan, Trigram.gen,
    Trigram.kun, Trigram.xun, Trigram.li, Trigram.dui,
  ];

  /// 文王卦序：列＝上卦、欄＝下卦（順序同 _order）。
  static const _kingWen = [
    [1, 25, 6, 33, 12, 44, 13, 10],
    [34, 51, 40, 62, 16, 32, 55, 54],
    [5, 3, 29, 39, 8, 48, 63, 60],
    [26, 27, 4, 52, 23, 18, 22, 41],
    [11, 24, 7, 15, 2, 46, 36, 19],
    [9, 42, 59, 53, 20, 57, 37, 61],
    [14, 21, 64, 56, 35, 50, 30, 38],
    [43, 17, 47, 31, 45, 28, 49, 58],
  ];

  static const _names = [
    '乾', '坤', '屯', '蒙', '需', '訟', '師', '比', '小畜', '履',
    '泰', '否', '同人', '大有', '謙', '豫', '隨', '蠱', '臨', '觀',
    '噬嗑', '賁', '剝', '復', '无妄', '大畜', '頤', '大過', '坎', '離',
    '咸', '恆', '遯', '大壯', '晉', '明夷', '家人', '睽', '蹇', '解',
    '損', '益', '夬', '姤', '萃', '升', '困', '井', '革', '鼎',
    '震', '艮', '漸', '歸妹', '豐', '旅', '巽', '兌', '渙', '節',
    '中孚', '小過', '既濟', '未濟',
  ];

  static const _pinyin = [
    'Qián', 'Kūn', 'Zhūn', 'Méng', 'Xū', 'Sòng', 'Shī', 'Bǐ', 'Xiǎo Xù', 'Lǚ',
    'Tài', 'Pǐ', 'Tóng Rén', 'Dà Yǒu', 'Qiān', 'Yù', 'Suí', 'Gǔ', 'Lín', 'Guān',
    'Shì Hé', 'Bì', 'Bō', 'Fù', 'Wú Wàng', 'Dà Xù', 'Yí', 'Dà Guò', 'Kǎn', 'Lí',
    'Xián', 'Héng', 'Dùn', 'Dà Zhuàng', 'Jìn', 'Míng Yí', 'Jiā Rén', 'Kuí', 'Jiǎn', 'Xiè',
    'Sǔn', 'Yì', 'Guài', 'Gòu', 'Cuì', 'Shēng', 'Kùn', 'Jǐng', 'Gé', 'Dǐng',
    'Zhèn', 'Gèn', 'Jiàn', 'Guī Mèi', 'Fēng', 'Lǚ', 'Xùn', 'Duì', 'Huàn', 'Jié',
    'Zhōng Fú', 'Xiǎo Guò', 'Jì Jì', 'Wèi Jì',
  ];

  static const _english = [
    'Creative Force', 'Receptivity', 'Sprouting', 'Youthful Learning', 'Waiting',
    'Dispute', 'The Army', 'Union', 'Small Restraint', 'Treading',
    'Peace', 'Standstill', 'Fellowship', 'Great Possession', 'Modesty',
    'Enthusiasm', 'Following', 'Repairing', 'Approach', 'Contemplation',
    'Biting Through', 'Adornment', 'Stripping Away', 'Return', 'Innocence',
    'Great Restraint', 'Nourishment', 'Great Excess', 'The Abyss', 'Radiance',
    'Influence', 'Constancy', 'Retreat', 'Great Strength', 'Advance',
    'Light Hidden', 'Family', 'Divergence', 'Obstruction', 'Release',
    'Decrease', 'Increase', 'Breakthrough', 'Encounter', 'Gathering',
    'Rising', 'Confinement', 'The Well', 'Transformation', 'The Cauldron',
    'Shock', 'Stillness', 'Gradual Progress', 'The Marrying Maiden', 'Abundance',
    'The Traveler', 'Gentle Penetration', 'Joy', 'Dispersion', 'Limitation',
    'Inner Truth', 'Small Excess', 'After Completion', 'Before Completion',
  ];

  static final List<HexagramInfo> all = _build();

  static List<HexagramInfo> _build() {
    final list = List<HexagramInfo?>.filled(64, null);
    for (var u = 0; u < 8; u++) {
      for (var l = 0; l < 8; l++) {
        final n = _kingWen[u][l];
        list[n - 1] = HexagramInfo(
          number: n,
          name: _names[n - 1],
          pinyin: _pinyin[n - 1],
          english: _english[n - 1],
          upper: _order[u],
          lower: _order[l],
        );
      }
    }
    return List.unmodifiable(list.cast<HexagramInfo>());
  }

  static int numberOf(Trigram upper, Trigram lower) =>
      _kingWen[_order.indexOf(upper)][_order.indexOf(lower)];

  /// 由下而上六爻 → 卦序。
  static int numberFromLines(List<bool> lines) {
    assert(lines.length == 6);
    return numberOf(
      Trigram.fromLines(lines.sublist(3, 6)),
      Trigram.fromLines(lines.sublist(0, 3)),
    );
  }

  static HexagramInfo byNumber(int n) => all[n - 1];
}
