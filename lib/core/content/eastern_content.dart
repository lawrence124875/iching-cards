import 'dart:convert';

import 'package:flutter/services.dart';

import 'lessons.dart';

/// 東方命理（紫微／八字）文案（iching-content `<語言>/eastern/templates.json` → assets/content/<語言>/eastern-templates.json）。
/// 未翻的語言依課程規則退回（簡中→繁中、其他→英文）。
class EasternContent {
  const EasternContent(this._j);

  final Map<String, dynamic> _j;

  Object? _at(String path) {
    Object? v = _j;
    for (final k in path.split('.')) {
      v = v is Map ? v[k] : null;
    }
    return v;
  }

  /// `s('ziwei.trend.pos')`；{name} 由 [args] 代入。找不到回傳空字串。
  String s(String path, [Map<String, String> args = const {}]) {
    final v = _at(path);
    var out = v is String ? v : '';
    args.forEach((k, x) => out = out.replaceAll('{$k}', x));
    return out;
  }

  List<String> list(String path) => [for (final x in (_at(path) as List? ?? const [])) if (x is String) x];
}

final easternSource = EasternSource();

class EasternSource {
  EasternSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, EasternContent?> _cache = {};

  Future<EasternContent?> load(String folder) async {
    for (final f in LessonSource.foldersFor(folder)) {
      if (_cache.containsKey(f)) {
        if (_cache[f] != null) return _cache[f];
        continue;
      }
      EasternContent? c;
      try {
        c = EasternContent(
            jsonDecode(await _bundle.loadString('assets/content/$f/eastern-templates.json')) as Map<String, dynamic>);
      } catch (_) {
        c = null;
      }
      _cache[f] = c;
      if (c != null) return c;
    }
    return null;
  }
}
