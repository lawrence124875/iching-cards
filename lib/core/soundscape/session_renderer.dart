import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../iching/trigram.dart';
import 'bed_source.dart';
import 'breath_timeline.dart';
import 'synth_bed_source.dart';

/// 一次呼吸練習要產生的音檔規格。只含基本型別，可送進背景 isolate。
class SessionSpec {
  const SessionSpec({
    required this.upper,
    required this.lower,
    required this.minutes,
    required this.bells,
  });

  final Trigram upper;
  final Trigram lower;
  final int minutes;
  final bool bells;

  SessionTimeline get timeline => SessionTimeline(minutes: minutes);

  /// 快取檔名用。改了合成方式請把 v1 往上加，舊快取自然失效。
  String get key => 'v1_${upper.name}_${lower.name}_${minutes}m_${bells ? 'b' : 'q'}';
}

/// 合成整段練習音檔（16-bit 單聲道 WAV）：上卦、下卦兩種音景疊加，
/// 依呼吸時間軸起伏音量，加上換氣鈴聲。純計算，可在背景 isolate 或單元測試中執行。
class SessionRenderer {
  const SessionRenderer({this.source = const SynthBedSource(), this.sampleRate = 22050});

  final BedSource source;
  final int sampleRate;

  /// 上、下卦循環長度不同（互質秒數），疊在一起時不容易聽出重複。
  static const upperSeconds = 31.0;
  static const lowerSeconds = 37.0;

  Uint8List renderWav(SessionSpec spec) {
    final sr = sampleRate;
    final tl = spec.timeline;
    final n = (tl.totalSeconds * sr).round();

    final same = spec.upper == spec.lower;
    final lower = source.bed(spec.lower, sampleRate: sr, seconds: lowerSeconds);
    final upper = same ? null : source.bed(spec.upper, sampleRate: sr, seconds: upperSeconds);
    // 兩段不相關的音景相加，均方根約放大 √2，各乘 0.75 讓總音量與單一音景相近
    final g = same ? 1.0 : 0.75;

    final bells = spec.bells ? tl.bells() : const <({double time, BellKind kind})>[];
    var nextBell = 0;
    final active = <_Bell>[];

    final data = ByteData(44 + n * 2);
    _writeHeader(data, n, sr);
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      var v = lower[i % lower.length] * g;
      if (upper != null) v += upper[i % upper.length] * g;
      v *= tl.bedGain(t);

      while (nextBell < bells.length && bells[nextBell].time <= t) {
        active.add(_Bell(bells[nextBell].kind, bells[nextBell].time));
        nextBell++;
      }
      if (active.isNotEmpty) {
        for (final b in active) {
          v += b.valueAt(t);
        }
        active.removeWhere((b) => t - b.start > b.length);
      }

      // 柔性限幅：一般音量幾乎不受影響，避免雷聲或劈啪聲爆音
      final y = _softClip(v);
      data.setInt16(44 + i * 2, (y * 32767).round().clamp(-32768, 32767).toInt(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  static double _softClip(double x) {
    const knee = 0.6;
    final a = x.abs();
    if (a <= knee) return x;
    final over = (a - knee) / (1 - knee);
    final y = knee + (1 - knee) * (1 - math.exp(-over));
    return x.isNegative ? -y : y;
  }

  static void _writeHeader(ByteData d, int samples, int sr) {
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        d.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    d.setUint32(4, 36 + samples * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    d.setUint32(16, 16, Endian.little); // PCM fmt chunk size
    d.setUint16(20, 1, Endian.little); // PCM
    d.setUint16(22, 1, Endian.little); // mono
    d.setUint32(24, sr, Endian.little);
    d.setUint32(28, sr * 2, Endian.little); // byte rate
    d.setUint16(32, 2, Endian.little); // block align
    d.setUint16(34, 16, Endian.little); // bits per sample
    ascii(36, 'data');
    d.setUint32(40, samples * 2, Endian.little);
  }
}

/// 頌缽般的柔和鈴聲：三個泛音、各自指數衰減。
class _Bell {
  _Bell(this.kind, this.start);

  final BellKind kind;
  final double start;

  static const _ratios = [1.0, 2.01, 2.99];
  static const _amps = [1.0, 0.35, 0.15];
  static const _decays = [1.6, 0.8, 0.5];

  double get _freq => switch (kind) {
        BellKind.inhale => 523.25, // C5
        BellKind.exhale => 392.0, // G4
        BellKind.end => 392.0,
      };

  double get _level => switch (kind) {
        BellKind.inhale => 0.10,
        BellKind.exhale => 0.08,
        BellKind.end => 0.12,
      };

  double get _decayScale => kind == BellKind.end ? 2.0 : 1.0;

  double get length => 5.0 * _decayScale;

  double valueAt(double t) {
    final dt = t - start;
    if (dt < 0) return 0;
    final attack = math.min(1.0, dt / 0.005);
    var v = 0.0;
    for (var p = 0; p < _ratios.length; p++) {
      v += _amps[p] * math.exp(-dt / (_decays[p] * _decayScale)) * math.sin(2 * math.pi * _freq * _ratios[p] * dt);
    }
    return v * attack * _level;
  }
}

/// 在背景 isolate 執行：產生音檔並寫入 [path]（先寫暫存檔再改名，避免留下半個檔案）。
Future<void> renderSessionToFile(SessionSpec spec, String path) async {
  final bytes = const SessionRenderer().renderWav(spec);
  final tmp = File('$path.part');
  await tmp.writeAsBytes(bytes, flush: true);
  await tmp.rename(path);
}
