import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/cast_result.dart';
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
}
