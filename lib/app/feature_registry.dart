import '../features/breath/breath_feature.dart';
import '../features/coin_cast/coin_cast_feature.dart';
import '../features/cross/cross_feature.dart';
import '../features/daily/daily_feature.dart';
import '../features/draw/draw_feature.dart';
import '../features/eastern/eastern_feature.dart';
import '../features/journal/journal_feature.dart';
import '../features/learn/learn_feature.dart';
import '../features/meihua/meihua_feature.dart';
import '../features/yarrow/yarrow_feature.dart';
import '../core/telemetry/remote_flags.dart';
import 'app_feature.dart';

export 'app_feature.dart';

/// 功能註冊表：增減功能＝增減這裡的一行（日後可再以 Remote Config 遠端開關）。
final List<AppFeature> registeredFeatures = [
  // 0.9.0 起首頁改底部分頁（home_page.dart 自己列出各入口）；這裡的順序只影響解讀頁的功能入口與通知處理
  drawFeature,
  dailyFeature,
  meihuaFeature,
  crossFeature,
  easternFeature,
  journalFeature,
  learnFeature,
  coinCastFeature,
  yarrowFeature,
  breathFeature,
];

/// 目前開放的功能：註冊表中、且遠端開關（`qg_feature_<id>`，§18）沒有關掉的。
/// 首頁與解讀頁的入口都由這裡決定；通知開啟（payload）仍走完整的註冊表。
Iterable<AppFeature> activeFeatures(RemoteFlags flags) =>
    registeredFeatures.where((f) => flags.featureEnabled(f.id));
