import 'package:flutter/material.dart';

import '../../shared/premium/ad_banner.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/journal/journal_store.dart';
import '../../l10n/l10n.dart';
import '../../shared/format.dart';
import '../../shared/widgets/hexagram_glyph.dart';
import 'journal_backup_menu.dart';
import 'journal_entry_page.dart';
import '../../shared/widgets/adaptive_layout.dart';

/// 卦記列表：由新到舊。
class JournalListPage extends StatelessWidget {
  const JournalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppServices.of(context).journal;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.featureJournal),
        actions: [if (store != null) const JournalBackupMenu()],
      ),
      body: store == null ? const _Empty() : _List(store: store),
      bottomNavigationBar: const AdBanner(),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.store});

  final JournalStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => FutureBuilder<List<JournalEntry>>(
        future: store.all(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snap.data!;
          if (entries.isEmpty) return const _Empty();
          return ListView.separated(
            padding: readablePadding(context, horizontal: 16, top: 8, bottom: 32),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: QianColors.inkCard),
            itemBuilder: (context, i) => _Tile(entry: entries[i]),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final cast = entry.cast;
    final p = HexagramTable.byNumber(cast.primary);
    final c = cast.changed == null ? null : HexagramTable.byNumber(cast.changed!);
    final reviews = entry.followUps.length;
    final pending = entry.reminderAt != null && entry.reminderAt!.isAfter(DateTime.now());
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: HexagramGlyph(lines: p.lines, changing: cast.changingPositions.toSet(), width: 32),
      title: Text(c == null ? l.journalTitleSingle(l.hexName(p)) : l.journalTitleChange(l.hexName(p), l.hexName(c)),
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
              if (reviews > 0) l.journalReviewCount(reviews),
              if (pending) l.journalReminderOn(formatDate(entry.reminderAt!)),
            ].join(l.separator),
            style: t.bodySmall,
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => JournalEntryPage(entryId: entry.id)),
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
