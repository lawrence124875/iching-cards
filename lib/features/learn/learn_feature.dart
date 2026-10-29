import '../../app/app_feature.dart';
import 'lesson_list_page.dart';

/// 學習課程：8 課，從陰陽、八卦到讀象與變爻；前 2 課免費，其餘會員解鎖。
final learnFeature = AppFeature(
  id: 'learn',
  label: (l) => l.featureLearn,
  placement: FeaturePlacement.secondary,
  builder: (_) => const LessonListPage(),
);
