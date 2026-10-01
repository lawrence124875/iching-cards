import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/iching/trigram.dart';

/// 牌背：先天八卦環（不用太極圖，HANDOFF §6.3）。
class CardBack extends StatelessWidget {
  const CardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QianColors.inkCard,
        border: Border.all(color: QianColors.earth, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: QianColors.mountain, width: 0.8)),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.78,
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(painter: _BaguaRingPainter()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BaguaRingPainter extends CustomPainter {
  // 先天八卦，南上北下、東左西右，從正上方順時針排列。
  static const _ring = [
    Trigram.qian, Trigram.xun, Trigram.kan, Trigram.gen,
    Trigram.kun, Trigram.zhen, Trigram.li, Trigram.dui,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final stroke = Paint()
      ..color = QianColors.mountain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(c, r * 0.98, stroke);
    canvas.drawCircle(c, r * 0.42, stroke);
    canvas.drawCircle(c, r * 0.05, Paint()..color = QianColors.earth);

    final bar = Paint()..color = QianColors.earth;
    final barH = r * 0.055;
    final gap = r * 0.11;
    final barW = r * 0.36;
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * pi / 4);
      final lines = _ring[i].lines; // 初爻在最內圈
      for (var k = 0; k < 3; k++) {
        final y = -(r * 0.55 + k * gap) - barH / 2;
        if (lines[k]) {
          canvas.drawRect(Rect.fromLTWH(-barW / 2, y, barW, barH), bar);
        } else {
          final seg = barW * 0.42;
          canvas.drawRect(Rect.fromLTWH(-barW / 2, y, seg, barH), bar);
          canvas.drawRect(Rect.fromLTWH(barW / 2 - seg, y, seg, barH), bar);
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BaguaRingPainter oldDelegate) => false;
}
