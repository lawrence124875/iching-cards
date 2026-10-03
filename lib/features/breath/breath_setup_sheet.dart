import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/iching/hexagram_table.dart';
import '../../core/soundscape/session_renderer.dart';
import 'breath_page.dart';
import '../../l10n/l10n.dart';

/// 開始前的設定：時長 1／2／3／5 分鐘、換氣鈴聲、雙耳節拍（皆預設關閉）。
/// 文案只描述做法，不寫任何療效（Google Play 健康宣稱政策，HANDOFF §14.2）。
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
  static bool _lastBells = false; // 預設關閉（2026-10-02 使用者決定）

  int _minutes = _lastMinutes;
  bool _bells = _lastBells;
  static bool _lastBinaural = false;
  bool _binaural = _lastBinaural;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final info = HexagramTable.byNumber(widget.hexagram);
    final up = info.upper, lo = info.lower;
    final sounds = up == lo
        ? l.breathSoundSingle(l.trigramLabel(up), l.trigramImage(up), l.soundscape(up))
        : '${l.breathSoundUpper(l.trigramLabel(up), l.trigramImage(up), l.soundscape(up))}\n'
            '${l.breathSoundLower(l.trigramLabel(lo), l.trigramImage(lo), l.soundscape(lo))}';

    // 內容可捲動、底部讓出系統導覽列，「開始」不會被擋住（0.1.0+12）
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 20 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.breathSetupTitle(l.hexFullName(info)), style: t.titleMedium),
            const SizedBox(height: 8),
            Text(sounds, style: t.bodyMedium),
            const SizedBox(height: 4),
            Text(l.breathSetupNote, style: t.bodySmall),
            const SizedBox(height: 16),
            Text(l.breathDuration, style: t.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (final m in _choices)
                  ChoiceChip(
                    label: Text(l.minutes(m)),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l.breathBells, style: t.bodyMedium),
              subtitle: Text(l.breathBellsSub, style: t.bodySmall),
              value: _bells,
              onChanged: (v) => setState(() => _bells = v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l.breathBinaural, style: t.bodyMedium),
              subtitle: Text(l.breathBinauralSub, style: t.bodySmall),
              value: _binaural,
              onChanged: (v) => setState(() => _binaural = v),
            ),
            const SizedBox(height: 4),
            Text(l.breathHeadphones, style: t.bodySmall),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () {
                  _lastMinutes = _minutes;
                  _lastBells = _bells;
                  _lastBinaural = _binaural;
                  Navigator.of(context).pop(SessionSpec(
                    upper: info.upper,
                    lower: info.lower,
                    minutes: _minutes,
                    bells: _bells,
                    binaural: _binaural,
                  ));
                },
                child: Text(l.breathStart),
              ),
            ),
          ],
      ),
    );
  }
}
