import '../core/iching/cast_result.dart';
import '../core/iching/focus_rule.dart';
import '../core/iching/hexagram_table.dart';
import '../core/iching/trigram.dart';
import '../core/reminders/reminder_service.dart';
import '../core/soundscape/breath_timeline.dart';
import 'app_localizations.dart';
import 'glossary.dart';

/// 易學名稱與 core 層代碼 → 介面文字（HANDOFF §16、§17）。core 不放介面文字，只回傳代碼（enum）。
///
/// 卦名、經卦名與象、傳統爻名一律依 11 語術語表（[Glossary]，來源 iching-content/glossary）。
/// 牌面上的大字卦名屬於牌面設計，各語言都保留漢字（見 CardFace）。
///
/// 爻名兩套（2026-10-03 決定，§17）：
/// - **介面爻位**（[linePosition]：初爻…上爻／Line 1…6）：擲錢頁逐爻擲出時用，只講位置，新手一看就懂。
/// - **傳統爻名**（[traditionalLineName]：初九、六二…／Nine at the beginning…）：詳細頁經文用，
///   同時標出陰陽與位置，是易學通例，也與經文「初六：」寫法一致。
extension IchingTerms on AppLocalizations {
  bool get isChinese => localeName.startsWith('zh');

  /// 介面語言對應的術語表代碼（AppLocalizations.localeName：zh、zh_Hans、en、pt_BR…）。
  String get glossaryCode {
    final parts = localeName.split(RegExp('[_-]'));
    final lang = parts.first;
    if (lang == 'zh') return parts.contains('Hans') ? 'zh-Hans' : 'zh-Hant';
    if (lang == 'pt') return 'pt-BR';
    return lang;
  }

  Glossary get glossary => Glossary.of(glossaryCode);

  /// 內文稱呼：謙／Modesty。
  String hexName(HexagramInfo h) => glossary.hexagram(h.number).name;

  /// 完整標題：地山謙／Modesty (Qiān)。
  String hexFullName(HexagramInfo h) => glossary.hexagram(h.number).title;

  /// 牌面漢字卦名下方的小字：拼音 · 卦義。中文介面沿用英文卦義（牌面設計），其他語言用該語言卦義。
  String cardSubtitle(HexagramInfo h) {
    final g = isChinese ? Glossary.of('en') : glossary;
    final meaning = g.hexagram(h.number).meaning;
    return meaning.isEmpty ? h.pinyin : '${h.pinyin}  ·  $meaning';
  }

  String trigramLabel(Trigram t) => glossary.trigram(t.name).name;
  String trigramImage(Trigram t) => glossary.trigram(t.name).image;
  String soundscape(Trigram t) => soundscapeName(t.name);

  /// 傳統爻名：position 1–6 依該爻陰陽（初九／初六…）；7＝用九（六爻皆陽）或用六。
  String traditionalLineName(HexagramInfo h, int position) {
    final lines = glossary.lines;
    if (position >= 1 && position <= 6) {
      return (h.lines[position - 1] ? lines.yang : lines.yin)[position - 1];
    }
    return h.lines.every((y) => y) ? lines.allYang : lines.allYin;
  }

  /// 詳細頁各爻的標題：爻辭已以爻名開頭（中文經文「初六：……」）就原樣顯示，否則加上傳統爻名。
  String lineHeading(HexagramInfo h, int position, String text, {String contentName = ''}) {
    final name = traditionalLineName(h, position);
    if (text.isEmpty) return name;
    if (text.startsWith(name) || (contentName.isNotEmpty && text.startsWith(contentName))) return text;
    return lineTitle(name, text);
  }

  /// 1＝初爻 … 6＝上爻。
  String linePosition(int position) =>
      lineName(const ['first', 'second', 'third', 'fourth', 'fifth', 'top'][position - 1]);

  String lineKind(LineValue v) => lineValue(v.name);

  String focusText(FocusCase c) => focusExplanation(c.name);

  String phase(BreathPhase p) => breathPhase(p.name);

  /// 牌面卦序：中文、日文「第十五卦」，其他語言用阿拉伯數字（ARB cardOrdinal：No. 15、제15괘）。
  String cardNumber(int n) => cardOrdinal(isChinese || glossaryCode == 'ja' ? chineseOrdinal(n) : '$n');

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
