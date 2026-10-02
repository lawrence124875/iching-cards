import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../core/content/hexagram_content.dart';
import '../core/iching/hexagram_table.dart';
import '../shared/widgets/hexagram_glyph.dart';
import 'section.dart';

/// 詳細頁：卦辭、彖傳、大象傳與各爻（含用九／用六）。highlight 為本次重點爻位。
class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.number, this.highlight = const {}});

  final int number;
  final Set<int> highlight;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final Future<HexagramContent?> _content =
      AppServices.of(context).content.hexagram(widget.number);

  @override
  Widget build(BuildContext context) {
    final info = HexagramTable.byNumber(widget.number);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(info.fullName)),
      body: FutureBuilder<HexagramContent?>(
        future: _content,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snap.data;
          return ListView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 40 + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              Center(child: HexagramGlyph(lines: info.lines, width: 64)),
              const SizedBox(height: 12),
              Text('${info.symbol}  ${info.fullName}',
                  textAlign: TextAlign.center, style: t.headlineSmall),
              if (c == null)
                const Section(title: '經文', child: Text('這一卦的內容撰寫中。'))
              else ...[
                Section(
                  title: '卦辭',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.judgment, style: t.bodyLarge),
                      const SizedBox(height: 10),
                      Text(c.tuan, style: t.bodyLarge?.copyWith(fontSize: 15.5)),
                      const SizedBox(height: 10),
                      Text(c.daxiang, style: t.bodyLarge?.copyWith(fontSize: 15.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final line in c.lines)
                  _LineTile(line: line, highlighted: widget.highlight.contains(line.position)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.highlighted});

  final LineContent line;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: QianColors.inkCard,
        border: Border(
          left: BorderSide(color: highlighted ? QianColors.rice : QianColors.mountain, width: highlighted ? 3 : 1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: highlighted,
          iconColor: QianColors.earth,
          collapsedIconColor: QianColors.mountain,
          title: Text(line.text, style: t.bodyLarge?.copyWith(fontSize: 16)),
          subtitle: Text([line.stage, if (highlighted) '本次重點'].where((s) => s.isNotEmpty).join('・'),
              style: t.bodySmall),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (line.xiaoxiang.isNotEmpty) Text(line.xiaoxiang, style: t.bodySmall?.copyWith(fontFamily: kSerif)),
            Section(title: '象的畫面', child: Text(line.image)),
            Section(title: '象從哪裡來', child: Text(line.source)),
            Section(title: '給現在的你', child: Text(line.forYou)),
          ],
        ),
      ),
    );
  }
}
