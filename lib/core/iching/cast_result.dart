import 'hexagram_table.dart';

/// 一爻的數值：6 老陰（變）、7 少陽、8 少陰、9 老陽（變）。
enum LineValue {
  oldYin(6, '老陰'),
  youngYang(7, '少陽'),
  youngYin(8, '少陰'),
  oldYang(9, '老陽');

  const LineValue(this.value, this.label);

  final int value;
  final String label;

  bool get isYang => this == youngYang || this == oldYang;
  bool get isChanging => this == oldYin || this == oldYang;

  /// 變爻變化後的陰陽。
  bool get changedIsYang => isChanging ? !isYang : isYang;

  static LineValue fromValue(int v) => values.firstWhere((e) => e.value == v);
}

/// 一次起卦的結果。lines 由下而上（初爻在 index 0）。
class CastResult {
  CastResult({required this.methodId, required List<LineValue> lines})
      : assert(lines.length == 6),
        lines = List.unmodifiable(lines);

  final String methodId;
  final List<LineValue> lines;

  /// 本卦卦序。
  int get primary => HexagramTable.numberFromLines([for (final l in lines) l.isYang]);

  bool get hasChanges => lines.any((l) => l.isChanging);

  /// 之卦卦序；沒有變爻時為 null。
  int? get changed => hasChanges
      ? HexagramTable.numberFromLines([for (final l in lines) l.changedIsYang])
      : null;

  /// 變爻位置（1＝初爻 … 6＝上爻）。
  List<int> get changingPositions => [
        for (var i = 0; i < 6; i++)
          if (lines[i].isChanging) i + 1,
      ];
}
