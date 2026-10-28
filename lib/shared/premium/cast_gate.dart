import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/events/event_bus.dart';
import '../../core/monetization/ad_service.dart';
import '../../core/monetization/cast_quota.dart';
import '../../l10n/l10n.dart';
import 'paywall_page.dart';

/// 可以起卦（[ensureCanCast] 的結果）。
class CastPass {
  const CastPass({required this.interstitial});

  /// 今天第一次免費起卦：顯示解讀前要先播插頁（[pauseBeforeReading]）。
  final bool interstitial;
}

/// 起卦前呼叫（抽一卦翻牌、三枚銅錢第一擲）。可以起卦就回傳 [CastPass]，並已記一次；不行回傳 null。
/// 免費版規則（HANDOFF §2.1）：每天 1 次，看獎勵廣告再 1 次（廣告失敗也給）；都用完直接開訂閱頁。
Future<CastPass?> ensureCanCast(BuildContext context) async {
  final s = AppServices.of(context);
  if (s.isPremium) {
    await _record(s, counted: false);
    return const CastPass(interstitial: false);
  }
  final allowance = await s.quota.check();
  if (allowance == CastAllowance.free) {
    final dailyFree = await _record(s);
    if (dailyFree) s.ads.preloadInterstitial(); // 翻牌、擲錢的時間拿來載入
    return CastPass(interstitial: dailyFree);
  }
  s.events.emit(const HitFreeLimit(type: 'cast'));
  if (!context.mounted) return null;
  if (allowance == CastAllowance.exhausted) return _paywall(context);
  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // 手機橫放時面板矮，內容改可捲動
    builder: (ctx) => const _LimitSheet(),
  );
  if (!context.mounted) return null;
  switch (choice) {
    case _Choice.watch:
      final outcome = await s.ads.showRewarded();
      switch (outcome) {
        case RewardedOutcome.earned:
          s.events.emit(const RewardedAdShown(source: 'cast', rewarded: true));
        case RewardedOutcome.dismissed:
          s.events.emit(const RewardedAdShown(source: 'cast', rewarded: false));
          return null; // 中途關掉不給
        case RewardedOutcome.failed:
          s.events.emit(const RewardedAdFailed(source: 'cast')); // 載入失敗、無填充：照樣給這一次
      }
      await s.quota.grantReward();
      if (await s.quota.check() != CastAllowance.free) return null;
      await _record(s);
      return const CastPass(interstitial: false); // 獎勵換來的那一次不再播插頁
    case _Choice.subscribe:
      return _paywall(context);
    case null:
      return null;
  }
}

/// 記一次起卦；回傳是否用的是今天的免費次數。
Future<bool> _record(Services s, {bool counted = true}) async {
  final r = await s.quota.recordCast(counted: counted);
  if (r.firstEver) s.events.emit(const FirstCast());
  return r.dailyFree;
}

Future<CastPass?> _paywall(BuildContext context) async {
  final ok = await openPaywall(context, source: 'cast_limit', note: context.l10n.paywallCastLimitNote);
  return ok ? const CastPass(interstitial: false) : null;
}

/// 每天第一次免費起卦、顯示解讀前：先出現過場文字「靜心片刻，解讀即將呈現」，再播一則插頁。
/// 插頁載入失敗、無填充或等超過 3 秒就直接回傳（呼叫端接著開解讀頁）。
Future<void> pauseBeforeReading(BuildContext context) async {
  final s = AppServices.of(context);
  if (s.isPremium || !s.ads.enabled) return;
  final nav = Navigator.of(context);
  final load = s.ads.loadInterstitial(timeout: const Duration(seconds: 3));
  final route = PageRouteBuilder<void>(
    opaque: true,
    pageBuilder: (_, __, ___) => const _PausePage(),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
  unawaited(nav.push(route));
  // 文字至少停留一下再播廣告；載入最多等 3 秒（與文字停留同時計算）
  final pause = Future<void>.delayed(const Duration(milliseconds: 1200));
  final loaded = await load;
  await pause;
  if (loaded == AdLoad.ready) {
    final shown = await s.ads.showInterstitial();
    s.events.emit(shown ? const InterstitialShown() : const InterstitialFailed(reason: 'show_failed'));
  } else {
    s.events.emit(InterstitialFailed(reason: loaded.name));
  }
  if (route.isActive) nav.removeRoute(route);
}

class _PausePage extends StatelessWidget {
  const _PausePage();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: false, // 不能返回；廣告結束或失敗時自動關閉
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                context.l10n.castInterstitialPause,
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(color: QianColors.textSub),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Choice { watch, subscribe }

class _LimitSheet extends StatelessWidget {
  const _LimitSheet();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.castLimitTitle, style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l.castLimitBody, style: t.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(context, _Choice.watch), child: Text(l.castWatchAd)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context, _Choice.subscribe), child: Text(l.menuPremium)),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.castComeTomorrow)),
          ],
        ),
      ),
    );
  }
}
