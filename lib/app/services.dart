import 'dart:math';

import 'package:flutter/widgets.dart';

import '../core/content/asset_content_source.dart';
import '../core/content/content_source.dart';
import '../core/events/event_bus.dart';
import '../core/journal/file_journal_store.dart';
import '../core/journal/journal_store.dart';
import '../core/iching/focus_rule.dart';
import '../core/reminders/local_notification_reminders.dart';
import '../core/reminders/reminder_service.dart';

/// App 共用服務。換實作（內容來源、變爻規則…）只改 Services.standard()。
class Services {
  Services({
    required this.content,
    required this.events,
    required this.focusRule,
    required this.random,
    required this.reminders,
    this.journal,
  });

  factory Services.standard() => Services(
        content: AssetContentSource(locale: 'zh-Hant'),
        events: EventBus(),
        focusRule: const ZhuXiFocusRule(),
        random: Random.secure(),
        reminders: LocalNotificationReminders(),
        journal: FileJournalStore(),
      );

  final ContentSource content;
  final EventBus events;
  final FocusRule focusRule;
  final Random random;
  final ReminderService reminders;

  /// 卦記；為 null 時（拔除卦記功能）解讀頁不顯示「記下這一卦」。
  final JournalStore? journal;
}

class AppServices extends InheritedWidget {
  const AppServices({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppServices>()!.services;

  @override
  bool updateShouldNotify(AppServices oldWidget) => services != oldWidget.services;
}
