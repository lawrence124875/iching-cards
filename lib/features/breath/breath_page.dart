import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_playback.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/soundscape/breath_timeline.dart';
import '../../core/soundscape/session_renderer.dart';
import '../../shared/format.dart';
import 'soundscape_labels.dart';

enum _Stage { preparing, failed, running, done }

/// 呼吸練習頁。畫面的時間一律取自音檔播放位置，與音景、鈴聲保持同步；
/// 音景無法播放時可改用無聲引導（改以碼錶計時）。
class BreathPage extends StatefulWidget {
  const BreathPage({super.key, required this.hexagram, required this.spec});

  final int hexagram;
  final SessionSpec spec;

  @override
  State<BreathPage> createState() => _BreathPageState();
}

class _BreathPageState extends State<BreathPage> with SingleTickerProviderStateMixin {
  BreathServices? _svc;
  bool _gotServices = false;
  late final SessionTimeline _tl = widget.spec.timeline;
  late final Ticker _ticker;
  final _clock = Stopwatch();

  AudioPlayback? _player;
  bool _silent = false;
  bool _paused = false;
  _Stage _stage = _Stage.preparing;
  double _now = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gotServices) return;
    _gotServices = true;
    _svc = AppServices.of(context).breath;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final svc = _svc;
    if (svc == null) {
      if (mounted) setState(() => _stage = _Stage.failed);
      return;
    }
    try {
      final path = await svc.files.prepare(widget.spec);
      if (!mounted) return;
      final p = svc.newPlayback();
      _player = p;
      await p.load(path);
      if (!mounted) return;
      _start();
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.failed);
    }
  }

  void _start() {
    setState(() => _stage = _Stage.running);
    _svc?.screenAwake.set(true);
    if (_silent) {
      _clock.start();
    } else {
      _player?.play();
    }
    if (!_ticker.isActive) _ticker.start();
  }

  void _startSilent() {
    _player?.dispose();
    _player = null;
    _silent = true;
    _start();
  }

  double get _position =>
      _silent || _player == null ? _clock.elapsedMilliseconds / 1000 : _player!.position.inMilliseconds / 1000;

  void _onTick(Duration _) {
    final now = _position;
    if (_tl.at(now).phase == BreathPhase.done) {
      // 音檔還會播完約 5 秒的淡出與結束鈴；畫面先顯示完成
      _ticker.stop();
      _svc?.screenAwake.set(false);
      setState(() {
        _now = now;
        _stage = _Stage.done;
      });
      return;
    }
    setState(() => _now = now);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      if (_silent) {
        _clock.stop();
      } else {
        _player?.pause();
      }
      _svc?.screenAwake.set(false);
    } else {
      if (_silent) {
        _clock.start();
      } else {
        _player?.play();
      }
      _svc?.screenAwake.set(true);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _player?.dispose();
    _svc?.screenAwake.set(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final info = HexagramTable.byNumber(widget.hexagram);
    final same = info.upper == info.lower;
    final sounds = same
        ? soundscapeName(info.upper)
        : '${soundscapeName(info.upper)}・${soundscapeName(info.lower)}';
    final state = _stage == _Stage.done ? const BreathState(BreathPhase.done, 1) : _tl.at(_now);

    return Scaffold(
      appBar: AppBar(title: Text(info.fullName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            children: [
              Text(sounds, style: t.bodySmall?.copyWith(letterSpacing: 2)),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: _BreathCirclePainter(
                        fullness: _stage == _Stage.running ? state.fullness : 0,
                        inhale: state.phase == BreathPhase.inhale,
                      ),
                      child: Center(child: _centre(t, state)),
                    ),
                  ),
                ),
              ),
              _bottom(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centre(TextTheme t, BreathState s) {
    switch (_stage) {
      case _Stage.preparing:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 16),
          Text('正在生成音景', style: t.bodyMedium),
          Text('第一次約需數秒', style: t.bodySmall),
        ]);
      case _Stage.failed:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text('這台手機暫時無法播放音景，\n可以改用無聲引導。', textAlign: TextAlign.center, style: t.bodyMedium),
        );
      case _Stage.done:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text('完成', style: t.headlineSmall),
          const SizedBox(height: 8),
          Text('${widget.spec.minutes} 分鐘・${widget.spec.minutes * 6} 次呼吸', style: t.bodySmall),
        ]);
      case _Stage.running:
        final label = switch (s.phase) {
          BreathPhase.prepare => '準備',
          BreathPhase.inhale => '吸',
          BreathPhase.exhale => '吐',
          BreathPhase.done => '完成',
        };
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: t.displaySmall?.copyWith(letterSpacing: 0)),
          const SizedBox(height: 4),
          Text('${math.max(1, s.secondsLeftInPhase.ceil())}', style: t.bodySmall),
        ]);
    }
  }

  Widget _bottom(TextTheme t) {
    switch (_stage) {
      case _Stage.preparing:
        return const SizedBox(height: 96);
      case _Stage.failed:
        return SizedBox(
          height: 96,
          child: Column(children: [
            FilledButton(onPressed: _startSilent, child: const Text('改用無聲引導')),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('返回')),
          ]),
        );
      case _Stage.done:
        return SizedBox(
          height: 96,
          child: Center(
            child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('回到解讀')),
          ),
        );
      case _Stage.running:
        final left = math.max(0.0, _tl.breathEnd - _now);
        return SizedBox(
          height: 96,
          child: Column(children: [
            Text('剩下 ${formatClock(left.ceil())}${_silent ? '・無聲' : ''}', style: t.bodySmall),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(onPressed: _togglePause, child: Text(_paused ? '繼續' : '暫停')),
              const SizedBox(width: 12),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('結束')),
            ]),
          ]),
        );
    }
  }
}

/// 呼吸圓：吸氣時漸漸擴大、吐氣時收回；內外兩條細線標出最小與最大。
class _BreathCirclePainter extends CustomPainter {
  _BreathCirclePainter({required this.fullness, required this.inhale});

  final double fullness;
  final bool inhale;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2 * 0.92;
    final minR = maxR * 0.42;
    final r = minR + (maxR - minR) * fullness;

    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = QianColors.mountain.withValues(alpha: 0.45);
    canvas.drawCircle(c, maxR, guide);
    canvas.drawCircle(c, minR, guide);

    final fill = Paint()
      ..shader = RadialGradient(colors: [
        QianColors.earth.withValues(alpha: 0.05 + 0.13 * fullness),
        QianColors.earth.withValues(alpha: 0.02),
      ]).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, fill);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = (inhale ? QianColors.rice : QianColors.earth).withValues(alpha: 0.85);
    canvas.drawCircle(c, r, ring);
  }

  @override
  bool shouldRepaint(_BreathCirclePainter old) => old.fullness != fullness || old.inhale != inhale;
}
