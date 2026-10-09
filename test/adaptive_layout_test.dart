// 大螢幕與橫向版面（2026-10-07）：App 不再鎖直向，Android 16 起平板、摺疊機也會忽略方向限制。
// 在手機直向／橫放（含側邊瀏海）、摺疊機展開、平板直橫向等尺寸走一遍主要畫面，
// 確認沒有版面溢出（RenderFlex overflowed）或其他例外。繁中與阿拉伯文（由右至左）各走一次。
//
// 測試字型（每個字一個方塊）比實際字型寬，這裡過得了，實機只會更寬鬆。

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/app/app.dart';
import 'package:iching_cards/app/services.dart';
import 'package:iching_cards/core/audio/audio_playback.dart';
import 'package:iching_cards/core/audio/screen_awake.dart';
import 'package:iching_cards/core/content/asset_content_source.dart';
import 'package:iching_cards/core/events/event_bus.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/iching/hexagram_table.dart';
import 'package:iching_cards/core/journal/journal_store.dart';
import 'package:iching_cards/core/monetization/ad_service.dart';
import 'package:iching_cards/core/monetization/premium_service.dart';
import 'package:iching_cards/core/reminders/reminder_service.dart';
import 'package:iching_cards/core/soundscape/session_renderer.dart';
import 'package:iching_cards/core/soundscape/soundscape_files.dart';
import 'package:iching_cards/features/breath/breath_page.dart';
import 'package:iching_cards/l10n/l10n.dart';

/// (名稱, 邏輯尺寸, 系統區域)
const _screens = [
  ('手機直向', Size(392, 850), FakeViewPadding(top: 38, bottom: 72)),
  ('手機橫放（瀏海在左）', Size(850, 392), FakeViewPadding(left: 38, bottom: 24)),
  ('小手機橫放', Size(640, 360), FakeViewPadding(left: 24, bottom: 24)),
  ('摺疊機展開', Size(841, 701), FakeViewPadding(top: 32, bottom: 24)),
  ('平板直向', Size(800, 1280), FakeViewPadding(top: 24, bottom: 48)),
  ('平板橫向', Size(1280, 800), FakeViewPadding(top: 24, bottom: 48)),
];

/// 繁中，以及由右至左的阿拉伯文（兩欄版面左右對調）
const _languages = ['zh-Hant', 'ar'];

void main() {
  for (final lang in _languages)
    for (final (name, size, padding) in _screens) {
      testWidgets('版面不溢出：$name（$lang）', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1
          ..padding = padding
          ..viewPadding = padding;
        addTearDown(tester.view.reset);
        L10n.language = AppLanguages.byCode(lang)!;
        tester.platformDispatcher.localesTestValue = [L10n.language.locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        final services = Services(
          content: AssetContentSource(folder: () => L10n.contentFolder),
          events: EventBus(),
          focusRule: const ZhuXiFocusRule(),
          random: Random(15),
          reminders: NoopReminderService(),
          journal: MemoryJournalStore(),
          breath: BreathServices(files: _NoFiles(), playback: _SilentPlayback(), screenAwake: NoopScreenAwake()),
          premium: FreePremium(premium: true),
          ads: NoAds(),
        );
        // 內容先在真實非同步中讀好（快取在內容來源裡），畫面一建好就有解讀
        await tester.runAsync(() async {
          for (var n = 1; n <= 64; n++) {
            await services.content.hexagram(n);
          }
        });
        await tester.pumpWidget(AppServices(services: services, child: const IchingApp()));
        await _settle(tester);
        final l = lookupAppLocalizations(L10n.language.locale);
        NavigatorState nav() => tester.state<NavigatorState>(find.byType(Navigator).first);

        // 首頁 → 抽一卦 → 翻牌 → 解讀（捲到底）
        await tester.tap(find.text(l.featureDraw));
        await _settle(tester);
        await tester.tap(find.widgetWithText(FilledButton, l.drawFlip));
        await _settle(tester);
        await tester.tap(find.widgetWithText(FilledButton, l.viewReading));
        await _settle(tester);
        await tester.fling(find.byType(Scrollable).last, const Offset(0, -6000), 3000);
        await _settle(tester);

        // 三枚銅錢：一次擲完
        nav().popUntil((r) => r.isFirst);
        await _settle(tester);
        await tester.tap(find.text(l.featureCoins));
        await _settle(tester);
        await tester.tap(find.widgetWithText(TextButton, l.coinsTossAll));
        await _settle(tester, frames: 40);

        // 蓍草：說明較長，先看未起卦的版面，再一次演完
        nav().popUntil((r) => r.isFirst);
        await _settle(tester);
        await tester.tap(find.text(l.featureYarrow));
        await _settle(tester);
        await tester.tap(find.widgetWithText(TextButton, l.yarrowAll));
        await _settle(tester, frames: 40);

        // 呼吸音景
        nav().popUntil((r) => r.isFirst);
        final qian = HexagramTable.byNumber(15);
        unawaited(nav().push(MaterialPageRoute<void>(
          builder: (_) => BreathPage(
            hexagram: 15,
            spec: SessionSpec(upper: qian.upper, lower: qian.lower, minutes: 3, bells: true),
          ),
        )));
        await _settle(tester);

        nav().popUntil((r) => r.isFirst); // 關掉呼吸頁的 Ticker 等
        await _settle(tester, frames: 3);
      });
    }
}

/// 讓資產讀取（真實非同步）與動畫跑完；每一格都檢查有沒有版面例外。
Future<void> _settle(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 50));
    final error = tester.takeException();
    expect(error, isNull, reason: error is FlutterError ? error.toStringDeep() : null);
  }
}

class _NoFiles implements SoundscapeFiles {
  @override
  Future<String> prepare(SessionSpec spec) async => 'silent.wav';
}

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
  Duration get position => const Duration(seconds: 10);

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  Stream<void> get completed => const Stream.empty();

  @override
  Stream<void> get stoppedExternally => const Stream.empty();
}
