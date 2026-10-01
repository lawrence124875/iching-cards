import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../core/content/hexagram_content.dart';
import '../core/events/event_bus.dart';
import '../core/iching/cast_result.dart';
import '../core/iching/focus_rule.dart';
import '../core/iching/hexagram_table.dart';
import '../shared/widgets/card_face.dart';
import '../shared/widgets/hexagram_glyph.dart';
import 'detail_page.dart';
import 'section.dart';

/// 解讀頁：牌面 →（擲錢時）本次重點 → 隨機一組解讀 → 東西相映 → 小行動與提問。
class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key, required this.cast});

  final CastResult cast;

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
  late final int _readingSeed = _services.random.nextInt(1 << 30);

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      appBar: AppBar(title: Text(primary.fullName)),
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
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
                const Section(title: '解讀', child: Text('這一卦的解讀還在撰寫中。可以先看看牌面的景象，想想它讓你聯想到什麼。'))
              else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(reading.title,
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                ),
                Section(title: '象的畫面', child: Text(reading.image, style: Theme.of(context).textTheme.bodyLarge)),
                Section(title: '象從哪裡來', child: Text(reading.source)),
                Section(title: '給現在的你', child: Text(reading.forYou)),
                if (pc?.eastWest != null) _EastWest(ew: pc!.eastWest!),
                Section(title: '今日小行動', child: Text(reading.action)),
                Section(title: '反思提問', child: Text(reading.question)),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => _openDetail(context, cast.primary, cast.primary == _focusHexagram ? _focusLines : const {}),
                child: Text('${primary.name}卦的經文與六爻'),
              ),
              if (changed != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _openDetail(context, changed.number, changed.number == _focusHexagram ? _focusLines : const {}),
                  child: Text('之卦：${changed.name}卦的經文與六爻'),
                ),
              ],
            ],
          );
        },
      ),
    );
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
    final p = HexagramTable.byNumber(cast.primary);
    Widget side(String label, HexagramInfo info, Set<int> changing) => Column(
          children: [
            Text(label, style: t.bodySmall),
            const SizedBox(height: 6),
            HexagramGlyph(lines: info.lines, changing: changing, width: 40),
            const SizedBox(height: 6),
            Text(info.name, style: t.titleMedium),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        side('本卦', p, cast.changingPositions.toSet()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Icon(Icons.east, color: QianColors.mountain),
        ),
        side('之卦', changed, const {}),
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
    return Section(
      title: '本次重點',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(focus.explanation, style: t.bodySmall),
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
    final info = HexagramTable.byNumber(item.hexagram);
    final c = content;
    String text;
    String sub = '';
    if (c == null) {
      text = '${info.name}卦的內容撰寫中。';
    } else if (item.kind == FocusKind.judgment) {
      text = c.judgment;
    } else {
      final line = c.line(item.position!);
      text = line?.text ?? '${info.name}卦這一爻的內容撰寫中。';
      sub = line?.forYou ?? '';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: item.primary ? QianColors.rice : QianColors.mountain, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: t.bodyLarge),
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
    return Section(
      title: '東西相映',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ew.hasQuote) ...[
            Text('「${ew.quoteText}」', style: t.bodyLarge),
            const SizedBox(height: 4),
            Text('${ew.quoteAuthor}，${ew.quoteSource}', style: t.bodySmall),
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
