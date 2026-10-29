import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/reminders/daily_reminder.dart';
import '../../l10n/l10n.dart';

/// 每日一卦提醒的設定（首頁選單）：開關＋時間。改了就馬上重排。
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

class _DailyReminderDialogState extends State<_DailyReminderDialog> {
  late DailyReminderSettings _s = widget.initial;
  String? _error;

  Future<void> _update(DailyReminderSettings next, {bool ask = false}) async {
    final l = context.l10n;
    setState(() {
      _s = next.copyWith(asked: true);
      _error = null;
    });
    await widget.daily.store.write(_s);
    final ok = await widget.daily.apply(
      _s,
      castToday: await widget.services.quota.castToday(),
      message: L10n.current.dailyMessage,
      askPermission: ask,
    );
    if (!ok && mounted) setState(() => _error = l.reminderFailed(l.reminderFailureText(widget.services.reminders.lastFailure)));
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
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.ok))],
    );
  }
}
