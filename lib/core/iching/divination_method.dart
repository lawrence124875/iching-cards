import 'dart:math';

import 'cast_result.dart';
import 'hexagram_table.dart';

/// 起卦方式（策略模式）。新增方式（例如蓍草法）＝新增一個實作。
abstract class DivinationMethod {
  String get id;
  CastResult cast(Random random);
}

/// 簡單抽卡：六十四卦等機率抽一張，沒有變爻。
class SimpleDraw implements DivinationMethod {
  const SimpleDraw();

  @override
  String get id => 'simple';

  @override
  CastResult cast(Random random) {
    final info = HexagramTable.byNumber(random.nextInt(64) + 1);
    return CastResult(
      methodId: id,
      lines: [for (final yang in info.lines) yang ? LineValue.youngYang : LineValue.youngYin],
    );
  }
}

/// 逐爻起卦（擲錢、蓍草）：畫面一次求一爻，由初爻往上六次。
abstract class StepwiseMethod implements DivinationMethod {
  const StepwiseMethod();

  LineStep step(Random random);

  @override
  CastResult cast(Random random) =>
      CastResult(methodId: id, lines: [for (var i = 0; i < 6; i++) step(random).line]);
}

/// 求得的一爻，以及畫面上顯示的算式（只有數字，介面文字由畫面提供）。
abstract class LineStep {
  LineValue get line;
  String get detail;
}

/// 一次擲三枚銅錢的結果：每枚 3（陽面）或 2（陰面）。
class CoinToss implements LineStep {
  const CoinToss(this.coins);

  final List<int> coins;

  @override
  LineValue get line => LineValue.fromValue(coins.fold(0, (a, b) => a + b));

  @override
  String get detail => coins.join(' + ');
}

/// 三枚銅錢擲六次，由初爻往上。
class ThreeCoins extends StepwiseMethod {
  const ThreeCoins();

  @override
  String get id => 'coins';

  @override
  CoinToss step(Random random) => CoinToss([for (var i = 0; i < 3; i++) random.nextBool() ? 3 : 2]);
}

/// 一爻的蓍草三變：[removed] 為每一變掛扐的根數（第一變 5 或 9，第二、三變 4 或 8）。
class YarrowLine implements LineStep {
  const YarrowLine(this.removed);

  final List<int> removed;

  /// 三變後剩下的根數：36／32／28／24。
  int get remaining => 49 - removed.fold(0, (a, b) => a + b);

  /// 剩下的根數除以四：9 老陽、8 少陰、7 少陽、6 老陰。
  @override
  LineValue get line => LineValue.fromValue(remaining ~/ 4);

  @override
  String get detail => '$remaining ÷ 4';
}

/// 蓍草法（《繫辭上》「大衍之數五十，其用四十有九」，朱熹《易學啟蒙》〈明蓍策〉）：
/// 四十九根分為兩堆（分二）、右堆取一根夾在指間（掛一）、兩堆各以四根一數（揲四）、
/// 餘數夾起（歸奇）；這樣三變得一爻。機率與擲錢不同：理想值老陰 1/16、少陽 5/16、少陰 7/16、老陽 3/16
/// （實際隨機分堆約 5%、29%、45%、21%，與手持蓍草相同，不另外校正）。
class YarrowStalks extends StepwiseMethod {
  const YarrowStalks();

  @override
  String get id => 'yarrow';

  @override
  YarrowLine step(Random random) {
    var stalks = 49;
    final removed = <int>[];
    for (var change = 0; change < 3; change++) {
      final r = _change(stalks, random);
      removed.add(r);
      stalks -= r;
    }
    return YarrowLine(removed);
  }

  /// 一變：回傳這一變拿出（掛一＋兩堆餘數）的根數。
  static int _change(int stalks, Random random) {
    // 分二：兩堆各至少一根（傳統上左手天、右手地）
    final left = 1 + random.nextInt(stalks - 2); // 右堆至少兩根，掛一後仍有可數的
    final right = stalks - left - 1; // 掛一：右堆取一根
    int rest(int n) => n % 4 == 0 ? 4 : n % 4; // 揲四：餘 1–4，整除時餘 4
    return 1 + rest(left) + rest(right);
  }
}
