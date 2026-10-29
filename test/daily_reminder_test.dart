import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/monetization/cast_quota.dart';
import 'package:iching_cards/core/monetization/free_limits.dart';
import 'package:iching_cards/core/reminders/daily_reminder.dart';
import 'package:iching_cards/core/reminders/reminder_service.dart';

class _FakeReminders extends NoopReminderService {
  final scheduled = <int, DateTime>{};
  final asks = <bool>[];

  @override
  Future<bool> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    ReminderKind kind = ReminderKind.review,
    bool askPermission = true,
  }) async {
    scheduled[id] = at;
    asks.add(askPermission);
    return true;
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}

void main() {
  const s = DailyReminderSettings();
  const msg = (title: 't', body: 'b');

  test('預設開啟、早上 8 點，排 7 天', () {
    final p = DailyReminder.plan(DateTime(2026, 10, 29, 6), s, castToday: false);
    expect(p.length, DailyReminder.days);
    expect(p.first, DateTime(2026, 10, 29, 8));
  });

  test('今天已起卦或時間已過就從明天開始', () {
    expect(DailyReminder.plan(DateTime(2026, 10, 29, 6), s, castToday: true).first, DateTime(2026, 10, 30, 8));
    expect(DailyReminder.plan(DateTime(2026, 10, 29, 9), s, castToday: false).first, DateTime(2026, 10, 30, 8));
    expect(DailyReminder.plan(DateTime(2026, 10, 31, 9), s, castToday: false).first, DateTime(2026, 11, 1, 8));
  });

  test('關閉就不排', () {
    expect(DailyReminder.plan(DateTime(2026, 10, 29), s.copyWith(enabled: false), castToday: false), isEmpty);
  });

  test('refresh 只在第一次請求權限，重排會取代舊的', () async {
    final r = _FakeReminders();
    final d = DailyReminder(reminders: r, store: MemoryDailyReminderStore());
    await d.refresh(castToday: false, message: msg);
    await d.refresh(castToday: true, message: msg);
    expect(r.scheduled.length, DailyReminder.days);
    expect(r.asks.where((a) => a).length, 1);
    expect((await d.store.read()).asked, isTrue);
  });

  test('起卦後 castToday 為 true（含訂閱戶不扣次數）', () async {
    final q = CastQuota(limits: const FreeLimits(), storage: MemoryQuotaStorage());
    expect(await q.castToday(), isFalse);
    await q.recordCast(counted: false);
    expect(await q.castToday(), isTrue);
  });

  test('設定存讀', () {
    final m = DailyReminderSettings.fromJson(s.copyWith(hour: 21, minute: 30, enabled: false).toJson());
    expect((m.enabled, m.hour, m.minute), (false, 21, 30));
    expect(DailyReminderSettings.fromJson({}).enabled, isTrue);
  });
}
