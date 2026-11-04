import 'package:flutter/material.dart';

import '../../app/app_feature.dart';
import '../../app/services.dart';
import '../../core/meihua/meihua_cast.dart';
import '../../l10n/l10n.dart';
import '../learn/lesson_course.dart';
import '../cross/cross_feature.dart';
import 'meihua_cast_page.dart';
import 'meihua_home_page.dart';

/// 梅花易數：13 課課程（第 13 課雙卦對照導向雙卦交叉）＋時間／數字／字數起卦＋以象為核心的解卦。
/// 免費：第 1 課、每天 1 次時間起卦（獎勵廣告 +1，與一般起卦分開算）；其餘訂閱解鎖（遠端開關 `qg_feature_meihua`）。
final meihuaFeature = AppFeature(
  id: 'meihua',
  label: (l) => l.featureMeihua,
  placement: FeaturePlacement.secondary,
  builder: (_) => const MeihuaHomePage(),
);

/// 梅花易數課程（iching-content `<語言>/meihua/lessons/NN.json`）。
final meihuaCourse = LessonCourse(
  prefix: 'meihua-lesson',
  count: 13,
  freeCount: (c) => AppServices.of(c).limits.meihuaFreeLessons,
  title: (c) => c.l10n.meihuaCourseTitle,
  paywallSource: 'meihua_lesson',
  paywallNote: (c) => c.l10n.meihuaPaywallLessonNote,
  openSimulator: (context, method) => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => method == 'cross' ? const CrossCastPage() : MeihuaCastPage(initial: switch (method) {
      'number' => MeihuaMethod.number,
      'words' => MeihuaMethod.wordCount,
      _ => MeihuaMethod.time,
    }),
  )),
);
