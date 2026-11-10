import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/eastern_content.dart';
import '../../core/eastern/birth_profile.dart';
import '../../core/eastern/ziwei.dart';
import '../../core/journal/journal_entry.dart';
import '../../l10n/l10n.dart';
import '../../reading/save_reading_sheet.dart';
import '../../reading/section.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';

/// 紫微年度基調卡：命宮主星性格（免費）→ 今年主題（流年命宮主星）→ 四化提示 → 年度趨勢＋主題 → 反思提問（會員）。
/// [at] 為卦記回看時的存檔時間（流年依當時）；[review] 為 true 時不顯示儲存。
class ZiweiYearPage extends StatefulWidget {
  const ZiweiYearPage({super.key, required this.profile, this.at, this.review = false});

  final BirthProfile profile;
  final DateTime? at;
  final bool review;

  @override
  State<ZiweiYearPage> createState() => _ZiweiYearPageState();
}

class _ZiweiYearPageState extends State<ZiweiYearPage> {
  late final Future<EasternContent?> _content = easternSource.load(L10n.language.contentFolder);
  bool _saved = false;

  Future<void> _save() async {
    final e = await showSaveCardSheet(
      context,
      methodId: 'ziwei',
      eastern: EasternRecord(birth: widget.profile.toJson(), systems: const ['ziwei']),
    );
    if (e != null && mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = AppServices.of(context);
    return FutureBuilder<EasternContent?>(
      future: _content,
      builder: (context, snap) {
        final ec = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(ec?.s('ziwei.title') ?? l.featureEastern)),
          body: snap.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ec == null
                  ? Center(child: Text(l.learnMissing))
                  : ValueListenableBuilder<bool>(
                      valueListenable: services.premium.isPremium,
                      builder: (context, premium, _) => ListView(
                        padding: readablePadding(context, top: 8, bottom: 40),
                        children: _body(context, ec, premium, services),
                      ),
                    ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, EasternContent ec, bool premium, Services services) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final chart = widget.profile.ziwei();
    if (chart == null) {
      return [const SizedBox(height: 24), Text(ec.s('ziwei.noHour'), textAlign: TextAlign.center)];
    }
    final y = ziweiYearAt(widget.at ?? DateTime.now());
    final year = chart.year(stem: y.stem, branch: y.branch);
    String star(String k) => ec.s('ziwei.stars.$k');
    String stars(List<MajorStar> s) => s.map((x) => star(x.name)).join(l.separator);
    final ming = chart.majorsOrBorrowed(chart.ming);
    final yearMajors = year.majors;
    final lead = ming.stars.isEmpty ? null : ming.stars.first;
    final yearLead = yearMajors.stars.isEmpty ? null : yearMajors.stars.first;
    final trend = year.trend;
    final color = switch (trend) {
      YearTrend.pos => QianColors.rice,
      YearTrend.even => QianColors.text,
      YearTrend.neg => QianColors.mountain,
    };

    return [
      Text(ec.s('ziwei.yearLabel', {'year': '${y.year}', 'ganzhi': '${stemChars[y.stem]}${branchChars[y.branch]}'}),
          textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
      Section(
        title: ec.s('ziwei.mingHeading', {'stars': stars(ming.stars)}),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (ming.borrowed) ...[
            Text(ec.s('ziwei.mingBorrowed', {'stars': stars(ming.stars)}), style: t.bodySmall),
            const SizedBox(height: 8),
          ],
          if (lead != null) Text(ec.s('ziwei.personality.${lead.name}')),
        ]),
      ),
      if (!premium) ...[
        const SizedBox(height: 24),
        Text(ec.s('ziwei.locked'), textAlign: TextAlign.center, style: t.bodySmall),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: () => openPaywall(context, source: 'ziwei'),
            child: Text(ec.s('ziwei.unlock')),
          ),
        ),
      ] else ...[
        Section(
          title: ec.s('ziwei.yearHeading', {'stars': stars(yearMajors.stars)}),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (yearMajors.borrowed) ...[
              Text(ec.s('ziwei.yearBorrowed', {'stars': stars(yearMajors.stars)}), style: t.bodySmall),
              const SizedBox(height: 8),
            ],
            if (yearLead != null) Text(ec.s('ziwei.yearTheme.${yearLead.name}')),
          ]),
        ),
        Section(
          title: ec.s('ziwei.sihuaHeading'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (year.sihuaInPalace.isEmpty) Text(ec.s('ziwei.sihuaNone')),
            for (final h in year.sihuaInPalace) ...[
              Text(
                ec.s('ziwei.sihuaItem', {
                  'star': star(h.star),
                  'hua': ec.s('ziwei.hua.${h.hua.name}'),
                  'source': ec.s(h.natal ? 'ziwei.natal' : 'ziwei.yearly'),
                }),
                style: t.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(ec.s('ziwei.huaHint.${h.hua.name}')),
              const SizedBox(height: 10),
            ],
          ]),
        ),
        Section(
          title: ec.s('ziwei.trendHeading'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ec.s('ziwei.trend.${trend.name}'),
                style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(ec.s('ziwei.themeLine', {'theme': ec.s('ziwei.themes.${year.theme.name}')}), style: t.bodySmall),
            const SizedBox(height: 8),
            Text(ec.s('ziwei.trendDesc.${trend.name}')),
          ]),
        ),
        Section(
          title: ec.s('ziwei.reflectionHeading'),
          child: Text(ec.s('ziwei.reflection.${trend.name}'), style: t.bodyMedium?.copyWith(color: QianColors.rice)),
        ),
        if (!widget.review && services.journal != null && services.flags.featureEnabled('journal')) ...[
          const SizedBox(height: 32),
          Center(
            child: _saved
                ? Text(l.savedToJournalHint, style: t.bodySmall)
                : FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(ec.s('saveCard')),
                  ),
          ),
        ],
      ],
      const SizedBox(height: 28),
      Text(ec.s('disclaimer'),
          textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
    ];
  }
}
