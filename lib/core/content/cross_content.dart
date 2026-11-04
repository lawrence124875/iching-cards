import 'dart:convert';

import 'package:flutter/services.dart';

import '../cross/cross_reading.dart';
import 'lessons.dart';

/// 雙卦交叉的文案模板（iching-content `<語言>/cross/templates.json` → assets/content/<語言>/cross-templates.json）。
/// 只有繁中、英文；其他語言依課程規則退回（簡中→繁中、其他→英文）。
class CrossContent {
  const CrossContent(this._j);

  final Map<String, dynamic> _j;

  String _at(List<String> path) {
    Object? v = _j;
    for (final k in path) {
      v = v is Map ? v[k] : null;
    }
    return v is String ? v : '';
  }

  /// `s('headings', 'action')` 這類取值；{name} 欄位由 [args] 代入。
  String s(String key, [String? sub, Map<String, String> args = const {}]) {
    var out = _at([key, if (sub != null) sub]);
    args.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  String angle(String side, TrendDirection d) => _at(['angle', side, d.name]);

  String tag(String trigram) => _at(['tags', trigram]);

  List<String> _list(String key, String combo) =>
      [for (final x in ((_j[key] as Map?)?[combo] as List? ?? const [])) if (x is String) x];

  /// 首次進入的 3 頁引導（title、body）。
  List<({String title, String body})> get guide => [
        for (final x in (_j['guide'] as List? ?? const []))
          if (x is Map) (title: x['title'] as String? ?? '', body: x['body'] as String? ?? ''),
      ];

  List<String> actions(String combo) => _list('actions', combo);
  List<String> questions(String combo) => _list('questions', combo);
}

final crossSource = CrossSource();

/// 讀模板與易經吉凶表（有快取）。
class CrossSource {
  CrossSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, CrossContent?> _cache = {};
  IchingTrendTable? _table;

  Future<CrossContent?> load(String folder) async {
    for (final f in LessonSource.foldersFor(folder)) {
      if (_cache.containsKey(f)) {
        if (_cache[f] != null) return _cache[f];
        continue;
      }
      CrossContent? c;
      try {
        c = CrossContent(jsonDecode(await _bundle.loadString('assets/content/$f/cross-templates.json')) as Map<String, dynamic>);
      } catch (_) {
        c = null;
      }
      _cache[f] = c;
      if (c != null) return c;
    }
    return null;
  }

  /// 讀不到時給空表（全部當「平」）。
  Future<IchingTrendTable> trendTable() async {
    if (_table != null) return _table!;
    try {
      _table = IchingTrendTable.fromJson(
          jsonDecode(await _bundle.loadString('assets/content/cross-trend.json')) as Map<String, dynamic>);
    } catch (_) {
      _table = IchingTrendTable(const {});
    }
    return _table!;
  }
}
