import 'package:flutter/material.dart';

import '../app/feature_registry.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../core/content/hexagram_content.dart';
import '../core/events/event_bus.dart';
import '../core/iching/cast_result.dart';
import '../core/iching/focus_rule.dart';
import '../core/iching/hexagram_table.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/card_face.dart';
import '../shared/widgets/hexagram_glyph.dart';
import 'detail_page.dart';
import '../shared/premium/paywall_page.dart';
import 'save_reading_sheet.dart';
import 'scripture.dart';
import 'section.dart';

/// 解讀頁：牌面 →（擲錢時）本次重點 → 隨機一組解讀 → 東西相映 → 小行動與提問 →（記下這一卦）。
/// [review] 為 true 時是從卦記回看：顯示當時那一組解讀（[readingIndex]），不發事件、不顯示儲存。
class ReadingPage extends StatefulWidget {
  const ReadingPage({
    super.key,
    required this.cast,
    this.question = '',
    this.readingIndex,
    this.review = false,
  });

  final CastResult cast;
  final String question;
  final int? readingIndex;
  final bool review;

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late final Services _services = AppServices.of(context);
  late final Future<List<HexagramContent?>> _content = Future.wait([
    _services.content.hexagram(widget.cast.primary),
    if (widget.cast.changed != null) _services.content.hexagram(widget.cast.changed!),
  ]);
  late final FocusResult _focus = _services.focusRule.focus(widget.cast);
  late final int _readingSeed = widget.readingIndex ?? _services.random.nextInt(1 << 30);
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.review) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _services.events.emit(ReadingShown(
        methodId: widget.cast.methodId,
        primary: widget.cast.primary,
        changed: widget.cast.changed,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cast = widget.cast;
    final primary = HexagramTable.byNumber(cast.primary);
    final changed = cast.changed == null ? null : HexagramTable.byNumber(cast.changed!);
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.hexFullName(primary))),
      body: FutureBuilder<List<HexagramContent?>>(
        future: _content,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final pc = snap.data![0];
          final cc = snap.data!.length > 1 ? snap.data![1] : null;
          final reading = (pc == null || pc.readings.isEmpty)
              ? null
              : pc.readings[_readingSeed % pc.readings.length];

          return ListView(
            // 底部加上系統導覽列高度，最後的按鈕不會被擋住
            padding: EdgeInsets.fromLTRB(24, 8, 24, 40 + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              if (widget.question.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(l.questionShown(widget.question),
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                ),
              Center(
                child: SizedBox(
                  width: 240,
                  child: AspectRatio(aspectRatio: 0.62, child: CardFace(info: primary, zoomable: true)),
                ),
              ),
              if (changed != null) ...[
                const SizedBox(height: 20),
                _ChangeRow(cast: cast, changed: changed),
              ],
              if (cast.methodId != 'simple') ...[
                const SizedBox(height: 8),
                _FocusBlock(
                  focus: _focus,
                  contentOf: (n) => n == cast.primary ? pc : (n == cast.changed ? cc : null),
                ),
              ],
              const SizedBox(height: 8),
              if (reading == null)
                Section(title: l.sectionReading, child: Text(l.readingNotWritten))
              else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(reading.title,
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                ),
                Section(title: l.sectionImage, child: Text(reading.image, style: Theme.of(context).textTheme.bodyLarge)),
                Section(title: l.sectionSource, child: Text(reading.source)),
                Section(title: l.sectionForYou, child: Text(reading.forYou)),
                if (pc?.eastWest != null) _EastWest(ew: pc!.eastWest!),
                Section(title: l.sectionAction, child: Text(reading.action)),
                Section(title: l.sectionQuestion, child: Text(reading.question)),
              ],
              for (final action in activeFeatures(_services.flags).map((f) => f.readingAction).whereType<ReadingAction>())
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => action.open(context, cast.primary),
                      icon: Icon(action.icon),
                      label: Text(action.label(l)),
                    ),
                  ),
                ),
              if (!widget.review && _services.journal != null && _services.flags.featureEnabled('journal')) ...[
                const SizedBox(height: 32),
                Center(
                  child: _saved
                      ? Text(l.savedToJournalHint, style: Theme.of(context).textTheme.bodySmall)
                      : FilledButton.icon(
                          onPressed: () => _save(pc),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text(l.saveThisReading),
                        ),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => _openDetail(context, cast.primary, cast.primary == _focusHexagram ? _focusLines : const {}),
                child: Text(l.detailButton(l.hexName(primary))),
              ),
              if (changed != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _openDetail(context, changed.number, changed.number == _focusHexagram ? _focusLines : const {}),
                  child: Text(l.detailButtonChanged(l.hexName(changed))),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(HexagramContent? pc) async {
    // 免費版卦記上限（§23）：已存的不刪，只是不能再新增
    final journal = _services.journal;
    if (!_services.isPremium && journal != null && (await journal.all()).length >= _services.limits.journalMax) {
      // 會員、或看完獎勵廣告換「存這一則」才繼續（每次一則，不累積額度）
      if (!mounted || !await _journalLimit()) return;
      if (!mounted) return;
    }
    final index = (pc == null || pc.readings.isEmpty) ? null : _readingSeed % pc.readings.length;
    final entry = await showSaveReadingSheet(
      context,
      cast: widget.cast,
      question: widget.question,
      readingIndex: index,
    );
    if (entry == null) return;
    _services.events.emit(JournalSaved(hasReminder: entry.reminderAt != null));
    if (mounted) setState(() => _saved = true);
  }

  /// 顯示卦記上限說明。成為會員、或看完獎勵廣告（只換存這一則）回傳 true。
  Future<bool> _journalLimit() async {
    final l = context.l10n;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.journalLimitTitle(_services.limits.journalMax)),
        content: Text(l.journalLimitBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.notNow)),
          TextButton(onPressed: () => Navigator.pop(ctx, 'watch'), child: Text(l.journalWatchAd)),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'premium'), child: Text(l.menuPremium)),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'premium') return openPaywall(context, source: 'journal_limit');
    if (choice != 'watch') return false;
    final ready = await _services.ads.prepareRewarded();
    if (!mounted) return false;
    if (!ready || !await _services.ads.showRewarded()) {
      if (mounted && !ready) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.castAdNotReady)));
      }
      return false;
    }
    _services.events.emit(const RewardedEarned(source: 'journal'));
    return true;
  }

  int? get _focusHexagram {
    final lineItems = _focus.items.where((i) => i.kind == FocusKind.line);
    return lineItems.isEmpty ? null : lineItems.first.hexagram;
  }

  Set<int> get _focusLines => {
        for (final i in _focus.items)
          if (i.kind == FocusKind.line) i.position!,
      };

  void _openDetail(BuildContext context, int number, Set<int> highlight) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DetailPage(number: number, highlight: highlight),
    ));
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.cast, required this.changed});

  final CastResult cast;
  final HexagramInfo changed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final p = HexagramTable.byNumber(cast.primary);
    Widget side(String label, HexagramInfo info, Set<int> changing) => Column(
          children: [
            Text(label, style: t.bodySmall),
            const SizedBox(height: 6),
            HexagramGlyph(lines: info.lines, changing: changing, width: 40),
            const SizedBox(height: 6),
            Text(l.hexName(info), style: t.titleMedium),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        side(l.primaryHexagram, p, cast.changingPositions.toSet()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Icon(Icons.east, color: QianColors.mountain),
        ),
        side(l.changedHexagram, changed, const {}),
      ],
    );
  }
}

class _FocusBlock extends StatelessWidget {
  const _FocusBlock({required this.focus, required this.contentOf});

  final FocusResult focus;
  final HexagramContent? Function(int) contentOf;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Section(
      title: l.sectionFocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.focusText(focus.reason), style: t.bodySmall),
          for (final item in focus.items) ...[
            const SizedBox(height: 12),
            _FocusText(item: item, content: contentOf(item.hexagram)),
          ],
        ],
      ),
    );
  }
}

class _FocusText extends StatelessWidget {
  const _FocusText({required this.item, required this.content});

  final FocusItem item;
  final HexagramContent? content;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final info = HexagramTable.byNumber(item.hexagram);
    final c = content;
    String text;
    String original = '';
    String sub = '';
    if (c == null) {
      text = l.contentInProgress(l.hexName(info));
    } else if (item.kind == FocusKind.judgment) {
      text = c.judgment;
      original = c.original?.judgment ?? '';
    } else {
      final line = c.line(item.position!);
      // 傳統爻名（§17）：中文爻辭本身含爻名；譯文不含時補上（§22）。
      text = line == null
          ? l.lineInProgress(l.hexName(info))
          : l.lineHeading(info, line.position, line.text, contentName: line.name);
      original = c.original?.line(item.position!)?.text ?? '';
      sub = line?.forYou ?? '';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(start: 12),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: item.primary ? QianColors.rice : QianColors.mountain, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Scripture(text: text, original: original, style: t.bodyLarge),
          if (sub.isNotEmpty) ...[const SizedBox(height: 6), Text(sub)],
        ],
      ),
    );
  }
}

class _EastWest extends StatelessWidget {
  const _EastWest({required this.ew});

  final EastWestContent ew;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return Section(
      title: l.sectionEastWest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ew.hasQuote) ...[
            Text(l.quoteMarks(ew.quoteText), style: t.bodyLarge),
            const SizedBox(height: 4),
            Text(l.quoteAttribution(ew.quoteAuthor, ew.quoteSource), style: t.bodySmall),
            if (ew.quoteTranslationNote.isNotEmpty) Text(ew.quoteTranslationNote, style: t.bodySmall),
            const SizedBox(height: 8),
            Text(ew.quoteNote),
          ],
          if (ew.hasQuote && ew.hasPsychology) const SizedBox(height: 20),
          if (ew.hasPsychology) ...[
            Text(ew.psyName, style: t.titleMedium),
            Text(ew.psyOrigin, style: t.bodySmall),
            const SizedBox(height: 8),
            Text(ew.psyNote),
            if (ew.psyEvidence.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(ew.psyEvidence, style: t.bodySmall),
            ],
          ],
        ],
      ),
    );
  }
}
