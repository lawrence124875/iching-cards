import 'package:flutter/material.dart';

import '../monetization/cast_quota.dart';

/// 外觀（0.11.0）：跟隨系統／淺色／深色，預設跟隨系統。存在 theme.json。
class ThemePref {
  ThemePref({QuotaStorage? storage}) : _storage = storage ?? MemoryQuotaStorage() {
    ready = _load();
  }

  final QuotaStorage _storage;
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  /// 讀檔完成（main 在 runApp 前等它，開機不會先閃另一種配色）。
  late final Future<void> ready;

  Future<void> _load() async {
    try {
      final v = (await _storage.read())['mode'];
      for (final m in ThemeMode.values) {
        if (m.name == v) mode.value = m;
      }
    } catch (_) {
      // 讀不到就照預設跟隨系統
    }
  }

  Future<void> set(ThemeMode value) async {
    mode.value = value;
    await _storage.write({'mode': value.name});
  }
}
