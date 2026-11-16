import 'package:flutter/material.dart';

import '../../shared/premium/ad_banner.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/journal/journal_filter.dart';
import '../../core/journal/journal_reminders.dart';
import '../../core/journal/journal_store.dart';
import '../../l10n/l10n.dart';
import '../../shared/format.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/hexagram_glyph.dart';
import 'journal_backup_menu.dart';
import 'journal_entry_page.dart';
import '../../shared/widgets/adaptive_layout.dart';

/// 卦記列表：由新到舊、依月份分組；分類／收藏／日期區間篩選、關鍵字搜尋；左滑刪除可復原、長按多選。
/// 免費版只顯示最近 [FreeLimits.journalDays] 天，較早的保留在手機上、上鎖（訂閱後顯示）。
class JournalListPage extends StatefulWidget {
  const JournalListPage({super.key});

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  late final Services _services = AppServices.of(context);
  final _search = TextEditingController();
  bool _searching = false;
  JournalFilter _filter = const JournalFilter();
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setFilter(JournalFilter f) => setState(() => _filter = f);

  JournalFilter _copy({Object? category = _keep, bool? starredOnly, Object? from = _keep, Object? to = _keep, String? text}) =>
      JournalFilter(
        category: identical(category, _keep) ? _filter.category : category as String?,
        starredOnly: starredOnly ?? _filter.starredOnly,
        from: identical(from, _keep) ? _filter.from : from as DateTime?,
        to: identical(to, _keep) ? _filter.to : to as DateTime?,
        text: text ?? _filter.text,
      );

  String _haystack(AppLocalizations l, JournalEntry e) {
    final parts = [JournalFilter.userText(e), l.journalMethodLabel(e.labelKey)];
    if (!e.isCard) {
      final cast = e.cast;
      final p = HexagramTable.byNumber(cast.primary);
      parts
        ..add(l.hexFullName(p))
        ..add(l.hexName(p));
      if (cast.changed != null) parts.add(l.hexFullName(HexagramTable.byNumber(cast.changed!)));
    }
    return parts.join('\n');
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _filter.hasDate ? DateTimeRange(start: _filter.from!, end: _filter.to!) : null,
    );
    if (r != null) _setFilter(_copy(from: r.start, to: r.end));
  }

  Future<void> _toggleStar(JournalEntry e) => _services.journal!.save(e.copyWith(starred: !e.starred));

  /// 左滑刪除：先刪，提示列可復原（復原時補排回顧提醒）。
  Future<void> _deleteWithUndo(List<JournalEntry> entries) async {
    final store = _services.journal!;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    for (final e in entries) {
      await _services.reminders.cancel(e.notificationId);
    }
    await store.deleteMany(entries.map((e) => e.id));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.journalDeletedCount(entries.length)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () async {
            await store.addMissing(entries);
            for (final e in entries) {
              try {
                await JournalReminders.apply(_services.reminders, e, l.reviewMessage);
              } catch (_) {}
            }
          },
        ),
      ));
  }

  Future<void> _deleteSelected(List<JournalEntry> all) async {
    final l = context.l10n;
    final targets = [for (final e in all) if (_selected.contains(e.id)) e];
    if (targets.isEmpty) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.journalDeleteManyTitle(targets.length)),
        content: Text(l.journalDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(_selected.clear);
    for (final e in targets) {
      await _services.reminders.cancel(e.notificationId);
    }
    await _services.journal!.deleteMany(targets.map((e) => e.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.journalDeletedCount(targets.length))));
    }
  }

  void _toggleSelect(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  void _toggleMany(List<JournalEntry> list) => setState(() {
        final ids = list.map((e) => e.id);
        if (ids.every(_selected.contains)) {
          _selected.removeAll(ids);
        } else {
          _selected.addAll(ids);
        }
      });

  @override
  Widget build(BuildContext context) {
    final store = _services.journal;
    if (store == null) {
      return Scaffold(appBar: AppBar(title: Text(context.l10n.featureJournal)), body: const _Empty());
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _services.premium.isPremium,
      builder: (context, premium, _) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => FutureBuilder<List<JournalEntry>>(
          future: store.all(),
          builder: (context, snap) => _scaffold(context, snap.data, premium),
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context, List<JournalEntry>? all, bool premium) {
    final l = context.l10n;
    final days = _services.limits.journalDays;
    final cutoff = JournalFilter.freeCutoff(DateTime.now(), days);
    final open = all == null ? <JournalEntry>[] : premium ? all : [for (final e in all) if (!e.createdAt.isBefore(cutoff)) e];
    final locked = (all?.length ?? 0) - open.length;
    final shown = [for (final e in open) if (_filter.matches(e, (x) => _haystack(l, x))) e];
    _selected.retainWhere((id) => open.any((e) => e.id == id));

    return PopScope(
      canPop: !_selecting && !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_selecting) {
            _selected.clear();
          } else {
            _searching = false;
            _search.clear();
            _filter = _copy(text: '');
          }
        });
      },
      child: Scaffold(
        appBar: _selecting ? _selectBar(l, shown, open) : _normalBar(l),
        body: all == null
            ? const Center(child: CircularProgressIndicator())
            : all.isEmpty
                ? const _Empty()
                : Column(children: [
                    _chips(l, open),
                    Expanded(child: _list(context, shown, locked, days)),
                  ]),
        bottomNavigationBar: const AdBanner(),
      ),
    );
  }

  PreferredSizeWidget _normalBar(AppLocalizations l) => AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(hintText: l.journalSearchHint, border: InputBorder.none),
                onChanged: (v) => _setFilter(_copy(text: v)),
              )
            : Text(l.featureJournal),
        actions: [
          IconButton(
            tooltip: _searching ? l.cancel : l.journalSearchHint,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _search.clear();
                _filter = _copy(text: '');
              }
            }),
          ),
          IconButton(tooltip: l.journalDateRange, icon: const Icon(Icons.date_range_outlined), onPressed: _pickDates),
          const JournalBackupMenu(),
        ],
      );

  PreferredSizeWidget _selectBar(AppLocalizations l, List<JournalEntry> shown, List<JournalEntry> open) => AppBar(
        leading: IconButton(icon: const Icon(Icons.close), tooltip: l.cancel, onPressed: () => setState(_selected.clear)),
        title: Text(l.journalSelectedCount(_selected.length)),
        actions: [
          IconButton(tooltip: l.journalSelectAll, icon: const Icon(Icons.select_all), onPressed: () => _toggleMany(shown)),
          IconButton(tooltip: l.delete, icon: const Icon(Icons.delete_outline), onPressed: () => _deleteSelected(open)),
        ],
      );

  Widget _chips(AppLocalizations l, List<JournalEntry> open) {
    final present = {for (final e in open) e.category};
    String label(String c) => switch (c) {
          'iching' => l.journalFilterIching,
          'meihua' => l.featureMeihua,
          'cross' => l.featureCross,
          'daily' => l.dailyTitle,
          _ => l.featureEastern,
        };
    final cats = [for (final c in JournalEntry.categories) if (present.contains(c) || _filter.category == c) c];
    Widget chip(String text, bool on, VoidCallback tap, {Widget? avatar}) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(label: Text(text), selected: on, onSelected: (_) => tap(), avatar: avatar, showCheckmark: false),
        );
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          chip(l.journalFilterAll, _filter.category == null && !_filter.starredOnly,
              () => _setFilter(_copy(category: null, starredOnly: false))),
          chip(l.journalFilterStarred, _filter.starredOnly, () => _setFilter(_copy(starredOnly: !_filter.starredOnly)),
              avatar: Icon(Icons.star, size: 18, color: QianColors.earth)),
          for (final c in cats)
            chip(label(c), _filter.category == c, () => _setFilter(_copy(category: _filter.category == c ? null : c))),
          if (_filter.hasDate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text('${formatDate(_filter.from!)} – ${formatDate(_filter.to!)}'),
                onPressed: _pickDates,
                onDeleted: () => _setFilter(_copy(from: null, to: null)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<JournalEntry> shown, int locked, int days) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final ml = MaterialLocalizations.of(context);
    final groups = JournalFilter.byMonth(shown);
    final children = <Widget>[
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(l.journalNoMatch, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: QianColors.textSub)),
        ),
      for (final g in groups) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
          child: Row(children: [
            Expanded(
              child: Text(ml.formatMonthYear(DateTime(g.year, g.month)),
                  style: t.titleSmall?.copyWith(color: QianColors.earth)),
            ),
            if (_selecting) TextButton(onPressed: () => _toggleMany(g.entries), child: Text(l.journalSelectMonth)),
          ]),
        ),
        for (final e in g.entries) ...[
          _selecting
              ? _Tile(
                  entry: e,
                  selected: _selected.contains(e.id),
                  onTap: () => _toggleSelect(e.id),
                  onLongPress: () => _toggleSelect(e.id),
                )
              : Dismissible(
                  key: ValueKey('j-${e.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                  ),
                  onDismissed: (_) => _deleteWithUndo([e]),
                  child: _Tile(
                    entry: e,
                    onStar: () => _toggleStar(e),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => JournalEntryPage(entryId: e.id)),
                    ),
                    onLongPress: () => _toggleSelect(e.id),
                  ),
                ),
          Divider(height: 1, color: QianColors.inkCard),
        ],
      ],
      if (locked > 0) _Locked(count: locked, days: days),
    ];
    return ListView(padding: readablePadding(context, horizontal: 16, top: 0, bottom: 32), children: children);
  }
}

const _keep = Object();

class _Tile extends StatelessWidget {
  const _Tile({required this.entry, required this.onTap, required this.onLongPress, this.onStar, this.selected});

  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onStar;

  /// 多選模式時非 null。
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final card = entry.isCard;
    final cast = card ? null : entry.cast;
    final p = cast == null ? null : HexagramTable.byNumber(cast.primary);
    final c = cast?.changed == null ? null : HexagramTable.byNumber(cast!.changed!);
    final reviews = entry.followUps.length;
    final pending = entry.reminderAt != null && entry.reminderAt!.isAfter(DateTime.now());
    final glyph = p == null
        ? SizedBox(width: 32, child: Icon(Icons.wb_twilight_outlined, color: QianColors.earth))
        : HexagramGlyph(lines: p.lines, changing: cast!.changingPositions.toSet(), width: 32);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      selected: selected ?? false,
      leading: selected == null
          ? glyph
          : Icon(selected! ? Icons.check_circle : Icons.radio_button_unchecked, color: QianColors.earth),
      title: Text(
          p == null
              ? l.journalMethodLabel(entry.labelKey)
              : c == null
                  ? l.journalTitleSingle(l.hexName(p))
                  : l.journalTitleChange(l.hexName(p), l.hexName(c)),
          style: t.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.question.isEmpty ? l.journalNoQuestion : entry.question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.bodyMedium?.copyWith(color: entry.question.isEmpty ? QianColors.textSub : null),
          ),
          const SizedBox(height: 2),
          Text(
            [
              formatDate(entry.createdAt),
              l.journalMethodLabel(entry.labelKey),
              if (reviews > 0) l.journalReviewCount(reviews),
              if (pending) l.journalReminderOn(formatDate(entry.reminderAt!)),
            ].join(l.separator),
            style: t.bodySmall,
          ),
        ],
      ),
      trailing: onStar == null
          ? null
          : IconButton(
              tooltip: entry.starred ? l.journalUnstar : l.journalFilterStarred,
              icon: Icon(entry.starred ? Icons.star : Icons.star_border,
                  color: entry.starred ? QianColors.earth : QianColors.textSub),
              onPressed: onStar,
            ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// 免費版：較早的卦記上鎖。
class _Locked extends StatelessWidget {
  const _Locked({required this.count, required this.days});

  final int count;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lock_outline, color: QianColors.earth),
              const SizedBox(width: 8),
              Expanded(child: Text(l.journalLockedTitle(count, days), style: t.titleSmall)),
            ]),
            const SizedBox(height: 8),
            Text(l.journalLockedBody(days), style: t.bodyMedium?.copyWith(color: QianColors.textSub)),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => openPaywall(context, source: 'journal_history'),
                child: Text(l.menuPremium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          context.l10n.journalEmpty,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: QianColors.textSub),
        ),
      ),
    );
  }
}
