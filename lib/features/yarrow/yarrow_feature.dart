import '../../app/app_feature.dart';
import '../../core/iching/divination_method.dart';
import '../../shared/cast/stepwise_cast_page.dart';

/// 蓍草起卦：大衍之數，三變成一爻（與擲錢共用逐爻起卦頁，只換策略與文字）。
final yarrowFeature = AppFeature(
  id: 'yarrow',
  label: (l) => l.featureYarrow,
  placement: FeaturePlacement.secondary,
  builder: (_) => StepwiseCastPage(
    method: const YarrowStalks(),
    instructions: (l) => l.yarrowInstructions,
    stepLabel: (l, n) => l.yarrowStep(n),
    allLabel: (l) => l.yarrowAll,
  ),
);
