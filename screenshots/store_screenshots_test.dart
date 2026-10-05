// 商店截圖：在雲端／CI 以 App 真實畫面渲染（2026-10-05 起取代手機截圖，HANDOFF §21.2）。
//
// 不是示意圖：畫面全部是 App 本身的 Widget（首頁、抽卦翻牌、解讀頁、擲錢、呼吸、卦記），
// 照使用者操作的順序點按鈕走到該畫面；字型為 App 打包的思源黑體／宋體子集（與實機相同），
// 牌面圖與解讀為 iching-content 匯入的正式內容。只換掉手機才有的部分：
//   - 會員（FreePremium(premium: true)，無廣告、無次數限制）、介面語言由 SCREENSHOT_LANG 指定（預設 en）
//   - 隨機數改成固定序列（抽到 15 謙、解讀第 1 組），每次產出相同
//   - 呼吸音景不出聲：播放器回報固定的播放位置（吸氣中）
//
// 用法（需先像 CI 一樣匯入內容、產生術語表與字型子集，見 screenshots/README.md）：
//   SCREENSHOT_OUT=/某資料夾 [SCREENSHOT_LANG=zh-Hans] flutter test screenshots/store_screenshots_test.dart
// 輸出 raw-01.png…raw-08.png（1080×2400，Redmi 實機比例，順序同 iching-content
// store/screenshots-<語言>/make.py 的 ITEMS），再交給 make.py 排版。
//
// ⚠️ 本 repo 公開：截圖含私人內容，輸出資料夾不可在本 repo 內（.gitignore 也擋 screenshots/out/）。

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/app/app.dart';
import 'package:iching_cards/app/services.dart';
import 'package:iching_cards/core/audio/audio_playback.dart';
import 'package:iching_cards/core/audio/screen_awake.dart';
import 'package:iching_cards/core/content/asset_content_source.dart';
import 'package:iching_cards/core/events/event_bus.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/iching/hexagram_table.dart';
import 'package:iching_cards/core/journal/journal_entry.dart';
import 'package:iching_cards/core/journal/journal_store.dart';
import 'package:iching_cards/core/monetization/ad_service.dart';
import 'package:iching_cards/core/monetization/premium_service.dart';
import 'package:iching_cards/core/reminders/reminder_service.dart';
import 'package:iching_cards/core/soundscape/session_renderer.dart';
import 'package:iching_cards/core/soundscape/soundscape_files.dart';
import 'package:iching_cards/features/breath/breath_page.dart';
import 'package:iching_cards/features/journal/journal_entry_page.dart';
import 'package:iching_cards/l10n/l10n.dart';

/// Redmi 實機（2026-10-04 繁中截圖用的那支）：1080×2400、密度 2.625。
/// 上 100 px 狀態列、下 190 px 三鍵導覽列，與 make.py 的裁切 (100, 2210) 對齊。
const _size = Size(1080, 2400);
const _dpr = 2.625;
const _statusBar = 100.0;
const _navBar = 190.0;

void main() {
  final out = Platform.environment['SCREENSHOT_OUT'] ?? '';
  final langCode = Platform.environment['SCREENSHOT_LANG'] ?? 'en';

  setUpAll(() async {
    await _loadFonts();
  });

  testWidgets('商店截圖（會員）', (tester) async {
    final lang = AppLanguages.byCode(langCode) ?? (throw StateError('不認得的 SCREENSHOT_LANG：$langCode'));
    if (out.isEmpty) {
      markTestSkipped('未設定 SCREENSHOT_OUT');
      return;
    }
    Directory(out).createSync(recursive: true);

    tester.view
      ..physicalSize = _size
      ..devicePixelRatio = _dpr
      ..padding = const FakeViewPadding(top: _statusBar, bottom: _navBar)
      ..viewPadding = const FakeViewPadding(top: _statusBar, bottom: _navBar);
    tester.platformDispatcher.localesTestValue = [lang.locale];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    L10n.language = lang;

    debugDisableShadows = false; // flutter_test 預設關掉陰影；實機有（測試結束前要改回，見最後）
    final journal = MemoryJournalStore();
    await journal.save(_sampleEntry(langCode));
    final playback = _SilentPlayback();
    final services = Services(
      content: AssetContentSource(folder: () => L10n.contentFolder),
      events: EventBus(),
      focusRule: const ZhuXiFocusRule(),
      // 抽卦：nextInt(64)=14 → 第 15 卦謙；解讀：nextInt(1<<30)=0 → 第 1 組。
      // 擲錢：18 次 nextBool（由初爻往上，每爻三枚）→ 9、8、8、7、8、6。
      random: _ScriptedRandom(
        ints: [14, 0, 0],
        bools: [
          for (final coins in const [
            [3, 3, 3], [3, 3, 2], [3, 2, 3], [2, 2, 3], [2, 3, 3], [2, 2, 2], //
          ])
            for (final c in coins) c == 3,
        ],
      ),
      reminders: NoopReminderService(),
      journal: journal,
      breath: BreathServices(files: _NoFiles(), playback: playback, screenAwake: NoopScreenAwake()),
      premium: FreePremium(premium: true),
      ads: NoAds(),
    );

    // 資產清單與內容先在真實非同步中讀好（快取在內容來源裡），畫面一建好就有圖與解讀
    await tester.runAsync(() async {
      await services.content.cardArt(15);
      for (final n in const [15, 46, 51]) {
        await services.content.hexagram(n);
      }
    });

    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: AppServices(services: services, child: const IchingApp()),
    ));
    await _settle(tester);

    Future<void> shot(int n) async {
      await _settle(tester);
      final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await tester.runAsync(() => render.toImage(pixelRatio: _dpr));
      final bytes = await tester.runAsync(() async {
        final data = await image!.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      expect(Size(image!.width.toDouble(), image.height.toDouble()), _size);
      image.dispose();
      final f = File('$out/raw-${n.toString().padLeft(2, '0')}.png')..writeAsBytesSync(bytes!);
      debugPrint('已輸出 ${f.path}');
    }

    NavigatorState nav() => tester.state<NavigatorState>(find.byType(Navigator).first);
    final en = lookupAppLocalizations(lang.locale);

    // 8 首頁（最後輸出，但先截：之後都從首頁進入）
    await shot(8);

    // 1 抽一卦：首頁「Draw a Card」→ 點「翻牌」→ 牌面
    await tester.tap(find.text(en.featureDraw));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, en.drawFlip));
    await _settle(tester, frames: 40);
    await shot(1);

    // 2–4 解讀頁：「View Reading」→ 依序捲到各段落
    await tester.tap(find.widgetWithText(FilledButton, en.viewReading));
    await _settle(tester);
    final reading = (await services.content.hexagram(15))!.readings[0];
    await _scrollTo(tester, find.text(reading.title), top: 8);
    await shot(2);
    await _scrollTo(tester, find.text(en.sectionEastWest), top: 8);
    await shot(3);
    await _scrollTo(tester, find.text(en.sectionAction), top: 8);
    await shot(4);

    // 5 三枚銅錢：回首頁 →「Cast with Three Coins」→ 擲六次
    nav().popUntil((r) => r.isFirst);
    await _settle(tester);
    await tester.tap(find.text(en.featureCoins));
    await _settle(tester);
    for (var i = 1; i <= 6; i++) {
      await tester.tap(find.widgetWithText(FilledButton, en.coinsToss(i)));
      await _settle(tester, frames: 4);
    }
    await shot(5);

    // 6 呼吸音景播放中（謙卦，3 分鐘；播放位置停在第 7 次吸氣的中段）
    nav().popUntil((r) => r.isFirst);
    final qian = HexagramTable.byNumber(15);
    unawaited(nav().push(MaterialPageRoute<void>(
      builder: (_) => BreathPage(
        hexagram: 15,
        spec: SessionSpec(upper: qian.upper, lower: qian.lower, minutes: 3, bells: true),
      ),
    )));
    await _settle(tester);
    await shot(6);

    // 7 卦記單筆頁：首頁「Journal」→ 點那一筆 → 捲到 Looking Back
    nav().popUntil((r) => r.isFirst);
    await _settle(tester);
    await tester.tap(find.text(en.featureJournal));
    await _settle(tester);
    await tester.tap(find.byType(ListTile).first);
    await _settle(tester);
    expect(find.byType(JournalEntryPage), findsOneWidget);
    await shot(7);

    nav().popUntil((r) => r.isFirst); // 關掉呼吸頁的 Ticker 等
    await _settle(tester, frames: 3);
    debugDisableShadows = true;
  });
}

/// 載入 App 打包的字型（照 pubspec.yaml 的 fonts，新增字族不必改這裡）與 Material 圖示字型；flutter_test 預設不載入。
Future<void> _loadFonts() async {
  Future<ByteData> file(String path) async => ByteData.sublistView(File(path).readAsBytesSync());
  final families = <String, List<String>>{};
  String? family;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final f = RegExp(r'^\s*- family:\s*(\S+)').firstMatch(line);
    final a = RegExp(r'^\s*- asset:\s*(\S+)').firstMatch(line);
    if (f != null) family = f.group(1);
    if (a != null && family != null) (families[family] ??= []).add(a.group(1)!);
  }
  families['MaterialIcons'] = [
    '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final p in e.value) {
      if (!File(p).existsSync()) throw StateError('缺少字型 $p（先依 screenshots/README.md 產生字型子集）');
      loader.addFont(file(p));
    }
    await loader.load();
  }
}

/// 讓資產讀取、圖片解碼（真實非同步）與動畫都跑完。
Future<void> _settle(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  // 畫面上的圖片全部解碼完成才截圖
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  final elements = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (var i = 0; i < images.length; i++) {
      await precacheImage(images[i].image, elements[i]);
    }
  });
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// 把 [target] 捲到畫面頂端（AppBar 下方 [top] 邏輯像素）。
Future<void> _scrollTo(WidgetTester tester, Finder target, {double top = 0}) async {
  await tester.scrollUntilVisible(target, 400, scrollable: find.byType(Scrollable).last);
  await _settle(tester, frames: 3);
  final scrollable = Scrollable.of(tester.element(target));
  final box = tester.renderObject<RenderBox>(target);
  final viewport = scrollable.context.findRenderObject()! as RenderBox;
  final dy = box.localToGlobal(Offset.zero, ancestor: viewport).dy - top;
  final pos = scrollable.position;
  pos.jumpTo((pos.pixels + dy).clamp(pos.minScrollExtent, pos.maxScrollExtent));
  await _settle(tester, frames: 3);
}

/// 卦記範例：三枚銅錢起得 46 升、九二變 → 之卦 15 謙；當時看第 1 組解讀；有一則回顧與待提醒。
/// 想問的事與回顧是使用者自己寫的文字，依截圖語言給一份。
const _sampleText = {
  'en': (
    'Should I take on the new project at work, or keep building what I have?',
    'I said yes, but asked to start small. The first two weeks felt like a seed under the soil: '
        'slow, quiet progress. The changing line toward Modesty reminded me not to rush the credit.',
  ),
  'zh-Hant': (
    '要接下公司的新專案，還是繼續把手上的事做紮實？',
    '後來答應了，但先從小範圍做起。頭兩週像種子在土裡，進展慢而安靜；變爻走向謙卦，提醒我不急著爭功。',
  ),
  'zh-Hans': (
    '要接下公司的新项目，还是继续把手上的事做扎实？',
    '后来答应了，但先从小范围做起。头两周像种子在土里，进展慢而安静；变爻走向谦卦，提醒我不急着争功。',
  ),
  'ja': (
    '職場の新しいプロジェクトを引き受けるべきか、いまの仕事をもっと固めるべきか？',
    '結局引き受けたけれど、小さな範囲から始めることにした。最初の二週間は土の中の種のようで、進みは遅く静かだった。変爻が謙へ向かうのを見て、手柄を急がないようにと思い出した。',
  ),
  'ko': (
    '회사의 새 프로젝트를 맡아야 할까, 아니면 지금 하는 일을 더 단단히 다져야 할까?',
    '결국 맡았지만 작은 범위부터 시작하기로 했다. 처음 두 주는 흙 속의 씨앗처럼 더디고 조용히 나아갔다. 변효가 겸괘로 향하는 것을 보고 공을 서두르지 말자고 다시 떠올렸다.',
  ),
};

JournalEntry _sampleEntry(String lang) {
  final now = DateTime.now();
  final created = DateTime(now.year, now.month, now.day, 21, 12).subtract(const Duration(days: 12));
  final (question, review) = _sampleText[lang] ?? _sampleText['en']!;
  return JournalEntry(
    id: 'sample',
    createdAt: created,
    methodId: 'coins',
    lineValues: const [8, 9, 7, 8, 8, 8],
    question: question,
    readingIndex: 0,
    reminderAt: DateTime(now.year, now.month, now.day, 9).add(const Duration(days: 9)),
    followUps: [FollowUp(at: created.add(const Duration(days: 10)), text: review)],
  );
}

/// 固定序列的亂數，讓每次產出的截圖相同。
class _ScriptedRandom implements Random {
  _ScriptedRandom({required List<int> ints, required List<bool> bools})
      : _ints = [...ints],
        _bools = [...bools];

  final List<int> _ints;
  final List<bool> _bools;

  @override
  int nextInt(int max) => _ints.isEmpty ? 0 : _ints.removeAt(0) % max;

  @override
  bool nextBool() => _bools.isEmpty ? false : _bools.removeAt(0);

  @override
  double nextDouble() => 0.5;
}

class _NoFiles implements SoundscapeFiles {
  @override
  Future<String> prepare(SessionSpec spec) async => 'silent.wav';
}

/// 不出聲的播放器：播放位置固定在 3 秒準備＋6 個完整呼吸（60 秒）＋吸氣 2.6 秒。
class _SilentPlayback implements AudioPlayback {
  final _playing = StreamController<bool>.broadcast();

  @override
  Future<Duration?> load(String filePath,
          {required String id, required String title, String subtitle = '', String? artFilePath}) async =>
      const Duration(minutes: 3, seconds: 8);

  @override
  Future<void> play() async => _playing.add(true);

  @override
  Future<void> pause() async => _playing.add(false);

  @override
  Future<void> stop() async {}

  @override
  Duration get position => const Duration(milliseconds: 3000 + 60000 + 2600);

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  Stream<void> get completed => const Stream.empty();

  @override
  Stream<void> get stoppedExternally => const Stream.empty();
}
