import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/cast_result.dart';
import 'package:iching_cards/core/journal/journal_backup.dart';
import 'package:iching_cards/core/journal/journal_entry.dart';
import 'package:iching_cards/core/journal/journal_filter.dart';
import 'package:iching_cards/core/journal/journal_reminders.dart';
import 'package:iching_cards/core/journal/journal_store.dart';
import 'package:iching_cards/features/journal/journal_stats_page.dart';

void main() {
  final cast = CastResult(methodId: 'coins', lines: [
    LineValue.oldYang, LineValue.youngYin, LineValue.youngYang,
    LineValue.oldYin, LineValue.youngYin, LineValue.youngYang,
  ]);

  test('卦記 JSON 來回轉換不失真，卦象與變爻一致', () {
    final now = DateTime(2026, 10, 2, 21, 5);
    final e = JournalEntry.fromCast(
      cast: cast,
      now: now,
      question: '要不要換工作？',
      readingIndex: 2,
      reminderAt: JournalReminders.reviewTime(now, 7),
    ).copyWith(followUps: [FollowUp(at: DateTime(2026, 10, 9), text: '果然是先蓄積')]);

    final back = JournalEntry.tryFromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>)!;
    expect(back.id, e.id);
    expect(back.question, '要不要換工作？');
    expect(back.readingIndex, 2);
    expect(back.reminderAt, DateTime(2026, 10, 9, 20));
    expect(back.followUps.single.text, '果然是先蓄積');
    expect(back.cast.primary, cast.primary);
    expect(back.cast.changed, cast.changed);
    expect(back.cast.changingPositions, [1, 4]);
    expect(back.notificationId, e.notificationId);
  });

  test('不合法的紀錄被略過', () {
    expect(JournalEntry.tryFromJson({'createdAt': '2026-10-02T00:00:00', 'lines': [7, 8]}), isNull);
    expect(JournalEntry.tryFromJson({'lines': [7, 7, 7, 7, 7, 7]}), isNull);
  });

  test('回顧時間為 N 天後晚上八點，跨月正確', () {
    expect(JournalReminders.reviewTime(DateTime(2026, 10, 30, 9), 3), DateTime(2026, 11, 2, 20));
  });

  test('payload 對應紀錄 id', () {
    final e = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 10, 2));
    expect(JournalReminders.entryIdFrom(JournalReminders.payloadFor(e)), e.id);
    expect(JournalReminders.entryIdFrom('other:1'), isNull);
  });

  test('記憶體儲存：新到舊、更新、刪除', () async {
    final store = MemoryJournalStore();
    final a = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 10, 1));
    final b = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 10, 2));
    await store.save(a);
    await store.save(b);
    expect((await store.all()).map((e) => e.id), [b.id, a.id]);
    await store.save(a.copyWith(question: '新問題'));
    expect((await store.byId(a.id))!.question, '新問題');
    await store.delete(b.id);
    expect((await store.all()).length, 1);
  });

  group('卦記備份', () {
    JournalEntry entry(DateTime at, String q) => JournalEntry.fromCast(cast: cast, now: at, question: q);

    test('匯出再匯入，內容不變；檔名含日期', () {
      final a = entry(DateTime(2026, 10, 1, 9), '甲').copyWith(followUps: [FollowUp(at: DateTime(2026, 10, 5), text: '後來')]);
      final b = entry(DateTime(2026, 10, 2, 9), '乙');
      final text = JournalBackup.encode([a, b], DateTime(2026, 10, 9));
      final back = JournalBackup.decode(text);
      expect(back.map((e) => e.id), [a.id, b.id]);
      expect(back.first.followUps.single.text, '後來');
      expect(back.last.question, '乙');
      expect(JournalBackup.fileName(DateTime(2026, 1, 9)), 'qiangua-journal-2026-01-09.json');
    });

    test('也接受 App 內的 journal.json；不是備份檔時丟 FormatException', () {
      final a = entry(DateTime(2026, 10, 1), '');
      expect(JournalBackup.decode(jsonEncode({'schemaVersion': 1, 'entries': [a.toJson()]})).single.id, a.id);
      expect(() => JournalBackup.decode('not json'), throwsFormatException);
      expect(() => JournalBackup.decode('[1,2]'), throwsFormatException);
      expect(() => JournalBackup.decode(jsonEncode({'format': 'other', 'entries': []})), throwsFormatException);
      expect(() => JournalBackup.decode(jsonEncode({'format': 'qiangua-journal'})), throwsFormatException);
      // 個別壞掉的紀錄略過，其餘照常還原
      final mixed = jsonEncode({'entries': [a.toJson(), {'lines': [1]}, 'x']});
      expect(JournalBackup.decode(mixed).single.id, a.id);
    });

    test('還原只加入手機上沒有的，已有的不覆蓋', () async {
      final store = MemoryJournalStore();
      final a = entry(DateTime(2026, 10, 1), '手機上的');
      final b = entry(DateTime(2026, 10, 2), '備份才有');
      await store.save(a);
      final added = await store.addMissing([a.copyWith(question: '備份裡的舊版'), b]);
      expect(added.map((e) => e.id), [b.id]);
      final all = await store.all();
      expect(all.length, 2);
      expect(all.firstWhere((e) => e.id == a.id).question, '手機上的');
      expect(await store.addMissing([a, b]), isEmpty);
    });
  });

  group('雙卦交叉紀錄', () {
    test('cross 與 verified 來回轉換；回饋可改可清除', () {
      final e = JournalEntry.fromCast(
        cast: CastResult(methodId: 'cross', lines: cast.lines),
        now: DateTime(2026, 11, 4, 9),
        question: '要不要接這個案子？',
        cross: CrossRecord(meihuaLines: [7, 7, 8, 9, 8, 7], monthBranch: 10),
      );
      final back = JournalEntry.tryFromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>)!;
      expect(back.methodId, 'cross');
      expect(back.cross!.meihuaLines, [7, 7, 8, 9, 8, 7]);
      expect(back.cross!.monthBranch, 10);
      expect(back.cross!.verified, isNull);

      final yes = back.copyWith(cross: back.cross!.withVerified('yes'));
      final again = JournalEntry.tryFromJson(jsonDecode(jsonEncode(yes.toJson())) as Map<String, dynamic>)!;
      expect(again.cross!.verified, 'yes');
      expect(again.cross!.withVerified(null).verified, isNull);
    });

    test('舊紀錄沒有 cross；不合法的 cross 或 verified 被略過', () {
      final old = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 10, 1));
      final j = old.toJson();
      expect(j.containsKey('cross'), isFalse);
      expect(JournalEntry.tryFromJson(j)!.cross, isNull);
      expect(JournalEntry.tryFromJson({...j, 'cross': {'meihua': [7, 7], 'monthBranch': 1}})!.cross, isNull);
      final bad = JournalEntry.tryFromJson({
        ...j,
        'cross': {'meihua': [7, 7, 8, 9, 8, 7], 'monthBranch': 3, 'verified': 'maybe'},
      })!;
      expect(bad.cross!.verified, isNull);
      expect(bad.cross!.monthBranch, 3);
    });
  });

  test('今日一卦、收藏標記可存回；分類正確', () {
    final e = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 11, 1), daily: true).copyWith(starred: true);
    final back = JournalEntry.tryFromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>)!;
    expect(back.daily, isTrue);
    expect(back.starred, isTrue);
    expect(back.category, 'daily');
    expect(back.labelKey, 'daily');
    expect(JournalEntry.fromCast(cast: cast, now: DateTime(2026, 11, 1)).category, 'iching');
    expect(JournalEntry.fromCast(cast: CastResult(methodId: 'meihua_time', lines: cast.lines), now: DateTime(2026, 11, 1)).category, 'meihua');
  });

  test('卦記篩選：分類、收藏、日期區間、關鍵字；月份分組', () {
    final a = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 11, 15, 9), question: '要不要換工作').copyWith(starred: true);
    final b = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 10, 31, 23), question: '感情', daily: true);
    String h(JournalEntry e) => JournalFilter.userText(e);
    expect(const JournalFilter().matches(a, h), isTrue);
    expect(const JournalFilter(category: 'daily').matches(a, h), isFalse);
    expect(const JournalFilter(category: 'daily').matches(b, h), isTrue);
    expect(const JournalFilter(starredOnly: true).matches(b, h), isFalse);
    expect(const JournalFilter(text: '工作').matches(a, h), isTrue);
    expect(const JournalFilter(text: '工作').matches(b, h), isFalse);
    final range = JournalFilter(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31));
    expect(range.matches(b, h), isTrue);
    expect(range.matches(a, h), isFalse);
    final g = JournalFilter.byMonth([a, b]);
    expect(g.length, 2);
    expect(g.first.month, 11);
    expect(JournalFilter.freeCutoff(DateTime(2026, 11, 16), 30), DateTime(2026, 10, 17));
  });

  test('備份檔可帶設定，舊格式沒有設定也能讀', () {
    final e = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 11, 1));
    final text = JournalBackup.encode([e], DateTime(2026, 11, 2), settings: {'theme.json': '{"mode":"dark"}'});
    expect(JournalBackup.decode(text).single.id, e.id);
    expect(JournalBackup.decodeSettings(text), {'theme.json': '{"mode":"dark"}'});
    expect(JournalBackup.decodeSettings(JournalBackup.encode([e], DateTime(2026, 11, 2))), isEmpty);
  });

  test('多筆刪除', () async {
    final store = MemoryJournalStore();
    final a = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 11, 1));
    final b = JournalEntry.fromCast(cast: cast, now: DateTime(2026, 11, 2));
    await store.save(a);
    await store.save(b);
    await store.deleteMany([a.id, b.id]);
    expect(await store.all(), isEmpty);
  });

  test('卦記統計', () {
    final now = DateTime(2026, 11, 1);
    final a = JournalEntry.fromCast(cast: cast, now: now).copyWith(followUps: [FollowUp(at: now, text: 'x')]);
    final b = JournalEntry.fromCast(cast: cast, now: now.add(const Duration(hours: 1)), daily: true);
    final st = JournalStats.of([a, b]);
    expect(st.reviewed, 1);
    expect(st.byCategory, {'iching': 1, 'daily': 1});
    expect(st.topHexagrams.single.count, 2);
    expect(st.verified, isEmpty);
  });
}
