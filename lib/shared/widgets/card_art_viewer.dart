import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';

/// 開啟滿版牌面圖，讓使用者專心看象。[overlay] 會疊在畫面下方（例如呼吸練習的小呼吸圓），不攔截點擊。
Future<void> showCardArt(BuildContext context, HexagramInfo info, {Widget? overlay}) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => CardArtViewer(info: info, overlay: overlay),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  ));
}

/// 滿版看圖：預設填滿螢幕（BoxFit.cover）；點兩下切換「完整畫面」（contain）；
/// 兩指可縮放；點一下返回。進入時隱藏系統列，離開時恢復。
class CardArtViewer extends StatefulWidget {
  const CardArtViewer({super.key, required this.info, this.overlay});

  final HexagramInfo info;
  final Widget? overlay;

  @override
  State<CardArtViewer> createState() => _CardArtViewerState();
}

class _CardArtViewerState extends State<CardArtViewer> {
  late final Future<ImageProvider?> _art = AppServices.of(context).content.cardArt(widget.info.number);
  final _zoom = TransformationController();
  bool _fill = true;
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

  void _toggleFit() => setState(() {
        _fill = !_fill;
        _zoom.value = Matrix4.identity();
      });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Semantics(
        label: '${widget.info.name}卦牌面圖，點一下返回',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          onDoubleTap: _toggleFit,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<ImageProvider?>(
                future: _art,
                builder: (context, snap) {
                  final img = snap.data;
                  if (img == null) {
                    return snap.connectionState == ConnectionState.done
                        ? Center(
                            child: Text(widget.info.symbol,
                                style: const TextStyle(fontSize: 160, color: QianColors.mountain)))
                        : const SizedBox.shrink();
                  }
                  return InteractiveViewer(
                    transformationController: _zoom,
                    minScale: 1,
                    maxScale: 4,
                    child: SizedBox.expand(
                      child: Image(image: img, fit: _fill ? BoxFit.cover : BoxFit.contain),
                    ),
                  );
                },
              ),
              if (widget.overlay != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 88,
                  child: IgnorePointer(child: Center(child: widget.overlay)),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _hint ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    // 只留「點一下返回」（點兩下切換完整畫面仍可用，不另提示）
                    child: Text('點一下返回',
                        textAlign: TextAlign.center,
                        style: t.bodySmall?.copyWith(
                          color: QianColors.text,
                          shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                        )),
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
