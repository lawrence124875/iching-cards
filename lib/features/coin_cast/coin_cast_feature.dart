import '../../app/app_feature.dart';
import 'coin_cast_page.dart';

final coinCastFeature = AppFeature(
  id: 'coin_cast',
  label: '用三枚銅錢起卦',
  placement: FeaturePlacement.secondary,
  builder: (_) => const CoinCastPage(),
);
