import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/soundscape/breath_timeline.dart';
import '../../core/soundscape/session_renderer.dart';
import '../../shared/format.dart';
import '../../shared/widgets/card_art_viewer.dart';
import '../../l10n/l10n.dart';

enum _Stage { preparing, failed, running, done }

/// 呼吸練習頁。畫面的時間一律取自音檔播放位置，與音景、鈴聲保持同步；
/// 離開 App 或關閉螢幕時音景繼續播放，通知列與鎖定畫面可暫停／播放（JustAudioPlayback）。
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
  Services? _services;
  late final SessionTimeline _tl = widget.spec.timeline;
  late final HexagramInfo _info = HexagramTable.byNumber(widget.hexagram);
  late final Ticker _ticker;
  final _clock = Stopwatch();

  /// 給看圖畫面上的小呼吸圓用（看圖是另一個畫面，透過它同步）。
  final _now = ValueNotifier<double>(0);

  final _subs = <StreamSubscription<void>>[];
  bool _loaded = false;
  bool _silent = false;
  bool _paused = false;
  bool _everPlayed = false;

  /// 從通知列或鎖定畫面按了「停止」。
  bool _stoppedEarly = false;
  _Stage _stage = _Stage.preparing;

  String _soundNames(AppLocalizations l) => _info.upper == _info.lower
      ? l.soundscape(_info.upper)
      : '${l.soundscape(_info.upper)}${l.separator}${l.soundscape(_info.lower)}';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = AppServices.of(context);
    _svc = _services!.breath;
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
      final art = await _artFile();
      if (!mounted) return;
      final p = svc.playback;
      final l = context.l10n;
      await p.load(
        path,
        id: 'breath-${widget.spec.key}',
        title: l.breathMediaTitle(l.hexFullName(_info)),
        subtitle: l.breathMediaSubtitle(_soundNames(l), l.minutes(widget.spec.minutes)),
        artFilePath: art,
      );
      _loaded = true;
      _subs.add(p.playingChanges.listen(_onPlaying));
      _subs.add(p.completed.listen((_) => _finish(stopAudio: true)));
      _subs.add(p.stoppedExternally.listen((_) {
        _stoppedEarly = _stage == _Stage.running;
        _finish(stopAudio: false);
      }));
      if (!mounted) return;
      _start();
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.failed);
    }
  }

  /// 鎖定畫面播放卡片的圖：把牌面圖寫到暫存資料夾（音檔快取以 breath_ 開頭，這裡用 art_ 避免被清掉）。
  Future<String?> _artFile() async {
    try {
      final bytes = await _services!.content.cardArtBytes(widget.hexagram);
      if (bytes == null) return null;
      final f = File('${(await getTemporaryDirectory()).path}/art_${_info.code}.webp');
      if (!await f.exists()) await f.writeAsBytes(bytes, flush: true);
      return f.path;
    } catch (_) {
      return null;
    }
  }

  void _start() {
    setState(() => _stage = _Stage.running);
    _svc?.screenAwake.set(true);
    if (_silent) {
      _clock.start();
    } else {
      _svc?.playback.play();
    }
    if (!_ticker.isActive) _ticker.start();
  }

  void _startSilent() {
    _silent = true;
    _start();
  }

  /// 通知列或鎖定畫面按了暫停／播放，畫面跟著改。
  void _onPlaying(bool playing) {
    if (playing) _everPlayed = true;
    if (!_everPlayed || _stage != _Stage.running || !mounted) return;
    if (_paused == !playing) return;
    setState(() => _paused = !playing);
    _svc?.screenAwake.set(playing);
  }

  double get _position =>
      _silent || !_loaded ? _clock.elapsedMilliseconds / 1000 : _svc!.playback.position.inMilliseconds / 1000;

  void _onTick(Duration _) {
    final now = _position;
    _now.value = now;
    if (_tl.at(now).phase == BreathPhase.done) {
      // 音檔還會播完約 5 秒的淡出與結束鈴，播完由 completed 停止並移除通知
      _finish(stopAudio: false);
      return;
    }
    setState(() {});
  }

  void _finish({required bool stopAudio}) {
    if (stopAudio && !_silent) _svc?.playback.stop();
    if (_stage == _Stage.done || !mounted) return;
    _ticker.stop();
    _clock.stop();
    _svc?.screenAwake.set(false);
    if (!_stoppedEarly) _now.value = _tl.breathEnd;
    setState(() => _stage = _Stage.done);
  }

  void _togglePause() {
    final pause = !_paused;
    setState(() => _paused = pause);
    if (_silent) {
      if (pause) {
        _clock.stop();
      } else {
        _clock.start();
      }
    } else if (pause) {
      _svc?.playback.pause();
    } else {
      _svc?.playback.play();
    }
    _svc?.screenAwake.set(!pause);
  }

  void _showArt() {
    showCardArt(
      context,
      _info,
      overlay: ValueListenableBuilder<double>(
        valueListenable: _now,
        builder: (_, now, __) => _MiniBreath(state: _tl.at(now)),
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _ticker.dispose();
    _now.dispose();
    if (_loaded) _svc?.playback.stop(); // 離開練習頁就停止，並移除通知
    _svc?.screenAwake.set(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final state = _stage == _Stage.done ? const BreathState(BreathPhase.done, 1) : _tl.at(_now.value);

    return Scaffold(
      appBar: AppBar(title: Text(l.hexFullName(_info))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
          child: Column(
            children: [
              Text(_soundNames(l), style: t.bodySmall?.copyWith(letterSpacing: 3)),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: BreathCirclePainter(
                        fullness: _stage == _Stage.running ? state.fullness : 0,
                        inhale: state.phase == BreathPhase.inhale,
                      ),
                      child: Center(child: _centre(t, state)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 132, child: _bottom(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centre(TextTheme t, BreathState s) {
    final l = context.l10n;
    switch (_stage) {
      case _Stage.preparing:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 16),
          Text(l.breathPreparing, style: t.bodyMedium),
          Text(l.breathPreparingSub, style: t.bodySmall),
        ]);
      case _Stage.failed:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.breathFailed, textAlign: TextAlign.center, style: t.bodyMedium),
        );
      case _Stage.done:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_stoppedEarly ? l.breathEnded : l.breathDone, style: t.headlineSmall),
          const SizedBox(height: 8),
          Text(
              _stoppedEarly
                  ? l.breathStoppedFromNotification
                  : l.breathSummary(widget.spec.minutes, widget.spec.minutes * 6),
              style: t.bodySmall),
        ]);
      case _Stage.running:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.phase(s.phase), style: t.displaySmall?.copyWith(letterSpacing: 0)),
          const SizedBox(height: 4),
          Text(_paused ? l.breathPaused : '${math.max(1, s.secondsLeftInPhase.ceil())}', style: t.bodySmall),
        ]);
    }
  }

  Widget _bottom(TextTheme t) {
    final l = context.l10n;
    switch (_stage) {
      case _Stage.preparing:
        return const SizedBox.shrink();
      case _Stage.failed:
        return Column(children: [
          FilledButton(onPressed: _startSilent, child: Text(l.breathUseSilent)),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.back)),
        ]);
      case _Stage.done:
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.breathBackToReading)),
          TextButton(onPressed: _showArt, child: Text(l.breathViewArtAgain)),
        ]);
      case _Stage.running:
        final left = math.max(0.0, _tl.breathEnd - _now.value);
        return Column(children: [
          Text('${l.breathRemaining(formatClock(left.ceil()))}${_silent ? l.breathSilentMark : ''}',
              style: t.bodySmall?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundButton(icon: Icons.landscape_outlined, label: l.breathViewArt, onTap: _showArt),
              const SizedBox(width: 36),
              _RoundButton(
                icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: _paused ? l.breathResume : l.breathPause,
                onTap: _togglePause,
                primary: true,
              ),
              const SizedBox(width: 36),
              _RoundButton(icon: Icons.close_rounded, label: l.breathEnd, onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ]);
    }
  }
}

/// 細金線圓形按鈕＋下方小字；主按鈕（暫停／繼續）較大、線條較亮。
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final size = primary ? 64.0 : 48.0;
    final color = primary ? QianColors.rice : QianColors.textSub;
    return Semantics(
      button: true,
      label: label,
      child: Column(children: [
        Material(
          color: primary ? QianColors.earth.withValues(alpha: 0.08) : Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(color: (primary ? QianColors.earth : QianColors.mountain).withValues(alpha: 0.8)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: color, size: primary ? 30 : 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, letterSpacing: 2)),
        ),
      ]),
    );
  }
}

/// 看圖時疊在下方的小呼吸圓，不遮住景象。
class _MiniBreath extends StatelessWidget {
  const _MiniBreath({required this.state});

  final BreathState state;

  @override
  Widget build(BuildContext context) {
    final running = state.phase == BreathPhase.inhale || state.phase == BreathPhase.exhale;
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: BreathCirclePainter(
          fullness: running ? state.fullness : 0,
          inhale: state.phase == BreathPhase.inhale,
          onImage: true,
        ),
        child: Center(
          child: Text(
            context.l10n.phase(state.phase),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: QianColors.text,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ),
      ),
    );
  }
}

/// 呼吸圓：吸氣時漸漸擴大、吐氣時收回；內外兩條細線標出最小與最大。
class BreathCirclePainter extends CustomPainter {
  BreathCirclePainter({required this.fullness, required this.inhale, this.onImage = false});

  final double fullness;
  final bool inhale;

  /// 疊在牌面圖上：加深底色讓圓看得清楚。
  final bool onImage;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2 * 0.92;
    final minR = maxR * 0.42;
    final r = minR + (maxR - minR) * fullness;

    if (onImage) {
      canvas.drawCircle(c, maxR, Paint()..color = Colors.black.withValues(alpha: 0.35));
    }
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = QianColors.mountain.withValues(alpha: onImage ? 0.7 : 0.45);
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
  bool shouldRepaint(BreathCirclePainter old) =>
      old.fullness != fullness || old.inhale != inhale || old.onImage != onImage;
}
