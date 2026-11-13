import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../l10n/l10n.dart';
import '../../reading/detail_page.dart';
import '../../shared/premium/ad_banner.dart';
import '../../shared/widgets/adaptive_layout.dart';
import '../../shared/widgets/hexagram_glyph.dart';

/// 六十四卦卦庫（0.9.0，參考塔羅 App 的牌庫）：依卦序排列，點一卦看完整卦辭、爻辭與解讀（不上鎖）。
class HexagramLibraryPage extends StatelessWidget {
  const HexagramLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.libraryTitle)),
      bottomNavigationBar: const AdBanner(),
      body: GridView.builder(
        padding: readablePadding(context, horizontal: 12, top: 8, bottom: 32),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
        ),
        itemCount: 64,
        itemBuilder: (context, i) {
          final info = HexagramTable.byNumber(i + 1);
          return Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => DetailPage(number: info.number),
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  HexagramGlyph(lines: info.lines, width: 36),
                  const SizedBox(height: 8),
                  Text(l.hexName(info),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                  Text('${info.number}', style: t.bodySmall?.copyWith(color: QianColors.textSub)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
