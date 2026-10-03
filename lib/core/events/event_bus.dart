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

class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<T> on<T extends AppEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  void emit(AppEvent event) => _controller.add(event);
}
