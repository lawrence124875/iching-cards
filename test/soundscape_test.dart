import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/iching/trigram.dart';
import 'package:iching_cards/core/soundscape/breath_timeline.dart';
import 'package:iching_cards/core/soundscape/dsp.dart';
import 'package:iching_cards/core/soundscape/session_renderer.dart';
import 'package:iching_cards/core/soundscape/synth_bed_source.dart';

void main() {
  group('呼吸節奏（吸 4、吐 6）', () {
    const p = BreathPattern();

    test('每分鐘 6 次', () => expect(60 / p.cycle, 6));

    test('階段與進度', () {
      expect(p.at(0).phase, BreathPhase.inhale);
      expect(p.at(2).progress, closeTo(0.5, 1e-9));
      expect(p.at(4).phase, BreathPhase.exhale);
      expect(p.at(7).progress, closeTo(0.5, 1e-9));
      expect(p.at(10).phase, BreathPhase.inhale);
      expect(p.at(10).cycle, 1);
      expect(p.at(9).secondsLeftInPhase, closeTo(1, 1e-9));
    });

    test('呼吸圓大小：吸到頂為 1、吐完為 0，連續', () {
      expect(p.at(0).fullness, closeTo(0, 1e-9));
      expect(p.at(3.999).fullness, closeTo(1, 1e-3));
      expect(p.at(4).fullness, closeTo(1, 1e-9));
      expect(p.at(9.999).fullness, closeTo(0, 1e-3));
    });
  });

  group('練習時間軸', () {
    const tl = SessionTimeline(minutes: 2);

    test('準備 → 呼吸 → 完成', () {
      expect(tl.at(1).phase, BreathPhase.prepare);
      expect(tl.at(tl.leadIn).phase, BreathPhase.inhale);
      expect(tl.at(tl.breathEnd - 0.01).phase, BreathPhase.exhale);
      expect(tl.at(tl.breathEnd).phase, BreathPhase.done);
      expect(tl.totalSeconds, tl.leadIn + 120 + tl.tail);
    });

    test('音量曲線在各段交界處連續，頭尾為 0', () {
      expect(tl.bedGain(0), closeTo(0, 1e-9));
      expect(tl.bedGain(tl.leadIn - 1e-6), closeTo(tl.bedGain(tl.leadIn), 1e-4));
      expect(tl.bedGain(tl.breathEnd - 1e-6), closeTo(tl.bedGain(tl.breathEnd), 1e-4));
      expect(tl.bedGain(tl.totalSeconds), closeTo(0, 1e-9));
      for (var t = 0.0; t < tl.totalSeconds; t += 0.25) {
        expect(tl.bedGain(t), inInclusiveRange(0, 1));
      }
    });

    test('鈴聲：每次吸、吐各一聲，加上結束鈴', () {
      final b = tl.bells();
      expect(b.length, 2 * 12 + 1);
      expect(b.first.time, tl.leadIn);
      expect(b[1].kind, BellKind.exhale);
      expect(b[1].time, tl.leadIn + 4);
      expect(b.last.kind, BellKind.end);
      expect(b.last.time, tl.breathEnd);
    });
  });

  group('八經卦音景（程式合成）', () {
    const source = SynthBedSource();
    const sr = 11025;

    for (final t in Trigram.values) {
      test('${t.label}・${t.nature}：長度正確、數值正常、音量合理', () {
        final b = source.bed(t, sampleRate: sr, seconds: 12);
        expect(b.length, 12 * sr);
        expect(b.every((v) => v.isFinite), isTrue);
        final r = rmsOf(b);
        expect(r, greaterThan(0.01));
        expect(r, lessThan(0.25));
        expect(peakOf(b), lessThan(1.5));
      });
    }

    test('同一設定產生同樣的聲音（可重現）', () {
      final a = source.bed(Trigram.kan, sampleRate: sr, seconds: 7);
      final b = source.bed(Trigram.kan, sampleRate: sr, seconds: 7);
      expect(a, b);
    });

    test('循環接縫：交叉淡化後開頭接得上原本的尾端', () {
      final raw = Float32List.fromList(List.generate(30, (i) => i.toDouble()));
      final loop = SynthBedSource.makeLoop(raw, 20, 10);
      expect(loop.length, 20);
      expect(loop[0], closeTo(raw[20], 1e-6)); // 第 0 個樣本＝原本第 n 個，接縫連續
      expect(loop[15], raw[15]);
    });
  });

  test('整段練習音檔：WAV 格式與長度', () {
    const spec = SessionSpec(upper: Trigram.kun, lower: Trigram.gen, minutes: 1, bells: true);
    final bytes = const SessionRenderer(sampleRate: 8000).renderWav(spec);
    String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
    expect(tag(0), 'RIFF');
    expect(tag(8), 'WAVE');
    expect(tag(36), 'data');
    final samples = (spec.timeline.totalSeconds * 8000).round();
    expect(bytes.length, 44 + samples * 2);
    final d = ByteData.sublistView(bytes);
    expect(d.getUint32(24, Endian.little), 8000);
    expect(d.getInt16(44, Endian.little).abs(), lessThan(10)); // 從無聲淡入
    expect(spec.key, 'v2_kun_gen_1m_b');
    expect(d.getUint16(22, Endian.little), 1);
  });

  test('雙耳節拍：立體聲、左右聲道不同', () {
    const spec = SessionSpec(upper: Trigram.qian, lower: Trigram.qian, minutes: 1, bells: false, binaural: true);
    final bytes = const SessionRenderer(sampleRate: 8000).renderWav(spec);
    final d = ByteData.sublistView(bytes);
    final samples = (spec.timeline.totalSeconds * 8000).round();
    expect(bytes.length, 44 + samples * 4);
    expect(d.getUint16(22, Endian.little), 2);
    expect(spec.key, 'v2_qian_qian_1m_q_bi');
    var diff = 0;
    for (var i = 8000 * 10; i < 8000 * 11; i++) {
      diff += (d.getInt16(44 + i * 4, Endian.little) - d.getInt16(46 + i * 4, Endian.little)).abs();
    }
    expect(diff, greaterThan(0));
  });
}
