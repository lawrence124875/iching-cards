import '../features/breath/breath_feature.dart';
import '../features/coin_cast/coin_cast_feature.dart';
import '../features/draw/draw_feature.dart';
import '../features/journal/journal_feature.dart';
import 'app_feature.dart';

export 'app_feature.dart';

/// 功能註冊表：增減功能＝增減這裡的一行（日後可再以 Remote Config 遠端開關）。
final List<AppFeature> registeredFeatures = [
  drawFeature,
  coinCastFeature,
  journalFeature,
  breathFeature,
];
