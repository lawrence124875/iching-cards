import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/guying/guying.dart';
import '../../l10n/l10n.dart';

/// 古圖縮圖：點一下開全螢幕檢視（右下角放大鏡提示可點）。
class GuyingThumb extends StatelessWidget {
  const GuyingThumb({super.key, required this.number, this.label});

  final int number;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => showGuying(context, number),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Image.asset(GuyingSource.imagePath(number),
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              PositionedDirectional(
                end: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.zoom_in, size: 20, color: QianColors.onImage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 開啟全螢幕古圖：完整顯示（contain），兩指縮放、拖曳，點兩下放大／還原，點一下或返回鍵關閉；底部保留出處。
Future<void> showGuying(BuildContext context, int number) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => GuyingViewer(number: number),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class GuyingViewer extends StatefulWidget {
  const GuyingViewer({super.key, required this.number});

  final int number;

  @override
  State<GuyingViewer> createState() => _GuyingViewerState();
}

class _GuyingViewerState extends State<GuyingViewer> {
  final _zoom = TransformationController();
  Offset _tapAt = Offset.zero;
  bool _hint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _zoom.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// 點兩下：未放大時以點的位置為中心放大 2.5 倍，已放大時還原。
  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
    } else {
      const s = 2.5;
      _zoom.value = Matrix4.diagonal3Values(s, s, 1)
        ..setTranslationRaw(-_tapAt.dx * (s - 1), -_tapAt.dy * (s - 1), 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    const shadow = [Shadow(blurRadius: 6, color: Colors.black)];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        onDoubleTapDown: (d) => _tapAt = d.localPosition,
        onDoubleTap: _toggleZoom,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              transformationController: _zoom,
              minScale: 1,
              maxScale: 6,
              child: SizedBox.expand(
                child: Image.asset(GuyingSource.imagePath(widget.number),
                    fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: _hint ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      child: Text(l.tapToReturn,
                          textAlign: TextAlign.center,
                          style: t.bodySmall?.copyWith(color: QianColors.onImage, shadows: shadow)),
                    ),
                    const SizedBox(height: 8),
                    Text(l.guyingCredit,
                        textAlign: TextAlign.center,
                        style: t.labelSmall?.copyWith(
                            color: QianColors.onImage.withValues(alpha: 0.75), shadows: shadow)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
