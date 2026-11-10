import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../core/iching/cast_result.dart';
import '../core/journal/journal_entry.dart';
import '../core/journal/journal_reminders.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/reminder_picker.dart';

/// 「記下這一卦」：填寫（或修改）想問的事、選擇幾天後提醒回顧。
/// 存檔成功回傳該筆紀錄，取消回傳 null。
Future<JournalEntry?> showSaveReadingSheet(
  BuildContext context, {
  required CastResult cast,
  required String question,
  required int? readingIndex,
  CrossRecord? cross,
  EasternRecord? eastern,
}) =>
    showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: QianColors.inkCard,
      builder: (_) => _SaveSheet(cast: cast, question: question, readingIndex: readingIndex, cross: cross, eastern: eastern),
    );

/// 存命理卡片（紫微年度卡、八字本月卡）：沒有六爻、不設回顧提醒。
Future<JournalEntry?> showSaveCardSheet(
  BuildContext context, {
  required String methodId,
  required EasternRecord eastern,
}) =>
    showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: QianColors.inkCard,
      builder: (_) => _SaveSheet(cast: null, question: '', readingIndex: null, eastern: eastern, cardMethod: methodId),
    );

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({required this.cast, required this.question, required this.readingIndex, this.cross, this.eastern, this.cardMethod});

  final CastResult? cast;

  /// 命理卡片的 methodId（`ziwei`、`bazi`）；此時 [cast] 為 null。
  final String? cardMethod;
  final String question;
  final int? readingIndex;
  final CrossRecord? cross;
  final EasternRecord? eastern;

  /// 命理卡片（紫微、八字）不設回顧提醒（通知內文以卦名為主）。
  bool get isCard => cardMethod != null;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  late final _controller = TextEditingController(text: widget.question);
  late int? _days = widget.isCard ? null : 7;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final services = AppServices.of(context);
    final l = context.l10n;
    final store = services.journal;
    if (store == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final card = widget.cardMethod;
    var entry = card != null
        ? JournalEntry(
            id: now.microsecondsSinceEpoch.toRadixString(36),
            createdAt: now,
            methodId: card,
            lineValues: const [],
            question: _controller.text.trim(),
            eastern: widget.eastern,
          )
        : JournalEntry.fromCast(
      cast: widget.cast!,
      now: now,
      question: _controller.text.trim(),
      readingIndex: widget.readingIndex,
      reminderAt: _days == null ? null : JournalReminders.reviewTime(now, _days!),
      cross: widget.cross,
      eastern: widget.eastern,
    );
    await store.save(entry);
    var reminderOk = true;
    String? reminderError;
    if (entry.reminderAt != null) {
      reminderOk = await JournalReminders.apply(services.reminders, entry, l.reviewMessage);
      if (!reminderOk) {
        reminderError = l.reminderFailureText(services.reminders.lastFailure);
        entry = entry.copyWith(clearReminder: true);
        await store.save(entry);
      }
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, entry);
    messenger.showSnackBar(SnackBar(
      content: Text(reminderOk ? l.savedOk : l.savedReminderFailed(reminderError ?? '')),
      duration: Duration(seconds: reminderOk ? 3 : 8),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
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
            Text(l.saveThisReading, style: t.headlineSmall),
            const SizedBox(height: 4),
            Text(l.saveSheetNote, style: t.bodySmall),
            const SizedBox(height: 16),
            Text(l.questionTitle, style: t.titleMedium),
            TextField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 200,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(hintText: l.optionalHint),
            ),
            if (!widget.isCard) ...[
              const SizedBox(height: 8),
              Text(l.saveSheetRemind, style: t.titleMedium),
              const SizedBox(height: 8),
              ReminderPicker(days: _days, onChanged: (d) => setState(() => _days = d)),
            ],
            if (_days != null) ...[
              const SizedBox(height: 6),
              Text(l.saveSheetRemindIn(_days!, hour12(JournalReminders.reviewHour)), style: t.bodySmall),
            ],
            const SizedBox(height: 20),
            Center(
              child: FilledButton(onPressed: _saving ? null : _save, child: Text(l.save)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
