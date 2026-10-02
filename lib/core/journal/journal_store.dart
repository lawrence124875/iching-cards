import 'package:flutter/foundation.dart';

import 'journal_entry.dart';

/// 卦記的儲存介面（依賴反轉：畫面只認這個介面，換儲存方式不改畫面）。
/// 有變動時 notifyListeners，列表頁據此更新。
abstract class JournalStore extends ChangeNotifier {
  /// 由新到舊。
  Future<List<JournalEntry>> all();

  Future<JournalEntry?> byId(String id) async {
    for (final e in await all()) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// 新增或更新（以 id 判斷）。
  Future<void> save(JournalEntry entry);

  Future<void> delete(String id);
}

/// 只存在記憶體中（測試用）。
class MemoryJournalStore extends JournalStore {
  final List<JournalEntry> _entries = [];

  @override
  Future<List<JournalEntry>> all() async =>
      [..._entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(JournalEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    _entries.add(entry);
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
