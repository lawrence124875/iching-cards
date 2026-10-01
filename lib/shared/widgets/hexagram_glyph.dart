import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 畫六爻（由下而上）。changing 為變爻位置（1–6），以稻金色並加圓點標示。
class HexagramGlyph extends StatelessWidget {
  const HexagramGlyph({
    super.key,
    required this.lines,
    this.changing = const {},
    this.width = 48,
    this.color = QianColors.earth,
    this.visibleCount = 6,
  });

  final List<bool> lines;
  final Set<int> changing;
  final double width;
  final Color color;

  /// 擲錢時逐爻顯示：只畫最下面的幾爻。
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final changeNote = changing.isEmpty ? '' : '，變爻：${changing.join('、')}';
    return Semantics(
      label: '卦象$changeNote',
      child: CustomPaint(
        size: Size(width * 1.25, width * 0.9),
        painter: _GlyphPainter(lines, changing, color, visibleCount),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.lines, this.changing, this.color, this.visibleCount);

  final List<bool> lines;
  final Set<int> changing;
  final Color color;
  final int visibleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 1.25;
    final step = size.height / 6;
    final barH = step * 0.55;
    for (var i = 0; i < 6; i++) {
      final y = size.height - (i + 1) * step + (step - barH) / 2;
      if (i >= visibleCount) {
        final ghost = Paint()
          ..color = color.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTWH(0, y, w, barH), ghost);
        continue;
      }
      final isChanging = changing.contains(i + 1);
      final paint = Paint()..color = isChanging ? QianColors.rice : color;
      if (lines[i]) {
        canvas.drawRect(Rect.fromLTWH(0, y, w, barH), paint);
      } else {
        final seg = w * 0.42;
        canvas.drawRect(Rect.fromLTWH(0, y, seg, barH), paint);
        canvas.drawRect(Rect.fromLTWH(w - seg, y, seg, barH), paint);
      }
      if (isChanging) {
        canvas.drawCircle(Offset(w + size.width * 0.1, y + barH / 2), barH * 0.35, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.lines != lines || old.changing != changing || old.visibleCount != visibleCount || old.color != color;
}
