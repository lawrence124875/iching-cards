import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../core/iching/cast_result.dart';
import '../core/journal/journal_entry.dart';
import '../core/journal/journal_reminders.dart';
import '../shared/widgets/reminder_picker.dart';

/// 「記下這一卦」：填寫（或修改）想問的事、選擇幾天後提醒回顧。
/// 存檔成功回傳該筆紀錄，取消回傳 null。
Future<JournalEntry?> showSaveReadingSheet(
  BuildContext context, {
  required CastResult cast,
  required String question,
  required int? readingIndex,
}) =>
    showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: QianColors.inkCard,
      builder: (_) => _SaveSheet(cast: cast, question: question, readingIndex: readingIndex),
    );

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({required this.cast, required this.question, required this.readingIndex});

  final CastResult cast;
  final String question;
  final int? readingIndex;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  late final _controller = TextEditingController(text: widget.question);
  int? _days = 7;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final services = AppServices.of(context);
    final store = services.journal;
    if (store == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    var entry = JournalEntry.fromCast(
      cast: widget.cast,
      now: now,
      question: _controller.text.trim(),
      readingIndex: widget.readingIndex,
      reminderAt: _days == null ? null : JournalReminders.reviewTime(now, _days!),
    );
    await store.save(entry);
    var reminderOk = true;
    String? reminderError;
    if (entry.reminderAt != null) {
      reminderOk = await JournalReminders.apply(services.reminders, entry);
      if (!reminderOk) {
        reminderError = services.reminders.lastError;
        entry = entry.copyWith(clearReminder: true);
        await store.save(entry);
      }
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, entry);
    messenger.showSnackBar(SnackBar(
      content: Text(reminderOk
          ? '已記在「卦記」。'
          : '已記在「卦記」，但提醒沒有設定成功。${reminderError ?? ''}'),
      duration: Duration(seconds: reminderOk ? 3 : 8),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // 鍵盤升起時整張面板可捲動，「儲存」不會被擋住；點面板空白處收起鍵盤。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.viewPaddingOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('記下這一卦', style: t.headlineSmall),
            const SizedBox(height: 4),
            Text('只存在這支手機裡。日後回來對照，練習看象。', style: t.bodySmall),
            const SizedBox(height: 16),
            Text('想問的事', style: t.titleMedium),
            TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 200,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(hintText: '可不填'),
            ),
            const SizedBox(height: 8),
            Text('提醒我回來回顧', style: t.titleMedium),
            const SizedBox(height: 8),
            ReminderPicker(days: _days, onChanged: (d) => setState(() => _days = d)),
            if (_days != null) ...[
              const SizedBox(height: 6),
              Text('${_days!} 天後晚上 ${JournalReminders.reviewHour} 點提醒', style: t.bodySmall),
            ],
            const SizedBox(height: 20),
            Center(
              child: FilledButton(onPressed: _saving ? null : _save, child: const Text('儲存')),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
