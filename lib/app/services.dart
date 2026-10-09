import 'dart:math';

import 'package:flutter/widgets.dart';

import '../core/audio/audio_playback.dart';
import '../core/audio/just_audio_playback.dart';
import '../core/audio/screen_awake.dart';
import '../core/content/asset_content_source.dart';
import '../core/content/content_source.dart';
import '../core/events/event_bus.dart';
import '../core/journal/file_journal_store.dart';
import '../core/onboarding/intro_store.dart';
import '../core/monetization/ad_service.dart';
import '../core/monetization/cast_quota.dart';
import '../core/monetization/free_limits.dart';
import '../core/monetization/premium_service.dart';
import '../core/journal/journal_store.dart';
import '../core/iching/focus_rule.dart';
import '../core/reminders/local_notification_reminders.dart';
import '../core/reminders/reminder_service.dart';
import '../core/soundscape/soundscape_files.dart';
import '../core/telemetry/analytics.dart';
import '../core/telemetry/remote_flags.dart';
import '../core/telemetry/usage_sharing.dart';
import '../l10n/l10n.dart';

/// App 共用服務。換實作（內容來源、變爻規則…）只改 Services.standard()。
class Services {
  Services({
    required this.content,
    required this.events,
    required this.focusRule,
    required this.random,
    required this.reminders,
    this.journal,
    this.breath,
    this.intro,
    this.analytics = const NoopAnalytics(),
    this.flags = const DefaultRemoteFlags(),
    this.usage,
    PremiumService? premium,
    AdService? ads,
    FreeLimits? limits,
    CastQuota? quota,
  })  : premium = premium ?? FreePremium(),
        ads = ads ?? NoAds(),
        limits = limits ?? const FreeLimits(),
        quota = quota ?? CastQuota(limits: limits ?? const FreeLimits(), storage: MemoryQuotaStorage());

  /// [analytics]、[flags]：main.dart 以 Firebase 初始化後傳入（§18）；不傳＝不統計、功能全開。
  factory Services.standard({
    Analytics analytics = const NoopAnalytics(),
    RemoteFlags flags = const DefaultRemoteFlags(),
    PremiumService? premium,
    AdService? ads,
    FreeLimits limits = const FreeLimits(),
    UsageSharing? usage,
  }) =>
      Services(
        content: AssetContentSource(folder: () => L10n.contentFolder),
        events: EventBus(),
        focusRule: const ZhuXiFocusRule(),
        random: Random.secure(),
        reminders: LocalNotificationReminders(
          channelName: () => L10n.current.reminderChannelName,
          channelDescription: () => L10n.current.reminderChannelDescription,
        ),
        journal: FileJournalStore(),
        intro: FileIntroStore(),
        breath: BreathServices(
          files: CachedSoundscapeFiles(),
          playback: JustAudioPlayback(),
          screenAwake: WakelockScreenAwake(),
        ),
        analytics: analytics,
        flags: flags,
        usage: usage,
        premium: premium,
        ads: ads,
        limits: limits,
        quota: CastQuota(limits: limits),
      );

  final ContentSource content;
  final EventBus events;
  final FocusRule focusRule;
  final Random random;
  final ReminderService reminders;

  /// 卦記；為 null 時（拔除卦記功能）解讀頁不顯示「記下這一卦」。
  final JournalStore? journal;

  /// 呼吸音景；為 null 時練習頁直接提供無聲引導。拔除功能請移出註冊表。
  final BreathServices? breath;

  /// 功能介紹是否看過；null＝不自動顯示（測試）。
  final IntroStore? intro;

  /// 使用統計（只由 AnalyticsListener 從事件匯流排轉送，畫面不直接呼叫）。
  final Analytics analytics;

  /// 遠端開關（Firebase Remote Config，§18）。
  final RemoteFlags flags;

  /// 「分享匿名使用統計與當機報告」開關（§18.4）；null＝選單不顯示（測試、沒有 Firebase）。
  final UsageSharing? usage;

  /// 訂閱（§23）。不傳＝永遠免費版、不能購買。
  final PremiumService premium;

  /// 廣告（§23）。不傳＝沒有廣告。訂閱戶由 main.dart 關掉（ads.enabled = false）。
  final AdService ads;

  /// 免費版限制（§23.1，可由 Remote Config 調整）。
  final FreeLimits limits;

  /// 每日起卦次數。
  final CastQuota quota;

  bool get isPremium => premium.isPremium.value;
}

/// 呼吸音景用到的服務（HANDOFF §14）。
class BreathServices {
  BreathServices({required this.files, required this.playback, required this.screenAwake});

  final SoundscapeFiles files;

  /// 全 App 共用一個播放器（背景播放套件只支援單一播放器）；練習結束時 stop()。
  final AudioPlayback playback;
  final ScreenAwake screenAwake;
}

class AppServices extends InheritedWidget {
  const AppServices({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppServices>()!.services;

  @override
  bool updateShouldNotify(AppServices oldWidget) => services != oldWidget.services;
}
