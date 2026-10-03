/// 11 語術語表（HANDOFF §17）：卦名、經卦名與象、傳統爻名的固定譯法。
///
/// 資料來源是私人 repo iching-content 的 `glossary/glossary.json`（唯一來源），
/// CI 以 `scripts/gen_glossary.py` 產生 `glossary_data.g.dart`（不進 repo）。
/// 改譯法＝改 glossary.json，不改這裡。畫面不直接用本檔，一律經過 `IchingTerms`（terms.dart）。
library;

part 'glossary_data.g.dart';

class GlossaryHexagram {
  const GlossaryHexagram(this.name, this.title, this.meaning, this.reading, this.titleReading);

  /// 內文稱呼：謙／Modesty／謙（日）。
  final String name;

  /// 完整標題：地山謙／Modesty (Qiān)。
  final String title;

  /// 卦義（非中文語言才有）：Modesty。
  final String meaning;

  /// 日文讀音（其他語言為空）。
  final String reading, titleReading;
}

class GlossaryTrigram {
  const GlossaryTrigram(this.name, this.image);

  /// 經卦名：艮／Gèn。
  final String name;

  /// 象：山／Mountain。
  final String image;
}

class GlossaryLines {
  const GlossaryLines(this.yang, this.yin, this.allYang, this.allYin);

  /// 由下而上的傳統爻名：初九…上九／Nine at the beginning…
  final List<String> yang, yin;

  /// 用九／用六。
  final String allYang, allYin;
}

/// 某一語言的術語。
class Glossary {
  const Glossary._(this.code);

  /// 術語表語言代碼：zh-Hant、zh-Hans、en、ja、ko、vi、id、es、pt-BR、th、ar。
  final String code;

  static const fallback = 'zh-Hant';

  /// 術語表收錄的語言。
  static List<String> get languages => _languages;

  /// 找不到該語言時退回繁中（不應發生：新增語言前術語表已有 11 語）。
  static Glossary of(String code) => Glossary._(_languages.contains(code) ? code : fallback);

  /// 1–64。
  GlossaryHexagram hexagram(int number) => _hexagrams[code]![number - 1];

  /// key 為 Trigram 的 enum 名稱（qian、dui…）。
  GlossaryTrigram trigram(String key) => _trigrams[code]![key]!;

  GlossaryLines get lines => _lines[code]!;
}
