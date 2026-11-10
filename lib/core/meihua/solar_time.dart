import 'dart:math' as math;

/// 真太陽時（選用的時辰校正）：依城市經度與均時差，把此刻換成當地太陽時。
/// 不需要位置權限；城市由使用者自己選（`MeihuaCities`）。
class SolarTime {
  SolarTime._();

  /// 均時差（分鐘，真太陽時－平太陽時），NOAA 近似公式，誤差約 1 分鐘內。
  static double equationOfTimeMinutes(DateTime utc) {
    final start = DateTime.utc(utc.year, 1, 1);
    final dayOfYear = utc.difference(start).inMinutes / 1440.0;
    final g = 2 * math.pi / 365 * (dayOfYear + (utc.hour - 12) / 24);
    return 229.18 *
        (0.000075 +
            0.001868 * math.cos(g) -
            0.032077 * math.sin(g) -
            0.014615 * math.cos(2 * g) -
            0.040849 * math.sin(2 * g));
  }

  /// 此刻在經度 [longitude]（東經為正）的真太陽時，以「不帶時區」的 DateTime 表示（只取年月日時分）。
  static DateTime at(DateTime moment, double longitude) {
    final utc = moment.toUtc();
    final minutes = longitude * 4 + equationOfTimeMinutes(utc);
    final s = utc.add(Duration(seconds: (minutes * 60).round()));
    return DateTime(s.year, s.month, s.day, s.hour, s.minute, s.second);
  }
}

class MeihuaCity {
  const MeihuaCity(this.id, this.name, this.longitude);
  final String id;

  /// 英文名＋當地寫法（不另做 11 語翻譯）。
  final String name;
  final double longitude;
}

/// 可選城市（依經度校正時辰）。依地區排列；同一時區內選最近的即可。
class MeihuaCities {
  MeihuaCities._();

  static const all = <MeihuaCity>[
    MeihuaCity('taipei', 'Taipei 台北', 121.56),
    MeihuaCity('kaohsiung', 'Kaohsiung 高雄', 120.30),
    MeihuaCity('keelung', 'Keelung 基隆', 121.74),
    MeihuaCity('taoyuan', 'Taoyuan 桃園', 121.30),
    MeihuaCity('hsinchu', 'Hsinchu 新竹', 120.97),
    MeihuaCity('miaoli', 'Miaoli 苗栗', 120.82),
    MeihuaCity('taichung', 'Taichung 台中', 120.68),
    MeihuaCity('changhua', 'Changhua 彰化', 120.54),
    MeihuaCity('nantou', 'Nantou 南投', 120.69),
    MeihuaCity('yunlin', 'Yunlin 雲林', 120.54),
    MeihuaCity('chiayi', 'Chiayi 嘉義', 120.45),
    MeihuaCity('tainan', 'Tainan 台南', 120.21),
    MeihuaCity('pingtung', 'Pingtung 屏東', 120.49),
    MeihuaCity('yilan', 'Yilan 宜蘭', 121.75),
    MeihuaCity('hualien', 'Hualien 花蓮', 121.60),
    MeihuaCity('taitung', 'Taitung 台東', 121.15),
    MeihuaCity('penghu', 'Penghu 澎湖', 119.57),
    MeihuaCity('kinmen', 'Kinmen 金門', 118.32),
    MeihuaCity('matsu', 'Matsu 馬祖', 119.95),
    MeihuaCity('hongkong', 'Hong Kong 香港', 114.17),
    MeihuaCity('macau', 'Macau 澳門', 113.54),
    MeihuaCity('beijing', 'Beijing 北京', 116.40),
    MeihuaCity('shanghai', 'Shanghai 上海', 121.47),
    MeihuaCity('guangzhou', 'Guangzhou 广州', 113.26),
    MeihuaCity('chengdu', 'Chengdu 成都', 104.07),
    MeihuaCity('chongqing', 'Chongqing 重庆', 106.55),
    MeihuaCity('xian', "Xi'an 西安", 108.94),
    MeihuaCity('wuhan', 'Wuhan 武汉', 114.31),
    MeihuaCity('harbin', 'Harbin 哈尔滨', 126.53),
    MeihuaCity('kunming', 'Kunming 昆明', 102.83),
    MeihuaCity('lanzhou', 'Lanzhou 兰州', 103.83),
    MeihuaCity('urumqi', 'Ürümqi 乌鲁木齐', 87.62),
    MeihuaCity('lhasa', 'Lhasa 拉萨', 91.13),
    MeihuaCity('singapore', 'Singapore 新加坡', 103.82),
    MeihuaCity('kualalumpur', 'Kuala Lumpur 吉隆坡', 101.69),
    MeihuaCity('tokyo', 'Tokyo 東京', 139.69),
    MeihuaCity('osaka', 'Osaka 大阪', 135.50),
    MeihuaCity('sapporo', 'Sapporo 札幌', 141.35),
    MeihuaCity('fukuoka', 'Fukuoka 福岡', 130.40),
    MeihuaCity('seoul', 'Seoul 서울', 126.98),
    MeihuaCity('busan', 'Busan 부산', 129.08),
    MeihuaCity('hanoi', 'Hanoi Hà Nội', 105.85),
    MeihuaCity('hochiminh', 'Ho Chi Minh City TP. Hồ Chí Minh', 106.70),
    MeihuaCity('bangkok', 'Bangkok กรุงเทพฯ', 100.50),
    MeihuaCity('chiangmai', 'Chiang Mai เชียงใหม่', 98.99),
    MeihuaCity('jakarta', 'Jakarta', 106.85),
    MeihuaCity('surabaya', 'Surabaya', 112.75),
    MeihuaCity('medan', 'Medan', 98.67),
    MeihuaCity('denpasar', 'Denpasar (Bali)', 115.22),
    MeihuaCity('manila', 'Manila', 120.98),
    MeihuaCity('sydney', 'Sydney', 151.21),
    MeihuaCity('melbourne', 'Melbourne', 144.96),
    MeihuaCity('perth', 'Perth', 115.86),
    MeihuaCity('auckland', 'Auckland', 174.76),
    MeihuaCity('delhi', 'New Delhi', 77.21),
    MeihuaCity('mumbai', 'Mumbai', 72.88),
    MeihuaCity('dubai', 'Dubai دبي', 55.27),
    MeihuaCity('riyadh', 'Riyadh الرياض', 46.68),
    MeihuaCity('jeddah', 'Jeddah جدة', 39.19),
    MeihuaCity('doha', 'Doha الدوحة', 51.53),
    MeihuaCity('kuwait', 'Kuwait City الكويت', 47.98),
    MeihuaCity('baghdad', 'Baghdad بغداد', 44.36),
    MeihuaCity('amman', 'Amman عمّان', 35.93),
    MeihuaCity('beirut', 'Beirut بيروت', 35.50),
    MeihuaCity('cairo', 'Cairo القاهرة', 31.24),
    MeihuaCity('casablanca', 'Casablanca الدار البيضاء', -7.59),
    MeihuaCity('algiers', 'Algiers الجزائر', 3.06),
    MeihuaCity('tunis', 'Tunis تونس', 10.18),
    MeihuaCity('istanbul', 'Istanbul', 28.98),
    MeihuaCity('moscow', 'Moscow Москва', 37.62),
    MeihuaCity('london', 'London', -0.13),
    MeihuaCity('paris', 'Paris', 2.35),
    MeihuaCity('berlin', 'Berlin', 13.40),
    MeihuaCity('amsterdam', 'Amsterdam', 4.90),
    MeihuaCity('rome', 'Rome Roma', 12.50),
    MeihuaCity('madrid', 'Madrid', -3.70),
    MeihuaCity('barcelona', 'Barcelona', 2.17),
    MeihuaCity('lisbon', 'Lisbon Lisboa', -9.14),
    MeihuaCity('newyork', 'New York', -74.01),
    MeihuaCity('toronto', 'Toronto', -79.38),
    MeihuaCity('chicago', 'Chicago', -87.63),
    MeihuaCity('denver', 'Denver', -104.99),
    MeihuaCity('losangeles', 'Los Angeles', -118.24),
    MeihuaCity('sanfrancisco', 'San Francisco', -122.42),
    MeihuaCity('vancouver', 'Vancouver', -123.12),
    MeihuaCity('honolulu', 'Honolulu', -157.86),
    MeihuaCity('mexicocity', 'Mexico City Ciudad de México', -99.13),
    MeihuaCity('bogota', 'Bogotá', -74.07),
    MeihuaCity('lima', 'Lima', -77.04),
    MeihuaCity('santiago', 'Santiago', -70.67),
    MeihuaCity('buenosaires', 'Buenos Aires', -58.38),
    MeihuaCity('saopaulo', 'São Paulo', -46.63),
    MeihuaCity('riodejaneiro', 'Rio de Janeiro', -43.17),
    MeihuaCity('brasilia', 'Brasília', -47.88),
    MeihuaCity('salvador', 'Salvador', -38.50),
    MeihuaCity('manaus', 'Manaus', -60.02),
    MeihuaCity('fortaleza', 'Fortaleza', -38.54),
  ];

  /// 自訂經度的 id 前綴（出生資料可自行輸入經度），例如 `lon:120.97`。
  static const customPrefix = 'lon:';

  static String customId(double longitude) => '$customPrefix${longitude.toStringAsFixed(2)}';

  /// 自訂經度：顯示成 `120.97°E`／`74.01°W`。
  static MeihuaCity? custom(String id) {
    if (!id.startsWith(customPrefix)) return null;
    final lon = double.tryParse(id.substring(customPrefix.length));
    if (lon == null || lon < -180 || lon > 180) return null;
    return MeihuaCity(id, '${lon.abs().toStringAsFixed(2)}°${lon < 0 ? 'W' : 'E'}', lon);
  }

  static MeihuaCity? byId(String? id) {
    if (id == null) return null;
    final c = custom(id);
    if (c != null) return c;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
