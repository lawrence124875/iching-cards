import 'dart:async';

import '../events/event_bus.dart';
import '../monetization/cast_quota.dart' show QuotaStorage;
import 'app_review.dart';

/// 評分邀請時機（ASO-STRATEGY §4.1）：事件匯流排的旁觀者。
/// - 第 3 次（含以後）看完解讀、離開解讀頁時；或回看一筆較早的卦記、離開該頁時。
/// - 每 [interval]（90 天）最多請求一次；請求後商店決定是否真的顯示。
/// 計數存在本機 `review.json`，不上傳；重裝會歸零（可接受）。
class ReviewPrompter {
  ReviewPrompter(
    EventBus events,
    this._review,
    this._storage, {
    DateTime Function()? clock,
    this.minReadings = 3,
    this.interval = const Duration(days: 90),
  }) : _clock = clock ?? DateTime.now {
    _sub = events.on<AppEvent>().listen(_handle);
  }

  final AppReview _review;
  final QuotaStorage _storage;
  final DateTime Function() _clock;
  final int minReadings;
  final Duration interval;
  late final StreamSubscription<AppEvent> _sub;
  Future<void> _queue = Future.value(); // 事件依序處理，避免同時讀寫檔案

  void _handle(AppEvent e) {
    if (e is ReadingFinished || e is JournalRevisited) {
      _queue = _queue.then((_) => _onCalmMoment(countReading: e is ReadingFinished));
    }
  }

  /// 處理完目前排隊的事件（測試用）。
  Future<void> settle() => _queue;

  Future<void> _onCalmMoment({required bool countReading}) async {
    try {
      final m = await _storage.read();
      var readings = (m['readings'] as num?)?.toInt() ?? 0;
      final lastAsked = (m['lastAsked'] as num?)?.toInt();
      if (countReading) readings++;
      final now = _clock();
      final due = readings >= minReadings &&
          (lastAsked == null || now.difference(DateTime.fromMillisecondsSinceEpoch(lastAsked)) >= interval);
      await _storage.write({'readings': readings, 'lastAsked': due ? now.millisecondsSinceEpoch : lastAsked});
      if (due) await _review.request();
    } catch (_) {
      // 評分邀請失敗不影響使用
    }
  }

  void dispose() => _sub.cancel();
}
