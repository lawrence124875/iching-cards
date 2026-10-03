import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/hexagram_table.dart';
import 'package:iching_cards/core/iching/trigram.dart';
import 'package:iching_cards/l10n/glossary.dart';
import 'package:iching_cards/l10n/l10n.dart';

/// 術語表套用（HANDOFF §17）：CI 從私人 repo 產生 glossary_data.g.dart，這裡檢查它與 App 原始資料一致。
void main() {
  final zh = lookupAppLocalizations(AppLanguages.zhHant.locale);
  final en = lookupAppLocalizations(AppLanguages.en.locale);

  test('術語表含 11 語，App 已登記的語言都在裡面', () {
    expect(Glossary.languages.length, 11);
    for (final lang in AppLanguages.all) {
      expect(Glossary.languages, contains(lang.code));
    }
  });

  test('繁中卦名、完整卦名與 App 卦序表一致；英文卦義一致', () {
    final g = Glossary.of('zh-Hant');
    final e = Glossary.of('en');
    for (final h in HexagramTable.all) {
      expect(g.hexagram(h.number).name, h.name, reason: '${h.number}');
      expect(g.hexagram(h.number).title, h.fullName, reason: '${h.number}');
      expect(e.hexagram(h.number).meaning, h.english, reason: '${h.number}');
    }
  });

  test('每個語言 64 卦、八經卦、12 爻名都齊全', () {
    for (final code in Glossary.languages) {
      final g = Glossary.of(code);
      for (var n = 1; n <= 64; n++) {
        expect(g.hexagram(n).name, isNotEmpty, reason: '$code $n');
        expect(g.hexagram(n).title, isNotEmpty, reason: '$code $n');
      }
      for (final t in Trigram.values) {
        expect(g.trigram(t.name).name, isNotEmpty, reason: '$code ${t.name}');
        expect(g.trigram(t.name).image, isNotEmpty, reason: '$code ${t.name}');
      }
      expect(g.lines.yang.length, 6, reason: code);
      expect(g.lines.yin.length, 6, reason: code);
    }
  });

  test('介面套用術語表', () {
    final qian15 = HexagramTable.byNumber(15);
    expect(zh.hexName(qian15), '謙');
    expect(zh.hexFullName(qian15), '地山謙');
    expect(en.hexName(qian15), 'Modesty');
    expect(en.hexFullName(qian15), 'Modesty (Qiān)');
    expect(en.hexName(HexagramTable.byNumber(1)), 'Creative Force');
    expect(zh.cardSubtitle(qian15), 'Qiān  ·  Modesty');
    expect(en.trigramLabel(Trigram.gen), 'Gèn');
    expect(en.trigramImage(Trigram.gen), 'Mountain');
    expect(zh.trigramImage(Trigram.kun), '地');
  });

  test('傳統爻名依陰陽與位置；用九／用六', () {
    final qian = HexagramTable.byNumber(1), kun = HexagramTable.byNumber(2), modesty = HexagramTable.byNumber(15);
    expect(zh.traditionalLineName(modesty, 1), '初六');
    expect(zh.traditionalLineName(modesty, 3), '九三');
    expect(zh.traditionalLineName(modesty, 6), '上六');
    expect(zh.traditionalLineName(qian, 7), '用九');
    expect(zh.traditionalLineName(kun, 7), '用六');
    expect(en.traditionalLineName(modesty, 3), 'Nine in the third place');
    expect(en.traditionalLineName(modesty, 1), 'Six at the beginning');
  });

  test('詳細頁爻標題：中文經文已含爻名就不重複', () {
    final modesty = HexagramTable.byNumber(15);
    expect(zh.lineHeading(modesty, 1, '初六：謙謙君子，用涉大川，吉。', contentName: '初六'),
        '初六：謙謙君子，用涉大川，吉。');
    expect(en.lineHeading(modesty, 3, 'Toiling modesty.'), 'Nine in the third place: Toiling modesty.');
    expect(en.lineHeading(modesty, 3, ''), 'Nine in the third place');
  });

  test('介面語言對應術語表代碼', () {
    expect(zh.glossaryCode, 'zh-Hant');
    expect(en.glossaryCode, 'en');
  });
}
