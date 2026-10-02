import '../iching/hexagram_table.dart';
import '../reminders/reminder_service.dart';
import 'journal_entry.dart';

/// 卦記與提醒的接合：回顧時間、通知文字、payload。
class JournalReminders {
  JournalReminders._();

  /// 回顧提醒固定在晚上八點（一天結束、適合回想的時間）。
  static const reviewHour = 20;
  static const payloadPrefix = 'journal:';

  /// [from] 之後第 [days] 天的晚上八點（本地時間）。
  static DateTime reviewTime(DateTime from, int days) =>
      DateTime(from.year, from.month, from.day + days, reviewHour);

  static String payloadFor(JournalEntry e) => '$payloadPrefix${e.id}';

  static String? entryIdFrom(String payload) =>
      payload.startsWith(payloadPrefix) ? payload.substring(payloadPrefix.length) : null;

  /// 依 entry.reminderAt 重新排程（先取消舊的）。沒有提醒或時間已過則只取消。
  /// 通知內文不放「想問的事」：鎖定畫面上任何人都看得到。
  static Future<bool> apply(ReminderService reminders, JournalEntry e) async {
    await reminders.cancel(e.notificationId);
    final at = e.reminderAt;
    if (at == null || !at.isAfter(DateTime.now())) return true;
    final name = HexagramTable.byNumber(e.cast.primary).name;
    final days = DateTime(at.year, at.month, at.day)
        .difference(DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .inDays;
    return reminders.schedule(
      id: e.notificationId,
      at: at,
      title: '回顧一卦：$name',
      body: '$days 天前抽到$name卦。回頭看看，這個象後來怎麼對上了？',
      payload: payloadFor(e),
    );
  }
}
