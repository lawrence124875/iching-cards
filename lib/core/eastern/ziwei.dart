/// 紫微斗數輕量排盤（HANDOFF §4-3 A，規格 iching-content docs/EASTERN-PLAN.md §3），純計算。
///
/// 只排：命宮、身宮、五行局、14 主星、文昌文曲左輔右弼（四化會用到）、生年四化與流年四化。
/// 地支一律 0＝子 … 11＝亥；天干 0＝甲 … 9＝癸；農曆月 1–12。
/// 演算法與開源排盤 iztro 2.6.5（預設設定）比對 3000 組隨機生辰全數一致，單元測試見 test/ziwei_test.dart。
library;

/// 14 主星，順序固定（同一宮有兩顆時，前面的當代表星）。
enum MajorStar { ziwei, tianji, taiyang, wuqu, tiantong, lianzhen, tianfu, taiyin, tanlang, jumen, tianxiang, tianliang, qisha, pojun }

/// 四化用到的輔星。
enum MinorStar { wenchang, wenqu, zuofu, youbi }

/// 化祿、化權、化科、化忌。
enum Sihua { lu, quan, ke, ji }

/// 年度趨勢：順、平、阻（與易經、梅花共用三向，見 cross_reading.dart TrendDirection）。
enum YearTrend { pos, even, neg }

/// 主題標籤：宜進、宜守、人際、財務。
enum LifeTheme { advance, hold, people, money }

int _m12(int x) => ((x % 12) + 12) % 12;

/// 星名鍵：主星用 MajorStar.name，輔星用 MinorStar.name。
typedef StarKey = String;

/// 各天干的四化（祿、權、科、忌）。庚年採「太陽、武曲、太陰、天同」（同 iztro 預設）。
const Map<int, List<StarKey>> sihuaTable = {
  0: ['lianzhen', 'pojun', 'wuqu', 'taiyang'], // 甲
  1: ['tianji', 'tianliang', 'ziwei', 'taiyin'], // 乙
  2: ['tiantong', 'tianji', 'wenchang', 'lianzhen'], // 丙
  3: ['taiyin', 'tiantong', 'tianji', 'jumen'], // 丁
  4: ['tanlang', 'taiyin', 'youbi', 'tianji'], // 戊
  5: ['wuqu', 'tanlang', 'tianliang', 'wenqu'], // 己
  6: ['taiyang', 'wuqu', 'taiyin', 'tiantong'], // 庚
  7: ['jumen', 'taiyang', 'wenqu', 'wenchang'], // 辛
  8: ['tianliang', 'ziwei', 'zuofu', 'wuqu'], // 壬
  9: ['pojun', 'jumen', 'taiyin', 'tanlang'], // 癸
};

/// 某天干的四化：星 → 化。
Map<StarKey, Sihua> sihuaOf(int stem) {
  final l = sihuaTable[stem % 10]!;
  return {for (var i = 0; i < 4; i++) l[i]: Sihua.values[i]};
}

/// 主星主題（初稿，給 Lawrence 審：/mnt/project-files/reviews/）。
const Map<MajorStar, LifeTheme> starTheme = {
  MajorStar.ziwei: LifeTheme.advance,
  MajorStar.tianji: LifeTheme.hold,
  MajorStar.taiyang: LifeTheme.people,
  MajorStar.wuqu: LifeTheme.money,
  MajorStar.tiantong: LifeTheme.hold,
  MajorStar.lianzhen: LifeTheme.people,
  MajorStar.tianfu: LifeTheme.money,
  MajorStar.taiyin: LifeTheme.money,
  MajorStar.tanlang: LifeTheme.people,
  MajorStar.jumen: LifeTheme.hold,
  MajorStar.tianxiang: LifeTheme.people,
  MajorStar.tianliang: LifeTheme.hold,
  MajorStar.qisha: LifeTheme.advance,
  MajorStar.pojun: LifeTheme.advance,
};

/// 本命盤。
class ZiweiChart {
  ZiweiChart._(this.yearStem, this.month, this.hour, this.ming, this.shen, this.ju, this.positions);

  /// [yearStem] 生年天干（農曆年，正月初一換年）；[month] 農曆月；[leap] 閏月；[day] 農曆日；[hour] 時辰地支（23 點起的子時，呼叫端先把日期換成次日）。
  /// 閏月：15 日（含）以前算本月，16 日起算下個月（同 iztro 預設）。
  factory ZiweiChart.compute({required int yearStem, required int month, bool leap = false, required int day, required int hour}) {
    var m = month;
    if (leap && day > 15) m = m == 12 ? 1 : m + 1;
    final h = _m12(hour);
    final ming = _m12(2 + m - 1 - h);
    final shen = _m12(2 + m - 1 + h);
    final ju = juOf(yearStem, ming);
    final z = ziweiPosition(day, ju);
    final f = _m12(4 - z);
    final pos = <StarKey, int>{
      'ziwei': z,
      'tianji': _m12(z - 1),
      'taiyang': _m12(z - 3),
      'wuqu': _m12(z - 4),
      'tiantong': _m12(z - 5),
      'lianzhen': _m12(z - 8),
      'tianfu': f,
      'taiyin': _m12(f + 1),
      'tanlang': _m12(f + 2),
      'jumen': _m12(f + 3),
      'tianxiang': _m12(f + 4),
      'tianliang': _m12(f + 5),
      'qisha': _m12(f + 6),
      'pojun': _m12(f + 10),
      'wenchang': _m12(10 - h),
      'wenqu': _m12(4 + h),
      'zuofu': _m12(4 + m - 1),
      'youbi': _m12(10 - (m - 1)),
    };
    return ZiweiChart._(yearStem % 10, m, h, ming, shen, ju, pos);
  }

  final int yearStem;
  final int month;
  final int hour;

  /// 命宮、身宮地支。
  final int ming;
  final int shen;

  /// 五行局：2 水、3 木、4 金、5 土、6 火。
  final int ju;

  /// 星 → 地支。
  final Map<StarKey, int> positions;

  /// 宮干（五虎遁）：甲己丙寅、乙庚戊寅、丙辛庚寅、丁壬壬寅、戊癸甲寅。
  static int palaceStem(int yearStem, int branch) => ([2, 4, 6, 8, 0][yearStem % 5] + _m12(branch - 2)) % 10;

  /// 命宮干支的納音五行局。
  static int juOf(int yearStem, int mingBranch) {
    final s = palaceStem(yearStem, mingBranch);
    var gz = 0;
    while (!(gz % 10 == s && gz % 12 == mingBranch)) {
      gz++;
    }
    const nayin = '金火木土金火水土金木水土火木水金火木土金火水土金木水土火木水';
    return const {'水': 2, '木': 3, '金': 4, '土': 5, '火': 6}[nayin[gz >> 1]]!;
  }

  /// 紫微星位置：找最小補數 x 使 (日＋x) 整除局數，商 q 由寅起數；x 奇數退 x 宮、偶數進 x 宮。
  static int ziweiPosition(int day, int ju) {
    var x = 0;
    while ((day + x) % ju != 0) {
      x++;
    }
    final q = (day + x) ~/ ju;
    return _m12(2 + q - 1 + (x.isOdd ? -x : x));
  }

  /// 某宮的主星（依 [MajorStar] 順序）。
  List<MajorStar> majorsAt(int branch) => [for (final s in MajorStar.values) if (positions[s.name] == branch) s];

  /// 某宮的星（主星＋四化輔星）。
  List<StarKey> starsAt(int branch) => [for (final e in positions.entries) if (e.value == branch) e.key];

  /// 空宮借對宮主星。回傳（主星、是否借星）。
  ({List<MajorStar> stars, bool borrowed}) majorsOrBorrowed(int branch) {
    final own = majorsAt(branch);
    if (own.isNotEmpty) return (stars: own, borrowed: false);
    return (stars: majorsAt(_m12(branch + 6)), borrowed: true);
  }

  /// 生年四化：星 → 化。
  Map<StarKey, Sihua> get natalSihua => sihuaOf(yearStem);

  /// 某年（流年天干、地支）的年度基調。
  ZiweiYear year({required int stem, required int branch}) => ZiweiYear._(this, stem % 10, _m12(branch));
}

/// 流年：流年命宮＝流年地支所在宮。
class ZiweiYear {
  ZiweiYear._(this.chart, this.stem, this.branch);

  final ZiweiChart chart;
  final int stem;
  final int branch;

  ({List<MajorStar> stars, bool borrowed}) get majors => chart.majorsOrBorrowed(branch);

  /// 流年命宮內（空宮看借來的對宮）的星。
  List<StarKey> get _starsInPalace {
    final m = majors;
    final b = m.borrowed ? _m12(branch + 6) : branch;
    return chart.starsAt(b);
  }

  /// 流年四化。
  Map<StarKey, Sihua> get yearSihua => sihuaOf(stem);

  /// 流年命宮見到的四化（生年＋流年，去重後依祿權科忌排序）。
  List<({StarKey star, Sihua hua, bool natal})> get sihuaInPalace {
    final stars = _starsInPalace;
    final out = <({StarKey star, Sihua hua, bool natal})>[];
    for (final s in stars) {
      final n = chart.natalSihua[s];
      if (n != null) out.add((star: s, hua: n, natal: true));
      final y = yearSihua[s];
      if (y != null) out.add((star: s, hua: y, natal: false));
    }
    out.sort((a, b) => a.hua.index.compareTo(b.hua.index));
    return out;
  }

  /// 趨勢（規格 §3 初稿）：見祿權科、不見忌 → 順；見忌、不見祿權科 → 阻；兩者都見或都不見 → 平。
  YearTrend get trend {
    final h = sihuaInPalace.map((x) => x.hua).toSet();
    final good = h.any((x) => x != Sihua.ji);
    final bad = h.contains(Sihua.ji);
    if (good && !bad) return YearTrend.pos;
    if (bad && !good) return YearTrend.neg;
    return YearTrend.even;
  }

  /// 主題：流年命宮代表星（空宮借對宮）的主題；理論上 14 主星必有一宮可借。
  LifeTheme get theme {
    final s = majors.stars;
    return s.isEmpty ? LifeTheme.hold : starTheme[s.first]!;
  }
}
