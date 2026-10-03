import 'package:flutter/material.dart';

import '../../app/app_feature.dart';
import '../../core/journal/journal_reminders.dart';
import 'journal_entry_page.dart';
import 'journal_list_page.dart';

/// 卦記：記下抽到的卦與想問的事，事後回顧象與實際發展如何對應（HANDOFF §13）。
final journalFeature = AppFeature(
  id: 'journal',
  label: (l) => l.featureJournal,
  placement: FeaturePlacement.secondary,
  builder: (_) => const JournalListPage(),
  openPayload: (nav, payload) {
    final id = JournalReminders.entryIdFrom(payload);
    if (id == null) return false;
    nav.push(MaterialPageRoute<void>(builder: (_) => JournalEntryPage(entryId: id)));
    return true;
  },
);
