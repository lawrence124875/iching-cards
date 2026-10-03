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

/// 為什麼看這些（介面文字由 l10n 的 focusExplanation 依此產生；core 不放介面文字）。
enum FocusCase { none, one, two, three, four, five, allQian, allKun, all }

class FocusResult {
  const FocusResult(this.items, this.reason);

  final List<FocusItem> items;
  final FocusCase reason;
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
        return FocusResult([FocusItem.judgment(p, primary: true)], FocusCase.none);
      case 1:
        return FocusResult([FocusItem.line(p, pos[0], primary: true)], FocusCase.one);
      case 2:
        return FocusResult(
          [FocusItem.line(p, pos[0]), FocusItem.line(p, pos[1], primary: true)],
          FocusCase.two,
        );
      case 3:
        return FocusResult(
          [FocusItem.judgment(p, primary: true), FocusItem.judgment(cast.changed!, primary: true)],
          FocusCase.three,
        );
      case 4:
        final c = cast.changed!;
        return FocusResult(
          [FocusItem.line(c, unchanged[0], primary: true), FocusItem.line(c, unchanged[1])],
          FocusCase.four,
        );
      case 5:
        return FocusResult(
          [FocusItem.line(cast.changed!, unchanged[0], primary: true)],
          FocusCase.five,
        );
      default:
        if (p == 1) {
          return FocusResult([FocusItem.line(1, 7, primary: true)], FocusCase.allQian);
        }
        if (p == 2) {
          return FocusResult([FocusItem.line(2, 7, primary: true)], FocusCase.allKun);
        }
        return FocusResult([FocusItem.judgment(cast.changed!, primary: true)], FocusCase.all);
    }
  }
}
