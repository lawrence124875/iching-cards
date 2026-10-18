import 'dart:typed_data';

import '../iching/trigram.dart';

/// 音景來源（策略，HANDOFF §9 第 2 點）：給一個經卦，回傳一段可無縫循環的單聲道音景。
/// 目前實作為程式合成（SynthBedSource）；日後若改用錄音檔，只需新增一個實作。
abstract class BedSource {
  const BedSource();

  /// 長度＝round(seconds × sampleRate)，最後一個樣本接回第一個樣本時不會有接縫。
  /// [pitch]：有音高的聲音（長鳴、蟲鳴、鳥鳴、水泡）一律乘上這個比例（調音，見 [Tuning]）；
  /// 風、雨、水、火等雜訊型的聲音沒有音高，不受影響。
  Float32List bed(Trigram trigram, {required int sampleRate, required double seconds, double pitch = 1});
}
