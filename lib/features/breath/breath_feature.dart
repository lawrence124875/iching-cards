import 'package:flutter/material.dart';

import '../../app/app_feature.dart';
import 'breath_setup_sheet.dart';

/// 呼吸音景：依抽到的卦，以上下經卦組合程式合成的自然音景，引導吸 4 吐 6 的呼吸（HANDOFF §14）。
/// 只從解讀頁進入（解讀頁顯示所有功能的 readingAction）；拔除＝移出註冊表一行。
final breathFeature = AppFeature(
  id: 'breath',
  label: (l) => l.featureBreath,
  placement: FeaturePlacement.none,
  readingAction: ReadingAction(
    label: (l) => l.readingActionBreath,
    icon: Icons.air,
    open: (context, hexagram) => showBreathSetup(context, hexagram),
  ),
);
