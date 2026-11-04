import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../core/content/cross_content.dart';
import '../../core/events/event_bus.dart';
import '../../core/journal/journal_entry.dart';
import '../../l10n/l10n.dart';
import '../../reading/section.dart';

/// 卦記回顧的「事後應驗了嗎？」一鍵回饋（應驗／部分／沒有；再按一次取消）。
/// 結果存在卦記（手機）；統計只送 `qg_cross_feedback` 的選項值，不含問題與卦象。
class CrossFeedbackSection extends StatelessWidget {
  const CrossFeedbackSection({super.key, required this.verified, required this.onChanged});

  final String? verified;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => FutureBuilder<CrossContent?>(
        future: crossSource.load(L10n.language.contentFolder),
        builder: (context, snap) {
          final cc = snap.data;
          if (cc == null) return const SizedBox.shrink();
          return Section(
            title: cc.s('feedback', 'question'),
            child: Wrap(spacing: 8, children: [
              for (final v in CrossRecord.verifiedValues)
                ChoiceChip(
                  label: Text(cc.s('feedback', v)),
                  selected: verified == v,
                  onSelected: (on) {
                    final next = on ? v : null;
                    onChanged(next);
                    AppServices.of(context).events.emit(CrossFeedback(verified: next ?? 'none'));
                    if (next != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cc.s('feedback', 'thanks'))));
                    }
                  },
                ),
            ]),
          );
        },
      );
}
