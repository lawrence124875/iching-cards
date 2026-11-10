import 'ziwei.dart';

/// 64 卦主題標籤（宜進／宜守／人際／財務），交叉頁比對三方主題用。
/// 初稿給 Lawrence 審（/mnt/project-files/reviews/eastern-theme-table.csv）；改這裡即可。
const Map<int, LifeTheme> hexagramTheme = {
  1: LifeTheme.advance, 2: LifeTheme.hold, 3: LifeTheme.hold, 4: LifeTheme.hold, // 乾、坤、屯、蒙
  5: LifeTheme.hold, 6: LifeTheme.people, 7: LifeTheme.advance, 8: LifeTheme.people, // 需、訟、師、比
  9: LifeTheme.money, 10: LifeTheme.hold, 11: LifeTheme.advance, 12: LifeTheme.hold, // 小畜、履、泰、否
  13: LifeTheme.people, 14: LifeTheme.money, 15: LifeTheme.people, 16: LifeTheme.advance, // 同人、大有、謙、豫
  17: LifeTheme.people, 18: LifeTheme.advance, 19: LifeTheme.advance, 20: LifeTheme.hold, // 隨、蠱、臨、觀
  21: LifeTheme.advance, 22: LifeTheme.people, 23: LifeTheme.hold, 24: LifeTheme.advance, // 噬嗑、賁、剝、復
  25: LifeTheme.hold, 26: LifeTheme.money, 27: LifeTheme.hold, 28: LifeTheme.hold, // 无妄、大畜、頤、大過
  29: LifeTheme.hold, 30: LifeTheme.people, 31: LifeTheme.people, 32: LifeTheme.hold, // 坎、離、咸、恆
  33: LifeTheme.hold, 34: LifeTheme.advance, 35: LifeTheme.advance, 36: LifeTheme.hold, // 遯、大壯、晉、明夷
  37: LifeTheme.people, 38: LifeTheme.people, 39: LifeTheme.hold, 40: LifeTheme.advance, // 家人、睽、蹇、解
  41: LifeTheme.money, 42: LifeTheme.money, 43: LifeTheme.advance, 44: LifeTheme.people, // 損、益、夬、姤
  45: LifeTheme.people, 46: LifeTheme.advance, 47: LifeTheme.hold, 48: LifeTheme.money, // 萃、升、困、井
  49: LifeTheme.advance, 50: LifeTheme.advance, 51: LifeTheme.advance, 52: LifeTheme.hold, // 革、鼎、震、艮
  53: LifeTheme.advance, 54: LifeTheme.people, 55: LifeTheme.money, 56: LifeTheme.hold, // 漸、歸妹、豐、旅
  57: LifeTheme.people, 58: LifeTheme.people, 59: LifeTheme.people, 60: LifeTheme.money, // 巽、兌、渙、節
  61: LifeTheme.people, 62: LifeTheme.hold, 63: LifeTheme.hold, 64: LifeTheme.advance, // 中孚、小過、既濟、未濟
};

/// 查不到時當「宜守」。
LifeTheme themeOfHexagram(int n) => hexagramTheme[n] ?? LifeTheme.hold;
