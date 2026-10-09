import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../core/iching/cast_result.dart';
import '../../core/iching/divination_method.dart';
import '../../l10n/l10n.dart';
import '../../reading/reading_page.dart';
import '../premium/cast_gate.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/hexagram_glyph.dart';
import '../widgets/question_dialog.dart';

/// 逐爻起卦頁（擲錢、蓍草共用）：由初爻往上求六爻；含變爻與之卦。
/// 版面固定在一個畫面內：說明 → 卦象＋六爻表（空間不足時等比縮小）→ 底部按鈕。
class StepwiseCastPage extends StatefulWidget {
  const StepwiseCastPage({
    super.key,
    required this.method,
    required this.instructions,
    required this.stepLabel,
    required this.allLabel,
  });

  final StepwiseMethod method;
  final String Function(AppLocalizations l) instructions;

  /// 求第 n 爻的按鈕文字。
  final String Function(AppLocalizations l, int n) stepLabel;
  final String Function(AppLocalizations l) allLabel;

  @override
  State<StepwiseCastPage> createState() => _StepwiseCastPageState();
}

class _StepwiseCastPageState extends State<StepwiseCastPage> {
  StepwiseMethod get _method => widget.method;
  final List<LineStep> _tosses = [];
  String _question = '';

  bool get _done => _tosses.length == 6;

  bool _checking = false;

  /// 每一卦（六擲）只在第一擲前檢查一次免費次數（§23）。
  Future<bool> _allowed() async {
    if (_tosses.isNotEmpty) return true;
    if (_checking) return false;
    _checking = true;
    final ok = await ensureCanCast(context);
    _checking = false;
    return ok && mounted;
  }

  Future<void> _toss() async {
    if (_done || !await _allowed()) return;
    setState(() => _tosses.add(_method.step(AppServices.of(context).random)));
  }

  Future<void> _openReading(List<LineValue> lines) async {
    final ads = AppServices.of(context).ads;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReadingPage(cast: CastResult(methodId: _method.id, lines: lines), question: _question),
    ));
    ads.readingClosed(); // 看完解讀回來：依限頻規則可能跳插頁
  }

  Future<void> _tossAll() async {
    if (!await _allowed()) return;
    final r = AppServices.of(context).random;
    setState(() {
      while (_tosses.length < 6) {
        _tosses.add(_method.step(r));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final lines = [for (final x in _tosses) x.line];
    final padded = [...lines.map((l) => l.isYang), ...List.filled(6 - lines.length, false)];
    final changing = {
      for (var i = 0; i < lines.length; i++)
        if (lines[i].isChanging) i + 1
    };

    final top = [
      Text(
        widget.instructions(l),
        textAlign: TextAlign.center,
        style: t.bodySmall,
      ),
      // 擲完六次就不再寫想問的事（存進卦記時仍可修改）
      QuestionPrompt(
        question: _question,
        onChanged: (q) => setState(() => _question = q),
        enabled: !_done,
      ),
    ];
    final lineTable = LayoutBuilder(
      builder: (context, box) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          // 寬度取「內容自然寬度」與「可用寬度（至少 320、最多 480）」較大者：爻位名稱較長的語言
          // （阿拉伯文、泰文）或橫放時左欄窄，整塊等比縮小而不是被擠出畫面；平板不隨螢幕無限加寬。
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: box.maxWidth.clamp(320, 480).toDouble()),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  HexagramGlyph(
                    lines: padded,
                    changing: changing,
                    width: 104,
                    visibleCount: lines.length,
                  ),
                  const SizedBox(height: 20),
                  // 六列固定保留，未擲的爻顯示「—」，畫面不會隨擲錢跳動。
                  for (var i = 5; i >= 0; i--) _row(t, l, i, i < lines.length ? _tosses[i] : null),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final buttons = [
      if (!_done) ...[
        FilledButton(onPressed: _toss, child: Text(widget.stepLabel(l, _tosses.length + 1))),
        TextButton(onPressed: _tossAll, child: Text(widget.allLabel(l))),
      ] else ...[
        FilledButton(
          onPressed: () => _openReading(lines),
          child: Text(l.viewReading),
        ),
        TextButton(onPressed: () => setState(_tosses.clear), child: Text(l.coinsRestart)),
      ],
    ];

    return Scaffold(
      appBar: AppBar(), // 首頁連結已寫起卦方式，這裡不再重複標題
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => isShortWide(box.biggest)
              // 手機橫放：卦象與六爻在左、說明與按鈕在右
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
                  child: Row(
                    children: [
                      Expanded(child: lineTable),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: 320,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [...top, const SizedBox(height: 16), ...buttons],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                  child: Column(
                    children: [...top, Expanded(child: lineTable), ...buttons],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _row(TextTheme t, AppLocalizations l, int i, LineStep? toss) {
    final line = toss?.line;
    final next = i == _tosses.length;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          // 英文「Line 1」較寬；泰文「เส้นที่ 1」更寬，固定寬度會折行，所以只給最小寬度、依字寬伸展
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: l.isChinese ? 44 : 60),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(l.linePosition(i + 1),
                  softWrap: false,
                  style: t.titleMedium?.copyWith(
                    color: line == null && !next ? QianColors.textSub.withValues(alpha: 0.5) : null,
                  )),
            ),
          ),
          Text(toss?.detail ?? '', style: t.bodySmall),
          const Spacer(),
          const SizedBox(width: 12),
          Text(
            line == null
                ? '—'
                : '${l.coinLineValue(line.value, l.lineKind(line))}${line.isChanging ? l.coinChangingMark : ''}',
            style: t.bodyMedium?.copyWith(
              color: line == null
                  ? QianColors.textSub.withValues(alpha: 0.5)
                  : (line.isChanging ? QianColors.rice : QianColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
