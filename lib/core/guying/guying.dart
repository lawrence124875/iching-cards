import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../content/lessons.dart';
import '../monetization/cast_quota.dart';

/// 古圖（明《斷易天機》卦影，1597，哈佛燕京本，公有領域）。設定開關預設關閉；
/// 打開後解讀頁與卦庫詳解多一個「古圖」區塊。圖只裁切、不修改（assets/guying/NN.webp，CI 從 iching-content 匯入）。
class GuyingPref {
  GuyingPref({QuotaStorage? storage}) : _storage = storage ?? MemoryQuotaStorage() {
    _load();
  }

  final QuotaStorage _storage;
  final ValueNotifier<bool> enabled = ValueNotifier(false);

  Future<void> _load() async {
    final v = (await _storage.read())['enabled'];
    if (v is bool) enabled.value = v;
  }

  Future<void> set(bool value) async {
    enabled.value = value;
    await _storage.write({'enabled': value});
  }
}

class GuyingSymbol {
  const GuyingSymbol(this.see, this.means);
  final String see;
  final String means;
}

class GuyingItem {
  const GuyingItem({
    required this.number,
    required this.title,
    required this.story,
    required this.symbols,
    required this.reading,
  });

  final int number;
  final String title;
  final String story;
  final List<GuyingSymbol> symbols;
  final String reading;

  factory GuyingItem.fromJson(Map<String, dynamic> j) => GuyingItem(
        number: j['n'] as int,
        title: j['title'] as String? ?? '',
        story: j['story'] as String? ?? '',
        symbols: [
          for (final s in (j['symbols'] as List? ?? const []))
            GuyingSymbol((s as Map)['see'] as String? ?? '', s['means'] as String? ?? ''),
        ],
        reading: j['reading'] as String? ?? '',
      );
}

/// 原書文字（繁體，語言無關）：此卦故事、解曰、課名、象名。
class GuyingOriginal {
  const GuyingOriginal({required this.story, required this.jie, required this.ke, required this.xiang});
  final String story;
  final String jie;
  final String ke;
  final String xiang;
}

class GuyingAboutSection {
  const GuyingAboutSection(this.heading, this.body);
  final String heading;
  final String body;
}

class GuyingContent {
  GuyingContent({required this.items, required this.aboutTitle, required this.about});

  final Map<int, GuyingItem> items;
  final String aboutTitle;
  final List<GuyingAboutSection> about;

  factory GuyingContent.fromJson(Map<String, dynamic> j) {
    final a = (j['about'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GuyingContent(
      items: {
        for (final m in (j['items'] as List? ?? const []))
          (m as Map)['n'] as int: GuyingItem.fromJson(m.cast<String, dynamic>()),
      },
      aboutTitle: a['title'] as String? ?? '',
      about: [
        for (final s in (a['sections'] as List? ?? const []))
          GuyingAboutSection((s as Map)['heading'] as String? ?? '', s['body'] as String? ?? ''),
      ],
    );
  }
}

/// assets/content/<語言>/guying.json；退回規則同課程（簡中→繁中、其他→英文）。
/// assets/content/guying-original.json：原書文字。
class GuyingSource {
  GuyingSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, GuyingContent?> _cache = {};
  Map<int, GuyingOriginal>? _original;

  static String imagePath(int number) => 'assets/guying/${number.toString().padLeft(2, '0')}.webp';

  Future<GuyingContent?> load(String folder) async {
    for (final f in LessonSource.foldersFor(folder)) {
      if (!_cache.containsKey(f)) {
        try {
          _cache[f] = GuyingContent.fromJson(
              jsonDecode(await _bundle.loadString('assets/content/$f/guying.json')) as Map<String, dynamic>);
        } catch (_) {
          _cache[f] = null;
        }
      }
      if (_cache[f] != null) return _cache[f];
    }
    return null;
  }

  Future<GuyingOriginal?> original(int number) async {
    if (_original == null) {
      try {
        final j = jsonDecode(await _bundle.loadString('assets/content/guying-original.json')) as Map<String, dynamic>;
        _original = {
          for (final m in (j['items'] as List))
            (m as Map)['n'] as int: GuyingOriginal(
              story: m['story'] as String? ?? '',
              jie: m['jie'] as String? ?? '',
              ke: m['ke'] as String? ?? '',
              xiang: m['xiang'] as String? ?? '',
            ),
        };
      } catch (_) {
        _original = {};
      }
    }
    return _original![number];
  }
}

final guyingSource = GuyingSource();
