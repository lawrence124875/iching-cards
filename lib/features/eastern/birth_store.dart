import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/eastern/birth_profile.dart';

/// 生辰存在 App 文件資料夾的 `birth_profile.json`（只在手機上；不進卦記備份）。
class BirthStore {
  BirthStore._();

  /// 目前的生辰；頁面監聽它即時更新。
  static final ValueNotifier<BirthProfile?> current = ValueNotifier(null);
  static bool _loaded = false;

  static Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/birth_profile.json');

  static Future<BirthProfile?> load() async {
    if (_loaded) return current.value;
    try {
      final f = await _file();
      current.value = await f.exists()
          ? BirthProfile.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>)
          : null;
    } catch (_) {
      current.value = null;
    }
    _loaded = true;
    return current.value;
  }

  static Future<void> save(BirthProfile? p) async {
    current.value = p;
    _loaded = true;
    try {
      final f = await _file();
      if (p == null) {
        if (await f.exists()) await f.delete();
      } else {
        await f.writeAsString(p.encode());
      }
    } catch (_) {}
  }
}
