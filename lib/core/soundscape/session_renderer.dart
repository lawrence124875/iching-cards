import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../iching/trigram.dart';
import 'bed_source.dart';
import 'dsp.dart';
import 'breath_timeline.dart';
import 'synth_bed_source.dart';

/// 一次呼吸練習要產生的音檔規格。只含基本型別，可送進背景 isolate。
class SessionSpec {
  const SessionSpec({
    required this.upper,
    required this.lower,
    required this.minutes,
    required this.bells,
    this.binaural = false,
  });

  final Trigram upper;
  final Trigram lower;
  final int minutes;
  final bool bells;

  /// 雙耳節拍：左耳 216Hz、右耳 223.83Hz，兩耳差 7.83Hz（需戴耳機）。開啟時輸出立體聲。
  final bool binaural;

  SessionTimeline get timeline => SessionTimeline(minutes: minutes);

  /// 快取檔名用。改了合成方式請把版本往上加，舊快取自然失效（v2：0.1.0+10 柔和版＋432Hz）。
  String get key => 'v2_${upper.name}_${lower.name}_${minutes}m_${bells ? 'b' : 'q'}${binaural ? '_bi' : ''}';
}

/// 合成整段練習音檔（16-bit WAV，單聲道；開雙耳節拍時立體聲）：上卦、下卦兩種音景疊加，
/// 柔化高頻後依呼吸時間軸起伏音量，加上換氣鈴聲（432Hz 調音）。純計算，可在背景 isolate 或單元測試中執行。
class SessionRenderer {
  const SessionRenderer({this.source = const SynthBedSource(), this.sampleRate = 22050});

  final BedSource source;
  final int sampleRate;

  /// 上、下卦循環長度不同（互質秒數），疊在一起時不容易聽出重複。
  static const upperSeconds = 31.0;
  static const lowerSeconds = 37.0;

  /// 雙耳節拍：載波取 432Hz 的低八度 216Hz，右耳高 7.83Hz（舒曼共振頻率）。
  static const binauralCarrier = 216.0;
  static const binauralBeat = 7.83;
  static const binauralLevel = 0.045;

  /// 全部音景最後再過一道低通，聲音更溫暖不刺耳。
  static const softenCutoff = 5000.0;

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

    final ch = spec.binaural ? 2 : 1;
    final soften = Biquad.lowpass(sr, softenCutoff, 0.6);
    final data = ByteData(44 + n * 2 * ch);
    _writeHeader(data, n, sr, ch);
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      var v = lower[i % lower.length] * g;
      if (upper != null) v += upper[i % upper.length] * g;
      v = soften.process(v) * tl.bedGain(t);

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

      if (ch == 1) {
        // 柔性限幅：一般音量幾乎不受影響，避免雷聲或劈啪聲爆音
        data.setInt16(44 + i * 2, _pcm(v), Endian.little);
      } else {
        // 雙耳節拍只隨準備淡入、結束淡出，不跟呼吸起伏（保持穩定的差頻）
        final e = binauralLevel * tl.bedGain(t) / (1 - tl.depth).clamp(0.01, 1.0);
        final env = math.min(e, binauralLevel);
        final l = v + env * math.sin(2 * math.pi * binauralCarrier * t);
        final r = v + env * math.sin(2 * math.pi * (binauralCarrier + binauralBeat) * t);
        data.setInt16(44 + i * 4, _pcm(l), Endian.little);
        data.setInt16(46 + i * 4, _pcm(r), Endian.little);
      }
    }
    return data.buffer.asUint8List();
  }

  static int _pcm(double v) => (_softClip(v) * 32767).round().clamp(-32768, 32767).toInt();

  static double _softClip(double x) {
    const knee = 0.6;
    final a = x.abs();
    if (a <= knee) return x;
    final over = (a - knee) / (1 - knee);
    final y = knee + (1 - knee) * (1 - math.exp(-over));
    return x.isNegative ? -y : y;
  }

  static void _writeHeader(ByteData d, int samples, int sr, int ch) {
    void ascii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        d.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    d.setUint32(4, 36 + samples * 2 * ch, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    d.setUint32(16, 16, Endian.little); // PCM fmt chunk size
    d.setUint16(20, 1, Endian.little); // PCM
    d.setUint16(22, ch, Endian.little); // 1＝單聲道、2＝立體聲
    d.setUint32(24, sr, Endian.little);
    d.setUint32(28, sr * 2 * ch, Endian.little); // byte rate
    d.setUint16(32, 2 * ch, Endian.little); // block align
    d.setUint16(34, 16, Endian.little); // bits per sample
    ascii(36, 'data');
    d.setUint32(40, samples * 2 * ch, Endian.little);
  }
}

/// 頌缽般的柔和鈴聲：三個泛音、各自指數衰減。432Hz 調音：吸氣 432Hz（A4）、吐氣與結束 324Hz（其下純四度）。
class _Bell {
  _Bell(this.kind, this.start);

  final BellKind kind;
  final double start;

  static const _ratios = [1.0, 2.01, 2.99];
  static const _amps = [1.0, 0.35, 0.15];
  static const _decays = [2.4, 1.2, 0.7];

  double get _freq => switch (kind) {
        BellKind.inhale => 432.0,
        BellKind.exhale => 324.0,
        BellKind.end => 324.0,
      };

  double get _level => switch (kind) {
        BellKind.inhale => 0.07,
        BellKind.exhale => 0.06,
        BellKind.end => 0.09,
      };

  double get _decayScale => kind == BellKind.end ? 2.0 : 1.0;

  double get length => 7.0 * _decayScale;

  double valueAt(double t) {
    final dt = t - start;
    if (dt < 0) return 0;
    final attack = smoothstep(dt / 0.03); // 起音放緩，像輕輕觸碰
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
