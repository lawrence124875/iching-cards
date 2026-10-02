import '../../core/iching/trigram.dart';

/// 八經卦音景的名稱（介面文字；多語系時移到 ARB）。
String soundscapeName(Trigram t) => switch (t) {
      Trigram.qian => '高空清風',
      Trigram.kun => '夜野蟲鳴',
      Trigram.zhen => '遠雷春雨',
      Trigram.xun => '林間風聲',
      Trigram.kan => '山澗流水',
      Trigram.li => '營火',
      Trigram.gen => '山林寂靜',
      Trigram.dui => '湖畔水波',
    };
