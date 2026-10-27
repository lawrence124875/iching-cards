import 'dart:math' as math;
import 'dart:typed_data';

import '../iching/trigram.dart';
import 'bed_source.dart';
import 'synth_bed_source.dart';

/// 錄音音景（0.2.0+50，REFERENCE §0.3）：`assets/audio/beds/<卦>.wav`，CC0／公有領域錄音，
/// 由 `tools/soundscape/build_beds.py` 壓掉近距離瞬態、低通、加殘響後截 56 秒（11025 Hz 單聲道 16-bit）。
///
/// 錄音沒有可調的音高，[pitch] 不影響（長音墊與鐘聲仍照調音精準輸出）。
/// [stereo]：左右聲道取同一循環的不同位置，做出包覆感（[SessionRenderer] 處理）。
class RecordedBedSource extends BedSource {
  const RecordedBedSource(this.clips);

  /// 各卦的 WAV 檔內容（只需要這次用到的卦）。
  final Map<Trigram, Uint8List> clips;

  static String assetOf(Trigram t) => 'assets/audio/beds/${t.name}.wav';

  @override
  bool get stereo => true;

  @override
  Float32List bed(Trigram trigram, {required int sampleRate, required double seconds, double pitch = 1}) {
    final wav = clips[trigram];
    if (wav == null) throw ArgumentError('沒有載入 ${trigram.name} 的錄音');
    final (:rate, :samples) = decodeWav16(wav);
    final raw = resample(samples, rate, sampleRate);
    final n = (seconds * sampleRate).round();
    final m = math.min((SynthBedSource.crossfadeSeconds * sampleRate).round(), n ~/ 2);
    if (raw.length < n + m) throw StateError('${trigram.name} 的錄音不足 ${seconds + SynthBedSource.crossfadeSeconds} 秒');
    return SynthBedSource.makeLoop(raw, n, m);
  }

  /// 讀 16-bit PCM 單聲道 WAV（找 fmt 與 data 區塊，不假設檔頭長度）。
  static ({int rate, Float32List samples}) decodeWav16(Uint8List bytes) {
    final d = ByteData.sublistView(bytes);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') throw const FormatException('不是 WAV 檔');
    var rate = 0;
    var pos = 12;
    while (pos + 8 <= bytes.length) {
      final id = tag(pos);
      final size = d.getUint32(pos + 4, Endian.little);
      if (id == 'fmt ') {
        if (d.getUint16(pos + 8, Endian.little) != 1 || d.getUint16(pos + 10, Endian.little) != 1 || d.getUint16(pos + 22, Endian.little) != 16) {
          throw const FormatException('只支援 16-bit PCM 單聲道');
        }
        rate = d.getUint32(pos + 12, Endian.little);
      } else if (id == 'data') {
        final count = math.min(size, bytes.length - pos - 8) ~/ 2;
        final out = Float32List(count);
        for (var i = 0; i < count; i++) {
          out[i] = d.getInt16(pos + 8 + i * 2, Endian.little) / 32768;
        }
        return (rate: rate, samples: out);
      }
      pos += 8 + size + (size & 1);
    }
    throw const FormatException('WAV 檔沒有 data 區塊');
  }

  /// 線性內插換取樣率（錄音已低通到 5 kHz 以下，升頻後的鏡像由 [SessionRenderer.softenCutoff] 濾掉）。
  static Float32List resample(Float32List x, int from, int to) {
    if (from == to) return x;
    final n = (x.length * to / from).floor();
    final out = Float32List(n);
    final step = from / to;
    for (var i = 0; i < n; i++) {
      final p = i * step;
      final j = p.floor();
      final f = p - j;
      out[i] = j + 1 < x.length ? x[j] * (1 - f) + x[j + 1] * f : x[j];
    }
    return out;
  }
}
