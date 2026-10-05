import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/feature_registry.dart';
import 'app/services.dart';
import 'core/audio/just_audio_playback.dart';
import 'core/admob/admob_ads.dart';
import 'core/firebase/firebase_telemetry.dart';
import 'core/monetization/ad_service.dart';
import 'core/monetization/free_limits.dart';
import 'core/revenuecat/revenuecat_premium.dart';
import 'core/telemetry/analytics_listener.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase（Analytics、Crashlytics、Remote Config，HANDOFF §18）放最前面，才接得到啟動中的當機；
  // 失敗不影響 App（統計不送、遠端開關全照預設）。
  final telemetry = await FirebaseTelemetry.init(featureIds: registeredFeatures.map((f) => f.id));
  _registerFontLicenses();
  // 卦卡為 9:16 直式設計，固定直向（HANDOFF §11.2）。
  // Android 另在 AndroidManifest 設定 screenOrientation，避免啟動瞬間閃成橫向。
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // 呼吸音景的背景播放與通知控制；失敗不影響其他功能
  // 通知類別名稱跟著手機語言（L10n 在 MaterialApp 決定語言前先依手機設定判斷）
  final l = L10n.current;
  await JustAudioPlayback.initBackground(channelName: l.breathChannelName, album: l.appTitle);
  // 訂閱與廣告（HANDOFF §23）：訂閱戶不載入任何廣告；廣告同意表單在 runApp 之後才跑，不拖慢啟動
  final limits = FreeLimits.from(telemetry.flags.intValue);
  final premium = await RevenueCatPremium.init();
  final ads = AdMobAds.create(
    pacer: InterstitialPacer(
      every: limits.interstitialEvery,
      minGap: Duration(minutes: limits.interstitialGapMinutes),
    ),
  );
  var appStarted = false;
  void syncAds() {
    ads.enabled = !premium.isPremium.value;
    if (appStarted && ads.enabled) unawaited(ads.start()); // 只會真的執行一次
  }
  premium.isPremium.addListener(syncAds);
  syncAds();
  final services = Services.standard(
    analytics: telemetry.analytics,
    flags: telemetry.flags,
    premium: premium,
    ads: ads,
    limits: limits,
  );
  AnalyticsListener(services.events, services.analytics); // 全 App 存活期間都在，不需 dispose
  await services.reminders.init(); // 不拋例外；失敗時提醒功能停用
  runApp(AppServices(services: services, child: const IchingApp()));
  appStarted = true;
  syncAds();
}

/// 思源黑體／宋體為 SIL OFL 1.1，散布時須附授權全文（顯示於系統授權頁）。
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final name in ['NotoSansTC', 'NotoSerifTC', 'NotoSansSC', 'NotoSerifSC']) {
      final text = await rootBundle.loadString('assets/licenses/$name-OFL.txt');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
