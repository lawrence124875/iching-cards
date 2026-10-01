import '../../app/app_feature.dart';
import 'draw_page.dart';

final drawFeature = AppFeature(
  id: 'draw',
  label: '抽一卦',
  placement: FeaturePlacement.primary,
  builder: (_) => const DrawPage(),
);
