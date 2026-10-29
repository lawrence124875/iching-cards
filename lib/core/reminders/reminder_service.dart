import 'dart:async';

/// 定時提醒介面（平台專屬的通知實作包在後面，iOS 只需補設定，REFERENCE §9.1）。
abstract class ReminderService {
  Future<void> init();

  /// 排定一次性提醒；回傳 false 表示沒有權限或排程失敗。
  /// [askPermission] 為 false 時沒有權限就直接失敗，不跳權限對話框（背景重排用）。
  Future<bool> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    ReminderKind kind = ReminderKind.review,
    bool askPermission = true,
  });

  Future<void> cancel(int id);

  /// 上一次 schedule 失敗的原因；成功時為 null。介面文字由 l10n 的 reminderFailureText 產生。
  ReminderFailure? get lastFailure;

  /// App 開著時使用者點了通知。
  Stream<String> get taps;

  /// App 是被點通知啟動的：取出該通知的 payload（只能取一次）。
  String? takeLaunchPayload();
}

/// 通知類別：卦記回顧（準時）、每日一卦（可延後，不要求「鬧鐘與提醒」權限）。
enum ReminderKind { review, daily }

enum ReminderFailureKind { permissionDenied, initFailed, scheduleFailed, unsupported }

/// 提醒失敗的原因；[detail] 為例外訊息（方便使用者回報）。
class ReminderFailure {
  const ReminderFailure(this.kind, [this.detail = '']);

  final ReminderFailureKind kind;
  final String detail;
}

/// 不做任何事（測試或尚未支援的平台）。
class NoopReminderService implements ReminderService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    ReminderKind kind = ReminderKind.review,
    bool askPermission = true,
  }) async =>
      false;

  @override
  Future<void> cancel(int id) async {}

  @override
  ReminderFailure? get lastFailure => const ReminderFailure(ReminderFailureKind.unsupported);

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  String? takeLaunchPayload() => null;
}
