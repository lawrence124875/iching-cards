import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/core/eastern/birth_profile.dart';
import 'package:iching_cards/core/eastern/ziwei.dart';
import 'package:iching_cards/core/journal/journal_entry.dart';

/// 已知命盤：由開源排盤 iztro 2.6.5（預設設定）產生，與本實作另外比對過 3000 組隨機生辰全數一致。
const fixtures = [
  // 2000-8-16 寅時 → 農曆 2000-7-17，木三局
  (stem: 6, month: 7, leap: false, day: 17, hour: 2, ming: 6, shen: 10, ju: 3, pos: {'wuqu':2,'tianxiang':2,'taiyang':3,'tianliang':3,'qisha':4,'youbi':4,'tianji':5,'ziwei':6,'wenqu':6,'pojun':8,'wenchang':8,'lianzhen':10,'tianfu':10,'zuofu':10,'taiyin':11,'tanlang':0,'tiantong':1,'jumen':1}),
  // 1985-3-21 未時 → 農曆 1985-2-1，水二局
  (stem: 1, month: 2, leap: false, day: 1, hour: 7, ming: 8, shen: 10, ju: 2, pos: {'tianfu':3,'wenchang':3,'taiyin':4,'lianzhen':5,'tanlang':5,'zuofu':5,'jumen':6,'tianxiang':7,'tiantong':8,'tianliang':8,'wuqu':9,'qisha':9,'youbi':9,'taiyang':10,'wenqu':11,'tianji':0,'ziwei':1,'pojun':1}),
  // 1993-6-30 亥時 → 農曆 1993-5-11，火六局
  (stem: 9, month: 5, leap: false, day: 11, hour: 11, ming: 7, shen: 5, ju: 6, pos: {'ziwei':2,'tianfu':2,'taiyin':3,'wenqu':3,'tanlang':4,'jumen':5,'lianzhen':6,'tianxiang':6,'youbi':6,'tianliang':7,'qisha':8,'zuofu':8,'tiantong':9,'wuqu':10,'taiyang':11,'wenchang':11,'pojun':0,'tianji':1}),
  // 2023-4-5 子時 → 農曆 2023-閏2-15（15 日以前算本月），水二局
  (stem: 9, month: 2, leap: true, day: 15, hour: 0, ming: 3, shen: 3, ju: 2, pos: {'qisha':2,'tiantong':3,'wuqu':4,'wenqu':4,'taiyang':5,'zuofu':5,'pojun':6,'tianji':7,'ziwei':8,'tianfu':8,'taiyin':9,'youbi':9,'tanlang':10,'wenchang':10,'jumen':11,'lianzhen':0,'tianxiang':0,'tianliang':1}),
];

void main() {
  group('紫微安星（已知命盤）', () {
    for (final f in fixtures) {
      test('stem ${f.stem} ${f.leap ? '閏' : ''}${f.month} 月 ${f.day} 日 時辰 ${f.hour}', () {
        final c = ZiweiChart.compute(yearStem: f.stem, month: f.month, leap: f.leap, day: f.day, hour: f.hour);
        expect(c.ming, f.ming, reason: '命宮');
        expect(c.shen, f.shen, reason: '身宮');
        expect(c.ju, f.ju, reason: '五行局');
        expect(c.positions, f.pos);
      });
    }

    test('閏月 16 日起算下個月：2020 閏四月二十 巳時 → 命宮丑、火六局、紫微在酉', () {
      final c = ZiweiChart.compute(yearStem: 6, month: 4, leap: true, day: 20, hour: 5);
      expect(c.ming, 1);
      expect(c.ju, 6);
      expect(c.positions['ziwei'], 9);
    });

    test('紫微位置表：水二局初一在丑、初二在寅；木三局初一在辰', () {
      expect(ZiweiChart.ziweiPosition(1, 2), 1);
      expect(ZiweiChart.ziweiPosition(2, 2), 2);
      expect(ZiweiChart.ziweiPosition(1, 3), 4);
      expect(ZiweiChart.ziweiPosition(2, 3), 1);
      expect(ZiweiChart.ziweiPosition(3, 3), 2);
    });

    test('四化表：每干四顆星', () {
      for (var s = 0; s < 10; s++) {
        expect(sihuaOf(s).length, 4);
      }
      expect(sihuaOf(6), {'taiyang': Sihua.lu, 'wuqu': Sihua.quan, 'taiyin': Sihua.ke, 'tiantong': Sihua.ji});
    });
  });

  group('流年趨勢與主題', () {
    final c = ZiweiChart.compute(yearStem: 6, month: 7, day: 17, hour: 2); // 庚年生
    test('丙午年：流年命宮午（紫微、文曲）無四化 → 平、宜進', () {
      final y = c.year(stem: 2, branch: 6);
      expect(y.sihuaInPalace, isEmpty);
      expect(y.trend, YearTrend.even);
      expect(y.theme, LifeTheme.advance);
    });
    test('甲寅年：武曲生年化權＋流年化科 → 順、財務', () {
      final y = c.year(stem: 0, branch: 2);
      expect(y.trend, YearTrend.pos);
      expect(y.theme, LifeTheme.money);
    });
    test('丙戌年：廉貞流年化忌 → 阻、人際', () {
      final y = c.year(stem: 2, branch: 10);
      expect(y.trend, YearTrend.neg);
      expect(y.theme, LifeTheme.people);
    });
    test('丁未年：未宮空、借丑宮天同巨門；忌與權都見 → 平', () {
      final y = c.year(stem: 3, branch: 7);
      expect(y.majors.borrowed, isTrue);
      expect(y.majors.stars, [MajorStar.tiantong, MajorStar.jumen]);
      expect(y.trend, YearTrend.even);
      expect(y.theme, LifeTheme.hold);
    });
  });

  group('生辰換算', () {
    test('2000-08-16 04:00 → 庚年七月十七寅時，命宮午、木三局', () {
      final c = const BirthProfile(year: 2000, month: 8, day: 16, hour: 4).ziwei()!;
      expect(c.yearStem, 6);
      expect(c.month, 7);
      expect(c.hour, 2);
      expect(c.ming, 6);
      expect(c.ju, 3);
    });
    test('不知道時辰不排紫微', () {
      expect(const BirthProfile(year: 2000, month: 8, day: 16).ziwei(), isNull);
    });
    test('流年以農曆正月初一換年：2026-02-16 仍是乙巳、02-17 起丙午', () {
      expect(ziweiYearAt(DateTime(2026, 2, 16, 12)).branch, 5);
      expect(ziweiYearAt(DateTime(2026, 2, 17, 12)), (year: 2026, stem: 2, branch: 6));
    });
    test('存讀', () {
      const p = BirthProfile(year: 1990, month: 5, day: 20, hour: 8, minute: 30, cityId: 'taipei');
      final q = BirthProfile.fromJson(p.toJson());
      expect(q.toJson(), p.toJson());
    });
  });

  group('卦記：命理卡片', () {
    test('紫微卡沒有六爻也能讀回；舊版不認得的沒有六爻紀錄仍略過', () {
      final e = JournalEntry(
        id: 'x',
        createdAt: DateTime(2026, 11, 10),
        methodId: 'ziwei',
        lineValues: const [],
        eastern: EasternRecord(birth: const BirthProfile(year: 1990, month: 5, day: 20, hour: 8).toJson(), systems: const ['ziwei']),
      );
      final back = JournalEntry.tryFromJson(e.toJson())!;
      expect(back.isCard, isTrue);
      expect(back.labelKey, 'ziwei');
      expect(back.eastern!.birth['y'], 1990);
      expect(JournalEntry.tryFromJson({...e.toJson(), 'eastern': null}), isNull);
    });
    test('交叉紀錄依用到的系統數標示三／四系統', () {
      JournalEntry cross(List<String> systems) => JournalEntry(
            id: 'c',
            createdAt: DateTime(2026, 11, 10),
            methodId: 'cross',
            lineValues: const [7, 7, 7, 8, 8, 8],
            eastern: EasternRecord(birth: const {'y': 1990, 'm': 1, 'd': 1}, systems: systems),
          );
      expect(cross(['ziwei']).labelKey, 'cross3');
      expect(cross(['ziwei', 'bazi']).labelKey, 'cross4');
      expect(JournalEntry.tryFromJson(cross(['bazi']).toJson())!.labelKey, 'cross3');
    });
  });
}
