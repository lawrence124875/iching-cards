import 'dart:async';

/// 事件只給「旁觀者」（紀錄、統計、評分提醒…）。主流程（起卦→解讀）直接呼叫，不走事件。
abstract class AppEvent {
  const AppEvent();
}

/// 使用者看到一次解讀。
class ReadingShown extends AppEvent {
  const ReadingShown({required this.methodId, required this.primary, this.changed});

  final String methodId;
  final int primary;
  final int? changed;
}

/// 存了一筆卦記（不帶任何文字內容）。
class JournalSaved extends AppEvent {
  const JournalSaved({required this.hasReminder});

  final bool hasReminder;
}

/// 開始一次呼吸練習。
class BreathStarted extends AppEvent {
  const BreathStarted({required this.hexagram, required this.minutes, required this.silent, required this.binaural});

  final int hexagram;
  final int minutes;
  final bool silent;
  final bool binaural;
}

/// 呼吸練習完整做完（從通知列提早停止的不算）。
class BreathCompleted extends AppEvent {
  const BreathCompleted({required this.hexagram, required this.minutes});

  final int hexagram;
  final int minutes;
}

/// 這支手機第一次起卦（統計漏斗起點）。
class FirstCast extends AppEvent {
  const FirstCast();
}

/// 碰到免費版上限（type：cast、journal、breath）。
class HitFreeLimit extends AppEvent {
  const HitFreeLimit({required this.type});

  final String type;
}

/// 獎勵廣告有播放（rewarded：是否看完拿到獎勵）。
class RewardedAdShown extends AppEvent {
  const RewardedAdShown({required this.source, required this.rewarded});

  final String source;
  final bool rewarded;
}

/// 獎勵廣告載入失敗、無填充或播放失敗（仍給這一次）。
class RewardedAdFailed extends AppEvent {
  const RewardedAdFailed({required this.source});

  final String source;
}

/// 解讀前的插頁有播放。
class InterstitialShown extends AppEvent {
  const InterstitialShown();
}

/// 解讀前的插頁沒播成（reason：failed、timeout、unavailable、show_failed），直接顯示解讀。
class InterstitialFailed extends AppEvent {
  const InterstitialFailed({required this.reason});

  final String reason;
}

/// 打開訂閱頁（source：cast_limit、journal_limit、breath、menu、lesson）。
class PaywallShown extends AppEvent {
  const PaywallShown({required this.source});

  final String source;
}

/// 開始免費試用（period：yearly、monthly）。
class TrialStarted extends AppEvent {
  const TrialStarted({required this.period});

  final String period;
}

/// 購買訂閱成功（period：monthly、yearly）。
class Subscribed extends AppEvent {
  const Subscribed({required this.period});

  final String period;
}

/// 恢復購買成功。
class Restored extends AppEvent {
  const Restored();
}

class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<T> on<T extends AppEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  void emit(AppEvent event) => _controller.add(event);
}
