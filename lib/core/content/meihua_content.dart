import 'dart:convert';

import 'package:flutter/services.dart';

import 'lessons.dart';

/// 一個八卦的類象（iching-content `<語言>/meihua/trigrams.json`）。
class TrigramImages {
  const TrigramImages(this._j);

  final Map<String, dynamic> _j;

  String _s(String k) => _j[k] as String? ?? '';

  String get name => _s('name');
  String get image => _s('image');
  String get person => _s('person');
  String get body => _s('body');
  String get direction => _s('direction');
  String get objects => _s('objects');
  String get quality => _s('quality');

  /// 當體卦（自己）時的描述。
  String get asSelf => _s('self');

  /// 當用卦（事／對方）時的描述。
  String get asOther => _s('other');

  /// 體卦是這一卦時的「今日小行動」。
  String get action => _s('action');
}

/// 梅花易數的解卦資料：八卦類象、64 卦上下卦畫面、解卦模板（roles.json）。
/// CI 匯入成 assets/content/<語言>/meihua-trigrams.json 等（scripts/import_content.sh）。
class MeihuaContent {
  MeihuaContent({required this.trigrams, required this.scenes, required this.roles});

  factory MeihuaContent.fromJson(Map<String, dynamic> trigrams, Map<String, dynamic> scenes, Map<String, dynamic> roles) =>
      MeihuaContent(
        trigrams: {for (final e in trigrams.entries) e.key: TrigramImages(e.value as Map<String, dynamic>)},
        scenes: {for (final e in scenes.entries) int.parse(e.key): e.value as String},
        roles: roles,
      );

  /// 鍵是 Trigram enum 名稱（qian、dui…）。
  final Map<String, TrigramImages> trigrams;

  /// 卦序 → 上下卦畫面。
  final Map<int, String> scenes;
  final Map<String, dynamic> roles;

  TrigramImages trigram(String name) => trigrams[name] ?? const TrigramImages({});

  String scene(int n) => scenes[n] ?? '';

  String heading(String k) => (roles['headings'] as Map?)?[k] as String? ?? '';

  /// 模板字串：{name} 這類欄位由 [args] 代入。
  String fill(String key, Map<String, String> args, {String? sub}) {
    var t = sub == null ? roles[key] : (roles[key] as Map?)?[sub];
    var s = t as String? ?? '';
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  String element(String name) => (roles['elements'] as Map?)?[name] as String? ?? name;
}

/// App 共用一份（有快取）。
final meihuaSource = MeihuaSource();

/// 讀梅花易數內容；語言退回規則同課程（簡中→繁中、其他→英文）。
class MeihuaSource {
  MeihuaSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, MeihuaContent?> _cache = {};

  Future<MeihuaContent?> load(String folder) async {
    for (final f in LessonSource.foldersFor(folder)) {
      if (_cache.containsKey(f)) {
        if (_cache[f] != null) return _cache[f];
        continue;
      }
      MeihuaContent? c;
      try {
        Future<Map<String, dynamic>> read(String name) async =>
            jsonDecode(await _bundle.loadString('assets/content/$f/meihua-$name.json')) as Map<String, dynamic>;
        c = MeihuaContent.fromJson(await read('trigrams'), await read('scenes'), await read('roles'));
      } catch (_) {
        c = null;
      }
      _cache[f] = c;
      if (c != null) return c;
    }
    return null;
  }
}
