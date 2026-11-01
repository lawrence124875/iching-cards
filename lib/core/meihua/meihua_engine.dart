import '../iching/trigram.dart';
import 'lunar_moment.dart';
import 'meihua_cast.dart';

/// 梅花易數起卦（邵雍《梅花易數》）。純計算、不碰介面，單元測試見 test/meihua_test.dart。
class MeihuaEngine {
  MeihuaEngine._();

  /// 先天八卦數：乾1 兌2 離3 震4 巽5 坎6 艮7 坤8。
  static const xiantian = [
    Trigram.qian, Trigram.dui, Trigram.li, Trigram.zhen,
    Trigram.xun, Trigram.kan, Trigram.gen, Trigram.kun,
  ];

  /// 數除以 8 取餘（整除為坤）對應的先天卦。
  static Trigram trigramOf(int n) => xiantian[_mod(n, 8) - 1];

  /// 先天數（1–8）。
  static int numberOf(Trigram t) => xiantian.indexOf(t) + 1;

  /// 數除以 6 取餘（整除為上爻）。
  static int lineOf(int n) => _mod(n, 6);

  static int _mod(int n, int m) {
    final r = n % m;
    return r == 0 ? m : r;
  }

  /// 時間起卦：年支數＋月＋日 → 上卦；再加時支數 → 下卦，總數 → 動爻。
  static MeihuaCast byTime(LunarMoment m) {
    final upperSum = m.yearNumber + m.month + m.day;
    final total = upperSum + m.hourNumber;
    return MeihuaCast(
      method: MeihuaMethod.time,
      upper: trigramOf(upperSum),
      lower: trigramOf(total),
      movingLine: lineOf(total),
      monthBranch: m.monthBranch,
    );
  }

  /// 數字起卦：第一個數 → 上卦，第二個數 → 下卦，兩數加時支數 → 動爻。
  static MeihuaCast byNumbers(int first, int second, LunarMoment m) {
    assert(first > 0 && second > 0);
    return MeihuaCast(
      method: MeihuaMethod.number,
      upper: trigramOf(first),
      lower: trigramOf(second),
      movingLine: lineOf(first + second + m.hourNumber),
      monthBranch: m.monthBranch,
    );
  }

  /// 字數起卦：字數平分，前半（奇數時少一字）→ 上卦，後半 → 下卦，總字數 → 動爻。
  /// 一個字時上下卦同數。
  static MeihuaCast byWordCount(int count, LunarMoment m) {
    assert(count > 0);
    final upperCount = count == 1 ? 1 : count ~/ 2;
    final lowerCount = count == 1 ? 1 : count - upperCount;
    return MeihuaCast(
      method: MeihuaMethod.wordCount,
      upper: trigramOf(upperCount),
      lower: trigramOf(lowerCount),
      movingLine: lineOf(count),
      monthBranch: m.monthBranch,
    );
  }

  /// 字數：中日文字一字算一個，其他語言以空白分隔的詞算一個；標點不算。
  static int countWords(String text) {
    var n = 0;
    final latin = StringBuffer();
    void flush() {
      if (latin.isNotEmpty) n++;
      latin.clear();
    }

    for (final r in text.runes) {
      if (_isCjk(r)) {
        flush();
        n++;
      } else if (_isWordChar(r)) {
        latin.writeCharCode(r);
      } else {
        flush();
      }
    }
    flush();
    return n;
  }

  static bool _isCjk(int r) =>
      (r >= 0x4E00 && r <= 0x9FFF) ||
      (r >= 0x3400 && r <= 0x4DBF) ||
      (r >= 0x20000 && r <= 0x2EBEF) ||
      (r >= 0x3040 && r <= 0x30FF); // 假名（韓文以空白分詞，算詞）

  static bool _isWordChar(int r) {
    final s = String.fromCharCode(r);
    return RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true).hasMatch(s);
  }
}
