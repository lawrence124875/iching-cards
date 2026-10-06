import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/app/app.dart';
import 'package:iching_cards/app/services.dart';
import 'package:iching_cards/core/content/asset_content_source.dart';
import 'package:iching_cards/core/events/event_bus.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/iching/hexagram_table.dart';
import 'package:iching_cards/core/onboarding/intro_store.dart';
import 'package:iching_cards/core/reminders/reminder_service.dart';
import 'package:iching_cards/features/intro/intro_page.dart';
import 'package:iching_cards/features/share/share.dart';
import 'package:iching_cards/l10n/l10n.dart';

Services _services({IntroStore? intro}) => Services(
      content: AssetContentSource(folder: () => L10n.contentFolder),
      events: EventBus(),
      focusRule: const ZhuXiFocusRule(),
      random: Random(1),
      reminders: NoopReminderService(),
      intro: intro,
    );

void main() {
  group('功能介紹', () {
    testWidgets('首次開啟顯示四頁，看完記為已看過', (tester) async {
      final store = MemoryIntroStore();
      await tester.pumpWidget(AppServices(services: _services(intro: store), child: const IchingApp()));
      await tester.pumpAndSettle();
      expect(find.byType(IntroPage), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(FilledButton)); // 最後一頁：開始使用
      await tester.pumpAndSettle();
      expect(find.byType(IntroPage), findsNothing);
      expect(store.value, isTrue);
    });

    testWidgets('看過就不再自動顯示', (tester) async {
      await tester
          .pumpWidget(AppServices(services: _services(intro: MemoryIntroStore(value: true)), child: const IchingApp()));
      await tester.pumpAndSettle();
      expect(find.byType(IntroPage), findsNothing);
    });

    testWidgets('略過也記為已看過', (tester) async {
      final store = MemoryIntroStore();
      await tester.pumpWidget(AppServices(services: _services(intro: store), child: const IchingApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(IntroPage), findsNothing);
      expect(store.value, isTrue);
    });
  });

  group('分享卡片', () {
    for (final lang in AppLanguages.all) {
      testWidgets('${lang.code}：卡片與介紹頁排版不溢出', (tester) async {
        L10n.language = lang;
        Widget app(Widget home) => AppServices(
              services: _services(),
              child: MaterialApp(
                locale: lang.locale,
                supportedLocales: [for (final l in AppLanguages.all) l.locale],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: home,
              ),
            );
        await tester.pumpWidget(app(Scaffold(
          body: Center(
            child: FittedBox(
              child: ShareCard(
                info: HexagramTable.byNumber(15),
                title: 'W' * 60,
                image: 'W ' * 400,
              ),
            ),
          ),
        )));
        await tester.pump();
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(360 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(const IntroPage()));
        for (var i = 0; i < 4; i++) {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (i < 3) await tester.tap(find.byType(FilledButton));
        }
      });
    }
  });
}
