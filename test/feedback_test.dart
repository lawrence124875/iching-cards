import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iching_cards/app/services.dart';
import 'package:iching_cards/core/content/asset_content_source.dart';
import 'package:iching_cards/core/events/event_bus.dart';
import 'package:iching_cards/core/feedback/feedback_sender.dart';
import 'package:iching_cards/core/iching/focus_rule.dart';
import 'package:iching_cards/core/reminders/reminder_service.dart';
import 'package:iching_cards/features/feedback/feedback_page.dart';
import 'package:iching_cards/l10n/l10n.dart';

class _Failing implements FeedbackSender {
  @override
  Future<void> send(FeedbackEntry entry) async => throw Exception('offline');
}

Widget _app(FeedbackSender sender, {Locale locale = const Locale('zh', 'TW')}) => AppServices(
      services: Services(
        content: AssetContentSource(folder: () => L10n.contentFolder),
        events: EventBus(),
        focusRule: const ZhuXiFocusRule(),
        random: Random(1),
        reminders: NoopReminderService(),
        feedback: sender,
      ),
      child: MaterialApp(
        locale: locale,
        supportedLocales: [for (final l in AppLanguages.all) l.locale],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => openFeedback(context), child: const Text('open')),
          ),
        ),
      ),
    );

void main() {
  group('意見回饋', () {
    testWidgets('空白不送出；填寫後送出類型、內容、信箱與語言，關閉頁面', (tester) async {
      final sender = MemoryFeedbackSender();
      await tester.pumpWidget(_app(sender));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackPage), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(sender.sent, isEmpty);

      final l = lookupAppLocalizations(const Locale('zh'));
      await tester.tap(find.text(l.feedbackCategoryBug));
      await tester.enterText(find.byType(TextField).first, '  起卦後畫面空白  ');
      await tester.enterText(find.byType(TextField).last, 'a@b.c');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(sender.sent, hasLength(1));
      final e = sender.sent.single;
      expect(e.message, '起卦後畫面空白');
      expect(e.category, FeedbackCategory.bug);
      expect(e.contactEmail, 'a@b.c');
      expect(e.locale, startsWith('zh'));
      expect(find.byType(FeedbackPage), findsNothing);
    });

    testWidgets('送出失敗：留在頁面、內容還在', (tester) async {
      await tester.pumpWidget(_app(_Failing()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'hi');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackPage), findsOneWidget);
      expect(find.text('hi'), findsOneWidget);
    });

    for (final lang in AppLanguages.all) {
      testWidgets('${lang.code}：360×640 不溢出', (tester) async {
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(MemoryFeedbackSender(), locale: lang.locale));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
