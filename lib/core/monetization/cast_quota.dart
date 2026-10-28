import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'free_limits.dart';

/// 今天還能不能起卦。
enum CastAllowance {
  /// 免費次數還有（或是訂閱戶）。
  free,

  /// 免費次數用完，但還能看獎勵廣告換一次。
  needsReward,

  /// 免費與獎勵次數都用完，明天再來或訂閱。
  exhausted,
}

/// 一次起卦的紀錄結果（[CastQuota.recordCast]）。
class CastRecord {
  const CastRecord({required this.firstEver, required this.dailyFree});

  /// 這支手機第一次起卦（統計 `qg_first_cast`）。
  final bool firstEver;

  /// 用的是今天的免費次數（不是獎勵換來的、也不是訂閱戶）：解讀前要播插頁（HANDOFF §2.1）。
  final bool dailyFree;
}

/// 每日起卦次數（本機計數，跨日自動歸零；以手機當地日期為準）。
/// 計數只存在本機檔案，不上傳；重裝 App 會歸零，這是可接受的寬鬆。
class CastQuota {
  CastQuota({required this.limits, QuotaStorage? storage, DateTime Function()? clock})
      : _storage = storage ?? FileQuotaStorage(),
        _clock = clock ?? DateTime.now;

  FreeLimits limits;
  final QuotaStorage _storage;
  final DateTime Function() _clock;

  String _day = '';
  int _used = 0; // 今天已起卦次數（含用獎勵換來的）
  int _rewarded = 0; // 今天看獎勵廣告換到的次數
  bool _everCast = false; // 曾經起過卦（不隨日期歸零）
  bool _loaded = false;

  String _today() {
    final n = _clock();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _ensure() async {
    if (!_loaded) {
      final m = await _storage.read();
      _day = m['day'] as String? ?? '';
      _used = (m['used'] as num?)?.toInt() ?? 0;
      _rewarded = (m['rewarded'] as num?)?.toInt() ?? 0;
      // 舊版存檔沒有 ever，但有 day＝以前起過卦（升級的使用者不算第一次）
      _everCast = m['ever'] == true || m.containsKey('day');
      _loaded = true;
    }
    final today = _today();
    if (_day != today) {
      _day = today;
      _used = 0;
      _rewarded = 0;
    }
  }

  Future<void> _persist() =>
      _storage.write({'day': _day, 'used': _used, 'rewarded': _rewarded, 'ever': _everCast});

  /// 可用次數＝免費次數＋今天看廣告換到的次數。
  Future<CastAllowance> check() async {
    await _ensure();
    if (_used < limits.castsPerDay + _rewarded) return CastAllowance.free;
    return _rewarded < limits.rewardedPerDay ? CastAllowance.needsReward : CastAllowance.exhausted;
  }

  /// 今天剩幾次免費（不含獎勵）；顯示用。
  Future<int> freeLeft() async {
    await _ensure();
    final left = limits.castsPerDay + _rewarded - _used;
    return left < 0 ? 0 : left;
  }

  /// 起卦成功時呼叫一次。訂閱戶傳 [counted] = false：不扣次數，只記「曾經起過卦」。
  Future<CastRecord> recordCast({bool counted = true}) async {
    await _ensure();
    final first = !_everCast;
    _everCast = true;
    final dailyFree = counted && _used < limits.castsPerDay;
    if (counted) _used++;
    if (counted || first) await _persist();
    return CastRecord(firstEver: first, dailyFree: dailyFree);
  }

  /// 使用者看完獎勵廣告：多一次起卦。
  Future<void> grantReward() async {
    await _ensure();
    _rewarded++;
    await _persist();
  }
}

abstract class QuotaStorage {
  Future<Map<String, Object?>> read();
  Future<void> write(Map<String, Object?> data);
}

class MemoryQuotaStorage implements QuotaStorage {
  Map<String, Object?> data = {};

  @override
  Future<Map<String, Object?>> read() async => {...data};

  @override
  Future<void> write(Map<String, Object?> d) async => data = {...d};
}

/// 存在 App 文件資料夾的 `quota.json`（與卦記同一個資料夾，不需權限）。
class FileQuotaStorage implements QuotaStorage {
  Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/quota.json');

  @override
  Future<Map<String, Object?>> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      return (jsonDecode(await f.readAsString()) as Map).cast<String, Object?>();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, Object?> data) async {
    try {
      await (await _file()).writeAsString(jsonEncode(data));
    } catch (_) {
      // 寫不進去只會讓計數寬鬆，不影響使用
    }
  }
}
