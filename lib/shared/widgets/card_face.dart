import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../l10n/l10n.dart';
import 'card_art_viewer.dart';
import 'hexagram_glyph.dart';

/// 有框版牌面（HANDOFF §6.3）：風景照置於框內，四周放卦序、卦象、卦名、拼音、卦義與上下經卦（術語表，§17）。
/// 多語系：牌面中央的大字卦名屬於牌面設計，各語言都保留漢字；卦序與上下經卦依介面語言（HANDOFF §16）。
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.info, this.zoomable = false});

  final HexagramInfo info;

  /// 為 true 時，點風景圖會開啟滿版看圖（右下角顯示放大提示）。
  final bool zoomable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QianColors.inkCard,
        border: Border.all(color: QianColors.earth, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(l.cardNumber(info.number),
                    style: t.bodySmall?.copyWith(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, letterSpacing: tracking(2))),
                const Spacer(),
                HexagramGlyph(lines: info.lines, width: 20),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: QianColors.mountain, width: 0.8)),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: zoomable ? _ZoomableArt(info: info) : _Art(info: info),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(info.name, textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontSize: 28)),
            Text(l.cardSubtitle(info),
                textAlign: TextAlign.center, style: t.bodySmall),
            const SizedBox(height: 2),
            Text(
                l.cardTrigrams(l.trigramLabel(info.upper), l.trigramImage(info.upper), l.trigramLabel(info.lower),
                    l.trigramImage(info.lower)),
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(fontFamily: kSerif, fontFamilyFallback: kSerifFallback, color: QianColors.mountain)),
          ],
        ),
      ),
    );
  }
}

class _ZoomableArt extends StatelessWidget {
  const _ZoomableArt({required this.info});

  final HexagramInfo info;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.cardZoomLabel(context.l10n.hexName(info)),
      child: GestureDetector(
        onTap: () => showCardArt(context, info),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Art(info: info),
            const PositionedDirectional(
              end: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.open_in_full, size: 15, color: QianColors.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.info});

  final HexagramInfo info;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
      future: AppServices.of(context).content.cardArt(info.number),
      builder: (context, snap) {
        final img = snap.data;
        if (img == null) return _Placeholder(info: info, loading: !snap.hasData && !snap.hasError);
        return Image(
          image: img,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(info: info, loading: false),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.info, required this.loading});

  final HexagramInfo info;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF22212B), Color(0xFF3A3226)],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? null
          : Text(info.symbol,
              style: const TextStyle(fontSize: 96, color: QianColors.mountain, height: 1)),
    );
  }
}
