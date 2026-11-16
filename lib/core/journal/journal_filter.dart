import 'journal_entry.dart';

/// 卦記列表的篩選條件（純邏輯，方便測試）。
class JournalFilter {
  const JournalFilter({this.category, this.starredOnly = false, this.from, this.to, this.text = ''});

  /// [JournalEntry.categories] 之一；null 為全部。
  final String? category;
  final bool starredOnly;

  /// 日期區間（含頭尾兩天，以日為單位）。
  final DateTime? from;
  final DateTime? to;
  final String text;

  bool get hasDate => from != null && to != null;
  bool get isEmpty => category == null && !starredOnly && !hasDate && text.trim().isEmpty;

  /// [haystack]：這筆卦記可被搜尋的文字（問題、回顧、卦名、起卦方式），由畫面依語言提供。
  bool matches(JournalEntry e, String Function(JournalEntry) haystack) {
    if (category != null && e.category != category) return false;
    if (starredOnly && !e.starred) return false;
    if (hasDate) {
      final start = DateTime(from!.year, from!.month, from!.day);
      final end = DateTime(to!.year, to!.month, to!.day + 1);
      if (e.createdAt.isBefore(start) || !e.createdAt.isBefore(end)) return false;
    }
    final q = text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final h = haystack(e).toLowerCase();
      for (final w in q.split(RegExp(r'\s+'))) {
        if (!h.contains(w)) return false;
      }
    }
    return true;
  }

  /// 可被搜尋的使用者文字（問題與回顧）。
  static String userText(JournalEntry e) => [e.question, for (final f in e.followUps) f.text].join('\n');

  /// 免費版：這個時間之前的卦記上鎖。
  static DateTime freeCutoff(DateTime now, int days) => now.subtract(Duration(days: days));

  /// 依月份分組（輸入由新到舊，輸出維持順序）。
  static List<({int year, int month, List<JournalEntry> entries})> byMonth(List<JournalEntry> entries) {
    final out = <({int year, int month, List<JournalEntry> entries})>[];
    for (final e in entries) {
      final y = e.createdAt.year, m = e.createdAt.month;
      if (out.isEmpty || out.last.year != y || out.last.month != m) {
        out.add((year: y, month: m, entries: <JournalEntry>[]));
      }
      out.last.entries.add(e);
    }
    return out;
  }
}
