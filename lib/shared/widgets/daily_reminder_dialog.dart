import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/reminders/daily_reminder.dart';
import '../../core/reminders/reminder_service.dart';
import '../../l10n/l10n.dart';

/// 每日一卦提醒的設定（首頁選單）：開關＋時間。改了就馬上重排。
/// 沒有通知權限就顯示關閉；打開開關時再請求一次權限，系統不再跳對話框就直接帶到通知設定，
/// 從設定回來已允許就自動開啟（另留「前往通知設定」按鈕）。
Future<void> showDailyReminderDialog(BuildContext context) async {
  final services = AppServices.of(context);
  final daily = services.dailyReminder;
  if (daily == null) return;
  final initial = await daily.store.read();
  if (!context.mounted) return;
  await showDialog<void>(context: context, builder: (_) => _DailyReminderDialog(services, daily, initial));
}

class _DailyReminderDialog extends StatefulWidget {
  const _DailyReminderDialog(this.services, this.daily, this.initial);

  final Services services;
  final DailyReminder daily;
  final DailyReminderSettings initial;

  @override
  State<_DailyReminderDialog> createState() => _DailyReminderDialogState();
}

class _DailyReminderDialogState extends State<_DailyReminderDialog> with WidgetsBindingObserver {
  late DailyReminderSettings _s = widget.initial;
  String? _error;

  /// 打開開關時權限被拒：顯示「前往通知設定」，回到 App 時再檢查一次。
  bool _needSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_s.enabled && _s.asked) _syncPermission(); // 還沒問過權限（尚未起卦）就維持開啟
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needSettings) _retryAfterSettings();
  }

  /// 開著但其實沒有權限（之後在系統關掉）：改成關閉。
  Future<void> _syncPermission() async {
    if (await widget.services.reminders.hasPermission() || !mounted) return;
    await _update(_s.copyWith(enabled: false));
  }

  Future<void> _retryAfterSettings() async {
    if (!await widget.services.reminders.hasPermission() || !mounted) return;
    await _update(_s.copyWith(enabled: true));
  }

  Future<void> _update(DailyReminderSettings next, {bool ask = false}) async {
    final l = context.l10n;
    setState(() {
      _s = next.copyWith(asked: true);
      _error = null;
      _needSettings = false;
    });
    await widget.daily.store.write(_s);
    final ok = await widget.daily.apply(
      _s,
      castToday: await widget.services.quota.castToday(),
      message: L10n.current.dailyMessage,
      askPermission: ask,
    );
    if (ok || !mounted) return;
    final failure = widget.services.reminders.lastFailure;
    if (_s.enabled && failure?.kind == ReminderFailureKind.permissionDenied) {
      // 沒有權限就不算開著：存回關閉，並讓使用者到系統設定開
      _s = _s.copyWith(enabled: false);
      await widget.daily.store.write(_s);
      if (!mounted) return;
      setState(() {
        _needSettings = true;
        _error = l.reminderPermissionDenied;
      });
      if (ask && failure!.promptSkipped) await widget.services.reminders.openSettings();
      return;
    }
    setState(() => _error = l.reminderFailed(l.reminderFailureText(failure)));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _s.hour, minute: _s.minute));
    if (t != null) await _update(_s.copyWith(hour: t.hour, minute: t.minute), ask: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final time = TimeOfDay(hour: _s.hour, minute: _s.minute).format(context);
    return AlertDialog(
      title: Text(l.menuDailyReminder),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.dailyReminderSwitch),
          value: _s.enabled,
          onChanged: (v) => _update(_s.copyWith(enabled: v), ask: v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: _s.enabled,
          title: Text(l.dailyReminderTime),
          trailing: Text(time),
          onTap: _pickTime,
        ),
        Text(l.dailyReminderHint, style: const TextStyle(color: QianColors.textSub)),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        if (_needSettings)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: widget.services.reminders.openSettings,
              child: Text(l.reminderOpenSettings),
            ),
          ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok))],
    );
  }
}
