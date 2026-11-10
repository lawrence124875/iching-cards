import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/eastern_content.dart';
import '../../core/eastern/bazi.dart';
import '../../core/eastern/birth_profile.dart';
import '../../core/journal/journal_entry.dart';
import '../../l10n/l10n.dart';
import '../../reading/save_reading_sheet.dart';
import '../../reading/section.dart';
import '../../shared/format.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';

/// 八字本月能量卡：日主（免費）→ 本月能量高／穩／耗＋方法 → 反思提問（會員）。
/// [at] 為卦記回看時的存檔時間（月份依當時）；[review] 為 true 時不顯示儲存。
class BaziMonthPage extends StatefulWidget {
  const BaziMonthPage({super.key, required this.profile, this.at, this.review = false});

  final BirthProfile profile;
  final DateTime? at;
  final bool review;

  @override
  State<BaziMonthPage> createState() => _BaziMonthPageState();
}

class _BaziMonthPageState extends State<BaziMonthPage> {
  late final Future<EasternContent?> _content = easternSource.load(L10n.language.contentFolder);
  bool _saved = false;

  Future<void> _save() async {
    final e = await showSaveCardSheet(
      context,
      methodId: 'bazi',
      eastern: EasternRecord(birth: widget.profile.toJson(), systems: const ['bazi']),
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
          appBar: AppBar(title: Text(ec?.s('bazi.title') ?? l.featureEastern)),
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
    final now = widget.at ?? DateTime.now();
    final m = widget.profile.monthAt(now);
    final energy = m.energy;
    final color = switch (energy) {
      MonthEnergy.high => QianColors.rice,
      MonthEnergy.steady => QianColors.text,
      MonthEnergy.drain => QianColors.mountain,
    };
    final dm = m.dayMaster.name;
    return [
      Text(
          ec.s('bazi.monthLabel', {
            'ganzhi': '${stemChars[m.monthStem]}${branchChars[m.monthBranch]}',
            'start': formatDate(baziMonthStart(now)),
          }),
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: QianColors.textSub)),
      Section(
        title: ec.s('bazi.dayMasterHeading', {'element': ec.s('bazi.elements.$dm')}),
        child: Text(ec.s('bazi.dayMaster.$dm')),
      ),
      if (!premium) ...[
        const SizedBox(height: 24),
        Text(ec.s('bazi.locked'), textAlign: TextAlign.center, style: t.bodySmall),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: () => openPaywall(context, source: 'bazi'),
            child: Text(ec.s('bazi.unlock')),
          ),
        ),
      ] else ...[
        Section(
          title: ec.s('bazi.energyHeading'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ec.s('bazi.energy.${energy.name}'),
                style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(ec.s('bazi.energyDesc.${energy.name}')),
          ]),
        ),
        Section(
          title: ec.s('bazi.reflectionHeading'),
          child: Text(ec.s('bazi.reflection.${energy.name}'), style: t.bodyMedium?.copyWith(color: QianColors.rice)),
        ),
        const SizedBox(height: 16),
        Text(ec.s('bazi.boundary'), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
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
