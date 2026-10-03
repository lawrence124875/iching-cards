import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/content/hexagram_content.dart';

/// 非中文語言：譯文檔＋繁中原文（HANDOFF §22）。
void main() {
  Map<String, dynamic> hex(String judgment, String line) => {
        'id': 1,
        'text': {'judgment': judgment, 'tuan': 't', 'daxiang': 'd'},
        'readings': [],
        'lines': [
          {'position': 1, 'name': 'n', 'text': line, 'xiaoxiang': 'x'},
        ],
      };

  test('withOriginal 保留譯文並接上原文', () {
    final en = HexagramContent.fromJson(hex('The Creative Force: originating.', 'Hidden dragon. Do not act.'));
    final zh = HexagramContent.fromJson(hex('乾：元亨利貞。', '初九：潛龍勿用。'));
    final merged = en.withOriginal(zh);
    expect(merged.judgment, 'The Creative Force: originating.');
    expect(merged.original?.judgment, '乾：元亨利貞。');
    expect(merged.line(1)?.text, 'Hidden dragon. Do not act.');
    expect(merged.original?.line(1)?.text, '初九：潛龍勿用。');
    expect(en.original, isNull);
  });
}
