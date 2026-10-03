import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/cast_result.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/iching/hexagram_table.dart';
import 'package:iching_cards/core/iching/trigram.dart';
import 'package:iching_cards/core/reminders/reminder_service.dart';
import 'package:iching_cards/core/soundscape/breath_timeline.dart';
import 'package:iching_cards/l10n/l10n.dart';

/// 介面翻譯（HANDOFF §16）：每個 ARB 的鍵與參數一致、語言判斷、select 每一種情況都有翻譯。
void main() {
  Map<String, dynamic> arb(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

  final template = arb('app_zh.arb');
  final arbFiles = Directory('lib/l10n')
      .listSync()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.endsWith('.arb'))
      .toList()
    ..sort();

  Set<String> messageKeys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();

  // 訊息中出現的參數名稱：{x} 或 {x, select/plural, …}。
  // 前面緊接英數字的是 select 分支（例如 qian{Qian}），不算參數。
  Set<String> usedNames(String msg) =>
      RegExp(r'(?<![A-Za-z0-9_=])\{(\w+)\s*[,}]').allMatches(msg).map((m) => m.group(1)!).toSet();

  Set<String> declared(String key) {
    final meta = template['@$key'] as Map<String, dynamic>?;
    final ph = meta?['placeholders'] as Map<String, dynamic>?;
    return ph?.keys.toSet() ?? {};
  }

  group('ARB', () {
    test('每個語言的鍵與範本（app_zh.arb）完全相同', () {
      final keys = messageKeys(template);
      for (final f in arbFiles) {
        final other = messageKeys(arb(f));
        expect(other.difference(keys), isEmpty, reason: '$f 多出的鍵');
        expect(keys.difference(other), isEmpty, reason: '$f 缺少的鍵');
      }
    });

    test('翻譯只用範本宣告過的參數', () {
      for (final f in arbFiles) {
        final m = arb(f);
        for (final key in messageKeys(m)) {
          final allowed = declared(key);
          final msg = m[key] as String;
          // 分支裡的 {x} 一定是參數；select／plural 的關鍵字不會接在 { 後面
          final used = usedNames(msg);
          expect(used.difference(allowed), isEmpty, reason: '$f 的 $key 用了未宣告的參數');
        }
      }
    });

    test('每個 ARB 都登記在 AppLanguages.all', () {
      final codes = {for (final l in AppLanguages.all) l.locale.languageCode};
      for (final f in arbFiles) {
        final lang = f.substring(4, f.length - 4).split('_').first; // app_zh.arb → zh
        expect(codes, contains(lang), reason: f);
      }
    });
  });

  group('語言判斷', () {
    final zhOnly = [AppLanguages.zhHant];
    final zhEn = [AppLanguages.zhHant, AppLanguages.en];

    test('台灣、香港用繁中', () {
      expect(AppLanguages.resolve([const Locale('zh', 'TW')], available: zhEn), AppLanguages.zhHant);
      expect(AppLanguages.resolve([const Locale('zh', 'HK')], available: zhEn), AppLanguages.zhHant);
      expect(
          AppLanguages.resolve([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')], available: zhEn),
          AppLanguages.zhHant);
    });

    test('簡體尚未開放時，簡體使用者看繁中而不是英文', () {
      expect(AppLanguages.resolve([const Locale('zh', 'CN')], available: zhEn), AppLanguages.zhHant);
    });

    test('英文開放後，英文與不支援的語言用英文；未開放時一律繁中', () {
      expect(AppLanguages.resolve([const Locale('en', 'US')], available: zhEn), AppLanguages.en);
      expect(AppLanguages.resolve([const Locale('de')], available: zhEn), AppLanguages.en);
      expect(AppLanguages.resolve([const Locale('en', 'US')], available: zhOnly), AppLanguages.zhHant);
    });

    test('依偏好順序：第一個對不上就看第二個', () {
      expect(AppLanguages.resolve([const Locale('ja'), const Locale('zh', 'TW')], available: zhEn),
          AppLanguages.zhHant);
    });

    test('上線原則：英文內容未完成前不開放（§12）', () {
      if (AppLanguages.forced != null) return; // 以 FORCE_LANG 建置的測試版例外
      expect(AppLanguages.enabled, contains(AppLanguages.zhHant));
      expect(AppLanguages.enabled.where((l) => !l.contentReady), isEmpty);
    });
  });

  group('翻譯內容', () {
    test('每個語言都能載入，App 名稱正確', () {
      expect(lookupAppLocalizations(AppLanguages.zhHant.locale).appTitle, '謙卦');
      expect(lookupAppLocalizations(AppLanguages.en.locale).appTitle, 'Qiangua');
    });

    test('單複數與 select', () {
      final en = lookupAppLocalizations(AppLanguages.en.locale);
      final zh = lookupAppLocalizations(AppLanguages.zhHant.locale);
      expect(en.minutes(1), '1 minute');
      expect(en.minutes(3), '3 minutes');
      expect(zh.minutes(3), '3 分鐘');
      expect(zh.trigramLabel(Trigram.gen), '艮');
      expect(en.trigramImage(Trigram.gen), 'Mountain');
      expect(zh.hexName(HexagramTable.byNumber(15)), '謙');
      expect(zh.linePosition(1), '初爻');
      expect(zh.linePosition(6), '上爻');
      expect(zh.cardNumber(15), '第十五卦');
      expect(zh.cardNumber(64), '第六十四卦');
      expect(en.cardNumber(15), 'No. 15');
    });

    test('所有 select 情況在每個語言都有翻譯（不會落到 other）', () {
      for (final lang in AppLanguages.all) {
        final l = lookupAppLocalizations(lang.locale);
        final texts = [
          for (final t in Trigram.values) ...[l.trigramLabel(t), l.trigramImage(t), l.soundscape(t)],
          for (final v in LineValue.values) l.lineKind(v),
          for (final c in FocusCase.values) l.focusText(c),
          for (final p in BreathPhase.values) l.phase(p),
          for (var i = 1; i <= 6; i++) l.linePosition(i),
          for (final k in ReminderFailureKind.values) l.reminderFailureText(ReminderFailure(k, 'x')),
        ];
        for (final s in texts) {
          expect(s.trim(), isNot(anyOf('', '-')), reason: lang.code);
        }
        // 六爻皆變的一般情況會用 other 分支，這裡另外確認文字正確
        expect(l.focusText(FocusCase.all), isNot(l.focusText(FocusCase.allQian)));
      }
    });

    test('回顧通知不含想問的事，只有卦名與天數', () {
      final zh = lookupAppLocalizations(AppLanguages.zhHant.locale);
      final m = zh.reviewMessage(15, 7);
      expect(m.title, '回顧一卦：謙');
      expect(m.body, startsWith('7 天前抽到謙卦'));
      expect(hour12(20), 8);
      expect(hour12(12), 12);
    });
  });
}
