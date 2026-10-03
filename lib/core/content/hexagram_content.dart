/// 一卦的解讀內容（對應 iching-content 的 JSON，HANDOFF §4.6）。
/// 解析採寬鬆模式：缺欄位給空字串，多出的欄位忽略，日後新增欄位不會讓舊版壞掉。
///
/// 非中文語言（HANDOFF §22）：檔案裡的 judgment／tuan／daxiang／爻 text／xiaoxiang 是**譯文**，
/// 漢字原文不重複存放，由內容來源把繁中檔接到 [original]（經文唯一來源＝zh-Hant）。
class HexagramContent {
  HexagramContent({
    required this.number,
    required this.judgment,
    required this.tuan,
    required this.daxiang,
    required this.readings,
    required this.lines,
    this.eastWest,
    this.original,
  });

  final int number;
  final String judgment;
  final String tuan;
  final String daxiang;
  final List<ReadingContent> readings;
  final List<LineContent> lines;
  final EastWestContent? eastWest;

  /// 經文漢字原文（繁中內容）；中文語言本身就是原文，為 null。
  final HexagramContent? original;

  /// 接上漢字原文，回傳新物件。
  HexagramContent withOriginal(HexagramContent? o) => HexagramContent(
        number: number,
        judgment: judgment,
        tuan: tuan,
        daxiang: daxiang,
        readings: readings,
        lines: lines,
        eastWest: eastWest,
        original: o,
      );

  LineContent? line(int position) {
    for (final l in lines) {
      if (l.position == position) return l;
    }
    return null;
  }

  factory HexagramContent.fromJson(Map<String, dynamic> j) {
    final text = _map(j['text']);
    return HexagramContent(
      number: (j['id'] as num?)?.toInt() ?? 0,
      judgment: _s(text, 'judgment'),
      tuan: _s(text, 'tuan'),
      daxiang: _s(text, 'daxiang'),
      readings: [for (final r in _list(j['readings'])) ReadingContent.fromJson(_map(r))],
      lines: [for (final l in _list(j['lines'])) LineContent.fromJson(_map(l))],
      eastWest: j['eastWest'] is Map ? EastWestContent.fromJson(_map(j['eastWest'])) : null,
    );
  }
}

class ReadingContent {
  ReadingContent.fromJson(Map<String, dynamic> j)
      : title = _s(j, 'title'),
        image = _s(j, 'image'),
        source = _s(j, 'source'),
        forYou = _s(j, 'forYou'),
        action = _s(j, 'action'),
        question = _s(j, 'question');

  final String title, image, source, forYou, action, question;
}

class LineContent {
  LineContent.fromJson(Map<String, dynamic> j)
      : position = (j['position'] as num?)?.toInt() ?? 0,
        name = _s(j, 'name'),
        stage = _s(j, 'stage'),
        text = _s(j, 'text'),
        xiaoxiang = _s(j, 'xiaoxiang'),
        image = _s(j, 'image'),
        source = _s(j, 'source'),
        forYou = _s(j, 'forYou');

  final int position;
  final String name, stage, text, xiaoxiang, image, source, forYou;
}

class EastWestContent {
  EastWestContent.fromJson(Map<String, dynamic> j)
      : quoteText = _s(_map(j['quote']), 'text'),
        quoteAuthor = _s(_map(j['quote']), 'author'),
        quoteSource = _s(_map(j['quote']), 'source'),
        quoteTranslationNote = _s(_map(j['quote']), 'translationNote'),
        quoteNote = _s(_map(j['quote']), 'note'),
        psyName = _s(_map(j['psychology']), 'name'),
        psyOrigin = _s(_map(j['psychology']), 'origin'),
        psyEvidence = _s(_map(j['psychology']), 'evidenceNote'),
        psyNote = _s(_map(j['psychology']), 'note');

  final String quoteText, quoteAuthor, quoteSource, quoteTranslationNote, quoteNote;
  final String psyName, psyOrigin, psyEvidence, psyNote;

  bool get hasQuote => quoteText.isNotEmpty;
  bool get hasPsychology => psyName.isNotEmpty;
}

String _s(Map<String, dynamic> m, String k) => (m[k] ?? '').toString();

Map<String, dynamic> _map(Object? o) =>
    o is Map ? o.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

List<Object?> _list(Object? o) => o is List ? o : const [];
