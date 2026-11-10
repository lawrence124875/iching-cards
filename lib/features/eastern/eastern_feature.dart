import '../../app/app_feature.dart';
import 'eastern_home_page.dart';

/// 東方命理（紫微年度基調、八字本月能量；HANDOFF §4-3，規格 iching-content docs/EASTERN-PLAN.md）。
/// 生辰只存手機（`BirthStore`）。免費看紫微命宮主星段，其餘屬會員；遠端開關 `qg_feature_eastern`。
final easternFeature = AppFeature(
  id: 'eastern',
  label: (l) => l.featureEastern,
  placement: FeaturePlacement.secondary,
  builder: (_) => const EasternHomePage(),
);
