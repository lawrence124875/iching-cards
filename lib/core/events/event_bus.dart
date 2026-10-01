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

class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<T> on<T extends AppEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  void emit(AppEvent event) => _controller.add(event);
}
