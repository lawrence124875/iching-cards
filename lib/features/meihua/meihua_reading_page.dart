import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/hexagram_content.dart';
import '../../core/content/meihua_content.dart';
import '../../core/events/event_bus.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/iching/trigram.dart';
import '../../core/meihua/meihua_cast.dart';
import '../../core/meihua/meihua_forecast.dart';
import '../../l10n/l10n.dart';
import '../../reading/reading_page.dart';
import '../../reading/save_reading_sheet.dart';
import '../../reading/section.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/hexagram_glyph.dart';

/// 梅花解卦，象與預測並重，順序固定：象（本卦之象 → 體用 → 互卦 → 變卦 → 動爻 → 畫面總結）
/// → 趨勢與應期（五級趨勢、生剋與旺衰、應期區間）→ 可以怎麼做（小阻／阻附化解方向＋今日小行動）
/// → 反思提問 → 頁底「僅供參考與自我覺察」。規則見 HANDOFF §2.2、lib/core/meihua/meihua_forecast.dart。
/// [review] 為 true 時是從卦記回看：不發事件、不顯示儲存。
class MeihuaReadingPage extends StatefulWidget {
  const MeihuaReadingPage({super.key, required this.cast, this.question = '', this.review = false});

  final MeihuaCast cast;
  final String question;
  final bool review;

  @override
  State<MeihuaReadingPage> createState() => _MeihuaReadingPageState();
}

class _MeihuaReadingPageState extends State<MeihuaReadingPage> {
  late final Services _services = AppServices.of(context);
  late final Future<(MeihuaContent?, HexagramContent?)> _content = () async {
    final c = await meihuaSource.load(L10n.language.contentFolder);
    final h = await _services.content.hexagram(widget.cast.primary);
    return (c, h);
  }();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.review) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _services.events.emit(ReadingShown(
        methodId: widget.cast.method.id,
        primary: widget.cast.primary,
        changed: widget.cast.changed,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cast = widget.cast;
    final primary = HexagramTable.byNumber(cast.primary);
    return Scaffold(
      appBar: AppBar(title: Text(l.hexFullName(primary))),
      body: FutureBuilder<(MeihuaContent?, HexagramContent?)>(
        future: _content,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final mc = snap.data!.$1;
          final hc = snap.data!.$2;
          if (mc == null) return Center(child: Text(l.learnMissing));
          return ListView(
            padding: readablePadding(context, top: 8, bottom: 40),
            children: [
              if (widget.question.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(l.questionShown(widget.question),
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                ),
              _GlyphRow(cast: cast),
              ..._sections(context, mc, hc),
              if (!widget.review && _services.journal != null && _services.flags.featureEnabled('journal')) ...[
                const SizedBox(height: 32),
                Center(
                  child: _saved
                      ? Text(l.savedToJournalHint, style: Theme.of(context).textTheme.bodySmall)
                      : FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text(l.saveThisReading),
                        ),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ReadingPage(cast: cast.toCastResult(), question: widget.question, review: true),
                )),
                child: Text(l.meihuaFullReading(l.hexName(primary))),
              ),
              const SizedBox(height: 28),
              Text(
                mc.fill('disclaimer', const {}),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: QianColors.textSub),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _sections(BuildContext context, MeihuaContent mc, HexagramContent? hc) {
    final l = context.l10n;
    final c = widget.cast;
    final t = Theme.of(context).textTheme;
    TrigramImages tri(Trigram x) => mc.trigram(x.name);
    String name(int n) => l.hexFullName(HexagramTable.byNumber(n));
    final ti = tri(c.ti), yong = tri(c.yong);
    final line = (hc != null && hc.lines.length >= c.movingLine) ? hc.lines[c.movingLine - 1] : null;
    final args = {'ti': mc.element(c.tiElement.name), 'yong': mc.element(c.yongElement.name)};
    return [
      Section(title: mc.heading('scene'), child: Text(mc.scene(c.primary), style: t.bodyLarge)),
      Section(
        title: mc.heading('tiyong'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mc.fill('ti', {'name': ti.name, 'image': ti.image}) + ti.asSelf),
          const SizedBox(height: 8),
          Text(mc.fill('yong', {'name': yong.name, 'image': yong.image}) + yong.asOther),
        ]),
      ),
      Section(title: mc.heading('mutual'), child: Text(mc.fill('mutual', {'hex': name(c.mutual)}) + mc.scene(c.mutual))),
      Section(title: mc.heading('changed'), child: Text(mc.fill('changed', {'hex': name(c.changed)}) + mc.scene(c.changed))),
      if (line != null)
        Section(
          title: '${mc.heading('line')}・${line.name}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (line.text.isNotEmpty) Text(line.text, style: t.bodyMedium?.copyWith(color: QianColors.earth)),
            if (line.forYou.isNotEmpty) ...[const SizedBox(height: 8), Text(line.forYou)],
          ]),
        ),
      Section(
        title: mc.heading('summary'),
        child: Text(mc.fill('summary', {
          'upper': tri(c.upper).image,
          'lower': tri(c.lower).image,
          'cUpper': tri(c.changedUpper).image,
          'cLower': tri(c.changedLower).image,
        })),
      ),
      Section(
        title: mc.heading('forecast'),
        child: _ForecastCard(cast: c, content: mc, args: args),
      ),
      Section(
        title: mc.heading('doing'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mc.fill('advice', const {}, sub: c.trend.name)),
          if (MeihuaForecast.needsRemedy(c.trend)) ...[
            const SizedBox(height: 8),
            Text(
              mc.fill('remedy', {'element': mc.element(c.remedyElement.name)}) +
                  mc.fill('remedyBy', const {}, sub: c.remedyElement.name),
            ),
          ],
          const SizedBox(height: 8),
          Text(mc.heading('action'), style: t.labelLarge?.copyWith(color: QianColors.earth)),
          const SizedBox(height: 4),
          Text(ti.action),
        ]),
      ),
      Section(title: mc.heading('question'), child: Text(mc.fill('question', const {}, sub: c.relation.name))),
    ];
  }

  /// 存進卦記是會員功能（梅花起卦紀錄併入卦記）。
  Future<void> _save() async {
    if (!_services.isPremium &&
        !await openPaywall(context, source: 'meihua_journal', note: context.l10n.meihuaPaywallJournalNote)) {
      return;
    }
    if (!mounted) return;
    final entry = await showSaveReadingSheet(
      context,
      cast: widget.cast.toCastResult(),
      question: widget.question,
      readingIndex: null,
    );
    if (entry == null) return;
    _services.events.emit(JournalSaved(hasReminder: entry.reminderAt != null));
    if (mounted) setState(() => _saved = true);
  }
}

/// 本卦（標出動爻）、互卦、變卦三幅卦畫，並標示體、用。
class _GlyphRow extends StatelessWidget {
  const _GlyphRow({required this.cast});

  final MeihuaCast cast;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    Widget one(String label, int n, {Set<int> changing = const {}}) {
      final info = HexagramTable.byNumber(n);
      return Column(children: [
        Text(label, style: t.bodySmall),
        const SizedBox(height: 6),
        HexagramGlyph(lines: info.lines, changing: changing, width: 40),
        const SizedBox(height: 6),
        Text(l.hexName(info), style: t.titleMedium),
      ]);
    }

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        one(l.meihuaPrimary, cast.primary, changing: {cast.movingLine}),
        one(l.meihuaMutual, cast.mutual),
        one(l.meihuaChanged, cast.changed),
      ]),
      const SizedBox(height: 12),
      Text(
        l.meihuaTiYong(l.trigramLabel(cast.ti), l.trigramLabel(cast.yong)),
        textAlign: TextAlign.center,
        style: t.bodySmall?.copyWith(color: QianColors.textSub),
      ),
    ]);
  }
}

/// 趨勢與應期：五級趨勢標籤（醒目）、說明、生剋與旺衰兩句、應期區間與推算依據。
class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.cast, required this.content, required this.args});

  final MeihuaCast cast;
  final MeihuaContent content;
  final Map<String, String> args;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mc = content;
    final c = cast;
    final level = c.trend;
    final color = switch (level) {
      TrendLevel.great || TrendLevel.good => QianColors.rice,
      TrendLevel.even => QianColors.text,
      TrendLevel.minorBlock || TrendLevel.block => QianColors.mountain,
    };
    Widget chip(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
            child: Column(children: [
              Text(label, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
              const SizedBox(height: 4),
              Text(value,
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        chip(mc.heading('trendLabel'), mc.fill('level', const {}, sub: level.name)),
        const SizedBox(width: 12),
        chip(mc.heading('timingLabel'), mc.fill('timing', const {}, sub: c.timing.name)),
      ]),
      const SizedBox(height: 12),
      Text(mc.fill('levelDesc', const {}, sub: level.name)),
      const SizedBox(height: 8),
      Text(_joinSentences(mc.fill('relation', args, sub: c.relation.name),
          mc.fill('strength', {'month': mc.element(c.monthElement.name)}, sub: c.tiStrength.name))),
      const SizedBox(height: 8),
      Text(
        mc.fill('timingWhy', {
          'sum': '${MeihuaForecast.numberSum(c.ti, c.yong)}',
          'pace': mc.fill('pace', const {}, sub: c.tiStrength.name),
          'window': mc.fill('timing', const {}, sub: c.timing.name),
        }),
        style: t.bodySmall?.copyWith(color: QianColors.textSub),
      ),
    ]);
  }
}

/// 兩句相接：中日文（全形標點、漢字、假名）直接相接，其他語言（含泰文）補一個空格。
String _joinSentences(String a, String b) {
  if (a.isEmpty || b.isEmpty || a.endsWith(' ')) return '$a$b';
  final last = a.codeUnitAt(a.length - 1);
  final cjk = (last >= 0x3000 && last <= 0x9FFF) || (last >= 0xFF00 && last <= 0xFFEF);
  return cjk ? '$a$b' : '$a $b';
}
