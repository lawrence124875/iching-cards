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

/// 一次擲三枚銅錢的結果：每枚 3（陽面）或 2（陰面）。
class CoinToss {
  const CoinToss(this.coins);

  final List<int> coins;

  LineValue get line => LineValue.fromValue(coins.fold(0, (a, b) => a + b));
}

/// 三枚銅錢擲六次，由初爻往上。
class ThreeCoins implements DivinationMethod {
  const ThreeCoins();

  @override
  String get id => 'coins';

  CoinToss tossOnce(Random random) =>
      CoinToss([for (var i = 0; i < 3; i++) random.nextBool() ? 3 : 2]);

  @override
  CastResult cast(Random random) =>
      CastResult(methodId: id, lines: [for (var i = 0; i < 6; i++) tossOnce(random).line]);
}
