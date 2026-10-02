import '../iching/cast_result.dart';

/// 事後的一次回顧：後來發生了什麼、象怎麼對上。
class FollowUp {
  const FollowUp({required this.at, required this.text});

  final DateTime at;
  final String text;

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'text': text};

  factory FollowUp.fromJson(Map<String, dynamic> j) => FollowUp(
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        text: j['text'] as String? ?? '',
      );
}

/// 一筆卦記：抽到的卦、想問的事、當時看到的那一組解讀，以及之後的回顧。
/// 只存在手機裡（HANDOFF §13）。
class JournalEntry {
  JournalEntry({
    required this.id,
    required this.createdAt,
    required this.methodId,
    required List<int> lineValues,
    this.question = '',
    this.readingIndex,
    this.reminderAt,
    List<FollowUp> followUps = const [],
  })  : lineValues = List.unmodifiable(lineValues),
        followUps = List.unmodifiable(followUps);

  factory JournalEntry.fromCast({
    required CastResult cast,
    required DateTime now,
    String question = '',
    int? readingIndex,
    DateTime? reminderAt,
  }) =>
      JournalEntry(
        id: now.microsecondsSinceEpoch.toRadixString(36),
        createdAt: now,
        methodId: cast.methodId,
        lineValues: [for (final l in cast.lines) l.value],
        question: question,
        readingIndex: readingIndex,
        reminderAt: reminderAt,
      );

  final String id;
  final DateTime createdAt;
  final String methodId;

  /// 六爻數值 6/7/8/9，由下而上。
  final List<int> lineValues;
  final String question;

  /// 當時隨機顯示的是第幾組解讀；回顧時顯示同一組。內容尚未撰寫時為 null。
  final int? readingIndex;
  final DateTime? reminderAt;
  final List<FollowUp> followUps;

  CastResult get cast =>
      CastResult(methodId: methodId, lines: [for (final v in lineValues) LineValue.fromValue(v)]);

  /// 通知 id：由建立時間推得，固定不變（取消或改期時用同一個）。
  int get notificationId => (createdAt.millisecondsSinceEpoch ~/ 1000) % 0x7fffffff;

  JournalEntry copyWith({
    String? question,
    DateTime? reminderAt,
    bool clearReminder = false,
    List<FollowUp>? followUps,
  }) =>
      JournalEntry(
        id: id,
        createdAt: createdAt,
        methodId: methodId,
        lineValues: lineValues,
        question: question ?? this.question,
        readingIndex: readingIndex,
        reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
        followUps: followUps ?? this.followUps,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'methodId': methodId,
        'lines': lineValues,
        'question': question,
        if (readingIndex != null) 'readingIndex': readingIndex,
        if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
        'followUps': [for (final f in followUps) f.toJson()],
      };

  /// 寬鬆解析：欄位缺漏給預設值，六爻不合法時回傳 null（略過該筆）。
  static JournalEntry? tryFromJson(Map<String, dynamic> j) {
    final lines = (j['lines'] as List?)?.whereType<int>().toList() ?? const [];
    if (lines.length != 6 || lines.any((v) => v < 6 || v > 9)) return null;
    final created = DateTime.tryParse(j['createdAt'] as String? ?? '');
    if (created == null) return null;
    return JournalEntry(
      id: j['id'] as String? ?? created.microsecondsSinceEpoch.toRadixString(36),
      createdAt: created,
      methodId: j['methodId'] as String? ?? 'simple',
      lineValues: lines,
      question: j['question'] as String? ?? '',
      readingIndex: j['readingIndex'] as int?,
      reminderAt: DateTime.tryParse(j['reminderAt'] as String? ?? ''),
      followUps: [
        for (final f in (j['followUps'] as List? ?? const []))
          if (f is Map<String, dynamic>) FollowUp.fromJson(f),
      ],
    );
  }
}
