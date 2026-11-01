import 'package:flutter/widgets.dart';

import '../../core/content/lessons.dart';
import '../../l10n/l10n.dart';

/// 一套課程（易經課程、梅花易數課程共用課程頁）：檔名前綴、課數、免費課數、付費牆來源與文案、模擬器入口。
class LessonCourse {
  const LessonCourse({
    required this.prefix,
    required this.count,
    required this.freeCount,
    required this.title,
    required this.paywallSource,
    required this.paywallNote,
    this.openSimulator,
  });

  final String prefix;
  final int count;
  final int Function(BuildContext context) freeCount;
  final String Function(BuildContext context) title;
  final String paywallSource;
  final String Function(BuildContext context) paywallNote;

  /// 課程內「開啟起卦模擬器」（[Lesson.simulator] 有值時顯示）。
  final void Function(BuildContext context, String method)? openSimulator;

  bool isFree(BuildContext context, int id) => id <= freeCount(context);
}

/// 易經學習課程（8 課、前 2 課免費）。
final ichingCourse = LessonCourse(
  prefix: 'lesson',
  count: lessonCount,
  freeCount: (_) => freeLessonCount,
  title: (c) => c.l10n.featureLearn,
  paywallSource: 'lesson',
  paywallNote: (c) => c.l10n.learnPaywallNote,
);
