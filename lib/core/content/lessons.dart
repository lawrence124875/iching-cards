import 'dart:convert';

import 'package:flutter/services.dart';

/// 學習課程（iching-content `<語言>/lessons/NN.json`，CI 匯入成 assets/content/<語言>/lesson-NN.json）。
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.keyPoints,
    required this.practice,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as int,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        sections: [for (final s in j['sections'] as List) LessonSection.fromJson(s as Map<String, dynamic>)],
        keyPoints: [for (final k in j['keyPoints'] as List? ?? const []) k as String],
        practice: j['practice'] as String? ?? '',
      );

  final int id;
  final String title;
  final String subtitle;
  final List<LessonSection> sections;
  final List<String> keyPoints;
  final String practice;
}

class LessonSection {
  const LessonSection({required this.heading, required this.body, this.glyphs = const [], this.items = const []});

  factory LessonSection.fromJson(Map<String, dynamic> j) => LessonSection(
        heading: j['heading'] as String,
        body: j['body'] as String? ?? '',
        glyphs: [for (final g in j['glyphs'] as List? ?? const []) LessonGlyph.fromJson(g as Map<String, dynamic>)],
        items: [for (final i in j['items'] as List? ?? const []) LessonItem.fromJson(i as Map<String, dynamic>)],
      );

  final String heading;

  /// 段落以空行分隔。
  final String body;
  final List<LessonGlyph> glyphs;
  final List<LessonItem> items;
}

/// 卦畫示意：lines 由下而上，'1' 陽、'0' 陰（三爻＝經卦、六爻＝重卦）。
List<bool> parseLines(String s) => [for (final c in s.split('')) c == '1'];

class LessonGlyph {
  const LessonGlyph({required this.lines, required this.caption, this.changing = const {}});

  factory LessonGlyph.fromJson(Map<String, dynamic> j) => LessonGlyph(
        lines: parseLines(j['lines'] as String),
        caption: j['caption'] as String? ?? '',
        changing: {for (final c in j['changing'] as List? ?? const []) c as int},
      );

  final List<bool> lines;
  final String caption;
  final Set<int> changing;
}

class LessonItem {
  const LessonItem({required this.label, required this.text, this.lines});

  factory LessonItem.fromJson(Map<String, dynamic> j) => LessonItem(
        label: j['label'] as String,
        text: j['text'] as String? ?? '',
        lines: j['lines'] == null ? null : parseLines(j['lines'] as String),
      );

  final String label;
  final String text;
  final List<bool>? lines;
}

/// 免費課數：前 2 課免費，其餘需要會員（2026-10-29 Lawrence 決定）。
const freeLessonCount = 2;
const lessonCount = 8;

bool lessonIsFree(int id) => id <= freeLessonCount;

/// App 共用一份（有快取）。
final lessonSource = LessonSource();

/// 讀課程：該語言還沒翻的課，簡中退回繁中，其他語言退回英文（其他 9 語待補，HANDOFF §4）。
class LessonSource {
  LessonSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, Lesson?> _cache = {};

  static List<String> foldersFor(String folder) => switch (folder) {
        'zh-Hant' || 'en' => [folder],
        'zh-Hans' => [folder, 'zh-Hant'],
        _ => [folder, 'en'],
      };

  /// 回傳課程與實際讀到的資料夾（與 [folder] 不同時，畫面顯示「暫以其他語言顯示」）。
  Future<(Lesson, String)?> load(String folder, int id) async {
    for (final f in foldersFor(folder)) {
      final lesson = await _load(f, id);
      if (lesson != null) return (lesson, f);
    }
    return null;
  }

  Future<Lesson?> _load(String folder, int id) async {
    final path = 'assets/content/$folder/lesson-${id.toString().padLeft(2, '0')}.json';
    if (_cache.containsKey(path)) return _cache[path];
    Lesson? result;
    try {
      result = Lesson.fromJson(jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>);
    } catch (_) {
      result = null;
    }
    return _cache[path] = result;
  }
}
