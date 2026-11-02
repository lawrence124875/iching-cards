import 'package:lunar/lunar.dart';

/// 起卦用的農曆時刻：年支數、農曆月日、時支數都是 1 起算（子＝1 … 亥＝12）。
/// monthBranch 是月令（依節氣，0＝子 … 11＝亥），只用在旺衰。
class LunarMoment {
  const LunarMoment({
    required this.yearNumber,
    required this.month,
    required this.day,
    required this.hourNumber,
    required this.monthBranch,
  });

  final int yearNumber;
  final int month;
  final int day;
  final int hourNumber;
  final int monthBranch;

  /// 由手機當地時間換算（`lunar` 套件）。
  /// 23 點起的子時算次日（梅花易數慣例），月令依節氣交接的確切時刻。
  /// 夏令時期間先扣回時差，改用當地標準時間（時辰以標準時間計）。
  factory LunarMoment.fromDateTime(DateTime time) {
    final t = standardTime(time);
    final dateLunar = Lunar.fromDate(t.hour == 23 ? t.add(const Duration(hours: 1)) : t);
    final exact = Lunar.fromDate(t);
    return LunarMoment(
      yearNumber: dateLunar.getYearZhiIndex() + 1,
      month: dateLunar.getMonth().abs(), // 閏月為負數，取同名月
      day: dateLunar.getDay(),
      hourNumber: exact.getTimeZhiIndex() + 1,
      monthBranch: exact.getMonthZhiIndexExact(),
    );
  }

  /// 把夏令時換回當地標準時間：標準時差取當年 1 月 1 日與 7 月 1 日較小者（南北半球皆適用）。
  /// `offset`、`standard` 只供測試注入。
  static DateTime standardTime(DateTime t, {Duration? offset, Duration? standard}) {
    final now = offset ?? t.timeZoneOffset;
    final std = standard ?? _minDuration(DateTime(t.year, 1, 1).timeZoneOffset, DateTime(t.year, 7, 1).timeZoneOffset);
    final dst = now - std;
    return dst > Duration.zero ? t.subtract(dst) : t;
  }

  static Duration _minDuration(Duration a, Duration b) => a < b ? a : b;
}
