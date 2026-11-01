import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/content/lessons.dart';

class _MapBundle extends CachingAssetBundle {
  _MapBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final s = files[key];
    if (s == null) throw Exception('missing $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }
}

String _lesson(int id, String title) => jsonEncode({
      'id': id,
      'title': title,
      'subtitle': 's',
      'sections': [
        {
          'heading': 'h',
          'body': 'a\n\nb',
          'glyphs': [
            {'lines': '001000', 'caption': 'c', 'changing': [3]}
          ],
          'items': [
            {'lines': '111', 'label': 'l', 'text': 't'},
            {'label': 'l2', 'text': 't2'}
          ],
        }
      ],
      'keyPoints': ['k'],
      'practice': 'p',
    });

void main() {
  test('解析課程：卦畫由下而上、變爻、條列可無卦畫', () {
    final l = Lesson.fromJson(jsonDecode(_lesson(1, 'x')) as Map<String, dynamic>);
    final s = l.sections.single;
    expect(s.glyphs.single.lines, [false, false, true, false, false, false]);
    expect(s.glyphs.single.changing, {3});
    expect(s.items.first.lines, [true, true, true]);
    expect(s.items.last.lines, isNull);
    expect(l.keyPoints, ['k']);
  });

  test('梅花課程：練習題與模擬器欄位；舊課程沒有也能解析', () {
    final j = jsonDecode(_lesson(1, 'x')) as Map<String, dynamic>;
    expect(Lesson.fromJson(j).exercises, isEmpty);
    expect(Lesson.fromJson(j).simulator, isNull);
    j['exercises'] = [
      {'q': 'q1', 'a': 'a1'}
    ];
    j['simulator'] = 'number';
    final l = Lesson.fromJson(j);
    expect(l.exercises.single.question, 'q1');
    expect(l.exercises.single.answer, 'a1');
    expect(l.simulator, 'number');
  });

  test('梅花課程檔名前綴', () async {
    final src = LessonSource(bundle: _MapBundle({'assets/content/en/meihua-lesson-03.json': _lesson(3, 'Ways to Cast')}));
    expect((await src.load('ja', 3, prefix: 'meihua-lesson'))?.$1.title, 'Ways to Cast');
    expect(await src.load('ja', 3), isNull);
  });

  test('前 2 課免費', () {
    expect([for (var i = 1; i <= lessonCount; i++) lessonIsFree(i)],
        [true, true, false, false, false, false, false, false]);
  });

  test('未翻譯的語言退回：簡中→繁中，其他→英文', () async {
    final src = LessonSource(bundle: _MapBundle({
      'assets/content/zh-Hant/lesson-01.json': _lesson(1, '陰陽與爻'),
      'assets/content/en/lesson-01.json': _lesson(1, 'Yin, Yang'),
    }));
    expect((await src.load('zh-Hans', 1))!.$2, 'zh-Hant');
    expect((await src.load('ja', 1))!.$2, 'en');
    expect((await src.load('en', 1))!.$1.title, 'Yin, Yang');
    expect(await src.load('en', 2), isNull);
  });
}
