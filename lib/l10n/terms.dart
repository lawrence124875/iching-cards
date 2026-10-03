import '../core/iching/cast_result.dart';
import '../core/iching/focus_rule.dart';
import '../core/iching/hexagram_table.dart';
import '../core/iching/trigram.dart';
import '../core/reminders/reminder_service.dart';
import '../core/soundscape/breath_timeline.dart';
import 'app_localizations.dart';

/// 易學名稱與 core 層代碼 → 介面文字（HANDOFF §16）。core 不放介面文字，只回傳代碼（enum）。
///
/// 卦名：中文介面用漢字卦名；其他語言暫用拼音與暫定英文卦義。
/// ⚠️ 11 語術語表（§10.6 第 4 項之 3）完成後，卦名改為依術語表顯示，只需改這裡。
/// 牌面上的大字卦名屬於牌面設計，各語言都保留漢字（見 CardFace）。
extension IchingTerms on AppLocalizations {
  bool get isChinese => localeName.startsWith('zh');

  String hexName(HexagramInfo h) => isChinese ? h.name : h.pinyin;

  /// 例：地山謙；英文：Qiān · Modesty。
  String hexFullName(HexagramInfo h) => isChinese ? h.fullName : '${h.pinyin} · ${h.english}';

  String trigramLabel(Trigram t) => trigramName(t.name);
  String trigramImage(Trigram t) => trigramNature(t.name);
  String soundscape(Trigram t) => soundscapeName(t.name);

  /// 1＝初爻 … 6＝上爻。
  String linePosition(int position) =>
      lineName(const ['first', 'second', 'third', 'fourth', 'fifth', 'top'][position - 1]);

  String lineKind(LineValue v) => lineValue(v.name);

  String focusText(FocusCase c) => focusExplanation(c.name);

  String phase(BreathPhase p) => breathPhase(p.name);

  /// 牌面卦序：中文「第十五卦」，其他語言「No. 15」。
  String cardNumber(int n) => cardOrdinal(isChinese ? chineseOrdinal(n) : '$n');

  String methodName(String methodId) => methodId == 'coins' ? methodCoins : methodDraw;

  /// 提醒失敗的原因（給使用者看）。
  String reminderFailureText(ReminderFailure? f) => switch (f?.kind) {
        null => '',
        ReminderFailureKind.permissionDenied => reminderPermissionDenied,
        ReminderFailureKind.initFailed => reminderInitFailed(f!.detail),
        ReminderFailureKind.scheduleFailed => reminderScheduleFailed(f!.detail),
        ReminderFailureKind.unsupported => reminderUnsupported,
      };

  /// 卦記回顧通知（內文不放想問的事）。
  ({String title, String body}) reviewMessage(int hexagram, int days) {
    final name = hexName(HexagramTable.byNumber(hexagram));
    return (title: reviewNotificationTitle(name), body: reviewNotificationBody(days, name));
  }
}

const _numerals = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

/// 卦序的中文數字（1–64）。
String chineseOrdinal(int n) {
  if (n < 10) return _numerals[n];
  final tens = n ~/ 10, ones = n % 10;
  return '${tens == 1 ? '' : _numerals[tens]}十${_numerals[ones]}';
}

/// 24 小時制 → 12 小時制（晚上 8 點＝8）。
int hour12(int h) => h % 12 == 0 ? 12 : h % 12;
