import '../../app/app_feature.dart';
import '../../l10n/l10n.dart';
import '../learn/lesson_course.dart';
import 'eastern_home_page.dart';

/// 東方命理（紫微年度基調、八字本月能量；HANDOFF §4-3，規格 iching-content docs/EASTERN-PLAN.md）。
/// 生辰只存手機（`BirthStore`）。免費看紫微命宮主星段，其餘屬會員；遠端開關 `qg_feature_eastern`。
final easternFeature = AppFeature(
  id: 'eastern',
  label: (l) => l.featureEastern,
  placement: FeaturePlacement.secondary,
  builder: (_) => const EasternHomePage(),
);

/// 紫微斗數課程（4 課）、八字課程（3 課），各第 1 課免費。
/// iching-content `<語言>/eastern/lessons/ziwei-NN.json`、`bazi-NN.json`。
final ziweiCourse = LessonCourse(
  prefix: 'ziwei-lesson',
  count: 4,
  freeCount: (_) => 1,
  title: (c) => c.l10n.ziweiCourseTitle,
  paywallSource: 'ziwei_lesson',
  paywallNote: (c) => c.l10n.easternPaywallLessonNote,
);

final baziCourse = LessonCourse(
  prefix: 'bazi-lesson',
  count: 3,
  freeCount: (_) => 1,
  title: (c) => c.l10n.baziCourseTitle,
  paywallSource: 'bazi_lesson',
  paywallNote: (c) => c.l10n.easternPaywallLessonNote,
);
