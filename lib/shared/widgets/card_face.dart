import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import 'card_art_viewer.dart';
import 'hexagram_glyph.dart';

const _numerals = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

/// 卦序的中文數字（1–64）。
String chineseOrdinal(int n) {
  if (n < 10) return _numerals[n];
  final tens = n ~/ 10, ones = n % 10;
  return '${tens == 1 ? '' : _numerals[tens]}十${_numerals[ones]}';
}

/// 有框版牌面（HANDOFF §6.3）：風景照置於框內，四周放卦序、卦象、卦名、拼音、英文卦義與上下經卦。
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.info, this.zoomable = false});

  final HexagramInfo info;

  /// 為 true 時，點風景圖會開啟滿版看圖（右下角顯示放大提示）。
  final bool zoomable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
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
                Text('第${chineseOrdinal(info.number)}卦',
                    style: t.bodySmall?.copyWith(fontFamily: kSerif, letterSpacing: 2)),
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
            Text('${info.pinyin}  ·  ${info.english}',
                textAlign: TextAlign.center, style: t.bodySmall),
            const SizedBox(height: 2),
            Text('上${info.upper.label}${info.upper.nature}　下${info.lower.label}${info.lower.nature}',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(fontFamily: kSerif, color: QianColors.mountain)),
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
      label: '放大看${info.name}卦牌面圖',
      child: GestureDetector(
        onTap: () => showCardArt(context, info),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Art(info: info),
            const Positioned(
              right: 6,
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
