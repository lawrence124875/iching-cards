import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/soundscape/session_renderer.dart';
import 'breath_page.dart';
import 'soundscape_labels.dart';

/// 開始前的設定：時長 1／2／3／5 分鐘、是否要換氣鈴聲。
/// 選擇只在這次開啟 App 期間記住（不另存檔）。
Future<void> showBreathSetup(BuildContext context, int hexagram) async {
  final spec = await showModalBottomSheet<SessionSpec>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QianColors.inkCard,
    builder: (_) => _SetupSheet(hexagram: hexagram),
  );
  if (spec == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => BreathPage(hexagram: hexagram, spec: spec),
  ));
}

class _SetupSheet extends StatefulWidget {
  const _SetupSheet({required this.hexagram});

  final int hexagram;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  static const _choices = [1, 2, 3, 5];
  static int _lastMinutes = 3;
  static bool _lastBells = true;

  int _minutes = _lastMinutes;
  bool _bells = _lastBells;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final info = HexagramTable.byNumber(widget.hexagram);
    final same = info.upper == info.lower;
    final sounds = same
        ? '${info.upper.label}・${info.upper.nature}：${soundscapeName(info.upper)}'
        : '上卦 ${info.upper.label}・${info.upper.nature}：${soundscapeName(info.upper)}\n'
            '下卦 ${info.lower.label}・${info.lower.nature}：${soundscapeName(info.lower)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('呼吸音景・${info.fullName}', style: t.titleMedium),
            const SizedBox(height: 8),
            Text(sounds, style: t.bodyMedium),
            const SizedBox(height: 4),
            Text('吸氣 4 秒、吐氣 6 秒（每分鐘 6 次）。音景會跟著呼吸起伏。', style: t.bodySmall),
            const SizedBox(height: 20),
            Text('時長', style: t.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (final m in _choices)
                  ChoiceChip(
                    label: Text('$m 分鐘'),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('換氣時輕敲鈴聲', style: t.bodyMedium),
              subtitle: Text('閉上眼睛也能跟著吸吐', style: t.bodySmall),
              value: _bells,
              onChanged: (v) => setState(() => _bells = v),
            ),
            const SizedBox(height: 4),
            Text('建議戴耳機；手機喇叭較難聽出低沉的聲音。', style: t.bodySmall),
            const SizedBox(height: 20),
            Center(
              child: FilledButton(
                onPressed: () {
                  _lastMinutes = _minutes;
                  _lastBells = _bells;
                  Navigator.of(context).pop(SessionSpec(
                    upper: info.upper,
                    lower: info.lower,
                    minutes: _minutes,
                    bells: _bells,
                  ));
                },
                child: const Text('開始'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
