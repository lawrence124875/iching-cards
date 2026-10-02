import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/hexagram_content.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/journal/journal_reminders.dart';
import '../../reading/reading_page.dart';
import '../../reading/section.dart';
import '../../shared/format.dart';
import '../../shared/widgets/card_face.dart';
import '../../shared/widgets/hexagram_glyph.dart';
import '../../shared/widgets/question_dialog.dart';
import '../../shared/widgets/reminder_picker.dart';

/// 一筆卦記：當時的卦與問題 → 當時的解讀 → 回顧（後來發生了什麼、象怎麼對上）→ 提醒。
class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key, required this.entryId});

  final String entryId;

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late final Services _services = AppServices.of(context);
  JournalEntry? _entry;
  HexagramContent? _content;
  bool _loaded = false;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final e = await _services.journal?.byId(widget.entryId);
    final c = e == null ? null : await _services.content.hexagram(e.cast.primary);
    if (!mounted) return;
    setState(() {
      _entry = e;
      _content = c;
      _ready = true;
    });
  }

  Future<void> _update(JournalEntry e) async {
    setState(() => _entry = e);
    await _services.journal?.save(e);
  }

  Future<void> _editQuestion() async {
    final q = await askQuestion(context, initial: _entry!.question);
    if (q != null) await _update(_entry!.copyWith(question: q));
  }

  Future<void> _editFollowUp([int? index]) async {
    final e = _entry!;
    final old = index == null ? null : e.followUps[index];
    final text = await askQuestion(
      context,
      initial: old?.text ?? '',
      title: index == null ? '後來發生了什麼？' : '修改回顧',
    );
    if (text == null) return;
    final list = [...e.followUps];
    if (index == null) {
      if (text.isEmpty) return;
      list.add(FollowUp(at: DateTime.now(), text: text));
    } else if (text.isEmpty) {
      list.removeAt(index);
    } else {
      list[index] = FollowUp(at: old!.at, text: text);
    }
    await _update(e.copyWith(followUps: list));
  }

  Future<void> _changeReminder(int? days) async {
    final e = _entry!;
    var next = days == null
        ? e.copyWith(clearReminder: true)
        : e.copyWith(reminderAt: JournalReminders.reviewTime(DateTime.now(), days));
    final ok = await JournalReminders.apply(_services.reminders, next);
    if (!ok) next = next.copyWith(clearReminder: true);
    await _update(next);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提醒沒有設定成功。${_services.reminders.lastError ?? ''}'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這筆卦記？'),
        content: const Text('刪除後無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
    if (yes != true) return;
    await _services.reminders.cancel(_entry!.notificationId);
    await _services.journal?.delete(_entry!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
    return Scaffold(
      appBar: AppBar(
        title: const Text('卦記'),
        actions: [
          if (e != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline), tooltip: '刪除'),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : e == null
              ? const Center(child: Text('找不到這筆卦記，可能已經刪除。'))
              : _body(context, e),
    );
  }

  Widget _body(BuildContext context, JournalEntry e) {
    final t = Theme.of(context).textTheme;
    final cast = e.cast;
    final p = HexagramTable.byNumber(cast.primary);
    final c = cast.changed == null ? null : HexagramTable.byNumber(cast.changed!);
    final readings = _content?.readings ?? const [];
    final reading = (e.readingIndex == null || readings.isEmpty) ? null : readings[e.readingIndex! % readings.length];
    final now = DateTime.now();
    final pending = e.reminderAt != null && e.reminderAt!.isAfter(now);
    final pendingDays = pending
        ? DateTime(e.reminderAt!.year, e.reminderAt!.month, e.reminderAt!.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays
        : null;

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 40 + MediaQuery.viewPaddingOf(context).bottom),
      children: [
        Text('${formatDateTime(e.createdAt)}・${methodLabel(e.methodId)}',
            textAlign: TextAlign.center, style: t.bodySmall),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 牌面按原尺寸排版後等比縮小，小縮圖裡的字才不會擠在一起
            SizedBox(
              width: 110,
              height: 110 / 0.62,
              child: FittedBox(
                child: SizedBox(width: 240, height: 240 / 0.62, child: CardFace(info: p, zoomable: true)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullName, style: t.headlineSmall),
                  if (c != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      HexagramGlyph(lines: p.lines, changing: cast.changingPositions.toSet(), width: 28),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.east, size: 18, color: QianColors.mountain),
                      ),
                      HexagramGlyph(lines: c.lines, width: 28),
                      const SizedBox(width: 8),
                      Text('之卦 ${c.name}', style: t.bodyMedium),
                    ]),
                  ],
                  if (reading != null) ...[
                    const SizedBox(height: 16),
                    Text('當時的解讀', style: t.bodySmall),
                    const SizedBox(height: 2),
                    Text(reading.title, style: t.titleMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
        Section(
          title: '想問的事',
          child: InkWell(
            onTap: _editQuestion,
            child: Row(children: [
              Expanded(
                child: Text(e.question.isEmpty ? '（未填寫，點這裡補上）' : e.question,
                    style: e.question.isEmpty ? t.bodyMedium?.copyWith(color: QianColors.textSub) : null),
              ),
              const Icon(Icons.edit_outlined, size: 18, color: QianColors.textSub),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ReadingPage(cast: cast, question: e.question, readingIndex: e.readingIndex, review: true),
          )),
          child: const Text('看當時的解讀'),
        ),
        Section(
          title: '回顧',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('後來發生了什麼？現在回頭看，這個象對應到事情的哪裡？', style: t.bodySmall),
              for (var i = 0; i < e.followUps.length; i++)
                InkWell(
                  onTap: () => _editFollowUp(i),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.only(left: 12),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: QianColors.rice, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatDate(e.followUps[i].at), style: t.bodySmall),
                        Text(e.followUps[i].text),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => _editFollowUp(),
                  icon: const Icon(Icons.add),
                  label: const Text('寫下後來的發展'),
                ),
              ),
            ],
          ),
        ),
        Section(
          title: '回顧提醒',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending ? '${formatDate(e.reminderAt!)} 晚上 ${JournalReminders.reviewHour} 點會提醒你' : '目前沒有提醒。選一個天數，從今天起算：',
                style: t.bodySmall,
              ),
              const SizedBox(height: 8),
              ReminderPicker(days: pendingDays, onChanged: _changeReminder),
            ],
          ),
        ),
      ],
    );
  }
}
