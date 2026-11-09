import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/content/cross_content.dart';
import '../../core/content/hexagram_content.dart';
import '../../core/content/meihua_content.dart';
import '../../core/cross/cross_reading.dart';
import '../../core/events/event_bus.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/focus_rule.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/meihua/meihua_cast.dart';
import '../../core/meihua/meihua_forecast.dart';
import '../../l10n/l10n.dart';
import '../../reading/reading_page.dart';
import '../../reading/save_reading_sheet.dart';
import '../../reading/section.dart';
import '../../shared/premium/paywall_page.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/hexagram_glyph.dart';
import '../meihua/meihua_reading_page.dart';
import 'cross_guide.dart';

/// 交叉頁（2026-11-09 改四段）：雙卦交會（共識／部分呼應／分歧、趨勢與應期、主題）
/// → 梅花：當下局勢（體用＋互卦／變卦轉折）→ 易經：長遠走向（本卦→之卦過程＋重點文字）
/// → 行動方向（今日小行動＋反思提問）→ 頁底聲明。分歧時兩邊各自說明，不合成結論。
/// 免費版只顯示對照標題，其餘為會員內容。[review] 為 true 時是從卦記回看：不發事件、不顯示儲存。
class CrossReadingPage extends StatefulWidget {
  const CrossReadingPage({
    super.key,
    required this.iching,
    required this.meihua,
    this.question = '',
    this.review = false,
    this.solarCity,
  });

  final CastResult iching;
  final MeihuaCast meihua;
  final String question;
  final bool review;
  final String? solarCity;

  @override
  State<CrossReadingPage> createState() => _CrossReadingPageState();
}

class _Data {
  _Data(this.cc, this.mc, this.result, this.focus, this.texts);

  final CrossContent cc;
  final MeihuaContent? mc;
  final CrossResult result;
  final FocusResult focus;

  /// 本次重點各段的文字（使用者語言）。
  final List<String> texts;
}

/// 阿拉伯文、印尼文不顯示應期（2026-11-01 文化審查：避免「何時發生」的預測）。
bool get crossShowsTiming => !const {'ar', 'id'}.contains(L10n.language.contentFolder);

class _CrossReadingPageState extends State<CrossReadingPage> {
  late final Services _services = AppServices.of(context);
  late final Future<_Data?> _data = _load();
  bool _saved = false;

  Future<_Data?> _load() async {
    final folder = L10n.language.contentFolder;
    final cc = await crossSource.load(folder);
    if (cc == null) return null;
    final mc = await meihuaSource.load(folder);
    final table = await crossSource.trendTable();
    final focus = _services.focusRule.focus(widget.iching);
    final result = CrossResult(
      UnifiedReading.iching(widget.iching, table, rule: _services.focusRule),
      UnifiedReading.meihua(widget.meihua),
    );
    final texts = <String>[];
    for (final item in focus.items) {
      final HexagramContent? h = await _services.content.hexagram(item.hexagram);
      if (h == null) continue;
      final t = item.kind == FocusKind.judgment
          ? h.judgment
          : h.lines.where((x) => x.position == item.position).map((x) => x.text).firstOrNull ?? '';
      if (t.isNotEmpty) texts.add(t);
    }
    return _Data(cc, mc, result, focus, texts);
  }

  @override
  void initState() {
    super.initState();
    if (widget.review) return;
    _events = _services.events; // 先取好，dispose 時不能再查 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _services.events.emit(ReadingShown(
        methodId: 'cross',
        primary: widget.iching.primary,
        changed: widget.iching.changed,
      ));
    });
  }

  CrossRecord get _record => CrossRecord(
        meihuaLines: [for (final l in widget.meihua.toCastResult().lines) l.value],
        monthBranch: widget.meihua.monthBranch,
      );

  Future<void> _save() async {
    final entry = await showSaveReadingSheet(
      context,
      cast: CastResult(methodId: 'cross', lines: widget.iching.lines),
      question: widget.question,
      readingIndex: null,
      cross: _record,
    );
    if (entry == null) return;
    _services.events.emit(JournalSaved(hasReminder: entry.reminderAt != null));
    if (mounted) setState(() => _saved = true);
  }

  EventBus? _events; // 只有不是回看時才有：離開時通知評分邀請

  @override
  void dispose() {
    _events?.emit(const ReadingFinished());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.featureCross), actions: [
        IconButton(
          onPressed: () => showCrossGuide(context),
          icon: const Icon(Icons.info_outline),
          tooltip: l.featureCross,
        ),
      ]),
      body: FutureBuilder<_Data?>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final d = snap.data;
          if (d == null) return Center(child: Text(l.learnMissing));
          return ValueListenableBuilder<bool>(
            valueListenable: _services.premium.isPremium,
            builder: (context, premium, _) => ListView(
              padding: readablePadding(context, top: 8, bottom: 40),
              children: [
                if (widget.question.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(l.questionShown(widget.question),
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                _Glyphs(iching: widget.iching, meihua: widget.meihua, cc: d.cc),
                const SizedBox(height: 20),
                _VerdictTitle(cc: d.cc, verdict: d.result.verdict),
                if (premium) ..._full(context, d) else ..._locked(context, d.cc),
                const SizedBox(height: 28),
                if (widget.solarCity != null && premium) ...[
                  Text(l.meihuaSolarOn(widget.solarCity!),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: QianColors.textSub)),
                  const SizedBox(height: 8),
                ],
                Text(d.cc.s('disclaimer'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: QianColors.textSub)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _locked(BuildContext context, CrossContent cc) => [
        const SizedBox(height: 16),
        Text(cc.s('preview'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: () => openPaywall(context, source: 'cross'),
            child: Text(cc.s('unlock')),
          ),
        ),
      ];

  List<Widget> _full(BuildContext context, _Data d) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final cc = d.cc;
    final mc = d.mc;
    final r = d.result;
    String level(TrendLevel x) => mc?.fill('level', const {}, sub: x.name) ?? x.name;
    String timing(TimingWindow x) => mc?.fill('timing', const {}, sub: x.name) ?? x.name;
    String tags(List<String> keys) => keys.map(cc.tag).where((x) => x.isNotEmpty).join(l.separator);
    final seed = CrossResult.seedOf(widget.iching.primary, widget.meihua.primary);
    final actions = cc.actions(r.comboKey);
    final questions = cc.questions(r.comboKey);
    final primary = HexagramTable.byNumber(widget.iching.primary);
    final meihuaPrimary = HexagramTable.byNumber(widget.meihua.primary);

    return [
      const SizedBox(height: 12),
      Text(cc.s('verdictDesc', r.verdict.name, {'iching': level(r.iching.level), 'meihua': level(r.meihua.level)})),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _SideCard(title: cc.s('source', 'iching'), level: r.iching.level, levelText: level(r.iching.level),
            timingText: crossShowsTiming ? timing(r.iching.timing) : null, cc: cc)),
        const SizedBox(width: 12),
        Expanded(child: _SideCard(title: cc.s('source', 'meihua'), level: r.meihua.level, levelText: level(r.meihua.level),
            timingText: crossShowsTiming ? timing(r.meihua.timing) : null, cc: cc)),
      ]),
      Section(
        title: cc.s('headings', 'tags'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.sharedTags.isNotEmpty
              ? cc.s('sharedTags', null, {'tags': tags(r.sharedTags)})
              : cc.s('noSharedTags', null, {'iching': tags(r.iching.tags), 'meihua': tags(r.meihua.tags)})),
          if (crossShowsTiming) ...[
            const SizedBox(height: 8),
            Text(r.timingOverlap
                ? cc.s('timingOverlap', null, {'timing': timing(r.iching.timing)})
                : cc.s('timingApart', null, {'iching': timing(r.iching.timing), 'meihua': timing(r.meihua.timing)})),
          ],
        ]),
      ),
      Section(
        title: cc.s('headings', 'meihua'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cc.angle('meihua', r.meihua.direction)),
          const SizedBox(height: 8),
          Text(l.meihuaTiYong(l.trigramLabel(widget.meihua.ti), l.trigramLabel(widget.meihua.yong)),
              style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          const SizedBox(height: 8),
          Text(cc.s('turning', null, {
            'mutual': l.hexName(HexagramTable.byNumber(widget.meihua.mutual)),
            'changed': l.hexName(HexagramTable.byNumber(widget.meihua.changed)),
          })),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => MeihuaReadingPage(cast: widget.meihua, question: widget.question, review: true),
            )),
            child: Text(l.meihuaFullReading(l.hexName(meihuaPrimary))),
          ),
        ]),
      ),
      Section(
        title: cc.s('headings', 'iching'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cc.angle('iching', r.iching.direction)),
          const SizedBox(height: 8),
          Text(widget.iching.changed == null
              ? cc.s('processStatic', null, {'primary': l.hexName(primary)})
              : cc.s('process', null, {
                  'primary': l.hexName(primary),
                  'changed': l.hexName(HexagramTable.byNumber(widget.iching.changed!)),
                })),
          for (final x in d.texts) ...[
            const SizedBox(height: 8),
            Text(x, style: t.bodyMedium?.copyWith(color: QianColors.rice)),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ReadingPage(cast: widget.iching, question: widget.question, review: true),
            )),
            child: Text(l.meihuaFullReading(l.hexName(primary))),
          ),
        ]),
      ),
      if (actions.isNotEmpty || questions.isNotEmpty)
        Section(
          title: cc.s('headings', 'plan'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (actions.isNotEmpty) ...[
              Text(cc.s('headings', 'action'), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
              const SizedBox(height: 4),
              Text(CrossResult.pick(actions, seed)),
            ],
            if (questions.isNotEmpty) ...[
              if (actions.isNotEmpty) const SizedBox(height: 12),
              Text(cc.s('headings', 'question'), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
              const SizedBox(height: 4),
              Text(CrossResult.pick(questions, seed)),
            ],
          ]),
        ),
      if (!widget.review && _services.journal != null && _services.flags.featureEnabled('journal')) ...[
        const SizedBox(height: 32),
        Center(
          child: _saved
              ? Text(l.savedToJournalHint, style: t.bodySmall)
              : FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(l.saveThisReading),
                ),
        ),
      ],
    ];
  }
}

Color _levelColor(TrendLevel level) => switch (level) {
      TrendLevel.great || TrendLevel.good => QianColors.rice,
      TrendLevel.even => QianColors.text,
      TrendLevel.minorBlock || TrendLevel.block => QianColors.mountain,
    };

class _VerdictTitle extends StatelessWidget {
  const _VerdictTitle({required this.cc, required this.verdict});

  final CrossContent cc;
  final CrossVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Text(cc.s('headings', 'verdict'), style: t.bodySmall?.copyWith(color: QianColors.textSub)),
      const SizedBox(height: 4),
      Text(cc.s('verdict', verdict.name),
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(
            color: verdict == CrossVerdict.consensus ? QianColors.rice : QianColors.text,
            fontWeight: FontWeight.w600,
          )),
    ]);
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({required this.title, required this.level, required this.levelText, required this.timingText, required this.cc});

  final String title;
  final TrendLevel level;
  final String levelText;
  final String? timingText;
  final CrossContent cc;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = _levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Column(children: [
        Text(title, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
        const SizedBox(height: 4),
        Text(levelText, textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        if (timingText != null) ...[
          const SizedBox(height: 4),
          Text('${cc.s('timingLabel')} $timingText', textAlign: TextAlign.center, style: t.bodySmall),
        ],
      ]),
    );
  }
}

class _Glyphs extends StatelessWidget {
  const _Glyphs({required this.iching, required this.meihua, required this.cc});

  final CastResult iching;
  final MeihuaCast meihua;
  final CrossContent cc;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    Widget one(String label, int n, Set<int> changing) {
      final h = HexagramTable.byNumber(n);
      return Expanded(
        child: Column(children: [
          Text(label, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
          const SizedBox(height: 6),
          HexagramGlyph(lines: h.lines, changing: changing, width: 44),
          const SizedBox(height: 6),
          Text(l.hexFullName(h), textAlign: TextAlign.center, style: t.titleSmall),
        ]),
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      one(cc.s('source', 'iching'), iching.primary, iching.changingPositions.toSet()),
      one(cc.s('source', 'meihua'), meihua.primary, {meihua.movingLine}),
    ]);
  }
}
