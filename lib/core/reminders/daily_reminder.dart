import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'reminder_service.dart';

/// 每日一卦提醒的設定（預設開啟、早上 8 點）。
class DailyReminderSettings {
  const DailyReminderSettings({this.enabled = true, this.hour = 8, this.minute = 0, this.asked = false});

  final bool enabled;
  final int hour;
  final int minute;

  /// 已經為這個提醒請求過一次通知權限；之後背景重排都不再跳權限對話框。
  final bool asked;

  DailyReminderSettings copyWith({bool? enabled, int? hour, int? minute, bool? asked}) => DailyReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        asked: asked ?? this.asked,
      );

  Map<String, Object?> toJson() => {'enabled': enabled, 'hour': hour, 'minute': minute, 'asked': asked};

  static DailyReminderSettings fromJson(Map m) => DailyReminderSettings(
        enabled: m['enabled'] != false,
        hour: (m['hour'] as num?)?.toInt() ?? 8,
        minute: (m['minute'] as num?)?.toInt() ?? 0,
        asked: m['asked'] == true,
      );
}

abstract class DailyReminderStore {
  Future<DailyReminderSettings> read();
  Future<void> write(DailyReminderSettings s);
}

class MemoryDailyReminderStore implements DailyReminderStore {
  MemoryDailyReminderStore([this.value = const DailyReminderSettings()]);

  DailyReminderSettings value;

  @override
  Future<DailyReminderSettings> read() async => value;

  @override
  Future<void> write(DailyReminderSettings s) async => value = s;
}

/// 存在 App 文件資料夾的 `daily_reminder.json`。
class FileDailyReminderStore implements DailyReminderStore {
  Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/daily_reminder.json');

  @override
  Future<DailyReminderSettings> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const DailyReminderSettings();
      return DailyReminderSettings.fromJson(jsonDecode(await f.readAsString()) as Map);
    } catch (_) {
      return const DailyReminderSettings();
    }
  }

  @override
  Future<void> write(DailyReminderSettings s) async {
    try {
      await (await _file()).writeAsString(jsonEncode(s.toJson()));
    } catch (_) {}
  }
}

/// 每日一卦提醒：一次排好接下來 [days] 天的一次性通知（不靠重複排程，才能跳過「今天已起卦」）。
/// App 啟動與每次看到解讀時重排；好幾天沒開 App 也還有 [days] 天的提醒。
class DailyReminder {
  DailyReminder({required this.reminders, required this.store});

  static const days = 7;
  static const baseId = 1500000000; // 卦記提醒 id 為秒數取餘數，不會落在這 7 個 id
  static const payload = 'daily';

  final ReminderService reminders;
  final DailyReminderStore store;

  /// 接下來要提醒的時間點：今天已起卦或時間已過就從明天開始。
  static List<DateTime> plan(DateTime now, DailyReminderSettings s, {required bool castToday}) {
    if (!s.enabled) return const [];
    final today = DateTime(now.year, now.month, now.day, s.hour, s.minute);
    final start = castToday || !today.isAfter(now) ? 1 : 0;
    return [for (var i = start; i < start + days; i++) DateTime(now.year, now.month, now.day + i, s.hour, s.minute)];
  }

  /// 重排提醒。[askPermission] 只在使用者自己打開開關，或第一次啟用時為 true；回傳 false 表示排程失敗。
  Future<bool> apply(
    DailyReminderSettings s, {
    required bool castToday,
    required ({String title, String body}) message,
    bool askPermission = false,
    DateTime? now,
  }) async {
    for (var i = 0; i < days + 1; i++) {
      await reminders.cancel(baseId + i);
    }
    final times = plan(now ?? DateTime.now(), s, castToday: castToday);
    var ok = true;
    for (var i = 0; i < times.length; i++) {
      ok = await reminders.schedule(
        id: baseId + i,
        at: times[i],
        title: message.title,
        body: message.body,
        payload: payload,
        kind: ReminderKind.daily,
        askPermission: askPermission && i == 0,
      );
      if (!ok) break;
    }
    return ok;
  }

  /// 啟動或起卦後呼叫：第一次（還沒問過權限）會請求一次權限。
  Future<void> refresh({required bool castToday, required ({String title, String body}) message}) async {
    var s = await store.read();
    final ask = s.enabled && !s.asked;
    await apply(s, castToday: castToday, message: message, askPermission: ask);
    if (ask) await store.write(s.copyWith(asked: true));
  }
}
