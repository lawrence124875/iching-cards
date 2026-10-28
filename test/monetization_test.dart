import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/monetization/ad_service.dart';
import 'package:iching_cards/core/monetization/cast_quota.dart';
import 'package:iching_cards/core/monetization/free_limits.dart';
import 'package:iching_cards/core/monetization/premium_service.dart';

void main() {
  group('每日起卦次數（HANDOFF §2.1：每天 1 次＋獎勵 1 次）', () {
    late DateTime now;
    late MemoryQuotaStorage storage;
    CastQuota quota() => CastQuota(limits: const FreeLimits(), storage: storage, clock: () => now);

    setUp(() {
      now = DateTime(2026, 10, 28, 9);
      storage = MemoryQuotaStorage();
    });

    test('預設：每天免費 1 次、獎勵 1 次（上限 2 次）', () {
      const l = FreeLimits();
      expect(l.castsPerDay, 1);
      expect(l.rewardedPerDay, 1);
      expect(l.journalMax, 10);
    });

    test('免費 1 次 → 需要獎勵 → 獎勵 1 次後用完', () async {
      final q = quota();
      expect(await q.check(), CastAllowance.free);
      final first = await q.recordCast();
      expect(first.dailyFree, isTrue); // 今天第一次免費：解讀前播插頁
      expect(await q.check(), CastAllowance.needsReward);
      await q.grantReward();
      expect(await q.check(), CastAllowance.free);
      final second = await q.recordCast();
      expect(second.dailyFree, isFalse); // 獎勵換來的那次不播插頁
      expect(await q.check(), CastAllowance.exhausted);
    });

    test('跨日（手機當地日期）歸零，且計數存檔（重開 App 仍在）', () async {
      final q = quota();
      await q.recordCast();
      expect(await quota().check(), CastAllowance.needsReward); // 新物件讀存檔
      now = DateTime(2026, 10, 28, 23, 59);
      expect(await quota().check(), CastAllowance.needsReward);
      now = DateTime(2026, 10, 29, 0, 1);
      expect(await quota().check(), CastAllowance.free);
      expect(await quota().freeLeft(), 1);
      expect((await quota().recordCast()).dailyFree, isTrue); // 隔天第一次又會播插頁
    });

    test('第一次起卦只記一次；訂閱戶不扣次數但也算', () async {
      final q = quota();
      final premium = await q.recordCast(counted: false);
      expect(premium.firstEver, isTrue);
      expect(premium.dailyFree, isFalse); // 訂閱戶不播插頁
      expect(await q.check(), CastAllowance.free); // 沒扣次數
      expect((await q.recordCast()).firstEver, isFalse);
      expect((await quota().recordCast(counted: false)).firstEver, isFalse); // 存檔後仍記得
    });

    test('舊版存檔（沒有 ever）視為起過卦，不重送 first_cast', () async {
      storage.data = {'day': '2026-10-20', 'used': 2, 'rewarded': 0};
      expect((await quota().recordCast()).firstEver, isFalse);
    });
  });

  test('遠端數值：qg_ 開頭；不合理的值退回預設；舊插頁頻率參數已移除', () {
    for (final k in FreeLimits.remoteDefaults.keys) {
      expect(k, startsWith('qg_'));
    }
    expect(FreeLimits.remoteDefaults.keys, isNot(contains('qg_interstitial_every')));
    expect(FreeLimits.remoteDefaults['qg_free_casts_per_day'], 1);
    expect(FreeLimits.remoteDefaults['qg_free_rewarded_per_day'], 1);
    final l = FreeLimits.from((k, d) => k == 'qg_free_casts_per_day' ? 0 : (k == 'qg_free_journal_max' ? 20 : d));
    expect(l.castsPerDay, 1); // 0 不合理
    expect(l.journalMax, 20);
  });

  test('沒有廣告時：插頁不可用、獎勵算失敗（照樣給這一次）', () async {
    final ads = NoAds();
    expect(await ads.loadInterstitial(), AdLoad.unavailable);
    expect(await ads.showInterstitial(), isFalse);
    expect(await ads.showRewarded(), RewardedOutcome.failed);
  });

  test('免費試用天數換算', () {
    expect(trialLengthDays('day', 7), 7);
    expect(trialLengthDays('week', 1), 7);
    expect(trialLengthDays('month', 1), 30);
    expect(trialLengthDays('unknown', 3), isNull);
    expect(trialLengthDays('day', 0), isNull);
  });

  test('方案價格只存商店字串，不寫死幣別', () {
    const p = SubscriptionPlan(period: PlanPeriod.yearly, price: '¥3,000', monthlyEquivalent: '¥250', trialDays: 7);
    expect(p.price, '¥3,000');
    expect(p.monthlyEquivalent, '¥250');
    expect(p.trialDays, 7);
  });
}
