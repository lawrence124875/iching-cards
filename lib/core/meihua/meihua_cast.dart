import '../iching/cast_result.dart';
import '../iching/hexagram_table.dart';
import '../iching/trigram.dart';
import 'wuxing.dart';

/// 梅花易數的起卦法。
enum MeihuaMethod {
  time('meihua_time'),
  number('meihua_number'),
  wordCount('meihua_words');

  const MeihuaMethod(this.id);

  /// 存進卦記的 methodId。
  final String id;

  static MeihuaMethod? fromId(String id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// 一次梅花起卦的結果：本卦、互卦、變卦、動爻、體用、生剋、月令旺衰。
/// 64 卦與爻的解讀沿用既有內容；這裡只算卦象。
class MeihuaCast {
  MeihuaCast({
    required this.method,
    required this.upper,
    required this.lower,
    required this.movingLine,
    required this.monthBranch,
  }) : assert(movingLine >= 1 && movingLine <= 6);

  final MeihuaMethod method;

  /// 本卦上卦、下卦。
  final Trigram upper;
  final Trigram lower;

  /// 動爻（1＝初爻 … 6＝上爻）。
  final int movingLine;

  /// 月令（0＝子 … 11＝亥）。
  final int monthBranch;

  /// 本卦六爻（由下而上，true＝陽）。
  List<bool> get lines => [...lower.lines, ...upper.lines];

  int get primary => HexagramTable.numberOf(upper, lower);

  /// 互卦：二三四爻為下卦、三四五爻為上卦。
  int get mutual => HexagramTable.numberFromLines([...lines.sublist(1, 4), ...lines.sublist(2, 5)]);

  Trigram get mutualLower => Trigram.fromLines(lines.sublist(1, 4));
  Trigram get mutualUpper => Trigram.fromLines(lines.sublist(2, 5));

  List<bool> get changedLines => [
        for (var i = 0; i < 6; i++) i == movingLine - 1 ? !lines[i] : lines[i],
      ];

  /// 變卦。
  int get changed => HexagramTable.numberFromLines(changedLines);

  Trigram get changedLower => Trigram.fromLines(changedLines.sublist(0, 3));
  Trigram get changedUpper => Trigram.fromLines(changedLines.sublist(3, 6));

  /// 動爻在下卦時，下卦為用、上卦為體；反之亦然。
  bool get tiIsUpper => movingLine <= 3;

  /// 體卦（自己）。
  Trigram get ti => tiIsUpper ? upper : lower;

  /// 用卦（事／對方）。
  Trigram get yong => tiIsUpper ? lower : upper;

  WuXing get tiElement => WuXing.ofTrigram(ti);
  WuXing get yongElement => WuXing.ofTrigram(yong);

  TiYongRelation get relation => TiYongRelation.of(tiElement, yongElement);

  WuXing get monthElement => WuXing.ofBranch(monthBranch);

  /// 體卦在當月的旺衰。
  SeasonalStrength get tiStrength => SeasonalStrength.of(tiElement, monthElement);

  /// 轉成一般起卦結果，好重用解讀頁與卦記（動爻＝老陰／老陽）。
  CastResult toCastResult() => CastResult(methodId: method.id, lines: [
        for (var i = 0; i < 6; i++)
          i == movingLine - 1
              ? (lines[i] ? LineValue.oldYang : LineValue.oldYin)
              : (lines[i] ? LineValue.youngYang : LineValue.youngYin),
      ]);
}
