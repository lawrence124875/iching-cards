import 'dart:convert';

import 'package:lunar/lunar.dart';

import '../meihua/lunar_moment.dart';
import '../meihua/solar_time.dart';
import 'ziwei.dart';

/// 生辰（國曆，手機當地時區）。只存在手機上（`birth_profile.json`），不上傳、不進卦記備份。
/// [hour] 為 null＝不知道時辰：紫微不排盤，八字改用三柱。[cityId] 選用，改用真太陽時（`SolarTime`）。
class BirthProfile {
  const BirthProfile({required this.year, required this.month, required this.day, this.hour, this.minute = 0, this.cityId});

  factory BirthProfile.fromJson(Map<String, dynamic> j) => BirthProfile(
        year: j['y'] as int,
        month: j['m'] as int,
        day: j['d'] as int,
        hour: j['h'] as int?,
        minute: j['min'] as int? ?? 0,
        cityId: j['city'] as String?,
      );

  final int year;
  final int month;
  final int day;
  final int? hour;
  final int minute;
  final String? cityId;

  bool get hasHour => hour != null;

  Map<String, dynamic> toJson() => {'y': year, 'm': month, 'd': day, 'h': hour, 'min': minute, 'city': cityId};

  String encode() => jsonEncode(toJson());

  /// 排盤用的時刻：選了城市用真太陽時，否則扣掉夏令時改用當地標準時間（同梅花時間起卦）。
  /// 不知道時辰時取正午（只用來定日期）。
  DateTime get effectiveTime {
    final local = DateTime(year, month, day, hour ?? 12, hasHour ? minute : 0);
    if (!hasHour) return local;
    final city = MeihuaCities.byId(cityId);
    return city == null ? LunarMoment.standardTime(local) : SolarTime.at(local, city.longitude);
  }

  /// 23 點起的子時算次日（與梅花一致）。
  DateTime get _dayTime {
    final t = effectiveTime;
    return hasHour && t.hour == 23 ? t.add(const Duration(hours: 1)) : t;
  }

  /// 紫微本命盤；不知道時辰回傳 null。
  ZiweiChart? ziwei() {
    if (!hasHour) return null;
    final lunar = Lunar.fromDate(_dayTime);
    return ZiweiChart.compute(
      yearStem: lunar.getYearGanIndex(),
      month: lunar.getMonth().abs(),
      leap: lunar.getMonth() < 0,
      day: lunar.getDay(),
      hour: Lunar.fromDate(effectiveTime).getTimeZhiIndex(),
    );
  }
}

/// 此刻的紫微流年（農曆正月初一換年）：年份、天干、地支。
({int year, int stem, int branch}) ziweiYearAt(DateTime now) {
  final l = Lunar.fromDate(now);
  return (year: l.getYear(), stem: l.getYearGanIndex(), branch: l.getYearZhiIndex());
}

/// 天干、地支字（排盤術語，各語言同樣顯示漢字）。
const stemChars = '甲乙丙丁戊己庚辛壬癸';
const branchChars = '子丑寅卯辰巳午未申酉戌亥';
