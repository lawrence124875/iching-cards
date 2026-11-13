import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/guying/guying.dart';
import '../../l10n/l10n.dart';
import '../../reading/section.dart';
import 'guying_about_page.dart';

/// 解讀頁與卦庫詳解的「古圖」區塊：設定裡打開「顯示古圖」才出現（預設關閉）。
class GuyingSection extends StatelessWidget {
  const GuyingSection({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final pref = AppServices.of(context).guying;
    return ValueListenableBuilder<bool>(
      valueListenable: pref.enabled,
      builder: (context, on, _) => on ? _GuyingBody(number: number) : const SizedBox.shrink(),
    );
  }
}

class _GuyingBody extends StatefulWidget {
  const _GuyingBody({required this.number});
  final int number;

  @override
  State<_GuyingBody> createState() => _GuyingBodyState();
}

class _GuyingBodyState extends State<_GuyingBody> {
  late final Future<(GuyingContent?, GuyingOriginal?)> _data = () async {
    final c = await guyingSource.load(L10n.contentFolder);
    final o = await guyingSource.original(widget.number);
    return (c, o);
  }();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return FutureBuilder<(GuyingContent?, GuyingOriginal?)>(
      future: _data,
      builder: (context, snap) {
        final item = snap.data?.$1?.items[widget.number];
        final orig = snap.data?.$2;
        if (item == null) return const SizedBox.shrink();
        final chinese = L10n.contentFolder.startsWith('zh');
        return Section(
          title: l.guyingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.asset(GuyingSource.imagePath(widget.number),
                      fit: BoxFit.fitWidth,
                      semanticLabel: item.title,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              ),
              const SizedBox(height: 6),
              Text(l.guyingCredit, style: t.bodySmall?.copyWith(color: QianColors.textSub)),
              const SizedBox(height: 12),
              Text(chinese && orig != null ? '${item.title}（${orig.ke}）' : item.title, style: t.titleSmall),
              const SizedBox(height: 6),
              Text(item.story),
              const SizedBox(height: 12),
              Text(l.guyingSymbols, style: t.titleSmall),
              const SizedBox(height: 4),
              for (final s in item.symbols)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('・${l.guyingSymbolLine(s.see, s.means)}'),
                ),
              const SizedBox(height: 12),
              Text(item.reading, style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              if (chinese && orig != null)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(l.guyingOriginal, style: t.bodyMedium?.copyWith(color: QianColors.textSub)),
                    children: [
                      Text('${orig.story}\n解曰：${orig.jie}\n${orig.ke}・${orig.xiang}',
                          style: t.bodySmall?.copyWith(
                              fontFamily: AppFonts.chinese.serif,
                              fontFamilyFallback: AppFonts.chinese.serifFallback,
                              color: QianColors.textSub)),
                    ],
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(l.guyingAbout),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const GuyingAboutPage())),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
