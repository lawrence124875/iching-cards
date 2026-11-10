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
/// 只存在手機裡（REFERENCE §13）。
/// 雙卦交叉紀錄（HANDOFF §2.4）：同一問題的梅花時間起卦（六爻數值＋當時月令），以及事後回饋。
/// 主卦（[JournalEntry.lineValues]）是易經三錢起卦。
class CrossRecord {
  CrossRecord({required List<int> meihuaLines, required this.monthBranch, this.verified})
      : meihuaLines = List.unmodifiable(meihuaLines);

  /// 梅花本卦六爻（6/7/8/9，一個動爻），由下而上。
  final List<int> meihuaLines;

  /// 起卦當時的月令（0＝子 … 11＝亥）。
  final int monthBranch;

  /// 「事後應驗了嗎？」：[verifiedValues] 之一，未回答為 null。只存手機。
  final String? verified;

  static const verifiedValues = ['yes', 'partly', 'no'];

  CrossRecord withVerified(String? v) => CrossRecord(meihuaLines: meihuaLines, monthBranch: monthBranch, verified: v);

  Map<String, dynamic> toJson() => {
        'meihua': meihuaLines,
        'monthBranch': monthBranch,
        if (verified != null) 'verified': verified,
      };

  static CrossRecord? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final lines = (j['meihua'] as List?)?.whereType<int>().toList() ?? const [];
    if (lines.length != 6 || lines.any((v) => v < 6 || v > 9)) return null;
    final m = j['monthBranch'];
    final v = j['verified'];
    return CrossRecord(
      meihuaLines: lines,
      monthBranch: m is int && m >= 0 && m < 12 ? m : 0,
      verified: verifiedValues.contains(v) ? v as String : null,
    );
  }
}

/// 東方命理紀錄（HANDOFF §4-3 C3）：存當時用的出生資料（只在手機與卦記備份檔），以及用到哪些系統。
/// 紫微年度卡（methodId `ziwei`）、八字本月卡（`bazi`）沒有六爻；交叉解讀（`cross`）帶這筆就是三／四系統交叉。
class EasternRecord {
  EasternRecord({required Map<String, dynamic> birth, required List<String> systems})
      : birth = Map.unmodifiable(birth),
        systems = List.unmodifiable(systems);

  /// BirthProfile.toJson()。
  final Map<String, dynamic> birth;

  /// 用到的命理系統：`ziwei`、`bazi`。
  final List<String> systems;

  Map<String, dynamic> toJson() => {'birth': birth, 'systems': systems};

  static EasternRecord? tryFromJson(Object? j) {
    if (j is! Map || j['birth'] is! Map) return null;
    return EasternRecord(
      birth: Map<String, dynamic>.from(j['birth'] as Map),
      systems: [for (final x in (j['systems'] as List? ?? const [])) if (x is String) x],
    );
  }
}

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
    this.cross,
    this.eastern,
  })  : lineValues = List.unmodifiable(lineValues),
        followUps = List.unmodifiable(followUps);

  factory JournalEntry.fromCast({
    required CastResult cast,
    required DateTime now,
    String question = '',
    int? readingIndex,
    DateTime? reminderAt,
    CrossRecord? cross,
    EasternRecord? eastern,
  }) =>
      JournalEntry(
        id: now.microsecondsSinceEpoch.toRadixString(36),
        createdAt: now,
        methodId: cast.methodId,
        lineValues: [for (final l in cast.lines) l.value],
        question: question,
        readingIndex: readingIndex,
        reminderAt: reminderAt,
        cross: cross,
        eastern: eastern,
      );

  /// 命理卡片（紫微年度卡、八字本月卡）：沒有六爻。
  static const cardMethods = {'ziwei', 'bazi'};

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

  /// 雙卦交叉紀錄；一般起卦為 null。
  final CrossRecord? cross;

  /// 東方命理紀錄；沒用到紫微／八字為 null。
  final EasternRecord? eastern;

  /// 命理卡片（沒有六爻，[cast] 不可用）。
  bool get isCard => cardMethods.contains(methodId);

  /// 卦記標示用的種類鍵：`ziwei`、`bazi`、`cross3`、`cross4`，其他照 methodId。
  String get labelKey {
    if (methodId == 'cross' && eastern != null && eastern!.systems.isNotEmpty) {
      return eastern!.systems.length >= 2 ? 'cross4' : 'cross3';
    }
    return methodId;
  }

  CastResult get cast =>
      CastResult(methodId: methodId, lines: [for (final v in lineValues) LineValue.fromValue(v)]);

  /// 通知 id：由建立時間推得，固定不變（取消或改期時用同一個）。
  int get notificationId => (createdAt.millisecondsSinceEpoch ~/ 1000) % 0x7fffffff;

  JournalEntry copyWith({
    String? question,
    DateTime? reminderAt,
    bool clearReminder = false,
    List<FollowUp>? followUps,
    CrossRecord? cross,
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
        cross: cross ?? this.cross,
        eastern: eastern,
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
        if (cross != null) 'cross': cross!.toJson(),
        if (eastern != null) 'eastern': eastern!.toJson(),
      };

  /// 寬鬆解析：欄位缺漏給預設值，六爻不合法時回傳 null（略過該筆）。
  /// 命理卡片沒有六爻（lines 為空），舊版 App 讀到會略過，不會誤顯示成某一卦。
  static JournalEntry? tryFromJson(Map<String, dynamic> j) {
    final lines = (j['lines'] as List?)?.whereType<int>().toList() ?? const [];
    final eastern = EasternRecord.tryFromJson(j['eastern']);
    final card = cardMethods.contains(j['methodId']) && eastern != null && lines.isEmpty;
    if (!card && (lines.length != 6 || lines.any((v) => v < 6 || v > 9))) return null;
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
      cross: CrossRecord.tryFromJson(j['cross']),
      eastern: eastern,
    );
  }
}
