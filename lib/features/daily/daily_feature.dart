import 'package:flutter/material.dart';

import '../../app/app_feature.dart';
import '../../core/reminders/daily_reminder.dart';
import 'daily_page.dart';

/// 今日一卦（0.9.0）：首頁「今日」分頁的大卡進入；每日一卦提醒的通知（payload `daily`）也打開這裡。
/// 遠端開關 `qg_feature_daily`。
final dailyFeature = AppFeature(
  id: 'daily',
  label: (l) => l.dailyTitle,
  placement: FeaturePlacement.none,
  builder: (_) => const DailyPage(),
  openPayload: (nav, payload) {
    if (payload != DailyReminder.payload) return false;
    nav.push(MaterialPageRoute<void>(builder: (_) => const DailyPage()));
    return true;
  },
);
