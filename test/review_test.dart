import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/events/event_bus.dart';
import 'package:iching_cards/core/monetization/cast_quota.dart';
import 'package:iching_cards/core/review/app_review.dart';
import 'package:iching_cards/core/review/review_prompter.dart';

class _CountingReview implements AppReview {
  int calls = 0;

  @override
  Future<void> request() async => calls++;
}

void main() {
  late EventBus events;
  late _CountingReview review;
  late MemoryQuotaStorage storage;
  late DateTime now;
  late ReviewPrompter prompter;

  setUp(() {
    events = EventBus();
    review = _CountingReview();
    storage = MemoryQuotaStorage();
    now = DateTime(2026, 11, 9);
    prompter = ReviewPrompter(events, review, storage, clock: () => now);
  });

  Future<void> emit(AppEvent e) async {
    events.emit(e);
    await Future<void>.delayed(Duration.zero);
    await prompter.settle();
  }

  test('第 3 次看完解讀才邀請評分，之後 90 天內不再邀請', () async {
    await emit(const ReadingFinished());
    await emit(const ReadingFinished());
    expect(review.calls, 0);
    await emit(const ReadingFinished());
    expect(review.calls, 1);
    now = now.add(const Duration(days: 89));
    await emit(const ReadingFinished());
    await emit(const JournalRevisited());
    expect(review.calls, 1);
    now = now.add(const Duration(days: 1));
    await emit(const JournalRevisited());
    expect(review.calls, 2);
  });

  test('解讀不到 3 次時回看卦記不邀請；ReadingShown 不計數', () async {
    await emit(const ReadingShown(methodId: 'coins', primary: 15));
    await emit(const ReadingFinished());
    await emit(const JournalRevisited());
    expect(review.calls, 0);
    expect(storage.data['readings'], 1);
  });
}
