import '../../app/app_feature.dart';
import 'coin_cast_page.dart';

final coinCastFeature = AppFeature(
  id: 'coin_cast',
  label: (l) => l.featureCoins,
  placement: FeaturePlacement.secondary,
  builder: (_) => const CoinCastPage(),
);
