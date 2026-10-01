import 'cast_result.dart';

enum FocusKind { judgment, line }

/// 本次重點的一個項目：某卦的卦辭，或某卦的某一爻（position 7＝用九／用六）。
class FocusItem {
  const FocusItem.judgment(this.hexagram, {this.primary = false})
      : kind = FocusKind.judgment,
        position = null;

  const FocusItem.line(this.hexagram, int this.position, {this.primary = false})
      : kind = FocusKind.line;

  final int hexagram;
  final FocusKind kind;
  final int? position;
  final bool primary;
}

class FocusResult {
  const FocusResult(this.items, this.explanation);

  final List<FocusItem> items;
  final String explanation;
}

/// 變爻取用規則（策略模式）。
abstract class FocusRule {
  String get id;
  FocusResult focus(CastResult cast);
}

/// 朱熹《易學啟蒙》的變爻取用規則（HANDOFF §4.3）。
class ZhuXiFocusRule implements FocusRule {
  const ZhuXiFocusRule();

  @override
  String get id => 'zhuxi';

  @override
  FocusResult focus(CastResult cast) {
    final p = cast.primary;
    final pos = cast.changingPositions;
    final unchanged = [for (var i = 1; i <= 6; i++) if (!pos.contains(i)) i];

    switch (pos.length) {
      case 0:
        return FocusResult([FocusItem.judgment(p, primary: true)], '沒有變爻，看本卦卦辭。');
      case 1:
        return FocusResult([FocusItem.line(p, pos[0], primary: true)], '一個變爻，看這一爻的爻辭。');
      case 2:
        return FocusResult(
          [FocusItem.line(p, pos[0]), FocusItem.line(p, pos[1], primary: true)],
          '兩個變爻，看這兩爻的爻辭，以上面那一爻為主。',
        );
      case 3:
        return FocusResult(
          [FocusItem.judgment(p, primary: true), FocusItem.judgment(cast.changed!, primary: true)],
          '三個變爻，看本卦與之卦的卦辭。',
        );
      case 4:
        final c = cast.changed!;
        return FocusResult(
          [FocusItem.line(c, unchanged[0], primary: true), FocusItem.line(c, unchanged[1])],
          '四個變爻，看之卦裡兩個沒有變的爻，以下面那一爻為主。',
        );
      case 5:
        return FocusResult(
          [FocusItem.line(cast.changed!, unchanged[0], primary: true)],
          '五個變爻，看之卦裡唯一沒有變的那一爻。',
        );
      default:
        if (p == 1) {
          return FocusResult([FocusItem.line(1, 7, primary: true)], '六爻皆變，乾卦看「用九」。');
        }
        if (p == 2) {
          return FocusResult([FocusItem.line(2, 7, primary: true)], '六爻皆變，坤卦看「用六」。');
        }
        return FocusResult([FocusItem.judgment(cast.changed!, primary: true)], '六爻皆變，看之卦卦辭。');
    }
  }
}
