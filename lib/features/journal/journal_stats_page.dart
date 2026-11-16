import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/journal/journal_filter.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/adaptive_layout.dart';
import 'journal_list_page.dart';

/// 卦記統計：總數、寫過回顧的、各起卦方式、最常出現的卦、雙卦交叉的事後回饋。
/// 免費版只統計看得到的（最近 [FreeLimits.journalDays] 天）。
class JournalStatsPage extends StatelessWidget {
  const JournalStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppServices.of(context);
    final l = context.l10n;
    final store = s.journal;
    return Scaffold(
      appBar: AppBar(title: Text(l.journalStats)),
      body: store == null
          ? const SizedBox.shrink()
          : FutureBuilder<List<JournalEntry>>(
              future: store.all(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final days = s.limits.journalDays;
                final cutoff = JournalFilter.freeCutoff(DateTime.now(), days);
                final all = snap.data!;
                final open = s.isPremium ? all : [for (final e in all) if (!e.createdAt.isBefore(cutoff)) e];
                return _Stats(entries: open, freeNote: open.length < all.length ? l.journalStatsFreeNote(days) : null);
              },
            ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.entries, this.freeNote});

  final List<JournalEntry> entries;
  final String? freeNote;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final stats = JournalStats.of(entries);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(text, style: t.titleMedium?.copyWith(color: QianColors.earth)),
        );
    Widget row(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [Expanded(child: Text(a, style: t.bodyLarge)), Text(b, style: t.bodyLarge)]),
        );
    return ListView(
      padding: readablePadding(context, top: 16, bottom: 40),
      children: [
        Text(l.journalStatsTotal(entries.length), style: t.headlineSmall),
        const SizedBox(height: 4),
        Text(l.journalStatsReviewed(stats.reviewed), style: t.bodyMedium?.copyWith(color: QianColors.textSub)),
        if (freeNote != null) ...[
          const SizedBox(height: 8),
          Text(freeNote!, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
        ],
        if (stats.byCategory.isNotEmpty) ...[
          heading(l.journalStatsTypes),
          for (final c in JournalEntry.categories)
            if (stats.byCategory[c] != null) row(journalCategoryLabel(l, c), l.journalStatsTimes(stats.byCategory[c]!)),
        ],
        if (stats.topHexagrams.isNotEmpty) ...[
          heading(l.journalStatsTopHex),
          for (final h in stats.topHexagrams)
            row(l.hexFullName(HexagramTable.byNumber(h.hexagram)), l.journalStatsTimes(h.count)),
        ],
        if (stats.verified.isNotEmpty) ...[
          heading(l.journalStatsVerified),
          if (stats.verified['yes'] != null) row(l.journalStatsYes, l.journalStatsTimes(stats.verified['yes']!)),
          if (stats.verified['partly'] != null) row(l.journalStatsPartly, l.journalStatsTimes(stats.verified['partly']!)),
          if (stats.verified['no'] != null) row(l.journalStatsNo, l.journalStatsTimes(stats.verified['no']!)),
        ],
      ],
    );
  }
}

/// 統計數字（純計算，方便測試）。
class JournalStats {
  JournalStats._(this.reviewed, this.byCategory, this.topHexagrams, this.verified);

  final int reviewed;
  final Map<String, int> byCategory;

  /// 本卦出現次數，多到少，最多 5 個（只出現一次的不列）。
  final List<({int hexagram, int count})> topHexagrams;

  /// 雙卦交叉「事後應驗了嗎？」：yes／partly／no 的次數。
  final Map<String, int> verified;

  factory JournalStats.of(List<JournalEntry> entries) {
    final cat = <String, int>{};
    final hex = <int, int>{};
    final ver = <String, int>{};
    var reviewed = 0;
    for (final e in entries) {
      cat[e.category] = (cat[e.category] ?? 0) + 1;
      if (e.followUps.isNotEmpty) reviewed++;
      if (!e.isCard) hex[e.cast.primary] = (hex[e.cast.primary] ?? 0) + 1;
      final v = e.cross?.verified;
      if (v != null) ver[v] = (ver[v] ?? 0) + 1;
    }
    final top = [for (final x in hex.entries) if (x.value > 1) (hexagram: x.key, count: x.value)]
      ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.hexagram.compareTo(b.hexagram));
    return JournalStats._(reviewed, cat, top.take(5).toList(), ver);
  }
}
