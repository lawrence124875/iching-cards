import '../../app/app_feature.dart';
import 'draw_page.dart';

final drawFeature = AppFeature(
  id: 'draw',
  label: (l) => l.featureDraw,
  placement: FeaturePlacement.primary,
  builder: (_) => const DrawPage(),
);
