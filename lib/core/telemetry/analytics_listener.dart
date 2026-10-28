import 'dart:async';

import '../events/event_bus.dart';
import 'analytics.dart';

/// 事件匯流排的「旁觀者」（§9 第 6 項）：把 App 事件轉成統計事件。
/// 只送功能使用情形的代碼與數字，不送任何使用者輸入的文字（§13）。
class AnalyticsListener {
  AnalyticsListener(EventBus events, this._analytics) {
    _sub = events.on<AppEvent>().listen(_handle);
  }

  final Analytics _analytics;
  late final StreamSubscription<AppEvent> _sub;

  /// 事件 → 統計事件名稱與參數；認不得的事件不送。可單獨測試。
  static (String, Map<String, Object>)? describe(AppEvent e) => switch (e) {
        ReadingShown r => (
            'qg_reading_shown',
            {'method': r.methodId, 'hexagram': r.primary, 'has_changed': r.changed == null ? 0 : 1},
          ),
        JournalSaved j => ('qg_journal_saved', {'has_reminder': j.hasReminder ? 1 : 0}),
        BreathStarted b => (
            'qg_breath_started',
            {'hexagram': b.hexagram, 'minutes': b.minutes, 'silent': b.silent ? 1 : 0, 'binaural': b.binaural ? 1 : 0},
          ),
        BreathCompleted b => ('qg_breath_completed', {'hexagram': b.hexagram, 'minutes': b.minutes}),
        // 付費漏斗（HANDOFF §2.1）；與智慧聽覺巡航共用 Firebase，一律 qg_ 前綴區分
        FirstCast _ => ('qg_first_cast', const <String, Object>{}),
        HitFreeLimit h => ('qg_hit_free_limit', {'type': h.type}),
        RewardedAdShown r => ('qg_rewarded_ad_shown', {'source': r.source, 'rewarded': r.rewarded ? 1 : 0}),
        RewardedAdFailed r => ('qg_rewarded_ad_failed', {'source': r.source}),
        InterstitialShown _ => ('qg_interstitial_shown', const <String, Object>{}),
        InterstitialFailed i => ('qg_interstitial_failed', {'reason': i.reason}),
        PaywallShown p => ('qg_paywall_view', {'source': p.source}),
        TrialStarted t => ('qg_trial_start', {'period': t.period}),
        Subscribed s => ('qg_purchase', {'period': s.period}),
        Restored _ => ('qg_restore', const <String, Object>{}),
        _ => null,
      };

  void _handle(AppEvent e) {
    final d = describe(e);
    if (d != null) _analytics.log(d.$1, d.$2);
  }

  Future<void> dispose() => _sub.cancel();
}
