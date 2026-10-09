import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/cast_result.dart';
import 'package:iching_cards/core/journal/journal_backup.dart';
import 'package:iching_cards/core/journal/journal_entry.dart';
import 'package:iching_cards/core/journal/journal_reminders.dart';
import 'package:iching_cards/core/journal/journal_store.dart';

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
}
