import '../../app/app_feature.dart';
import '../../core/iching/divination_method.dart';
import '../../shared/cast/stepwise_cast_page.dart';

final coinCastFeature = AppFeature(
  id: 'coin_cast',
  label: (l) => l.featureCoins,
  placement: FeaturePlacement.secondary,
  builder: (_) => StepwiseCastPage(
    method: const ThreeCoins(),
    instructions: (l) => l.coinsInstructions,
    stepLabel: (l, n) => l.coinsToss(n),
    allLabel: (l) => l.coinsTossAll,
  ),
);
